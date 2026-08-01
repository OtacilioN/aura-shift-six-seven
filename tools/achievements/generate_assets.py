#!/usr/bin/env python3
"""Generate deterministic Play Games achievement import assets."""

from __future__ import annotations

import csv
import json
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "docs" / "play-games" / "achievements"
ICONS = OUTPUT / "icons"
ZIP_PATH = OUTPUT / "aura-shift-achievements-import.zip"


ACHIEVEMENTS = [
    ("first_movement", "First Movement", "Produce aura with your first movement.", "Primeiro Movimento", "Produza aura com seu primeiro movimento.", False, None, "Revealed", 5, 1, "spark"),
    ("first_six", "Six", "Perform your first Six.", "Six", "Faça seu primeiro Six.", False, None, "Revealed", 5, 2, "six"),
    ("first_seven", "Seven", "Perform your first Seven.", "Seven", "Faça seu primeiro Seven.", False, None, "Revealed", 5, 3, "seven"),
    ("six_seven", "SixSeven!", "Farm a total of 67 aura.", "SixSeven!", "Farme um total de 67 de aura.", False, None, "Revealed", 10, 4, "cycle"),
    ("first_purchase", "First Purchase", "Buy your first upgrade.", "Primeira Aquisição", "Compre sua primeira melhoria.", False, None, "Revealed", 10, 5, "cart"),
    ("first_automatic_production", "Now It Runs Itself", "Start producing aura automatically.", "Agora Vai Sozinho", "Comece a produzir aura automaticamente.", False, None, "Revealed", 10, 6, "gear"),
    ("first_offline_reward", "Aura Never Sleeps", "Collect aura produced while you were away.", "A Aura Não Dorme", "Colete aura produzida enquanto você estava fora.", False, None, "Revealed", 15, 7, "moon"),
    ("manual_movements_100", "A Hundred or So", "Perform 100 manual movements.", "Cento e Poucos", "Realize 100 movimentos manuais.", True, 100, "Revealed", 10, 8, "hand"),
    ("manual_movements_1000", "Hands at Work", "Perform 1000 manual movements.", "Mãos à Obra", "Realize 1.000 movimentos manuais.", True, 1000, "Revealed", 25, 9, "hands"),
    ("manual_movements_10000", "Spiritual Tendinitis", "Perform 10000 manual movements.", "Tendinite Espiritual", "Realize 10.000 movimentos manuais.", True, 10000, "Revealed", 50, 10, "spiral"),
    ("total_aura_1000", "Rookie Aura", "Farm a total of one thousand aura.", "Aura de Cria", "Farme um total de mil de aura.", False, None, "Revealed", 15, 11, "drop"),
    ("total_aura_1_million", "Industrial Aura", "Farm a total of one million aura.", "Aura Industrial", "Farme um total de um milhão de aura.", False, None, "Revealed", 30, 12, "pipes"),
    ("total_aura_1_billion", "Legendary Aura", "Farm a total of one billion aura.", "Aura Lendária", "Farme um total de um bilhão de aura.", False, None, "Revealed", 50, 13, "gem"),
    ("total_aura_1_trillion", "Cosmic Aura", "Farm a total of one trillion aura.", "Aura Cósmica", "Farme um total de um trilhão de aura.", False, None, "Revealed", 75, 14, "planet"),
    ("total_aura_1_quintillion", "This Is Escalating", "Farm a total of one quintillion aura.", "Isso Está Escalando", "Farme um total de um quintilhão de aura.", False, None, "Revealed", 100, 15, "rocket"),
    ("ten_items", "Collector", "Unlock ten different items.", "Colecionador", "Desbloqueie dez itens diferentes.", False, None, "Revealed", 30, 16, "chest"),
    ("original_item_catalog", "Complete Catalog", "Unlock every item in the original catalog.", "Catálogo Completo", "Desbloqueie todos os itens do catálogo original.", False, None, "Revealed", 75, 17, "grid"),
    ("five_characters", "A Solid Cast", "Unlock three Aura Transformations.", "Elenco de Respeito", "Desbloqueie três Transformações de Aura.", False, None, "Revealed", 30, 18, "masks"),
    ("original_character_roster", "Everyone Has Aura", "Unlock every original Aura Transformation.", "Todo Mundo Tem Aura", "Desbloqueie todas as Transformações de Aura originais.", False, None, "Revealed", 75, 19, "roster"),
    ("maximum_aura_state", "Maximum Aura", "Reach the maximum visual aura state.", "Aura Máxima", "Alcance o estado visual máximo de aura.", False, None, "Revealed", 50, 20, "crown"),
    ("forty_two", "Forty Two", "Unlock the answer to life the universe and everything.", "Forty Two", "Desbloqueie a resposta para a vida o universo e tudo mais.", False, None, "Hidden", 40, 21, "secret"),
    ("seven_distinct_days", "Seven Days of Aura", "Play Aura Shift on seven different days.", "Sete Dias de Aura", "Jogue Aura Shift em sete dias diferentes.", True, 7, "Revealed", 30, 22, "calendar"),
    ("thirty_distinct_days", "Faithful to the Farm", "Play Aura Shift on thirty different days.", "Fiel ao Farm", "Jogue Aura Shift em trinta dias diferentes.", True, 30, "Revealed", 75, 23, "calendar_orbit"),
    ("aura_per_second_67", "Sixty-Seven per Second", "Produce at least 67 aura per second.", "Sessenta e Sete por Segundo", "Produza pelo menos 67 de aura por segundo.", False, None, "Revealed", 15, 24, "gauge"),
    ("aura_per_second_1_million", "Serious Production", "Produce at least one million aura per second.", "Produção de Respeito", "Produza pelo menos um milhão de aura por segundo.", False, None, "Revealed", 50, 25, "factory"),
    ("single_movement_1_million", "One Absurd Movement", "Produce one million aura in a single movement.", "Um Movimento Absurdo", "Produza um milhão de aura em um único movimento.", False, None, "Revealed", 50, 26, "impact"),
]


MOTIFS = {
    "spark": '<path d="M256 105l32 107 102 44-102 44-32 107-32-107-102-44 102-44z"/>',
    "six": '<path d="M334 144c-118 9-154 163-63 219 69 43 139-22 99-87-29-47-103-28-105 30" fill="none" stroke-width="42" stroke-linecap="round"/>',
    "seven": '<path d="M150 153h220L225 374" fill="none" stroke-width="44" stroke-linecap="round" stroke-linejoin="round"/>',
    "cycle": '<path d="M148 219a119 119 0 01201-49l29-25-4 74-73-10 27-22M364 293a119 119 0 01-201 49l-29 25 4-74 73 10-27 22" fill="none" stroke-width="28" stroke-linejoin="round"/>',
    "cart": '<path d="M135 151h43l35 150h143l36-100H205M235 353a22 22 0 110 44 22 22 0 010-44zm117 0a22 22 0 110 44 22 22 0 010-44z" fill="none" stroke-width="27" stroke-linecap="round" stroke-linejoin="round"/>',
    "gear": '<path d="M256 110l24 40 45-9 8 46 44 15-18 43 31 34-34 31 11 45-45 10-15 44-43-19-34 31-31-34-45 11-10-45-44-15 19-43-31-34 34-31-11-45 45-10 15-44 43 19z"/><circle cx="256" cy="256" r="65" fill="none" stroke-width="31"/>',
    "moon": '<path d="M332 113c-106 27-133 168-48 232 41 31 96 34 140 8-57 72-168 77-233 12-78-78-47-213 55-251 28-10 58-11 86-1z"/>',
    "hand": '<path d="M190 358v-142c0-23 34-23 34 0v48-100c0-24 36-24 36 0v91-112c0-24 36-24 36 0v112-88c0-24 36-24 36 0v102-38c0-26 39-26 39 0v75c0 68-44 105-105 105-35 0-76-23-76-53z"/>',
    "hands": '<path d="M132 331V210c0-20 30-20 30 0v39-82c0-20 31-20 31 0v75-93c0-20 31-20 31 0v93-72c0-20 31-20 31 0v118c0 54-36 86-82 86M380 331V210c0-20-30-20-30 0v39-82c0-20-31-20-31 0v75-93c0-20-31-20-31 0v93" fill="none" stroke-width="24" stroke-linecap="round" stroke-linejoin="round"/>',
    "spiral": '<path d="M366 256c0 61-49 110-110 110s-110-49-110-110 49-110 110-110c48 0 87 39 87 87s-39 87-87 87c-35 0-64-29-64-64s29-64 64-64c23 0 42 19 42 42s-19 42-42 42" fill="none" stroke-width="25" stroke-linecap="round"/>',
    "drop": '<path d="M256 105c-31 61-99 126-99 198a99 99 0 00198 0c0-72-68-137-99-198z"/>',
    "pipes": '<path d="M130 164h98v65h56v-65h98v68h-54v58h54v68h-98v-65h-56v65h-98v-68h54v-58h-54z"/>',
    "gem": '<path d="M158 175l57-55h82l57 55 33 67-131 155-131-155zM158 175h196M125 242h262M215 120l-25 122 66 155 66-155-25-122" fill="none" stroke-width="24" stroke-linejoin="round"/>',
    "planet": '<circle cx="256" cy="256" r="91"/><path d="M101 326c44 30 156 7 248-51s133-121 83-139c-40-14-124 10-204 54" fill="none" stroke-width="28" stroke-linecap="round"/>',
    "rocket": '<path d="M209 317c-33 3-63 23-83 56l74-2M303 317c33 3 63 23 83 56l-74-2M207 315c-32-83-4-161 49-217 53 56 81 134 49 217zM226 315h60l-30 99z"/><circle cx="256" cy="218" r="33" fill="none" stroke-width="20"/>',
    "chest": '<path d="M129 218h254v162H129zM149 132h214l20 86H129zM224 218h64v91h-64zM244 249h24" fill="none" stroke-width="27" stroke-linejoin="round"/>',
    "grid": '<rect x="126" y="126" width="104" height="104" rx="18"/><rect x="282" y="126" width="104" height="104" rx="18"/><rect x="126" y="282" width="104" height="104" rx="18"/><path d="M300 338l31 31 67-87" fill="none" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>',
    "masks": '<path d="M115 185c49-35 101-34 141 0v91c-28 62-112 62-141 0zM256 185c40-34 92-35 141 0v91c-29 62-113 62-141 0" fill="none" stroke-width="25"/><path d="M150 230l37 15M221 230l-34 15M291 230l34 15M362 230l-37 15" fill="none" stroke-width="18" stroke-linecap="round"/>',
    "roster": '<circle cx="256" cy="168" r="54"/><circle cx="148" cy="237" r="41"/><circle cx="364" cy="237" r="41"/><path d="M166 386c2-77 38-119 90-119s88 42 90 119M83 371c2-62 27-94 65-94 27 0 46 14 56 41M429 371c-2-62-27-94-65-94-27 0-46 14-56 41" fill="none" stroke-width="27" stroke-linecap="round"/>',
    "crown": '<path d="M121 191l80 59 55-126 55 126 80-59-35 191H156zM156 330h200" fill="none" stroke-width="29" stroke-linejoin="round"/>',
    "secret": '<path d="M184 198c9-68 133-72 145-5 9 50-73 58-73 111M256 368h1" fill="none" stroke-width="39" stroke-linecap="round"/><path d="M120 329l43 5 17 40 17-40 43-5-33-28 10-42-37 22-37-22 10 42z" opacity=".72"/>',
    "calendar": '<rect x="125" y="150" width="262" height="237" rx="26" fill="none" stroke-width="28"/><path d="M125 222h262M188 118v64M324 118v64M182 277h44M234 277h44M286 277h44M182 330h44M234 330h44M286 330h44" fill="none" stroke-width="23" stroke-linecap="round"/>',
    "calendar_orbit": '<rect x="149" y="151" width="214" height="212" rx="24" fill="none" stroke-width="25"/><path d="M149 214h214M204 118v65M308 118v65M195 264h122M195 312h122M91 352c92 84 276 73 340-28M417 269l14 55-55 14" fill="none" stroke-width="23" stroke-linecap="round" stroke-linejoin="round"/>',
    "gauge": '<path d="M121 345a150 150 0 11270 0" fill="none" stroke-width="34" stroke-linecap="round"/><path d="M256 333l85-103" fill="none" stroke-width="29" stroke-linecap="round"/><circle cx="256" cy="333" r="28"/>',
    "factory": '<path d="M112 389V236l85-55v55l88-55v55l88-55v208zM157 310h50v79M260 310h50v79M363 310h25M120 236l19-116h60l18 73" fill="none" stroke-width="25" stroke-linejoin="round"/>',
    "impact": '<path d="M256 93l26 93 78-56-34 90 96-8-84 50 84 49-96-7 34 89-78-55-26 93-26-93-78 55 34-89-96 7 84-49-84-50 96 8-34-90 78 56z"/><circle cx="256" cy="262" r="53" fill="none" stroke-width="25"/>',
}


PALETTES = [
    ("#66f0ff", "#9d5cff"),
    ("#ffcf45", "#ff5b8a"),
    ("#7ff28a", "#23a6ff"),
    ("#ff8ee8", "#5e5cff"),
    ("#ffd36a", "#f05c58"),
    ("#84f5de", "#4579ff"),
]


def svg_for(index: int, motif: str) -> str:
    primary, secondary = PALETTES[index % len(PALETTES)]
    shape = MOTIFS[motif]
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<defs>
  <radialGradient id="disc" cx="42%" cy="35%">
    <stop offset="0" stop-color="{primary}" stop-opacity=".34"/>
    <stop offset=".72" stop-color="{secondary}" stop-opacity=".2"/>
    <stop offset="1" stop-color="#071127" stop-opacity=".92"/>
  </radialGradient>
  <linearGradient id="ink" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="{primary}"/><stop offset="1" stop-color="{secondary}"/>
  </linearGradient>
  <filter id="glow"><feGaussianBlur stdDeviation="7" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
</defs>
<circle cx="256" cy="256" r="226" fill="url(#disc)" stroke="{primary}" stroke-opacity=".32" stroke-width="8"/>
<circle cx="256" cy="256" r="197" fill="none" stroke="{secondary}" stroke-opacity=".2" stroke-width="3" stroke-dasharray="{10 + index % 5} {16 + index % 7}"/>
<g fill="url(#ink)" stroke="url(#ink)" stroke-linecap="round" stroke-linejoin="round" filter="url(#glow)">{shape}</g>
</svg>
"""


def write_csv(path: Path, rows: list[list[object]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        csv.writer(handle, lineterminator="\n").writerows(rows)


def main() -> None:
    ICONS.mkdir(parents=True, exist_ok=True)
    for stale_icon in ICONS.glob("*.png"):
        stale_icon.unlink()
    metadata: list[list[object]] = []
    localizations: list[list[object]] = []
    mappings: list[list[object]] = []
    ids: dict[str, str] = {}

    with tempfile.TemporaryDirectory(prefix="aura-achievements-") as tmp:
        temporary = Path(tmp)
        for index, achievement in enumerate(ACHIEVEMENTS):
            (
                key,
                en_name,
                en_description,
                pt_name,
                pt_description,
                incremental,
                steps,
                initial_state,
                points,
                order,
                motif,
            ) = achievement
            filename = f"achievement_{order:02d}_{key}.png"
            metadata.append([
                en_name,
                en_description,
                "True" if incremental else "False",
                steps or "",
                initial_state,
                points,
                order,
            ])
            localizations.append([en_name, pt_name, pt_description, "pt-BR"])
            mappings.append([en_name, filename])
            ids[key] = ""

            source = temporary / f"{key}.svg"
            source.write_text(svg_for(index, motif), encoding="utf-8")
            subprocess.run(
                ["rsvg-convert", "-w", "512", "-h", "512", "-o", str(ICONS / filename), str(source)],
                check=True,
            )

    write_csv(OUTPUT / "AchievementsMetadata.csv", metadata)
    write_csv(OUTPUT / "AchievementsLocalizations.csv", localizations)
    write_csv(OUTPUT / "AchievementsIconMappings.csv", mappings)
    # Compatibility alias for the plural spelling in the product specification.
    shutil.copyfile(
        OUTPUT / "AchievementsIconMappings.csv",
        OUTPUT / "AchievementsIconsMappings.csv",
    )
    (OUTPUT / "achievement-ids.template.json").write_text(
        json.dumps(ids, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for csv_name in (
            "AchievementsMetadata.csv",
            "AchievementsLocalizations.csv",
            "AchievementsIconsMappings.csv",
        ):
            archive.write(OUTPUT / csv_name, csv_name)
        for icon in sorted(ICONS.glob("*.png")):
            archive.write(icon, icon.name)

    print(f"Generated {len(ACHIEVEMENTS)} achievements at {OUTPUT}")
    print(f"Points: {sum(int(item[8]) for item in ACHIEVEMENTS)}")
    print(f"ZIP: {ZIP_PATH}")


if __name__ == "__main__":
    main()
