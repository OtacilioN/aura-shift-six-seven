#!/usr/bin/env python3
"""Create a local, no-dependency listening sheet for the human audio gate."""

from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "assets/audio/audio-candidate-manifest-v1.json"
REVIEW = ROOT / "reports/audio-review-results.json"
OUTPUT = ROOT / "reports/audio-listening-sheet.html"


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    review = json.loads(REVIEW.read_text(encoding="utf-8"))
    if (
        manifest.get("status") != "candidate-reviewed"
        or manifest.get("revision") != 3
        or review.get("reviewEvidenceRevision") != 2
    ):
        raise SystemExit(
            "listening sheet only accepts reviewed audio revision 3 / evidence revision 2"
        )

    warnings = review["crossDecoderReview"]["warnings"]
    sections: list[str] = []
    groups = ["music", "cycle", "ui", "event"]
    rendered = 0
    for group in groups:
        rows: list[str] = []
        for entry in (item for item in manifest["assets"] if item["group"] == group):
            rendered += 1
            runtime = entry["runtimePath"]
            relative = "../" + runtime
            metrics = entry["reviewedMetrics"]["runtime"]
            coreaudio = entry["reviewedMetrics"]["coreAudio"]
            badge = "conditional" if entry["conditional"] else "required"
            loop = " loop" if entry["loop"] else ""
            decoder_rows = ""
            if entry["group"] == "music":
                alignment = coreaudio["alignment"]
                decoder_rows = (
                    f"<div><dt>CoreAudio</dt><dd>{esc(coreaudio['decodedFrames'])}/{esc(coreaudio['expectedFrames'])} frames</dd></div>"
                    f"<div><dt>Offset</dt><dd>{esc(alignment['coreAudioFrame0MatchesLibsndfileFrame'])} frames</dd></div>"
                    f"<div><dt>Seam</dt><dd>{esc(coreaudio['coreAudioLoopBoundary']['boundaryDeltaDbfs'])} dBFS — {esc(coreaudio['coreAudioSeamGate'])}</dd></div>"
                )
            rows.append(
                "<article class='asset'>"
                f"<header><code>{esc(entry['id'])}</code><span>{badge}</span></header>"
                f"<audio controls preload='none'{loop} src='{esc(relative)}'></audio>"
                "<dl>"
                f"<div><dt>Runtime</dt><dd>{esc(runtime)}</dd></div>"
                f"<div><dt>Formato</dt><dd>{esc(metrics['format'])} / {esc(metrics['subtype'])}</dd></div>"
                f"<div><dt>Duração</dt><dd>{esc(metrics['durationSeconds'])} s</dd></div>"
                f"<div><dt>Pico</dt><dd>{esc(metrics['samplePeakDbfs'])} dBFS</dd></div>"
                f"{decoder_rows}"
                "</dl></article>"
            )
        sections.append(f"<section><h2>{esc(group)}</h2><div class='grid'>{''.join(rows)}</div></section>")

    if rendered != len(manifest["assets"]):
        raise SystemExit(f"listening sheet omitted {len(manifest['assets']) - rendered} assets")

    warning_items = "".join(f"<li>{esc(item)}</li>" for item in warnings)
    document = f"""<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Aura Shift — escuta humana de áudio r3</title>
  <style>
    :root {{ color-scheme: dark; font-family: system-ui, sans-serif; background:#090b1a; color:#f7f5ff; }}
    body {{ margin:0 auto; max-width:1440px; padding:32px; }}
    h1 {{ margin-bottom:8px; }} h2 {{ color:#43e6ff; margin-top:42px; text-transform:capitalize; }}
    .notice {{ background:#171d43; border:1px solid #8b7cff; border-radius:16px; padding:18px; line-height:1.5; }}
    .grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(300px,1fr)); gap:14px; }}
    .asset {{ background:#111632; border:1px solid #202750; border-radius:14px; padding:16px; }}
    header {{ display:flex; justify-content:space-between; gap:12px; margin-bottom:12px; }}
    header span {{ color:#ffd166; font-size:.8rem; }} audio {{ width:100%; }}
    dl {{ font-size:.82rem; color:#d8d5ec; overflow-wrap:anywhere; }}
    dl div {{ display:grid; grid-template-columns:68px 1fr; gap:8px; }} dt {{ color:#8b7cff; }} dd {{ margin:0; }}
  </style>
</head>
<body>
  <h1>Aura Shift: Six Seven — escuta r3</h1>
  <p>44 candidatos: 40 obrigatórios e quatro mixes condicionais. Esta página não aprova nenhum som.</p>
  <div class="notice">
    <strong>Ordem mínima:</strong> I0, I3, seis pares Six/Seven, FORM-01, FORM-05, Ascensão e Marco 67.
    Rejeite fadiga, semelhança reconhecível, conotação de moeda/jackpot, Seven ambíguo ou Six que pareça recompensa.
    <p><strong>CoreAudio:</strong> frame count, offset PCM e seam são métricas diferentes. O taper passa o gate numérico, mas não elimina o offset do decoder. Repetir cada loop no Android.</p><ul>{warning_items}</ul>
  </div>
  {''.join(sections)}
</body>
</html>
"""
    OUTPUT.write_text(document, encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(ROOT)} with {len(manifest['assets'])} players")


if __name__ == "__main__":
    main()
