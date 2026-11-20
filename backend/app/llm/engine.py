"""Self-hosted LLM Conversation Engine (llama.cpp / vLLM OpenAI-compatible API + adaptive local tutor)."""
from __future__ import annotations

import re
from typing import Any

import httpx

from app.config import settings
from app.models.schemas import GrammarCorrection

SYSTEM_PROMPT_TEMPLATE = """You are TALKORA AI, a warm, natural, open-ended AI English speaking companion.
Strict rules:
1. Always identify yourself clearly as an AI speaking companion if asked; never claim to be human.
2. Adapt vocabulary and sentence complexity to CEFR level: {cefr_level}.
3. Keep responses natural, conversational (2-4 sentences), never robotic or textbook-like.
4. Handle imperfect grammar and hesitations empathetically; ask a relevant follow-up question to keep the learner talking.
5. User learning goal: {learning_goal}. Preferred accent: {accent}.
6. Known learner focus areas from memory: {memory_context}.
"""

COMMON_GRAMMAR_PATTERNS: list[tuple[re.Pattern[str], str, str, str]] = [
    (
        re.compile(r"\bi am go\b", re.IGNORECASE),
        "I am going",
        "Use 'am going' (present continuous) instead of 'am go'.",
        "استخدم 'I am going' للمضارع المستمر بدلاً من 'I am go'.",
    ),
    (
        re.compile(r"\bhe don't\b", re.IGNORECASE),
        "he doesn't",
        "With 'he/she/it', use 'doesn't' instead of 'don't'.",
        "مع الضمائر he/she/it نستخدم doesn't بدلاً من don't.",
    ),
    (
        re.compile(r"\bshe don't\b", re.IGNORECASE),
        "she doesn't",
        "With 'he/she/it', use 'doesn't' instead of 'don't'.",
        "مع الضمائر he/she/it نستخدم doesn't بدلاً من don't.",
    ),
    (
        re.compile(r"\bi didn't went\b", re.IGNORECASE),
        "I didn't go",
        "After 'didn't', always use the base verb ('go', not 'went').",
        "بعد didn't نستخدم الفعل في المصدر (go وليس went).",
    ),
    (
        re.compile(r"\bmore better\b", re.IGNORECASE),
        "much better",
        "'Better' is already comparative; say 'much better' instead of 'more better'.",
        "كلمة better هي صيغة مقارنة بالفعل، لذا نقول much better.",
    ),
]


def analyze_grammar(user_text: str) -> GrammarCorrection:
    for pattern, replacement, exp_en, exp_ar in COMMON_GRAMMAR_PATTERNS:
        if pattern.search(user_text):
            corrected = pattern.sub(replacement, user_text)
            return GrammarCorrection(
                has_issue=True,
                original=user_text,
                corrected=corrected,
                explanation_en=exp_en,
                explanation_ar=exp_ar,
            )
    return GrammarCorrection(has_issue=False, original=user_text, corrected=user_text)


class ConversationLLMEngine:
    """Connects to self-hosted llama.cpp or vLLM OpenAI-compatible server, with intelligent local fallback."""

    def __init__(self) -> None:
        self.provider = settings.llm_provider
        self.base_url = settings.llm_base_url.rstrip("/")
        self.model = settings.llm_model

    async def generate_reply(
        self,
        user_text: str,
        history: list[dict[str, str]],
        profile: dict[str, Any],
        memory_context: str = "",
        topic: str = "Daily Life",
    ) -> dict[str, Any]:
        cefr = profile.get("english_level", "B1")
        goal = profile.get("learning_goal", "Fluency")
        accent = profile.get("preferred_accent", "American")
        system_prompt = SYSTEM_PROMPT_TEMPLATE.format(
            cefr_level=cefr,
            learning_goal=goal,
            accent=accent,
            memory_context=memory_context or "None yet",
        )

        reply_text = ""
        if self.provider in {"llama_cpp", "vllm"}:
            reply_text = await self._call_local_openai_server(system_prompt, history, user_text)

        if not reply_text:
            reply_text = self._generate_contextual_fallback(user_text, cefr=cefr, topic=topic, name=profile.get("display_name", "friend"))

        correction = analyze_grammar(user_text)
        arabic_translation = self._simple_arabic_gloss(reply_text)
        follow_ups = self._build_follow_ups(user_text, topic)

        return {
            "reply": reply_text,
            "arabic_translation": arabic_translation,
            "correction": correction,
            "follow_up_suggestions": follow_ups,
        }

    async def _call_local_openai_server(
        self, system_prompt: str, history: list[dict[str, str]], user_text: str
    ) -> str:
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-10:])
        messages.append({"role": "user", "content": user_text})
        try:
            async with httpx.AsyncClient(timeout=12.0) as client:
                resp = await client.post(
                    f"{self.base_url}/chat/completions",
                    json={
                        "model": self.model,
                        "messages": messages,
                        "temperature": 0.7,
                        "max_tokens": 220,
                    },
                )
                if resp.status_code == 200:
                    data = resp.json()
                    return data["choices"][0]["message"]["content"].strip()
        except Exception:
            pass
        return ""

    def _generate_contextual_fallback(self, user_text: str, cefr: str, topic: str, name: str) -> str:
        lower = user_text.lower()
        if any(k in lower for k in ["are you human", "real person", "who are you"]):
            return (
                f"I'm TALKORA AI, your self-hosted AI English speaking companion — not a real person, "
                f"just an AI designed to help you practice comfortably at your {cefr} level, {name}. "
                f"What topic would you love to talk about right now?"
            )
        if any(k in lower for k in ["programming", "flutter", "code", "python", "app", "tech"]):
            return (
                "That sounds like a really exciting tech topic! When you're building or debugging a project, "
                "talking through your architecture out loud is actually a fantastic way to build technical fluency. "
                "What part of the project has been the most interesting for you lately?"
            )
        if any(k in lower for k in ["travel", "trip", "airport", "flight", "hotel", "city"]):
            return (
                "Travel stories are one of the best ways to practice natural storytelling in English. "
                "If you could pack your bags and fly anywhere next month, where would you go first and what would you try there?"
            )
        if any(k in lower for k in ["work", "job", "interview", "meeting", "career"]):
            return (
                "Practicing workplace English makes a huge difference in confidence during meetings and interviews. "
                "Walk me through a typical day in your work, or tell me about a recent challenge you solved!"
            )
        if any(k in lower for k in ["food", "coffee", "cook", "restaurant", "eat"]):
            return (
                "Now you're speaking my language — food conversations are full of great descriptive vocabulary! "
                "What's a dish you could happily eat every week, and how would you describe its flavor?"
            )
        return (
            f"I hear you, {name}! That's a great point to explore in our {topic.lower()} conversation. "
            f"Could you tell me a little more about what made you think of that, or share a quick example from your week?"
        )

    def _simple_arabic_gloss(self, english_text: str) -> str:
        if "TALKORA AI" in english_text:
            return "أنا TALKORA AI، رفيقك الذكي لتعلم وممارسة التحدث بالإنجليزية. ما الموضوع الذي تود الحديث عنه الآن؟"
        if "tech" in english_text.lower():
            return "يبدو هذا موضوعاً تقنياً رائعاً! ما الجزء الأكثر إثارة في مشروعك مؤخراً؟"
        if "travel" in english_text.lower():
            return "قصص السفر طريقة ممتازة لممارسة الإنجليزية. إلى أين تود السفر لو أتيحت لك الفرصة الشهر القادم؟"
        return "رائع جداً! هل يمكنك إخباري بالمزيد عن هذا الموضوع أو مشاركة مثال سريع من أسبوعك؟"

    def _build_follow_ups(self, user_text: str, topic: str) -> list[str]:
        return [
            f"Tell me more about your experience with {topic.lower()}.",
            "Can you explain that phrase in simpler English?",
            "Let's switch to a quick role-play scenario.",
        ]


llm_engine = ConversationLLMEngine()
