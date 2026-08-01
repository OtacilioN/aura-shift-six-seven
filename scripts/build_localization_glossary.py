#!/usr/bin/env python3
"""Materializa o glossário a partir das traduções efetivamente versionadas."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "localization"
OUTPUT = ROOT / "docs" / "LOCALIZATION-GLOSSARY.md"
LOCALES = ("en-US", "pt-BR", "es-419", "fr-FR", "de-DE", "id", "ja-JP", "ar")
TERMS = (
    ("app_title", "marca; não transcriar"),
    ("app_tagline", "transcriar gesto + escala"),
    ("play_available_aura", "saldo gastável"),
    ("play_total_aura", "progresso vitalício"),
    ("play_journey_aura", "desde a última Ascensão"),
    ("play_cycle_power", "ganho somente na Seven"),
    ("play_passive_rate", "taxa sem Ciclo"),
    ("play_phase_six", "fase; preservar Six"),
    ("play_phase_seven", "fase; preservar Seven"),
    ("shop_techniques", "melhoramentos ativos"),
    ("shop_aura_tree", "rede de itens passivos"),
    ("collection_appearances", "visual sem vantagem"),
    ("collection_transformations", "estado permanente da cena"),
    ("collection_achievements", "comemorativo local"),
    ("collection_seals", "coleção separada"),
    ("ascension_title", "reset voluntário + ganho permanente"),
    ("cloud_save_title", "sincronização de progresso via Google Play Games"),
    ("settings_accessibility", "grupo de ajustes"),
    ("content.branch_a.name", "território Poise"),
    ("content.branch_b.name", "território Motion"),
    ("content.branch_c.name", "território Signal"),
    ("content.signal_67.name", "assinatura de marco"),
)


def escape(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", "<br>")


def main() -> None:
    catalogs = {
        locale: json.loads((L10N / f"{locale}.json").read_text(encoding="utf-8"))
        for locale in LOCALES
    }
    lines = [
        "# Aura Shift: Six Seven — Glossário e memória de tradução `l10n-v1`",
        "",
        "> Gerado dos oito catálogos versionados. Catálogos são a memória de tradução executável; esta tabela é a referência humana de termos de sistema.",
        "",
        "## Termos canônicos",
        "",
        "| ID | Intenção | " + " | ".join(f"`{locale}`" for locale in LOCALES) + " |",
        "| --- | --- | " + " | ".join("---" for _ in LOCALES) + " |",
    ]
    for key, note in TERMS:
        values = [escape(catalogs[locale][key]) for locale in LOCALES]
        lines.append(f"| `{key}` | {note} | " + " | ".join(values) + " |")
    lines.extend(
        [
            "",
            "## Tokens invariáveis",
            "",
            "- IDs, placeholders e chaves ICU nunca são traduzidos.",
            "- `Aura Shift: Six Seven`, `Six`, `Seven`, dígitos ASCII, `67`, sufixos K–Dc, expoentes e operadores econômicos permanecem canônicos.",
            "- `Aura` pode receber flexão/artigo ao redor, mas o token econômico formatado chega inteiro do formatter.",
            "- Em árabe, tokens econômicos recebem isolamento LTR na UI; os JSONs não armazenam marcas bidi invisíveis.",
            "- Nomes culturais podem ser transcriados, mas IDs, função, intensidade e risco precisam permanecer equivalentes.",
            "",
            "## Atualização simultânea",
            "",
            "1. alterar `COPY-DECK.md`, `CONTENT-CATALOG.md` ou `ACHIEVEMENTS.md`;",
            "2. regenerar `en-US` e `en-XA`;",
            "3. bloquear merge enquanto qualquer locale tiver chave ou placeholder divergente;",
            "4. traduzir, revisar por outro agente e comparar semanticamente textos críticos;",
            "5. regenerar este glossário e executar `scripts/validate_planning.py`;",
            "6. durante o desenvolvimento, executar pseudo-localização, RTL, reflow e smoke test no build.",
            "",
            "## Limites de validação",
            "",
            "A revisão documental não equivale a revisão humana nativa nem a QA em tela. Naturalidade, fontes, shaping, truncamento, TalkBack e bidi precisam ser revalidados no build candidato; correções linguísticas não podem alterar IDs ou estado econômico.",
            "",
        ]
    )
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {len(TERMS)} terms to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
