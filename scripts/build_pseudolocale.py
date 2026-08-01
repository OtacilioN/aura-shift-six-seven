#!/usr/bin/env python3
"""Gera `en-XA` expandido preservando placeholders ICU para QA visual."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "localization" / "en-US.json"
OUTPUT = ROOT / "localization" / "en-XA.json"
TOKEN = re.compile(r"\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|\b(?:\d+(?:[.,]\d+)?(?:K|M|B|T|Qa|Qi|Sx|Sp|Oc|No|Dc)?|Aura|Six-Seven)\b")
ACCENTS = str.maketrans(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "áƀçđëƒğħïĵķľɱñöþɋřşŧüṽŵẋÿžÁƁÇĐËƑĞĦÏĴĶĽṀÑÖÞɊŘŞŦÜṼŴẊŸŽ",
)

INVARIANT_KEYS = {"content.tech_06.name"}


def transform_text(text: str) -> str:
    parts: list[str] = []
    cursor = 0
    for match in TOKEN.finditer(text):
        parts.append(text[cursor : match.start()].translate(ACCENTS))
        parts.append(match.group(0))
        cursor = match.end()
    parts.append(text[cursor:].translate(ACCENTS))
    transformed = "".join(parts)
    padding = " ~" * max(1, len(text) // 12)
    return f"⟦{transformed}{padding}⟧"


def main() -> None:
    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    pseudo = {
        key: value if key in INVARIANT_KEYS else transform_text(value)
        for key, value in source.items()
    }
    OUTPUT.write_text(json.dumps(pseudo, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(pseudo)} pseudo-localized strings to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
