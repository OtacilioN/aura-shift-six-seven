#!/usr/bin/env python3
"""Validação determinística dos artefatos de P01–P11.

Não substitui revisão cultural, visual, sonora ou linguística. O objetivo é
detectar lacunas mecânicas: arquivos ausentes, slots sem identidade, catálogos
incompletos, placeholders divergentes e links locais quebrados.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
L10N = ROOT / "localization"
RUNTIME_L10N = ROOT / "assets" / "l10n"

REQUIRED_DOCS = (
    "CULTURAL-RESEARCH-DOSSIER.md",
    "BRAND-VOICE-GUIDE.md",
    "UX-WIREFRAMES.md",
    "UI-DESIGN-SYSTEM.md",
    "ASSET-MANIFEST.md",
    "MOTION-VFX-BIBLE.md",
    "AUDIO-INVENTORY.md",
    "COPY-DECK.md",
    "LOCALIZATION-GLOSSARY.md",
    "PLANNING-AUDIT.md",
    "USER-APPROVAL-PACKET.md",
)

LOCALES = ("en-US", "pt-BR", "es-419", "fr-FR", "de-DE", "id", "ja-JP", "ar")
PSEUDO_LOCALE = "en-XA"

CONTENT_IDS = (
    *(f"ITEM-{branch}-{depth:02d}" for branch in "ABC" for depth in range(1, 6)),
    *(f"ITEM-CONV-{index:02d}" for index in range(1, 4)),
    *(f"TECH-{index:02d}" for index in range(1, 7)),
    *(f"FORM-{index:02d}" for index in range(1, 6)),
    *(f"ACH-V-{index:02d}" for index in range(1, 7)),
    *(f"ACH-S-{index:02d}" for index in range(1, 8)),
)

PLACEHOLDER = re.compile(r"\{([a-z][a-z0-9_]*)\b")
LOCAL_LINK = re.compile(r"\[[^\]]+\]\((?!https?://|mailto:|#)([^)#]+)(?:#[^)]+)?\)")
BIDI_MARK = re.compile("[\u202a-\u202e\u2066-\u2069]")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def load_catalog(locale: str, errors: list[str]) -> dict[str, str]:
    path = L10N / f"{locale}.json"
    if not path.exists():
        fail(errors, f"catálogo ausente: {path.relative_to(ROOT)}")
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(errors, f"catálogo inválido {path.relative_to(ROOT)}: {exc}")
        return {}
    if not isinstance(value, dict) or not all(
        isinstance(key, str) and isinstance(text, str) for key, text in value.items()
    ):
        fail(errors, f"catálogo deve ser objeto string:string: {path.relative_to(ROOT)}")
        return {}
    return value


def check_required_docs(errors: list[str]) -> None:
    for name in REQUIRED_DOCS:
        if not (DOCS / name).exists():
            fail(errors, f"documento ausente: docs/{name}")


def check_content_slots(errors: list[str]) -> None:
    sources = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (DOCS / "CONTENT-CATALOG.md", DOCS / "ACHIEVEMENTS.md")
        if path.exists()
    )
    for content_id in CONTENT_IDS:
        if content_id not in sources:
            fail(errors, f"slot cultural ausente: {content_id}")
    for path in (DOCS / "CONTENT-CATALOG.md", DOCS / "ACHIEVEMENTS.md"):
        if path.exists() and re.search(r"\bA definir\b|\bTBD\b", path.read_text(encoding="utf-8"), re.I):
            fail(errors, f"marcador não resolvido em {path.relative_to(ROOT)}")


def check_catalogs(errors: list[str]) -> None:
    catalogs = {locale: load_catalog(locale, errors) for locale in LOCALES}
    source = catalogs["en-US"]
    if not source:
        return

    source_keys = set(source)
    for locale, catalog in catalogs.items():
        if not catalog:
            continue
        keys = set(catalog)
        missing = sorted(source_keys - keys)
        extra = sorted(keys - source_keys)
        if missing:
            fail(errors, f"{locale}: {len(missing)} chaves ausentes: {', '.join(missing[:8])}")
        if extra:
            fail(errors, f"{locale}: {len(extra)} chaves extras: {', '.join(extra[:8])}")
        for key in sorted(source_keys & keys):
            expected = sorted(PLACEHOLDER.findall(source[key]))
            actual = sorted(PLACEHOLDER.findall(catalog[key]))
            if actual != expected:
                fail(errors, f"{locale}:{key}: placeholders {actual} != {expected}")
            if not catalog[key].strip():
                fail(errors, f"{locale}:{key}: string vazia")
            if BIDI_MARK.search(catalog[key]):
                fail(errors, f"{locale}:{key}: marca bidi persistida; isolamento pertence à UI")
        short_description = catalog.get("store_short_description", "")
        if len(short_description) > 80:
            fail(errors, f"{locale}: store_short_description excede 80 caracteres ({len(short_description)})")

    pseudo = load_catalog(PSEUDO_LOCALE, errors)
    if pseudo:
        if set(pseudo) != source_keys:
            fail(errors, f"{PSEUDO_LOCALE}: chaves divergentes da fonte")
        for key in sorted(source_keys & set(pseudo)):
            expected = sorted(PLACEHOLDER.findall(source[key]))
            actual = sorted(PLACEHOLDER.findall(pseudo[key]))
            if actual != expected:
                fail(errors, f"{PSEUDO_LOCALE}:{key}: placeholders {actual} != {expected}")

    for locale in (*LOCALES, PSEUDO_LOCALE):
        source_path = L10N / f"{locale}.json"
        runtime_path = RUNTIME_L10N / f"{locale}.json"
        if not runtime_path.exists():
            fail(errors, f"catálogo runtime ausente: {runtime_path.relative_to(ROOT)}")
            continue
        if source_path.exists() and source_path.read_bytes() != runtime_path.read_bytes():
            fail(
                errors,
                f"catálogo runtime divergente: {runtime_path.relative_to(ROOT)} != "
                f"{source_path.relative_to(ROOT)}",
            )


def check_local_links(errors: list[str]) -> None:
    for path in (ROOT / "README.md", ROOT / "CONTEXT.md", *sorted(DOCS.rglob("*.md"))):
        if not path.exists():
            continue
        for raw_target in LOCAL_LINK.findall(path.read_text(encoding="utf-8")):
            target = raw_target.replace("%20", " ")
            resolved = (path.parent / target).resolve()
            if not resolved.exists():
                fail(errors, f"link local quebrado em {path.relative_to(ROOT)}: {raw_target}")


def main() -> int:
    errors: list[str] = []
    check_required_docs(errors)
    check_content_slots(errors)
    check_catalogs(errors)
    check_local_links(errors)
    if errors:
        print(f"PLANNING VALIDATION: FAILED ({len(errors)} issue(s))")
        for error in errors:
            print(f"- {error}")
        return 1
    print(
        "PLANNING VALIDATION: PASSED — P01–P11 artifacts present, "
        f"{len(CONTENT_IDS)} content slots identified, {len(LOCALES)} catalogs aligned."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
