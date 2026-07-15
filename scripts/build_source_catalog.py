#!/usr/bin/env python3
"""Gera localization/en-US.json a partir das fontes canônicas de copy/conteúdo."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
OUTPUT = ROOT / "localization" / "en-US.json"

UI_ID = re.compile(r"^[a-z][a-z0-9_]*$")
CONTENT_ID = re.compile(r"^(ITEM-[ABC]-\d{2}|ITEM-CONV-\d{2}|TECH-\d{2}|FORM-\d{2}|ACH-[VS]-\d{2})$")


def cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def plain(value: str) -> str:
    value = value.strip()
    if value.startswith("**") and value.endswith("**"):
        value = value[2:-2]
    if value.startswith("`") and value.endswith("`"):
        value = value[1:-1]
    return value.replace("\\|", "|").strip()


def content_key(content_id: str, field: str) -> str:
    return f"content.{content_id.lower().replace('-', '_')}.{field}"


def extract_copy_deck(catalog: dict[str, str]) -> None:
    for line in (DOCS / "COPY-DECK.md").read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        row = cells(line)
        if len(row) < 2:
            continue
        first = plain(row[0])
        second = plain(row[1])
        if UI_ID.fullmatch(first) and not UI_ID.fullmatch(second):
            catalog[first] = second
        elif len(row) >= 3 and UI_ID.fullmatch(second):
            # Tabela de variantes curtas: ID normal | ID curto | fonte curta.
            catalog[second] = plain(row[2])


def extract_content(catalog: dict[str, str]) -> None:
    for filename in ("CONTENT-CATALOG.md", "ACHIEVEMENTS.md"):
        for line in (DOCS / filename).read_text(encoding="utf-8").splitlines():
            if not line.startswith("|"):
                continue
            row = cells(line)
            if len(row) < 3:
                continue
            content_id = plain(row[0])
            if not CONTENT_ID.fullmatch(content_id):
                continue
            catalog[content_key(content_id, "name")] = plain(row[1])
            if content_id.startswith("FORM-"):
                continue
            description = plain(row[2])
            if description and not description.startswith("`ITEM-"):
                catalog[content_key(content_id, "description")] = description

    form_descriptions = {
        "FORM-01": "A clear outline turns the first spark into a steady glow.",
        "FORM-02": "Your presence arrives twice, one clean echo behind.",
        "FORM-03": "The whole scene starts carrying your signal.",
        "FORM-04": "One pulse reaches from the mascot to the horizon.",
        "FORM-05": "Every route of Aura meets at the highest point.",
    }
    for content_id, description in form_descriptions.items():
        catalog[content_key(content_id, "description")] = description

    catalog.update(
        {
            "app_title": "Aura Shift: Six Seven",
            "app_tagline": "Two taps. Infinite aura.",
            "store_short_description": "Two taps. Infinite Aura. Build your style and shift the whole scene.",
            "store_full_description": "Tap twice to complete a Six-Seven Cycle and farm Aura. Build active Techniques, grow three equally strong Aura Tree paths, collect Appearances, unlock Transformations, and Ascend for permanent momentum.\n\nPlay your way:\n• Active and passive progress\n• Up to 4 hours of Offline Production\n• Optional rewarded ads only\n• No account, required connection, or in-app purchases\n• Manual Backup, accessibility controls, and 8 languages\n\nAura Shift: Six Seven is a trend-driven incremental game for ages 13 and up.",
            "store_feature_graphic_alt": "Mascot switching oversized hands between Six and Seven as Aura fills the scene.",
            "content.branch_a.name": "Poise",
            "content.branch_a.description": "Quiet presence, clean lines, and visual weight.",
            "content.branch_b.name": "Motion",
            "content.branch_b.description": "Pulse, movement, and echoes that wake the scene.",
            "content.branch_c.name": "Signal",
            "content.branch_c.description": "Loops, static, and a horizon that keeps expanding.",
            "content.signal_67.name": "Signal 67",
            "content.signal_67.celebration": "SIX. SEVEN. {amount} signal locked.",
        }
    )


def main() -> None:
    catalog: dict[str, str] = {}
    extract_copy_deck(catalog)
    extract_content(catalog)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(dict(sorted(catalog.items())), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {len(catalog)} strings to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
