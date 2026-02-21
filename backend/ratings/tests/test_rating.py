"""
ratings/tests/test_rating.py

Unit tests for the stateless DUPR-style rating engine (ratings/rating.py).
All tests use deterministic numeric inputs; no database is required.

Run with:
    python manage.py test ratings.tests.test_rating --verbosity=2
"""
import math
import datetime
from django.test import SimpleTestCase

from ratings.rating import (
    DUPR_MIN,
    DUPR_MAX,
    ELO_REF,
    ELO_PER_DUPR,
    K_BASE,
    PROVISIONAL_THRESHOLD,
    dupr_to_elo,
    elo_to_dupr,
    expected_score,
    k_factor,
    recency_weight,
    reliability_from_matches,
    update_one_player,
    update_doubles,
)


class TestDuprEloConversions(SimpleTestCase):
    """dupr_to_elo and elo_to_dupr round-trip tests."""

    def test_reference_point(self):
        """DUPR 4.000 should map to ELO 1500."""
        self.assertAlmostEqual(dupr_to_elo(4.000), 1500.0, places=3)

    def test_dupr_2_maps_to_900(self):
        self.assertAlmostEqual(dupr_to_elo(2.000), 900.0, places=3)

    def test_dupr_8_maps_to_2700(self):
        self.assertAlmostEqual(dupr_to_elo(8.000), 2700.0, places=3)

    def test_elo_roundtrip(self):
        """elo_to_dupr(dupr_to_elo(x)) == x for all within range."""
        for dupr in [2.000, 3.000, 3.500, 4.000, 5.250, 7.000, 8.000]:
            self.assertAlmostEqual(elo_to_dupr(dupr_to_elo(dupr)), dupr, places=3)

    def test_clamp_below_min(self):
        """ELO below minimum clamps to DUPR_MIN."""
        self.assertEqual(elo_to_dupr(0.0), DUPR_MIN)

    def test_clamp_above_max(self):
        """ELO above maximum clamps to DUPR_MAX."""
        self.assertEqual(elo_to_dupr(99999.0), DUPR_MAX)

    def test_monotonically_increasing(self):
        """Higher DUPR → higher ELO."""
        elos = [dupr_to_elo(d) for d in [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]]
        self.assertEqual(elos, sorted(elos))


class TestExpectedScore(SimpleTestCase):
    """expected_score tests."""

    def test_equal_ratings_fifty_fifty(self):
        """Equal ELO ratings → 0.5 expected score."""
        self.assertAlmostEqual(expected_score(1500, 1500), 0.5, places=5)

    def test_higher_rating_favoured(self):
        """Higher-rated player has E > 0.5."""
        e = expected_score(1600, 1400)
        self.assertGreater(e, 0.5)

    def test_lower_rating_unfavoured(self):
        """Lower-rated player has E < 0.5."""
        e = expected_score(1400, 1600)
        self.assertLess(e, 0.5)

    def test_symmetry(self):
        """expected_score(a, b) + expected_score(b, a) == 1.0."""
        for a, b in [(1500, 1350), (1700, 1200), (900, 2700)]:
            self.assertAlmostEqual(expected_score(a, b) + expected_score(b, a), 1.0, places=9)

    def test_known_value(self):
        """A=4.000 (ELO 1500), B=3.500 (ELO 1350): E_A ≈ 0.703."""
        elo_a = dupr_to_elo(4.000)
        elo_b = dupr_to_elo(3.500)
        e = expected_score(elo_a, elo_b)
        # 1 / (1 + 10^((1350-1500)/400)) = 1 / (1 + 10^(-0.375)) ≈ 0.7034
        self.assertAlmostEqual(e, 0.7034, delta=0.001)


class TestKFactor(SimpleTestCase):
    """k_factor tests."""

    def test_casual_multiplier(self):
        """Casual K = K_BASE × 0.8 × boost × recency"""
        k = k_factor(matches_played=30, importance="CASUAL", recency_weight_val=1.0)
        self.assertAlmostEqual(k, K_BASE * 0.8, places=5)

    def test_league_multiplier(self):
        """League K = K_BASE × 1.0"""
        k = k_factor(matches_played=30, importance="LEAGUE", recency_weight_val=1.0)
        self.assertAlmostEqual(k, K_BASE * 1.0, places=5)

    def test_tournament_multiplier(self):
        """Tournament K = K_BASE × 1.2"""
        k = k_factor(matches_played=30, importance="TOURNAMENT", recency_weight_val=1.0)
        self.assertAlmostEqual(k, K_BASE * 1.2, places=5)

    def test_provisional_boost(self):
        """Players with < 10 matches get a 1.5× provisional boost."""
        k_prov = k_factor(matches_played=3, importance="CASUAL", recency_weight_val=1.0)
        k_estab = k_factor(matches_played=20, importance="CASUAL", recency_weight_val=1.0)
        self.assertAlmostEqual(k_prov, k_estab * 1.5, places=5)

    def test_recency_weight_applied(self):
        """Recency weight scales K proportionally."""
        k_full = k_factor(30, "LEAGUE", recency_weight_val=1.0)
        k_half = k_factor(30, "LEAGUE", recency_weight_val=0.5)
        self.assertAlmostEqual(k_half, k_full * 0.5, places=5)

    def test_k_always_positive(self):
        """K-factor is always positive."""
        for mp in [0, 1, 5, 9, 10, 25, 100]:
            for imp in ["CASUAL", "LEAGUE", "TOURNAMENT"]:
                self.assertGreater(k_factor(mp, imp), 0)


class TestRecencyWeight(SimpleTestCase):
    """recency_weight tests."""

    def _reference(self):
        return datetime.date(2026, 3, 1)

    def test_same_day_weight_is_one(self):
        ref = self._reference()
        w = recency_weight(ref, reference_date=ref, decay_days=90)
        self.assertAlmostEqual(w, 1.0, places=9)

    def test_half_life_decay(self):
        """At age == decay_days, weight should be ~0.5."""
        ref = datetime.date(2026, 3, 1)
        match = datetime.date(2025, 12, 1)  # 90 days ago
        w = recency_weight(match, reference_date=ref, decay_days=90)
        self.assertAlmostEqual(w, 0.5, delta=0.02)

    def test_double_half_life(self):
        """At age == 2×decay_days, weight ≈ 0.25."""
        ref = datetime.date(2026, 3, 1)
        match = datetime.date(2025, 9, 2)  # ~180 days ago
        w = recency_weight(match, reference_date=ref, decay_days=90)
        self.assertAlmostEqual(w, 0.25, delta=0.03)

    def test_weight_always_positive(self):
        ref = datetime.date(2026, 3, 1)
        match = datetime.date(2020, 1, 1)    # very old
        self.assertGreater(recency_weight(match, ref, 90), 0)

    def test_weight_at_most_one(self):
        ref = datetime.date(2026, 3, 1)
        self.assertLessEqual(recency_weight(ref, ref), 1.0)

    def test_string_date_input(self):
        """Accepts ISO date string."""
        ref = datetime.date(2026, 3, 1)
        w = recency_weight("2026-03-01", reference_date=ref, decay_days=90)
        self.assertAlmostEqual(w, 1.0, places=9)


class TestReliability(SimpleTestCase):
    """reliability_from_matches tests."""

    def test_zero_matches(self):
        self.assertEqual(reliability_from_matches(0), 0)

    def test_five_matches(self):
        r = reliability_from_matches(5)
        self.assertEqual(r, 40)   # int(5/10 * 80) = 40

    def test_provisional_threshold(self):
        """Exactly 10 matches → reliability 80."""
        self.assertEqual(reliability_from_matches(PROVISIONAL_THRESHOLD), 80)

    def test_full_reliability(self):
        """20+ matches → reliability 100."""
        self.assertEqual(reliability_from_matches(20), 100)
        self.assertEqual(reliability_from_matches(50), 100)

    def test_monotonically_increasing(self):
        vals = [reliability_from_matches(n) for n in range(0, 25)]
        self.assertEqual(vals, sorted(vals))

    def test_range_0_to_100(self):
        for n in range(0, 50):
            r = reliability_from_matches(n)
            self.assertGreaterEqual(r, 0)
            self.assertLessEqual(r, 100)


class TestUpdateOnePlayer(SimpleTestCase):
    """update_one_player — spec numeric example."""

    def test_spec_example_winner(self):
        """
        Spec example: A=4.000, B=3.500, A wins, casual, 20 matches.
        E_A ≈ 0.703 (ELO gap 150, scale 400).
        K = 32 * 0.8 = 25.6 (established, casual)
        Δelo = 25.6 * (1.0 - 0.703) ≈ +7.6 → DUPR ≈ 4.025
        A should gain rating (delta > 0).
        """
        new_dupr, delta = update_one_player(
            current_dupr=4.000,
            opponent_dupr=3.500,
            actual_score=1.0,
            matches_played=20,
            importance="CASUAL",
        )
        self.assertGreater(delta, 0, "Winner should gain rating")
        self.assertGreater(new_dupr, 4.000)
        # Rough bound: small gain because A was strongly favoured
        self.assertAlmostEqual(new_dupr, 4.025, delta=0.010)

    def test_spec_example_loser(self):
        """
        Spec example: B=3.500 loses to A=4.000 (casual, 20 matches).
        E_B ≈ 0.297. K = 25.6. Δelo = 25.6 * (0.0 - 0.297) ≈ -7.6 → DUPR ≈ 3.475
        B should lose rating (delta < 0).
        """
        new_dupr, delta = update_one_player(
            current_dupr=3.500,
            opponent_dupr=4.000,
            actual_score=0.0,
            matches_played=20,
            importance="CASUAL",
        )
        self.assertLess(delta, 0, "Loser should lose rating")
        self.assertLess(new_dupr, 3.500)
        self.assertAlmostEqual(new_dupr, 3.475, delta=0.010)

    def test_upset_winner_gains_more(self):
        """Upset winner (lower rated beats higher) gains more rating."""
        # Low-rated beats high-rated
        new_low, delta_low = update_one_player(3.000, 5.000, 1.0, 20, "CASUAL")
        # High-rated beats low-rated (expected outcome)
        new_high, delta_high = update_one_player(5.000, 3.000, 1.0, 20, "CASUAL")
        self.assertGreater(delta_low, delta_high, "Upset winner gains more")

    def test_win_loss_zero_sum(self):
        """Rating gained by winner + lost by loser ≈ 0 (ELO is zero-sum)."""
        _, delta_win = update_one_player(4.0, 4.0, 1.0, 20, "CASUAL")
        _, delta_loss = update_one_player(4.0, 4.0, 0.0, 20, "CASUAL")
        self.assertAlmostEqual(delta_win + delta_loss, 0.0, delta=0.005)

    def test_draw_equal_rating_no_change(self):
        """Equal rating draw → no change."""
        _, delta = update_one_player(4.0, 4.0, 0.5, 20, "CASUAL")
        self.assertAlmostEqual(delta, 0.0, places=5)

    def test_tournament_bigger_swing(self):
        """Tournament importance produces larger rating swing than casual."""
        _, d_casual = update_one_player(4.0, 4.0, 1.0, 20, "CASUAL")
        _, d_tourn = update_one_player(4.0, 4.0, 1.0, 20, "TOURNAMENT")
        self.assertGreater(d_tourn, d_casual)

    def test_output_clamped_to_range(self):
        """Rating cannot go below DUPR_MIN or above DUPR_MAX."""
        new_high, _ = update_one_player(7.999, 2.001, 1.0, 100, "TOURNAMENT")
        self.assertLessEqual(new_high, DUPR_MAX)
        new_low, _ = update_one_player(2.001, 7.999, 0.0, 100, "TOURNAMENT")
        self.assertGreaterEqual(new_low, DUPR_MIN)


class TestUpdateDoubles(SimpleTestCase):
    """update_doubles tests."""

    def test_winning_team_gains(self):
        """Every player on the winning team should gain rating."""
        results = update_doubles(
            team_a_ratings=[4.0, 4.0],
            team_b_ratings=[4.0, 4.0],
            score_a=6, score_b=3,
            matches_played_list=[20, 20, 20, 20],
            importance="CASUAL",
        )
        team_a = results[:2]
        team_b = results[2:]
        for _, delta in team_a:
            self.assertGreater(delta, 0)
        for _, delta in team_b:
            self.assertLess(delta, 0)

    def test_zero_sum_between_teams(self):
        """
        With equal ratings/K the net gain across winning team ≈ net loss of losing team.
        We check that winning team total delta > 0 and losing team total delta < 0.
        """
        results = update_doubles(
            [4.0, 4.0], [4.0, 4.0],
            6, 3, [20, 20, 20, 20], "CASUAL",
        )
        team_a_total = sum(d for _, d in results[:2])
        team_b_total = sum(d for _, d in results[2:])
        self.assertGreater(team_a_total, 0, "Winning team should have net positive delta")
        self.assertLess(team_b_total, 0, "Losing team should have net negative delta")

    def test_symmetric_teams(self):
        """
        Use a decisive 7-0 score (actual_a=1.0) so the winning team's actual
        score always exceeds their expected score regardless of rating gap,
        guaranteeing delta > 0 for winners and delta < 0 for losers.
        """
        # Scenario 1: team A (4.0, 4.0) wins 7-0 over team B (3.5, 3.5)
        r_a_wins = update_doubles([4.0, 4.0], [3.5, 3.5], 7, 0, [20]*4, "CASUAL")
        for _, delta in r_a_wins[:2]:  # team A (winners)
            self.assertGreater(delta, 0, "Decisive winners should gain")
        for _, delta in r_a_wins[2:]:  # team B (losers)
            self.assertLess(delta, 0, "Decisively beaten team should lose")

        # Scenario 2: upset — team B (3.5, 3.5) beats team A (4.0, 4.0) 7-0
        r_b_wins = update_doubles([4.0, 4.0], [3.5, 3.5], 0, 7, [20]*4, "CASUAL")
        for _, delta in r_b_wins[:2]:  # team A (listed first, lost)
            self.assertLess(delta, 0, "Team A 0-7 losers should lose")
        for _, delta in r_b_wins[2:]:  # team B (upset winners)
            self.assertGreater(delta, 0, "Upset 7-0 winners should gain")

    def test_returns_four_results(self):
        results = update_doubles([4.0, 4.0], [4.0, 4.0], 6, 3, [20]*4, "CASUAL")
        self.assertEqual(len(results), 4)

    def test_all_results_in_range(self):
        results = update_doubles([4.0, 4.0], [4.0, 4.0], 6, 3, [20]*4, "TOURNAMENT")
        for new_dupr, _ in results:
            self.assertGreaterEqual(new_dupr, DUPR_MIN)
            self.assertLessEqual(new_dupr, DUPR_MAX)
