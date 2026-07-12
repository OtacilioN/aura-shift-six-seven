#!/usr/bin/env python3
"""Create a local, no-dependency listening sheet for the human audio gate."""

from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "assets/audio/audio-candidate-manifest-v2.json"
OUTPUT = ROOT / "reports/audio-listening-sheet.html"
PROPOSAL_MANIFEST = ROOT / "assets/audio/proposals/proposal-manifest-v1.json"


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def render_proposals() -> tuple[str, int]:
    if not PROPOSAL_MANIFEST.is_file():
        return "", 0
    manifest = json.loads(PROPOSAL_MANIFEST.read_text(encoding="utf-8"))
    tracks = manifest.get("tracks", [])
    if (
        manifest.get("contract") != "music-proposal-manifest-v1"
        or manifest.get("status") != "refined-demo-reviewed"
        or manifest.get("count") != 6
        or len(tracks) != 6
    ):
        raise SystemExit("proposal listening section requires six reviewed demos")

    rows: list[str] = []
    for entry in tracks:
        runtime = entry["runtimePath"]
        metrics = entry["metrics"]["runtime"]
        rows.append(
            "<article class='asset proposal'>"
            f"<header><code>{esc(entry['id'])}</code><span>{esc(entry['genre'])}</span></header>"
            f"<h3>{esc(entry['title'])}</h3>"
            f"<p>{esc(entry['description'])}</p>"
            f"<audio controls preload='none' loop src='../{esc(runtime)}'></audio>"
            "<dl>"
            f"<div><dt>Agente</dt><dd>{esc(entry['agent'])}</dd></div>"
            f"<div><dt>Runtime</dt><dd>{esc(runtime)}</dd></div>"
            f"<div><dt>Duração</dt><dd>{esc(metrics['durationSeconds'])} s</dd></div>"
            f"<div><dt>LUFS-I</dt><dd>{esc(metrics['integratedLufs'])}</dd></div>"
            f"<div><dt>True peak</dt><dd>{esc(metrics['truePeakDbtp'])} dBTP</dd></div>"
            f"<div><dt>Status</dt><dd>{esc(entry['status'])}; escuta humana pendente</dd></div>"
            "</dl></article>"
        )
    section = (
        "<section id='new-music-proposals'>"
        "<h2>novas propostas — demos refinadas</h2>"
        "<p class='proposal-note'>Seis faixas produzidas independentemente para comparação. "
        "Elas são alternativas históricas fora do runtime e permanecem preservadas apenas para comparação.</p>"
        f"<div class='grid'>{''.join(rows)}</div></section>"
    )
    return section, len(rows)


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if (
        manifest.get("contract") != "audio-candidate-manifest-v2"
        or manifest.get("status") != "candidate-reviewed"
        or manifest.get("revision") != 1
    ):
        raise SystemExit("listening sheet only accepts reviewed audio v2 revision 1")

    warnings = [
        "As sete músicas são faixas completas non-loop; validar crossfade, foco e retomada no Android.",
        "Licença/termos comerciais do gerador e similaridade independente permanecem gates de release.",
    ]
    proposal_section, proposal_count = render_proposals()
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
            badge = "principal" if entry.get("primary") else "required"
            loop = " loop" if entry["loop"] else ""
            decoder_rows = ""
            if entry["group"] == "music":
                decoder_rows = (
                    f"<div><dt>Título</dt><dd>{esc(entry['title'])}</dd></div>"
                    f"<div><dt>LUFS-I</dt><dd>{esc(metrics['integratedLufs'])}</dd></div>"
                    f"<div><dt>True peak</dt><dd>{esc(metrics['truePeakDbtp'])} dBTP</dd></div>"
                    f"<div><dt>Playback</dt><dd>playlist non-loop; ordem {esc(entry['playlistOrder'] + 1)}</dd></div>"
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
  <title>Aura Shift — escuta humana de áudio v2</title>
  <style>
    :root {{ color-scheme: dark; font-family: system-ui, sans-serif; background:#090b1a; color:#f7f5ff; }}
    body {{ margin:0 auto; max-width:1440px; padding:32px; }}
    h1 {{ margin-bottom:8px; }} h2 {{ color:#43e6ff; margin-top:42px; text-transform:capitalize; }}
    .notice {{ background:#171d43; border:1px solid #8b7cff; border-radius:16px; padding:18px; line-height:1.5; }}
    .grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(300px,1fr)); gap:14px; }}
    .asset {{ background:#111632; border:1px solid #202750; border-radius:14px; padding:16px; }}
    .asset.proposal {{ border-color:#ff4fa3; background:linear-gradient(145deg,#17183a,#111632); }}
    .asset h3 {{ margin:.15rem 0 .5rem; color:#f7f5ff; }}
    .asset p {{ color:#d8d5ec; line-height:1.4; min-height:2.8em; }}
    .proposal-note {{ color:#d8d5ec; max-width:880px; }}
    header {{ display:flex; justify-content:space-between; gap:12px; margin-bottom:12px; }}
    header span {{ color:#ffd166; font-size:.8rem; }} audio {{ width:100%; }}
    dl {{ font-size:.82rem; color:#d8d5ec; overflow-wrap:anywhere; }}
    dl div {{ display:grid; grid-template-columns:68px 1fr; gap:8px; }} dt {{ color:#8b7cff; }} dd {{ margin:0; }}
  </style>
</head>
<body>
  <h1>Aura Shift: Six Seven — escuta v2</h1>
  <p>{len(manifest['assets'])} assets atuais (7 músicas + 35 SFX) e {proposal_count} demos históricas fora do runtime.</p>
  <div class="notice">
    <strong>Ordem mínima:</strong> Boss Shift, ciclo completo das sete faixas, seis pares Six/Seven, FORM-01, FORM-05, Ascensão e Marco 67.
    Rejeite fadiga, semelhança reconhecível, conotação de moeda/jackpot, Seven ambíguo ou Six que pareça recompensa.
    <p><strong>Playlist:</strong> as músicas não repetem individualmente; validar a troca por posição/conclusão e o crossfade em aparelho.</p><ul>{warning_items}</ul>
  </div>
  {proposal_section}
  {''.join(sections)}
</body>
</html>
"""
    OUTPUT.write_text(document, encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(ROOT)} with {len(manifest['assets'])} players")


if __name__ == "__main__":
    main()
