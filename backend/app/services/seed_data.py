"""Curated CEFR A1-C2 learning seed content for Vocabulary, Grammar, Listening, and Daily Challenges."""
from __future__ import annotations

from app.database.db import db

STARTER_VOCABULARY = [
    {
        "id": "voc_001",
        "word": "articulate",
        "ipa": "/ɑːrˈtɪk.jə.lət/",
        "arabic_meaning": "فصيح / يُعبّر بوضوح",
        "english_definition": "Able to express ideas and feelings clearly and effectively in speech.",
        "example_sentence": "She is very articulate when explaining complex software architectures.",
        "cefr_level": "B2",
        "category": "communication",
        "audio_hint": "ar-TIK-yuh-luht",
    },
    {
        "id": "voc_002",
        "word": "commute",
        "ipa": "/kəˈmjuːt/",
        "arabic_meaning": "يتنقل يومياً للعمل أو الدراسة",
        "english_definition": "To travel regularly between home and work or school.",
        "example_sentence": "My morning commute takes about thirty minutes by metro.",
        "cefr_level": "B1",
        "category": "daily_life",
        "audio_hint": "kuh-MYOOT",
    },
    {
        "id": "voc_003",
        "word": "resilient",
        "ipa": "/rɪˈzɪl.jənt/",
        "arabic_meaning": "مرن / قادر على التعافي السريع",
        "english_definition": "Able to recover quickly from difficulties or adapt to change.",
        "example_sentence": "Building resilient habits helps you stay consistent with English practice.",
        "cefr_level": "C1",
        "category": "personal_growth",
        "audio_hint": "ri-ZIL-yuhnt",
    },
    {
        "id": "voc_004",
        "word": "itinerary",
        "ipa": "/aɪˈtɪn.ə.rer.i/",
        "arabic_meaning": "خط سير الرحلة / برنامج السفر",
        "english_definition": "A planned route or schedule for a journey.",
        "example_sentence": "Let us review our travel itinerary before heading to the airport.",
        "cefr_level": "B2",
        "category": "travel",
        "audio_hint": "eye-TIN-uh-rer-ee",
    },
    {
        "id": "voc_005",
        "word": "collaborate",
        "ipa": "/kəˈlæb.ə.reɪt/",
        "arabic_meaning": "يتعاون",
        "english_definition": "To work jointly with others on a shared project or goal.",
        "example_sentence": "Engineers and designers collaborate closely during every sprint.",
        "cefr_level": "B1",
        "category": "work",
        "audio_hint": "kuh-LAB-uh-rayt",
    },
    {
        "id": "voc_006",
        "word": "hesitate",
        "ipa": "/ˈhez.ɪ.teɪt/",
        "arabic_meaning": "يتردد",
        "english_definition": "To pause briefly before saying or doing something because of uncertainty.",
        "example_sentence": "Do not hesitate to ask follow-up questions during a conversation.",
        "cefr_level": "A2",
        "category": "communication",
        "audio_hint": "HEZ-i-tayt",
    },
    {
        "id": "voc_007",
        "word": "break the ice",
        "ipa": "/breɪk ði aɪs/",
        "arabic_meaning": "يكسر الجمود في بداية الحديث",
        "english_definition": "To say or do something to make people feel relaxed in a new situation.",
        "example_sentence": "A light joke is a great way to break the ice at a networking event.",
        "cefr_level": "B1",
        "category": "idioms",
        "audio_hint": "brayk thee eyes",
    },
    {
        "id": "voc_008",
        "word": "figure out",
        "ipa": "/ˈfɪɡ.jər aʊt/",
        "arabic_meaning": "يستنتج / يجد حلاً",
        "english_definition": "To understand or solve something after thinking about it.",
        "example_sentence": "We need to figure out why the WebSocket connection dropped.",
        "cefr_level": "A2",
        "category": "phrasal_verbs",
        "audio_hint": "FIG-yur owt",
    },
    {
        "id": "voc_009",
        "word": "nuance",
        "ipa": "/ˈnjuː.ɑːns/",
        "arabic_meaning": "فارق دقيق / دقة في المعنى",
        "english_definition": "A subtle difference in meaning, tone, or expression.",
        "example_sentence": "Listening to native podcasts helps you notice nuances in tone.",
        "cefr_level": "C1",
        "category": "communication",
        "audio_hint": "NYOO-ahns",
    },
    {
        "id": "voc_010",
        "word": "schedule",
        "ipa": "/ˈskedʒ.uːl/",
        "arabic_meaning": "جدول مواعيد",
        "english_definition": "A plan for carrying out tasks or events at specific times.",
        "example_sentence": "I keep fifteen minutes open on my schedule for daily speaking.",
        "cefr_level": "A1",
        "category": "daily_life",
        "audio_hint": "SKEJ-ool",
    },
]

GRAMMAR_LESSONS = [
    {
        "id": "gram_001",
        "title": "Present Perfect vs. Past Simple",
        "title_ar": "المضارع التام مقابل الماضي البسيط",
        "cefr_level": "B1",
        "explanation": "Use Past Simple for finished actions at a specific past time ('I visited London in 2023'). Use Present Perfect for life experiences or actions connected to now ('I have visited London twice').",
        "explanation_ar": "نستخدم الماضي البسيط للأحداث المنتهية في وقت محدد بالماضي، ونستخدم المضارع التام للخبرات الحياتية أو الأحداث المرتبطة بالحاضر.",
        "examples": [
            "I finished my report an hour ago. (Past Simple)",
            "I have worked on Flutter apps for three years. (Present Perfect)",
        ],
        "questions": [
            {
                "id": "q1",
                "prompt": "She ___ in Cairo since 2021.",
                "options": ["lived", "has lived", "is living", "lives"],
                "answer": "has lived",
                "tip": "Use Present Perfect with 'since' + a starting point in time.",
            },
            {
                "id": "q2",
                "prompt": "We ___ the museum yesterday afternoon.",
                "options": ["have visited", "visited", "visit", "were visit"],
                "answer": "visited",
                "tip": "'Yesterday afternoon' is a finished past time expression.",
            },
        ],
    },
    {
        "id": "gram_002",
        "title": "Articles: A, An, The, and Zero Article",
        "title_ar": "أدوات التعريف والتنكير",
        "cefr_level": "A2",
        "explanation": "Use 'a/an' for singular countable nouns mentioned for the first time, 'the' for specific known nouns, and no article for general plural or uncountable nouns.",
        "explanation_ar": "تُستخدم a/an للمفرد النكرة، وthe للمعرفة المحددة، وبدون أداة عند الحديث بشكل عام عن الجمع أو غير المعدود.",
        "examples": [
            "I bought a new microphone. The microphone sounds crystal clear.",
            "Music helps many learners relax.",
        ],
        "questions": [
            {
                "id": "q1",
                "prompt": "He is ___ engineer who builds voice assistants.",
                "options": ["a", "an", "the", "no article"],
                "answer": "an",
                "tip": "Use 'an' before vowel sounds like /e/ in 'engineer'.",
            },
            {
                "id": "q2",
                "prompt": "___ coffee in Egypt is often served strong and sweet.",
                "options": ["A", "An", "The", "No article"],
                "answer": "No article",
                "tip": "Uncountable nouns used generally take no article (or 'Coffee...').",
            },
        ],
    },
    {
        "id": "gram_003",
        "title": "Second Conditional for Hypotheticals",
        "title_ar": "الجملة الشرطية الثانية للمواقف الافتراضية",
        "cefr_level": "B2",
        "explanation": "Use 'If + Past Simple, would + base verb' to talk about imaginary or unlikely situations in the present or future.",
        "explanation_ar": "تُستخدم للتعبير عن مواقف خيالية أو غير محتملة في الحاضر أو المستقبل.",
        "examples": [
            "If I had more free time, I would learn Japanese too.",
            "What would you build if you had an unlimited GPU cluster?",
        ],
        "questions": [
            {
                "id": "q1",
                "prompt": "If I ___ closer to the office, I would walk every morning.",
                "options": ["live", "lived", "would live", "have lived"],
                "answer": "lived",
                "tip": "The 'if' clause in the 2nd conditional uses Past Simple.",
            },
        ],
    },
]

LISTENING_LESSONS = [
    {
        "id": "list_001",
        "title": "Ordering Specialty Coffee in London",
        "title_ar": "طلب القهوة المختصة في لندن",
        "accent": "British",
        "cefr_level": "A2",
        "duration_seconds": 45,
        "transcript": (
            "Barista: Good morning! What can I get started for you today? "
            "Customer: Hi there, could I have a medium flat white with oat milk, please? "
            "Barista: Of course. Would you like that to have here or to take away? "
            "Customer: To take away, thanks. Oh, and one almond croissant if you still have any."
        ),
        "questions": [
            {
                "id": "lq1",
                "prompt": "What kind of milk does the customer ask for?",
                "options": ["Whole milk", "Oat milk", "Soy milk", "Skim milk"],
                "answer": "Oat milk",
            },
            {
                "id": "lq2",
                "prompt": "Is the customer drinking the coffee inside the cafe?",
                "options": ["Yes, sitting inside", "No, taking it away"],
                "answer": "No, taking it away",
            },
        ],
    },
    {
        "id": "list_002",
        "title": "Daily Engineering Stand-Up Sync",
        "title_ar": "اجتماع المتابعة اليومي لفريق البرمجة",
        "accent": "American",
        "cefr_level": "B2",
        "duration_seconds": 65,
        "transcript": (
            "Lead: Morning everyone. Quick round of updates before we kick off sprint tasks. "
            "Developer: Yesterday I wired up the WebSocket audio streamer and reduced first-byte latency by thirty percent. "
            "Today I am adding barge-in interruption tests so playback halts immediately when a user speaks. No blockers so far."
        ),
        "questions": [
            {
                "id": "lq1",
                "prompt": "How much did the developer reduce first-byte latency?",
                "options": ["10%", "20%", "30%", "50%"],
                "answer": "30%",
            },
            {
                "id": "lq2",
                "prompt": "What is the developer working on today?",
                "options": ["Database migration", "Barge-in interruption tests", "UI splash screen", "App store release"],
                "answer": "Barge-in interruption tests",
            },
        ],
    },
]

DAILY_CHALLENGES = [
    {
        "id": "chal_daily_01",
        "topic": "Describe Your Ideal Productive Morning",
        "topic_ar": "صف صباحك المثالي والمنتج",
        "objective": "Speak naturally for 90 seconds using at least 2 sequence words (first, after that, finally) and 1 future plan.",
        "objective_ar": "تحدث بشكل طبيعي لمدة 90 ثانية مستخدماً كلمتي تسلسل على الأقل وخطة مستقبلية واحدة.",
        "suggested_duration_seconds": 90,
        "cefr_level": "B1",
        "starter_prompts": [
            "What time do you prefer to wake up and why?",
            "What is the first habit that sets your mood for the day?",
            "How do you avoid distractions before noon?",
        ],
    },
    {
        "id": "chal_daily_02",
        "topic": "Explain Your Favorite App to a Friend",
        "topic_ar": "اشرح تطبيقك المفضل لصديق",
        "objective": "Describe what problem it solves, why you enjoy its design, and one feature you would improve.",
        "objective_ar": "اذكر المشكلة التي يحلها التطبيق ولماذا يعجبك تصميمه وميزة واحدة تود تحسينها.",
        "suggested_duration_seconds": 120,
        "cefr_level": "B2",
        "starter_prompts": [
            "How did you discover the app?",
            "What makes it better than alternatives?",
        ],
    },
]


def seed_initial_data() -> None:
    with db.connect() as conn:
        for item in STARTER_VOCABULARY:
            conn.execute(
                """
                INSERT OR IGNORE INTO vocabulary_items
                (id, word, ipa, arabic_meaning, english_definition, example_sentence, cefr_level, category, audio_hint)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    item["id"],
                    item["word"],
                    item["ipa"],
                    item["arabic_meaning"],
                    item["english_definition"],
                    item["example_sentence"],
                    item["cefr_level"],
                    item["category"],
                    item["audio_hint"],
                ),
            )
