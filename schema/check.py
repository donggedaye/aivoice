"""驗證 claim.json 本身，以及 examples/ 底下的正例與反例。

    python3 -m venv .venv && .venv/bin/pip install jsonschema
    .venv/bin/python schema/check.py

9/22 的後端會用同一份 schema 驗模型回來的 JSON，所以這支只依賴 jsonschema，
不依賴後端的任何東西。
"""

import json
import pathlib
import sys

from jsonschema import Draft202012Validator

HERE = pathlib.Path(__file__).parent
SCHEMA = json.loads((HERE / "claim.json").read_text(encoding="utf-8"))


def validator(ref: str) -> Draft202012Validator:
    """拿 schema 裡的某一個定義來驗。"""
    return Draft202012Validator({**SCHEMA, "$ref": f"#/$defs/{ref}"})


def main() -> int:
    Draft202012Validator.check_schema(SCHEMA)
    print("schema 本身合法")

    failures = 0

    response = json.loads(
        (HERE / "examples" / "analyze_response.json").read_text(encoding="utf-8")
    )
    errors = list(validator("analyze_response").iter_errors(response))
    print(f"正例 analyze_response：{len(errors)} 個錯誤")
    for error in errors:
        print("   ", list(error.path), error.message)
    failures += len(errors)

    claim = validator("analyzed_claim_strict")
    rejected = json.loads(
        (HERE / "examples" / "rejected.json").read_text(encoding="utf-8")
    )
    print("\n反例（應該每一條都被擋下）：")
    for case in rejected["cases"]:
        errors = list(claim.iter_errors(case["claim"]))
        if errors:
            print(f"  擋下：{case['why'][:30]}…")
        elif case.get("schema_cannot_catch"):
            # 對人的判斷這種事 JSON Schema 驗不了，是提示詞與人工檢查的責任。
            print(f"  擋不住（已知）：{case['why'][:30]}…")
        else:
            print(f"  **沒擋住**：{case['why']}")
            failures += 1

    print("\n失敗數：", failures)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
