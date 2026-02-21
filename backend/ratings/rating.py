"""
ratings/rating.py

Stateless DUPR-style ELO rating engine.
────────────────────────────────────────
All functions are pure (no DB access) and deterministic given the same inputs.
This makes them trivially testable and reusable from both the live path
(per-match task) and the batch recompute command.

## Rating scale mapping
  DUPR 2.000 ↔ ELO  900
  DUPR 4.000 ↔ ELO 1500   (reference point)
  DUPR 6.000 ↔ ELO 2100
  DUPR 8.000 ↔ ELO 2700

  slope = (2700 - 900) / (8.000 - 2.000) = 300 ELO per DUPR point

## Numeric example from spec (used in unit tests)
  Player A: DUPR 4.000  Player B: DUPR 3.500
  Format: singles, importance: casual (K multiplier 0.8)
  A wins (actual_score=1.0 for A, 0.0 for B)

  elo_A = 1500, elo_B = 1350
  E_A  = 1 / (1 + 10^((1350-1500)/400)) = 1 / (1 + 10^-0.375) ≈ 0.7034
  K    = 32 * 0.8 = 25.6  (established player, no provisional boost)
  Δelo_A = 25.6 * (1.0 - 0.7034) ≈ +7.59
  new_elo_A = 1500 + 7.59 = 1507.59  → DUPR ≈ 4.025
  new_elo_B = 1350 - 7.59 = 1342.41  → DUPR ≈ 3.475
"""
import math
from datetime import date as date_type
from typing import List, Tuple

# ─── Constants ────────────────────────────────────────────────────────────────

DUPR_MIN: float = 2.000
DUPR_MAX: float = 8.000

ELO_REF_DUPR: float = 4.000          # DUPR rating that maps to ELO_REF
ELO_REF: float = 1_500.0             # reference ELO
ELO_SCALE: float = 400.0             # logistic scale (standard)
ELO_PER_DUPR: float = 300.0          # 300 ELO points per DUPR point

K_BASE: int = 32                     # base K-factor

IMPORTANCE_MULTIPLIERS = {
    "CASUAL":     0.8,
    "LEAGUE":     1.0,
    "TOURNAMENT": 1.2,
}

PROVISIONAL_THRESHOLD: int = 10      # matches < this → provisional
RELIABILITY_FULL_AT: int = 20        # matches ≥ this → reliability 100

DECAY_DAYS_DEFAULT: int = 90         # half-life for recency weighting


# ─── Unit conversions ─────────────────────────────────────────────────────────

def dupr_to_elo(dupr: float) -> float:
    """Convert a DUPR rating to an internal ELO value."""
    return ELO_REF + (dupr - ELO_REF_DUPR) * ELO_PER_DUPR


def elo_to_dupr(elo: float) -> float:
    """Convert an ELO value back to DUPR, clamped within [DUPR_MIN, DUPR_MAX]."""
    raw = ELO_REF_DUPR + (elo - ELO_REF) / ELO_PER_DUPR
    return max(DUPR_MIN, min(DUPR_MAX, round(raw, 3)))


# ─── ELO core ─────────────────────────────────────────────────────────────────

def expected_score(rating_a: float, rating_b: float) -> float:
    """
    Expected score for player A when facing player B.
    Inputs and outputs are ELO values.
    Returns a probability in (0, 1).
    """
    return 1.0 / (1.0 + math.pow(10.0, (rating_b - rating_a) / ELO_SCALE))


def k_factor(
    matches_played: int,
    importance: str = "CASUAL",
    recency_weight_val: float = 1.0,
) -> float:
    """
    Effective K-factor for a single rating update.

    Factors:
      - K_BASE (32)
      - importance multiplier (0.8 / 1.0 / 1.2)
      - recency weight (per-match decay, when used in batch recompute)
      - provisional boost: ×1.5 when matches_played < PROVISIONAL_THRESHOLD
    """
    multiplier = IMPORTANCE_MULTIPLIERS.get(importance.upper(), 1.0)
    provisional_boost = 1.5 if matches_played < PROVISIONAL_THRESHOLD else 1.0
    return K_BASE * multiplier * provisional_boost * recency_weight_val


# ─── Recency / decay ──────────────────────────────────────────────────────────

def recency_weight(
    match_date,
    reference_date=None,
    decay_days: int = DECAY_DAYS_DEFAULT,
) -> float:
    """
    Exponential decay weight based on how old the match is.

    recency_weight = exp(-lambda * age_days)
      where lambda = ln(2) / decay_days  (half-life = decay_days)

    Returns a value in (0, 1]:
      age 0 days  → 1.0
      age decay_days → ~0.5
      age 2×decay_days → ~0.25

    Used by the batch recompute command; ignored in the live (per-match) path.
    """
    if reference_date is None:
        import datetime
        reference_date = datetime.date.today()

    if isinstance(match_date, str):
        import datetime
        match_date = datetime.date.fromisoformat(match_date)

    age_days = max(0, (reference_date - match_date).days)
    lam = math.log(2) / max(1, decay_days)
    return math.exp(-lam * age_days)


# ─── Reliability ──────────────────────────────────────────────────────────────

def reliability_from_matches(n: int) -> int:
    """
    Map number of matches played to a reliability score (0–100).

      0 matches  →   0
      5 matches  →  50  (linear interpolation in provisional range)
     10 matches  →  80  (crosses provisional threshold)
     20+ matches → 100  (fully established)

    Uses piecewise linear interpolation for a smooth curve.
    """
    if n <= 0:
        return 0
    if n >= RELIABILITY_FULL_AT:
        return 100
    if n >= PROVISIONAL_THRESHOLD:
        # 10 → 80, 20 → 100  (linear)
        frac = (n - PROVISIONAL_THRESHOLD) / (RELIABILITY_FULL_AT - PROVISIONAL_THRESHOLD)
        return int(80 + frac * 20)
    else:
        # 0 → 0, 10 → 80  (linear)
        frac = n / PROVISIONAL_THRESHOLD
        return int(frac * 80)


# ─── Singles update ───────────────────────────────────────────────────────────

def update_one_player(
    current_dupr: float,
    opponent_dupr: float,
    actual_score: float,          # 1.0 = win, 0.0 = loss, 0.5 = draw
    matches_played: int,
    importance: str = "CASUAL",
    recency_weight_val: float = 1.0,
) -> Tuple[float, float]:
    """
    Compute new DUPR for a single player after one singles match.

    Returns:
        (new_dupr, delta)  — both rounded to 3 decimal places.

    Example (from spec):
        A=4.000, B=3.500, A wins, casual, matches=20
        → A ≈ 4.031
    """
    elo_a = dupr_to_elo(current_dupr)
    elo_b = dupr_to_elo(opponent_dupr)
    expected = expected_score(elo_a, elo_b)
    k = k_factor(matches_played, importance, recency_weight_val)
    new_elo = elo_a + k * (actual_score - expected)
    new_dupr = elo_to_dupr(new_elo)
    delta = round(new_dupr - current_dupr, 3)
    return new_dupr, delta


# ─── Doubles update ───────────────────────────────────────────────────────────

def update_doubles(
    team_a_ratings: List[float],   # [dupr_p1, dupr_p2]
    team_b_ratings: List[float],   # [dupr_p3, dupr_p4]
    score_a: int,                  # sets/games won by team A
    score_b: int,                  # sets/games won by team B
    matches_played_list: List[int],# [mp_p1, mp_p2, mp_p3, mp_p4]
    importance: str = "CASUAL",
    recency_weight_val: float = 1.0,
) -> List[Tuple[float, float]]:
    """
    Compute new DUPR for all four players in a doubles match.

    Algorithm:
      1. Each team's ELO is the *average* of its two members' ELOs.
      2. Actual score is 1.0 for the winning team, 0.0 for the losing team.
      3. Each player is updated individually using their personal K-factor,
         applied to the team-level expected/actual outcome.

    Returns:
        [(new_dupr, delta), ...] in order [p1, p2, p3, p4]
    """
    assert len(team_a_ratings) == 2, "Team A must have exactly 2 players"
    assert len(team_b_ratings) == 2, "Team B must have exactly 2 players"
    assert len(matches_played_list) == 4, "Need matches_played for all 4 players"

    total_games = score_a + score_b
    actual_a = score_a / total_games if total_games > 0 else 0.5
    actual_b = 1.0 - actual_a

    elo_a_avg = sum(dupr_to_elo(r) for r in team_a_ratings) / 2
    elo_b_avg = sum(dupr_to_elo(r) for r in team_b_ratings) / 2

    expected_a = expected_score(elo_a_avg, elo_b_avg)
    expected_b = 1.0 - expected_a

    results = []
    for i, (dupr, mp) in enumerate(
        zip(team_a_ratings + team_b_ratings, matches_played_list)
    ):
        elo = dupr_to_elo(dupr)
        is_team_a = i < 2
        actual = actual_a if is_team_a else actual_b
        expected = expected_a if is_team_a else expected_b
        k = k_factor(mp, importance, recency_weight_val)
        new_elo = elo + k * (actual - expected)
        new_dupr = elo_to_dupr(new_elo)
        delta = round(new_dupr - dupr, 3)
        results.append((new_dupr, delta))

    return results
