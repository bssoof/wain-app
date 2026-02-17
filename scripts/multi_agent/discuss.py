"""
🤖 Multi-Agent Discussion Script
=================================
يجمع نموذجين AI لمناقشة وتحسين خطة التطوير.

Mode 1 (default): Gemini Flash vs Gemini Pro  (free!)
Mode 2: Gemini + OpenAI GPT-4o               (needs OpenAI credits)

Usage:
  pip install google-genai python-dotenv openai
  python discuss.py              # Gemini-only mode
  python discuss.py --with-openai  # With OpenAI
"""

import os
import sys
from datetime import datetime
from pathlib import Path

try:
    from dotenv import load_dotenv
    from google import genai
except ImportError:
    print("❌ Missing dependencies. Run:")
    print("   pip install google-genai python-dotenv")
    sys.exit(1)

# Load API keys from .env file
SCRIPT_DIR = Path(__file__).parent
load_dotenv(SCRIPT_DIR / ".env")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

USE_OPENAI = "--with-openai" in sys.argv and OPENAI_API_KEY and "xxxxx" not in OPENAI_API_KEY

if not GEMINI_API_KEY or "xxxxx" in GEMINI_API_KEY:
    print("❌ Please set your GEMINI_API_KEY in the .env file")
    print(f"   File location: {SCRIPT_DIR / '.env'}")
    sys.exit(1)

# Configure APIs
gemini_client = genai.Client(api_key=GEMINI_API_KEY)

openai_client = None
if USE_OPENAI:
    try:
        import openai
        openai_client = openai.OpenAI(api_key=OPENAI_API_KEY)
    except ImportError:
        print("⚠️  openai package not installed, using Gemini-only mode")
        USE_OPENAI = False

PLAN_FILE = SCRIPT_DIR / "plan.md"
OUTPUT_DIR = SCRIPT_DIR / "discussions"
OUTPUT_DIR.mkdir(exist_ok=True)

# Agent configurations
AGENT_A_NAME = "Agent A (Architect)"
AGENT_B_NAME = "Agent B (Critic)"

AGENT_A_PERSONA = """أنت مهندس معماري برمجيات خبير في Flutter و Firebase.
تميل للحلول العملية والسريعة. تركز على تجربة المستخدم والأداء.
اسمك "Agent A - المعماري".
اكتب بالعربية. كن محدداً وعملياً."""

AGENT_B_PERSONA = """أنت مراجع كود صارم وخبير أمان في Flutter و Firebase.
تميل للتدقيق والتفاصيل. تركز على الأمان والجودة وقابلية الصيانة.
اسمك "Agent B - الناقد".
اكتب بالعربية. كن نقدياً وصريحاً."""


def call_agent_a(prompt: str) -> str:
    """Agent A: Uses Gemini Pro (creative, architectural thinking)."""
    try:
        response = gemini_client.models.generate_content(
            model="gemini-2.5-pro",
            contents=f"{AGENT_A_PERSONA}\n\n{prompt}",
        )
        return response.text
    except Exception as e:
        return f"❌ Agent A Error: {e}"


def call_agent_b(prompt: str) -> str:
    """Agent B: Uses OpenAI or Gemini Flash (critical, detail-oriented)."""
    if USE_OPENAI and openai_client:
        try:
            response = openai_client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": AGENT_B_PERSONA},
                    {"role": "user", "content": prompt},
                ],
                max_tokens=4000,
                temperature=0.7,
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"❌ Agent B (OpenAI) Error: {e}"
    else:
        try:
            response = gemini_client.models.generate_content(
                model="gemini-2.5-flash",
                contents=f"{AGENT_B_PERSONA}\n\n{prompt}",
            )
            return response.text
        except Exception as e:
            return f"❌ Agent B Error: {e}"


def run_discussion(plan: str, rounds: int = 3):
    """Run a multi-round discussion between agents."""

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = OUTPUT_DIR / f"discussion_{timestamp}.md"
    
    discussion_log = []
    
    def log(text: str):
        discussion_log.append(text)
        print(text)

    mode = "Gemini Pro + GPT-4o" if USE_OPENAI else "Gemini Pro + Gemini Flash"
    
    log("# 🤖 Multi-Agent Discussion")
    log(f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    log(f"**Mode:** {mode}\n")
    log("---\n")
    log("## 📋 Original Plan\n")
    log(f"{plan}\n")
    log("---\n")

    review_prompt = """راجع هذه الخطة بشكل نقدي وبنّاء:

{plan}

قدم:
1. **نقاط القوة** (3 نقاط)
2. **نقاط الضعف أو المخاطر** (3 نقاط على الأقل)
3. **اقتراحات تحسين محددة** (3 اقتراحات)
4. **ترتيب الأولويات المقترح**"""

    # ============================================
    # Round 1: Initial Reviews
    # ============================================
    log("## 🔄 Round 1: المراجعة الأولية\n")

    log(f"### 🟦 {AGENT_A_NAME}:\n")
    print(f"   ⏳ Waiting for {AGENT_A_NAME}...")
    agent_a_review = call_agent_a(review_prompt.format(plan=plan))
    log(f"{agent_a_review}\n")

    log(f"### 🟧 {AGENT_B_NAME}:\n")
    print(f"   ⏳ Waiting for {AGENT_B_NAME}...")
    agent_b_review = call_agent_b(review_prompt.format(plan=plan))
    log(f"{agent_b_review}\n")

    # ============================================
    # Rounds 2+: Cross-critique
    # ============================================
    cross_prompt = """الخطة الأصلية:
{plan}

زميلك قدم هذه الملاحظات:
{other_review}

ردك:
1. ما هي الملاحظات التي توافق عليها؟ ولماذا؟
2. ما هي التي تختلف معها؟ وما البديل الذي تقترحه؟
3. هل هناك نقاط مهمة فاتت الطرفين؟
4. اقترح تعديلات محددة على الخطة."""

    for round_num in range(2, rounds + 1):
        log("---\n")
        log(f"## 🔄 Round {round_num}: النقاش المتبادل\n")

        log(f"### 🟦 {AGENT_A_NAME} يرد:\n")
        print(f"   ⏳ Waiting for {AGENT_A_NAME}...")
        agent_a_cross = call_agent_a(cross_prompt.format(plan=plan, other_review=agent_b_review))
        log(f"{agent_a_cross}\n")

        log(f"### 🟧 {AGENT_B_NAME} يرد:\n")
        print(f"   ⏳ Waiting for {AGENT_B_NAME}...")
        agent_b_cross = call_agent_b(cross_prompt.format(plan=plan, other_review=agent_a_review))
        log(f"{agent_b_cross}\n")

        agent_a_review = agent_a_cross
        agent_b_review = agent_b_cross

    # ============================================
    # Final: Consensus Plan
    # ============================================
    log("---\n")
    log("## ✅ الخطة النهائية المتفق عليها\n")

    print("   ⏳ Generating final consensus plan...")
    final_plan = call_agent_a(f"""بناءً على النقاش التالي بين خبيرين:

**الخطة الأصلية:**
{plan}

**ملاحظات المعماري الأخيرة:**
{agent_a_review}

**ملاحظات الناقد الأخيرة:**
{agent_b_review}

اكتب **الخطة النهائية المحسّنة** التي تدمج أفضل الأفكار من كلا الطرفين.
اكتبها بشكل منظم وجاهز للتنفيذ مع:
- الأولويات مرتبة
- المهام محددة بوضوح
- الجدول الزمني المقترح
- المخاطر وخطة التخفيف""")
    log(f"{final_plan}\n")

    # Save to file
    full_output = "\n".join(discussion_log)
    output_file.write_text(full_output, encoding="utf-8")
    print(f"\n{'='*60}")
    print(f"💾 Discussion saved to: {output_file}")
    print(f"{'='*60}")


def main():
    if not PLAN_FILE.exists():
        PLAN_FILE.write_text("""# خطة تطوير تطبيق WAIN

## الهدف
تحسين تجربة المستخدم وإضافة ميزات جديدة.

## المهام
1. تحسين أداء التطبيق
2. إضافة نظام إشعارات
3. تحسين واجهة المستخدم

---
(عدّل هذا الملف وأضف خطتك الكاملة)
""", encoding="utf-8")
        print(f"📝 Created plan template: {PLAN_FILE}")
        print(f"   Edit it with your plan, then run again.")
        return

    plan = PLAN_FILE.read_text(encoding="utf-8")
    
    if len(plan.strip()) < 50:
        print("⚠️  Plan is too short. Please write a detailed plan in plan.md")
        return

    mode = "Gemini Pro + GPT-4o" if USE_OPENAI else "Gemini Pro + Gemini Flash"
    print("🚀 Starting Multi-Agent Discussion...")
    print(f"   Mode: {mode}")
    print(f"   Rounds: 3")
    if not USE_OPENAI:
        print(f"   💡 Add --with-openai flag to use OpenAI too")
    print(f"{'='*60}\n")

    run_discussion(plan, rounds=3)


if __name__ == "__main__":
    main()
