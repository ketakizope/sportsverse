# backend/api/ai_utils.py
#
# Two-stage Gemini pipeline for SportsVerse chatbot.
# Uses `google-genai` SDK (google.genai).
#
# Model priority (most generous free tier first):
#   1. gemini-2.0-flash-lite  — highest free RPM on most projects
#   2. gemini-2.5-flash-preview-05-20  — fallback if lite unavailable
#
# Handles 429 RESOURCE_EXHAUSTED with automatic retry + backoff.

import json
import time
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

# ── Singleton client ──────────────────────────────────────────────────────────

_client = None

def _get_client():
    global _client
    if _client is not None:
        return _client
    key = getattr(settings, 'GEMINI_API_KEY', None)
    if not key:
        raise EnvironmentError(
            "GEMINI_API_KEY is not set. "
            "Add GEMINI_API_KEY=your_key to backend/.env and restart the server."
        )
    from google import genai
    _client = genai.Client(api_key=key)
    return _client


# ── Model priority (confirmed available for this API key) ────────────────────
# Ordered lightest → heavier to maximize free-tier chance.
# Run: python -c "from api.ai_utils import _get_client; [print(m.name) for m in _get_client().models.list()]"
# to see your own list.
_MODEL_PRIORITY = [
    "gemini-2.5-flash-lite",      # Lightest Gemini 2.5 — best free quota
    "gemini-2.0-flash-lite",      # Gemini 2.0 lite fallback
    "gemini-2.5-flash",           # Full flash if lite exhausted
    "gemini-2.0-flash",           # Last resort
]


def _call_gemini(contents: str, system_instruction: str,
                 temperature: float = 0.1, max_output_tokens: int = 256) -> str:
    """
    Try each model in _MODEL_PRIORITY.
    For 429 errors: wait the suggested retry-delay and try again once.
    Raises the last exception if all models fail.
    """
    from google.genai import types

    client = _get_client()
    last_error = None

    for model in _MODEL_PRIORITY:
        # Two attempts per model: first try + one 429 retry
        for attempt in range(2):
            try:
                response = client.models.generate_content(
                    model=model,
                    contents=contents,
                    config=types.GenerateContentConfig(
                        system_instruction=system_instruction,
                        temperature=temperature,
                        max_output_tokens=max_output_tokens,
                    ),
                )
                logger.debug("Gemini OK with model=%s attempt=%d", model, attempt + 1)
                return response.text.strip()

            except Exception as e:
                err_str = str(e)
                if '429' in err_str or 'RESOURCE_EXHAUSTED' in err_str:
                    # Extract suggested retry delay from error message (default 10s)
                    retry_delay = 10
                    try:
                        import re
                        match = re.search(r'retryDelay.*?(\d+)s', err_str)
                        if match:
                            retry_delay = int(match.group(1)) + 1
                    except Exception:
                        pass

                    if attempt == 0:
                        logger.warning(
                            "429 on model=%s, waiting %ds then retrying...",
                            model, retry_delay
                        )
                        time.sleep(retry_delay)
                        continue  # retry same model
                    else:
                        # Both attempts failed on this model — try next model
                        logger.warning("429 persists on model=%s, trying next model.", model)
                        last_error = e
                        break
                else:
                    # Non-quota error (auth, model-not-found, etc.) — try next model
                    logger.warning("Gemini error on model=%s: %s", model, e)
                    last_error = e
                    break

    raise last_error or Exception("All Gemini models failed.")


# ── Role-specific intent catalogues ──────────────────────────────────────────

_ADMIN_INTENTS = [
    "get_dashboard_summary", "get_attendance_for_batch", "get_student_list",
    "get_unpaid_fees", "get_student_fees", "get_batch_students",
    "get_branch_batches", "get_coach_assignments", "get_fee_collection_summary",
    "get_active_enrollments",
]
_COACH_INTENTS = [
    "get_my_schedule", "get_my_batch_students",
    "get_student_attendance", "get_attendance_summary",
]
_STUDENT_INTENTS = [
    "get_my_attendance", "get_my_payments", "get_my_payment_summary",
    "get_my_schedule", "get_my_enrollment", "get_sessions_remaining",
]


def get_role_intents(role: str) -> list:
    return {
        'ACADEMY_ADMIN': _ADMIN_INTENTS,
        'COACH': _COACH_INTENTS,
        'STUDENT': _STUDENT_INTENTS,
    }.get(role, [])


# ── Stage 1: Intent Detection ─────────────────────────────────────────────────

def parse_intent(user_text: str, role: str, user_id: int, org_id: int,
                 extra_context: dict = None) -> dict:
    """
    Returns: { "intent": str, "params": dict, "confidence": float }
    """
    intents = get_role_intents(role)
    extra = extra_context or {}

    scope_lines = {
        'ACADEMY_ADMIN': (
            f"You are an intent parser for an ACADEMY_ADMIN (user_id={user_id}, org_id={org_id}). "
            "They can query students, coaches, batches, branches, attendance, and payments "
            "ONLY within their own organization."
        ),
        'COACH': (
            f"You are an intent parser for a COACH (user_id={user_id}, org_id={org_id}). "
            f"Assigned batch IDs: {extra.get('assigned_batch_ids', [])}. "
            "They must NOT access fee data, salary data, or students outside their batches."
        ),
        'STUDENT': (
            f"You are an intent parser for a STUDENT "
            f"(user_id={user_id}, student_id={extra.get('student_id', '?')}, org_id={org_id}). "
            "They can ONLY query their own attendance, payments, schedule, and enrollment."
        ),
    }.get(role, f"Intent parser for role={role}.")

    system_prompt = (
        f"{scope_lines}\n\n"
        "Extract the user's intent and parameters. "
        "Respond ONLY with a single valid JSON object — no markdown fences, no extra text.\n"
        '{ "intent": "<name>", "params": { ... }, "confidence": <0.0-1.0> }\n\n'
        f"Valid intents: {json.dumps(intents)}\n\n"
        "If unclear or out-of-scope: "
        '{ "intent": "unknown", "params": {}, "confidence": 0.0 }\n\n'
        "Param keys: batch_name, branch_name, student_name, month, date, status."
    )

    raw = ''
    try:
        raw = _call_gemini(
            contents=user_text,
            system_instruction=system_prompt,
            temperature=0.1,
            max_output_tokens=256,
        )

        # Strip markdown fences if present
        if raw.startswith("```"):
            parts = raw.split("```")
            raw = parts[1] if len(parts) > 1 else raw
            if raw.startswith("json"):
                raw = raw[4:]
        raw = raw.strip()

        result = json.loads(raw)
        if not isinstance(result, dict) or 'intent' not in result:
            raise ValueError("Malformed intent JSON")
        result.setdefault('params', {})
        result.setdefault('confidence', 0.0)
        logger.debug("Stage 1 OK: %s", result)
        return result

    except json.JSONDecodeError as e:
        logger.warning("Stage 1 JSON parse failed: %s | raw=%s", e, raw[:200])
        return {"intent": "unknown", "params": {}, "confidence": 0.0}
    except Exception as e:
        logger.error("Stage 1 Gemini error: %s", e)
        return {"intent": "unknown", "params": {}, "confidence": 0.0}


# ── Stage 2: Natural Language Response ───────────────────────────────────────

def generate_response(original_query: str, api_data, role: str) -> str:
    """
    Turn structured API data into a friendly natural-language reply.
    """
    if api_data is None:
        data_str = "No data was found."
    elif isinstance(api_data, (dict, list)):
        data_str = json.dumps(api_data, default=str)
    else:
        data_str = str(api_data)

    system_prompt = (
        "You are a helpful, friendly AI assistant for SportsVerse, a sports academy management app.\n"
        "Rules:\n"
        "- Use ONLY the data provided. Never fabricate or estimate.\n"
        "- If the data is empty, say so honestly.\n"
        "- Keep responses under 4 sentences unless presenting a list (use • bullets).\n"
        "- Use ₹ for currency. Be warm and professional.\n"
        "- Never expose internal field names like 'org_id' or 'enrollment_id' to the user.\n"
    )

    prompt = (
        f"User asked: \"{original_query}\"\n\n"
        f"Data:\n{data_str}\n\n"
        "Generate a clear, friendly response."
    )

    try:
        return _call_gemini(
            contents=prompt,
            system_instruction=system_prompt,
            temperature=0.7,
            max_output_tokens=512,
        )
    except Exception as e:
        logger.error("Stage 2 Gemini error: %s", e)
        return "The AI assistant is temporarily unavailable. Please use the app directly."