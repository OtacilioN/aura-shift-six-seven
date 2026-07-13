#!/usr/bin/env python3
"""Canonical procedural art specification for Aura Shift: Six Seven.

This module contains only deterministic geometry and metadata.  It intentionally
does not read external images, fonts, network resources, or environment state.
"""

from __future__ import annotations

from dataclasses import dataclass
from html import escape
from typing import Callable, Iterable


PALETTE = {
    "ink_900": "#090B1A",
    "ink_700": "#141936",
    "surface_2": "#202750",
    "body_violet": "#322860",
    "paper_050": "#F7F5FF",
    "text_secondary": "#C9C7D8",
    "divider": "#4C5276",
    "aura_violet": "#8B7CFF",
    "aura_cyan": "#43E6FF",
    "aura_magenta": "#FF4FA3",
    "aura_gold": "#FFD166",
    "aura_mint": "#52E0A4",
    "aura_coral": "#FF7A66",
    "aura_blue": "#3478F6",
    "status_success": "#B7F171",
    "status_warning": "#FFE59A",
    "status_error": "#FFB4AB",
    "status_info": "#B9C3FF",
}

I9 = PALETTE["ink_900"]
I7 = PALETTE["ink_700"]
S2 = PALETTE["surface_2"]
BV = PALETTE["body_violet"]
PAPER = PALETTE["paper_050"]
VIOLET = PALETTE["aura_violet"]
CYAN = PALETTE["aura_cyan"]
MAGENTA = PALETTE["aura_magenta"]
GOLD = PALETTE["aura_gold"]
MINT = PALETTE["aura_mint"]
CORAL = PALETTE["aura_coral"]
BLUE = PALETTE["aura_blue"]


@dataclass(frozen=True)
class AssetSpec:
    manifest_id: str
    family: str
    source_size: tuple[int, int]
    runtime_size: tuple[int, int]
    pivot: tuple[float, float]
    slot: str | None
    z_layer: str
    variant: str
    export_mode: str
    description: str
    builder: Callable[["AssetSpec"], str]
    metadata: tuple[tuple[str, object], ...] = ()
    runtime_included: bool = True


def _attrs(values: dict[str, object]) -> str:
    return " ".join(
        f'{key.replace("_", "-")}="{escape(str(value), quote=True)}"'
        for key, value in values.items()
    )


def tag(name: str, **attrs: object) -> str:
    return f"<{name} {_attrs(attrs)}/>"


def group(group_id: str, content: Iterable[str] | str, **attrs: object) -> str:
    body = content if isinstance(content, str) else "".join(content)
    attr_text = _attrs({"id": group_id, **attrs})
    return f"<g {attr_text}>{body}</g>"


def svg_document(
    spec: AssetSpec,
    body: Iterable[str] | str,
    *,
    defs: str = "",
    view_box: tuple[int, int, int, int] | None = None,
) -> str:
    width, height = spec.source_size
    view = view_box or (0, 0, width, height)
    content = body if isinstance(body, str) else "".join(body)
    title = escape(spec.manifest_id)
    desc = escape(spec.description)
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="{view[0]} {view[1]} {view[2]} {view[3]}" '
        'color-interpolation="sRGB" shape-rendering="geometricPrecision">\n'
        f"  <title>{title}</title>\n"
        f"  <desc>{desc}. Original project-authored procedural vector, art-v1.</desc>\n"
        f"  <metadata>manifestId={title};style=art-v1;license=project-original</metadata>\n"
        f"  <defs>{defs}</defs>\n"
        f"  {group('asset', content)}\n"
        "</svg>\n"
    )


def linear_gradient(gradient_id: str, stops: list[tuple[str, str]], **attrs: object) -> str:
    defaults: dict[str, object] = {"id": gradient_id, "x1": "0%", "y1": "0%", "x2": "100%", "y2": "100%"}
    defaults.update(attrs)
    stop_tags = "".join(tag("stop", offset=offset, stop_color=color) for offset, color in stops)
    return f"<linearGradient {_attrs(defaults)}>{stop_tags}</linearGradient>"


def radial_gradient(gradient_id: str, stops: list[tuple[str, str, float]]) -> str:
    stop_tags = "".join(
        tag("stop", offset=offset, stop_color=color, stop_opacity=opacity)
        for offset, color, opacity in stops
    )
    return f'<radialGradient id="{gradient_id}" cx="50%" cy="50%" r="50%">{stop_tags}</radialGradient>'


SKIN_META = [
    ("item_a_01", "A", "CHEST", "suspicious button physical four-hole stitched shirt button"),
    ("item_a_02", "A", "HIP", "luminous thermal receipt tucked into right shorts pocket"),
    ("item_a_03", "A", "FACE_WEAR", "QA goggles paired transparent lenses with bridge and temple arms"),
    ("item_a_04", "A", "BODY_WEAR", "open gate coat with lapels split zipper and geometric pockets"),
    ("item_a_05", "A", "HEAD_WEAR", "segmented technological hotfix crown worn above the cap"),
    ("item_b_01", "B", "GROUND_PROP", "6:70 twin-bell digital alarm clock ground prop"),
    ("item_b_02", "B", "ANKLES", "complete paired lag sneakers with short delayed contour echoes"),
    ("item_b_03", "B", "HAND_PROP", "floating physical remainder ring with one small surviving gem point"),
    ("item_b_04", "B", "HANDS_WEAR", "paired cooperative touch cuffs with tactile palm buttons"),
    ("item_b_05", "B", "SCENE_FRAME", "right-side astral financial statement with transactions total and opposing trend chart"),
    ("item_c_01", "C", "CHEST", "official homologation chest badge with legible approval seal and controlled channel-split glitches"),
    ("item_c_02", "C", "HIP", "small clandestine runaway decimal point and partial segmented digits diving into a side pocket"),
    ("item_c_03", "C", "BODY_BACK", "worn cache cape with shoulder collar split fabric tails digital stitching and cache blocks"),
    ("item_c_04", "C", "GROUND_PROP", "unemployed physical Wi-Fi router ground prop with enclosure twin antennas status LEDs and vector signal mark"),
    ("item_c_05", "C", "SCENE_FRAME", "broken 404 scene frame with interrupted missing horizon"),
    ("item_conv_01", "CONV", "AURA_BACK", "three participant ribbons braided into one meeting knot"),
    ("item_conv_02", "CONV", "AURA_BACK", "three exhausted irregular color streams settling into one stable common core"),
    ("item_conv_03", "CONV", "AURA_BACK", "oversized physical side screw with cross-slot head threaded shaft and three tether lines"),
]


SLOT_Z = {
    "CHEST": "SLOT-CHEST",
    "SHOULDER": "SLOT-SHOULDER-FRONT",
    "FACE_SIDE": "SLOT-FACE-SIDE",
    "FACE_WEAR": "SLOT-FACE-WEAR",
    "BODY_WEAR": "SLOT-BODY-WEAR",
    "BODY_BACK": "SLOT-BODY-BACK",
    "HEAD_BACK": "SLOT-HEAD-BACK",
    "HEAD_WEAR": "SLOT-HEAD-WEAR",
    "HANDS_WEAR": "SLOT-HANDS-WEAR-FRONT",
    "HIP": "SLOT-HIP",
    "ANKLES": "SLOT-ANKLES",
    "HAND_PROP": "SLOT-HAND-PROP-FRONT",
    "GROUND_BACK": "SLOT-GROUND-BACK",
    "GROUND_PROP": "SLOT-GROUND-PROP-BACK",
    "SCENE_FRAME": "SLOT-SCENE-FRAME",
    "AURA_BACK": "SLOT-AURA-BACK",
}

SLOT_PIVOTS = {
    "CHEST": (0.50, 0.50),
    "SHOULDER": (0.50, 0.50),
    "FACE_SIDE": (0.50, 0.50),
    "FACE_WEAR": (0.50, 0.50),
    "BODY_WEAR": (0.50, 0.72),
    "HEAD_BACK": (0.50, 0.82),
    "HEAD_WEAR": (0.50, 0.82),
    "HANDS_WEAR": (0.50, 0.56),
    "HIP": (0.50, 0.50),
    "ANKLES": (0.50, 0.76),
    "HAND_PROP": (0.50, 0.50),
    "BODY_BACK": (0.50, 0.72),
    "GROUND_BACK": (0.50, 0.50),
    "GROUND_PROP": (0.77, 0.88),
    "SCENE_FRAME": (0.50, 0.50),
    "AURA_BACK": (0.50, 0.58),
}

SKIN_ATTACHMENTS = {
    "item_a_01": ("left", "CHEST_L", (-0.11, -0.04)),
    "item_a_02": ("right", "HIP_R", (0.11, 0.04)),
    "item_a_03": ("center", "FACE_EYES", (0.00, 0.00)),
    "item_a_04": ("center", "BODY_WEAR_CENTER", (0.00, 0.00)),
    "item_a_05": ("center", "HEAD_WEAR_CENTER", (0.00, -0.06)),
    "item_b_01": ("right", "GROUND_PROP_R", (0.00, 0.00)),
    "item_b_02": ("both", "ANKLES_PAIR", (0.00, 0.01)),
    "item_b_03": ("right", "HAND_PROP_HIGH_R", (0.14, -0.16)),
    "item_b_04": ("both", "HANDS_LINK_PAIR", (0.00, 0.00)),
    "item_b_05": ("right", "SCENE_FRAME_R", (0.27, -0.11)),
    "item_c_01": ("left", "CHEST_L", (-0.12, -0.01)),
    "item_c_02": ("right", "HIP_R", (0.17, 0.06)),
    "item_c_03": ("center", "BODY_BACK_CENTER", (0.00, -0.02)),
    "item_c_04": ("right", "GROUND_PROP_R", (0.00, 0.00)),
    "item_c_05": ("center", "SCENE_FRAME_CENTER", (0.00, -0.04)),
    "item_conv_01": ("center", "AURA_BACK_CENTER", (0.00, -0.02)),
    "item_conv_02": ("center", "AURA_BACK_CENTER", (0.00, -0.02)),
    "item_conv_03": ("right", "AURA_BACK_R", (0.18, -0.02)),
}

THUMB_TRANSFORMS = {
    "item_a_01": (400, 548, 5.0), "item_a_02": (668, 654, 3.1),
    "item_a_03": (512, 374, 2.8), "item_a_04": (512, 630, 1.65),
    "item_a_05": (512, 158, 1.9), "item_b_01": (790, 790, 2.25),
    "item_b_02": (512, 850, 1.75), "item_b_03": (790, 252, 2.2),
    "item_b_04": (512, 525, 1.15), "item_b_05": (845, 446, 1.35),
    "item_c_01": (385, 535, 4.2), "item_c_02": (730, 690, 3.2),
    "item_c_03": (512, 600, 1.45), "item_c_04": (790, 750, 2.15),
    "item_c_05": (512, 468, 0.92), "item_conv_01": (512, 535, 0.84),
    "item_conv_02": (512, 520, 1.04), "item_conv_03": (820, 515, 0.94),
}


def _skin_palette(branch: str) -> tuple[str, str]:
    return {"A": (CYAN, BLUE), "B": (MAGENTA, CORAL), "C": (GOLD, MINT), "CONV": (VIOLET, GOLD)}[branch]


def _skin_layers(item_id: str, primary: str, secondary: str) -> tuple[list[str], list[str], list[str]]:
    sw = 18
    base: list[str] = []
    accent: list[str] = []
    glow: list[str] = []
    if item_id == "item_a_01":
        stitch_path = "M406 556 L454 604 M454 556 L406 604"
        base += [
            tag("circle", cx=430, cy=580, r=78, fill=primary, stroke=I9, stroke_width=24),
            tag("circle", cx=430, cy=580, r=57, fill=I7, stroke=secondary, stroke_width=10),
        ]
        accent += [
            tag("path", d="M393 545 A52 52 0 0 1 464 544", fill="none", stroke=PAPER, stroke_width=9, stroke_linecap="round", opacity="0.76"),
            *[tag("circle", cx=x, cy=y, r=12, fill=I9, stroke=PAPER, stroke_width=5) for x, y in ((406, 556), (454, 556), (406, 604), (454, 604))],
            tag("path", d=stitch_path, fill="none", stroke=I9, stroke_width=15, stroke_linecap="round"),
            tag("path", d=stitch_path, fill="none", stroke=secondary, stroke_width=8, stroke_linecap="round"),
        ]
        glow += [
            tag("circle", cx=430, cy=580, r=98, fill="none", stroke=primary, stroke_width=18, opacity="0.28"),
            tag("path", d="M350 536 A94 94 0 0 1 390 496 M510 624 A94 94 0 0 1 470 664", fill="none", stroke=secondary, stroke_width=12, stroke_linecap="round", opacity="0.34"),
        ]
        fitted = "translate(400 548) scale(0.62) translate(-430 -580)"
        base[:] = [group("fitted_shirt_button", base, transform=fitted)]
        accent[:] = [group("fitted_shirt_button_accent", accent, transform=fitted)]
        glow[:] = [group("fitted_shirt_button_glow", glow, transform=fitted)]
    elif item_id == "item_a_02":
        receipt = "M590 570 L605 562 L620 570 L635 562 L650 570 L665 562 L680 570 L695 562 L710 570 L725 562 L740 570 L740 742 L725 734 L710 742 L695 734 L680 742 L665 734 L650 742 L635 734 L620 742 L605 734 L590 742 Z"
        tilt = "rotate(-8 665 652)"
        base += [
            tag("path", d=receipt, fill=primary, opacity="0.24", stroke=primary, stroke_width=38, stroke_linejoin="round", transform=tilt),
            tag("path", d=receipt, fill=PAPER, stroke=I9, stroke_width=22, stroke_linejoin="round", transform=tilt),
            tag("path", d="M606 708 Q668 734 730 706 L736 742 Q670 774 604 744 Z", fill=I7, stroke=I9, stroke_width=18, stroke_linejoin="round", transform="rotate(-5 670 738)"),
        ]
        accent += [
            tag("rect", x=612, y=594, width=106, height=24, rx=12, fill=primary, stroke=I9, stroke_width=8, transform=tilt),
            tag("path", d="M614 642 H710 M614 670 H694 M614 698 H668", fill="none", stroke=secondary, stroke_width=13, stroke_linecap="round", transform=tilt),
            tag("circle", cx=704, cy=690, r=25, fill=secondary, stroke=I9, stroke_width=10, transform=tilt),
            tag("path", d="M691 690 L701 700 L718 680", fill="none", stroke=PAPER, stroke_width=9, stroke_linecap="round", stroke_linejoin="round", transform=tilt),
            tag("path", d="M616 725 Q668 745 720 722", fill="none", stroke=primary, stroke_width=9, stroke_linecap="round", transform="rotate(-5 670 738)"),
        ]
        glow += [
            tag("path", d=receipt, fill="none", stroke=primary, stroke_width=32, opacity="0.30", stroke_linejoin="round", transform=tilt),
            tag("circle", cx=704, cy=690, r=43, fill="none", stroke=secondary, stroke_width=16, opacity="0.28", transform=tilt),
            tag("path", d="M758 574 L768 594 L790 604 L768 614 L758 636 L748 614 L726 604 L748 594 Z", fill=primary, opacity="0.82"),
        ]
    elif item_id == "item_a_03":
        temples = "M414 326 L382 316 Q366 314 356 330 M610 326 L642 316 Q658 314 668 330"
        bridge = "M502 330 Q512 316 522 330"
        base += [
            tag("path", d=temples, fill="none", stroke=I9, stroke_width=18, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=temples, fill="none", stroke=primary, stroke_width=7, stroke_linecap="round", stroke_linejoin="round"),
            tag("rect", x=414, y=304, width=88, height=72, rx=28, fill=primary, opacity="0.22", stroke=I9, stroke_width=18),
            tag("rect", x=522, y=304, width=88, height=72, rx=28, fill=primary, opacity="0.22", stroke=I9, stroke_width=18),
            tag("path", d=bridge, fill="none", stroke=I9, stroke_width=18, stroke_linecap="round"),
        ]
        accent += [
            tag("rect", x=414, y=304, width=88, height=72, rx=28, fill="none", stroke=primary, stroke_width=8),
            tag("rect", x=522, y=304, width=88, height=72, rx=28, fill="none", stroke=primary, stroke_width=8),
            tag("path", d=bridge, fill="none", stroke=secondary, stroke_width=7, stroke_linecap="round"),
            tag("path", d="M433 326 L449 312 M541 326 L557 312", fill="none", stroke=PAPER, stroke_width=7, stroke_linecap="round"),
        ]
        glow += [
            tag("rect", x=402, y=292, width=112, height=96, rx=40, fill="none", stroke=primary, stroke_width=14, opacity="0.28"),
            tag("rect", x=510, y=292, width=112, height=96, rx=40, fill="none", stroke=primary, stroke_width=14, opacity="0.28"),
            tag("path", d="M430 354 H486 M538 354 H594", fill="none", stroke=secondary, stroke_width=9, stroke_linecap="round", opacity="0.34"),
        ]
        face_fit = "translate(0 34)"
        base[:] = [group("qa_glasses_eye_alignment", base, transform=face_fit)]
        accent[:] = [group("qa_glasses_eye_alignment_accent", accent, transform=face_fit)]
        glow[:] = [group("qa_glasses_eye_alignment_glow", glow, transform=face_fit)]
    elif item_id == "item_a_04":
        left_panel = "M368 492 Q398 458 448 450 L512 522 L486 798 L416 818 Q378 728 362 592 Z"
        right_panel = "M656 492 Q626 458 576 450 L512 522 L538 798 L608 818 Q646 728 662 592 Z"
        base += [
            tag("path", d=left_panel, fill=I7, stroke=I9, stroke_width=sw, stroke_linejoin="round"),
            tag("path", d=right_panel, fill=I7, stroke=I9, stroke_width=sw, stroke_linejoin="round"),
            tag("path", d="M448 450 L512 522 L466 612 L404 486 Z", fill=S2, stroke=I9, stroke_width=14, stroke_linejoin="round"),
            tag("path", d="M576 450 L512 522 L558 612 L620 486 Z", fill=S2, stroke=I9, stroke_width=14, stroke_linejoin="round"),
            tag("path", d="M506 540 L484 788 M518 540 L540 788", fill="none", stroke=I9, stroke_width=20, stroke_linecap="round"),
            tag("path", d="M390 646 L472 626 L468 700 L404 716 Z", fill=S2, stroke=I9, stroke_width=14, stroke_linejoin="round"),
            tag("path", d="M552 626 L634 646 L620 716 L556 700 Z", fill=S2, stroke=I9, stroke_width=14, stroke_linejoin="round"),
        ]
        accent += [
            tag("path", d="M448 466 L494 522 L464 598 M576 466 L530 522 L560 598", fill="none", stroke=primary, stroke_width=13, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d="M504 550 L484 786 M520 550 L540 786", fill="none", stroke=primary, stroke_width=11, stroke_dasharray="10 14", stroke_linecap="round"),
            tag("circle", cx=522, cy=566, r=14, fill=PAPER, stroke=I9, stroke_width=8),
            tag("path", d="M522 580 L526 606", fill="none", stroke=secondary, stroke_width=10, stroke_linecap="round"),
            tag("path", d="M402 658 L466 642 M558 642 L622 658", fill="none", stroke=secondary, stroke_width=12, stroke_linecap="round"),
            tag("path", d="M416 784 Q452 804 486 782 M538 782 Q572 804 608 784", fill="none", stroke=primary, stroke_width=10, stroke_linecap="round"),
        ]
        glow += [
            tag("path", d="M352 500 Q388 444 446 438 M578 438 Q636 444 672 500", fill="none", stroke=primary, stroke_width=28, opacity="0.22", stroke_linecap="round"),
            tag("path", d="M494 536 L470 800 M530 536 L554 800", fill="none", stroke=primary, stroke_width=24, opacity="0.24", stroke_linecap="round"),
            tag("path", d="M388 642 L474 620 M550 620 L636 642", fill="none", stroke=secondary, stroke_width=22, opacity="0.20", stroke_linecap="round"),
        ]
    elif item_id == "item_a_05":
        crown = "M350 218 L332 118 L424 168 L512 54 L600 168 L692 118 L674 218 Q512 250 350 218 Z"
        band = "M348 182 Q512 214 676 182 L674 218 Q512 250 350 218 Z"
        left_patch = "M366 188 Q404 197 450 202 L446 226 Q404 220 370 212 Z"
        center_patch = "M464 204 Q512 210 560 204 L558 232 Q512 239 466 232 Z"
        right_patch = "M574 202 Q620 197 658 188 L654 212 Q620 220 578 226 Z"
        base += [
            tag("path", d=crown, fill=I7, stroke=I9, stroke_width=24, stroke_linejoin="round"),
            tag("path", d=band, fill=S2, stroke=I9, stroke_width=16, stroke_linejoin="round"),
            tag("path", d="M424 168 L442 194 M600 168 L582 194", fill="none", stroke=I9, stroke_width=14, stroke_linecap="round"),
        ]
        accent += [
            tag("path", d="M350 132 L424 172 L512 66 L600 172 L674 132", fill="none", stroke=primary, stroke_width=12, stroke_linecap="round", stroke_linejoin="round"),
            tag("rect", x=482, y=106, width=60, height=42, rx=10, fill=secondary, stroke=I9, stroke_width=10),
            tag("path", d=left_patch, fill=primary, stroke=I9, stroke_width=9, stroke_linejoin="round"),
            tag("path", d=center_patch, fill=secondary, stroke=I9, stroke_width=9, stroke_linejoin="round"),
            tag("path", d=right_patch, fill=primary, stroke=I9, stroke_width=9, stroke_linejoin="round"),
            tag("circle", cx=494, cy=127, r=5, fill=PAPER),
            tag("circle", cx=530, cy=127, r=5, fill=PAPER),
            tag("circle", cx=388, cy=204, r=5, fill=PAPER),
            tag("circle", cx=512, cy=221, r=5, fill=PAPER),
            tag("circle", cx=636, cy=204, r=5, fill=PAPER),
        ]
        glow += [
            tag("path", d=left_patch, fill="none", stroke=primary, stroke_width=20, opacity="0.24", stroke_linejoin="round"),
            tag("path", d=center_patch, fill="none", stroke=secondary, stroke_width=20, opacity="0.24", stroke_linejoin="round"),
            tag("path", d=right_patch, fill="none", stroke=primary, stroke_width=20, opacity="0.24", stroke_linejoin="round"),
        ]
    elif item_id == "item_b_01":
        base += [
            tag("ellipse", cx=790, cy=916, rx=150, ry=25, fill=I9, opacity="0.34"),
            tag("path", d="M690 862 L660 918 H738 L754 870 Z", fill=I7, stroke=I9, stroke_width=20, stroke_linejoin="round"),
            tag("path", d="M890 862 L920 918 H842 L826 870 Z", fill=I7, stroke=I9, stroke_width=20, stroke_linejoin="round"),
            tag("path", d="M700 664 Q790 596 880 664", fill="none", stroke=I9, stroke_width=30, stroke_linecap="round"),
            tag("path", d="M700 664 Q790 596 880 664", fill="none", stroke=primary, stroke_width=12, stroke_linecap="round"),
            tag("path", d="M716 674 L744 724 M864 674 L836 724", fill="none", stroke=I9, stroke_width=22, stroke_linecap="round"),
            tag("path", d="M642 681 Q650 631 699 618 Q746 629 756 681 L734 703 H666 Z", fill=primary, stroke=I9, stroke_width=20, stroke_linejoin="round"),
            tag("path", d="M824 681 Q834 629 881 618 Q930 631 938 681 L914 703 H846 Z", fill=primary, stroke=I9, stroke_width=20, stroke_linejoin="round"),
            tag("rect", x=640, y=696, width=300, height=198, rx=64, fill=I7, stroke=I9, stroke_width=24),
            tag("rect", x=762, y=679, width=56, height=30, rx=14, fill=secondary, stroke=I9, stroke_width=12),
            tag("rect", x=672, y=744, width=236, height=103, rx=20, fill=I9, stroke=primary, stroke_width=10),
            # 6:70 is built only from seven-segment vector primitives.
            *[tag("rect", x=x, y=y, width=w, height=h, rx=4, fill=PAPER) for x, y, w, h in (
                (714, 759, 26, 8), (707, 766, 8, 24), (714, 789, 26, 8),
                (707, 796, 8, 24), (739, 796, 8, 24), (714, 819, 26, 8),
                (780, 759, 26, 8), (805, 766, 8, 24), (805, 796, 8, 24),
                (840, 759, 26, 8), (833, 766, 8, 24), (865, 766, 8, 24),
                (833, 796, 8, 24), (865, 796, 8, 24), (840, 819, 26, 8),
            )],
            tag("circle", cx=761, cy=780, r=6, fill=secondary),
            tag("circle", cx=761, cy=807, r=6, fill=secondary),
        ]
        accent += [
            tag("rect", x=654, y=710, width=272, height=170, rx=52, fill="none", stroke=primary, stroke_width=9, opacity="0.78"),
            tag("path", d="M666 666 Q683 640 710 638 M870 638 Q897 640 914 666", fill="none", stroke=PAPER, stroke_width=9, stroke_linecap="round", opacity="0.72"),
            tag("path", d="M690 884 H724 M856 884 H890", fill="none", stroke=secondary, stroke_width=10, stroke_linecap="round"),
        ]
        glow += [
            tag("rect", x=622, y=680, width=336, height=232, rx=82, fill="none", stroke=primary, stroke_width=20, opacity="0.24"),
            tag("ellipse", cx=790, cy=914, rx=174, ry=38, fill="none", stroke=secondary, stroke_width=16, opacity="0.22"),
            tag("path", d="M622 640 Q598 662 606 694 M958 640 Q982 662 974 694", fill="none", stroke=secondary, stroke_width=14, stroke_linecap="round", opacity="0.44"),
        ]
    elif item_id == "item_b_02":
        base += [
            # Opaque, outward-facing sneaker silhouettes replace the mascot's
            # original footwear instead of reading as ankle-mounted modules.
            tag("path", d="M468 778 C490 782 503 799 501 821 L499 836 C516 844 528 860 531 881 L534 902 C536 919 522 932 504 932 L398 928 C370 927 348 919 341 903 C334 886 342 866 360 857 L408 833 L416 806 C422 786 445 773 468 778 Z", fill=I7, stroke=I9, stroke_width=20, stroke_linejoin="round"),
            tag("path", d="M556 778 C534 782 521 799 523 821 L525 836 C508 844 496 860 493 881 L490 902 C488 919 502 932 520 932 L626 928 C654 927 676 919 683 903 C690 886 682 866 664 857 L616 833 L608 806 C602 786 579 773 556 778 Z", fill=I7, stroke=I9, stroke_width=20, stroke_linejoin="round"),
            tag("path", d="M421 807 C431 784 459 778 478 793 L496 846 L452 864 L409 839 Z", fill=primary, stroke=I9, stroke_width=12, stroke_linejoin="round"),
            tag("path", d="M603 807 C593 784 565 778 546 793 L528 846 L572 864 L615 839 Z", fill=primary, stroke=I9, stroke_width=12, stroke_linejoin="round"),
            tag("path", d="M426 806 Q451 784 478 795 Q490 801 494 814 Q465 807 438 827 Z", fill=I9),
            tag("path", d="M598 806 Q573 784 546 795 Q534 801 530 814 Q559 807 586 827 Z", fill=I9),
            tag("path", d="M360 858 Q392 842 415 834 Q450 842 470 879 Q427 902 347 890 Q347 870 360 858 Z", fill=S2, stroke=I9, stroke_width=12, stroke_linejoin="round"),
            tag("path", d="M664 858 Q632 842 609 834 Q574 842 554 879 Q597 902 677 890 Q677 870 664 858 Z", fill=S2, stroke=I9, stroke_width=12, stroke_linejoin="round"),
            tag("path", d="M341 889 C382 904 429 909 477 903 L533 891 L535 909 C537 926 523 939 505 940 L396 936 C369 935 348 926 341 911 Q337 900 341 889 Z", fill=PAPER, stroke=I9, stroke_width=12, stroke_linejoin="round"),
            tag("path", d="M683 889 C642 904 595 909 547 903 L491 891 L489 909 C487 926 501 939 519 940 L628 936 C655 935 676 926 683 911 Q687 900 683 889 Z", fill=PAPER, stroke=I9, stroke_width=12, stroke_linejoin="round"),
        ]
        accent += [
            tag("path", d="M429 824 L477 815 M426 839 L480 829 M431 854 L482 842", fill="none", stroke=secondary, stroke_width=10, stroke_linecap="round"),
            tag("path", d="M595 824 L547 815 M598 839 L544 829 M593 854 L542 842", fill="none", stroke=secondary, stroke_width=10, stroke_linecap="round"),
            tag("path", d="M354 901 Q418 919 486 909 M670 901 Q606 919 538 909", fill="none", stroke=primary, stroke_width=8, stroke_linecap="round"),
            tag("path", d="M372 864 L397 853 L413 870 M652 864 L627 853 L611 870", fill="none", stroke=secondary, stroke_width=9, stroke_linecap="round", stroke_linejoin="round"),
        ]
        glow += [
            # Partial heel/toe echoes suggest delayed arrival without creating
            # a second pair of shoes or enclosing the feet in glowing boxes.
            tag("path", d="M342 838 C319 848 310 869 316 890 C321 909 342 923 374 929", fill="none", stroke=primary, stroke_width=16, opacity="0.28", stroke_linecap="round"),
            tag("path", d="M682 838 C705 848 714 869 708 890 C703 909 682 923 650 929", fill="none", stroke=primary, stroke_width=16, opacity="0.28", stroke_linecap="round"),
            tag("path", d="M330 856 Q310 879 326 902 M694 856 Q714 879 698 902", fill="none", stroke=secondary, stroke_width=10, opacity="0.24", stroke_linecap="round"),
            tag("path", d="M332 930 Q358 943 388 946 M692 930 Q666 943 636 946", fill="none", stroke=primary, stroke_width=12, opacity="0.22", stroke_linecap="round"),
        ]
    elif item_id == "item_b_03":
        # A vertical, jewelry-like loop reads as a ring instead of a floor aura.
        # The slight rightward tilt keeps it clear of the face while placing it
        # naturally above the raised-hand territory used by the runtime orbit.
        ring = (
            "M790 136 C844 136 882 190 882 260 "
            "C882 332 844 384 790 384 "
            "C736 384 698 332 698 260 "
            "C698 190 736 136 790 136 Z "
            "M790 194 C762 194 744 222 744 260 "
            "C744 300 762 326 790 326 "
            "C818 326 836 300 836 260 "
            "C836 222 818 194 790 194 Z"
        )
        tilt = "rotate(12 790 260)"
        base += [
            tag("path", d=ring, fill=I7, fill_rule="evenodd", stroke=I9, stroke_width=20, stroke_linejoin="round", transform=tilt),
            tag("path", d="M754 158 L764 126 Q790 102 816 126 L826 158 L806 180 H774 Z", fill=S2, stroke=I9, stroke_width=14, stroke_linejoin="round", transform=tilt),
            tag("circle", cx=790, cy=124, r=23, fill=secondary, stroke=I9, stroke_width=11, transform=tilt),
        ]
        accent += [
            tag("path", d="M728 326 C710 282 712 218 734 178 M846 192 C868 236 868 294 850 334", fill="none", stroke=primary, stroke_width=15, stroke_linecap="round", transform=tilt),
            tag("path", d="M780 116 Q790 108 800 116", fill="none", stroke=PAPER, stroke_width=7, stroke_linecap="round", transform=tilt),
            tag("circle", cx=796, cy=120, r=5, fill=PAPER, transform=tilt),
        ]
        glow += [
            tag("path", d="M690 330 C660 260 672 184 724 138 M856 148 C904 204 910 286 874 348", fill="none", stroke=primary, stroke_width=24, stroke_linecap="round", opacity="0.24", transform=tilt),
            tag("circle", cx=790, cy=124, r=42, fill="none", stroke=secondary, stroke_width=16, opacity="0.30", transform=tilt),
        ]
    elif item_id == "item_b_04":
        base += [
            # Two local palm-to-cuff links keep the static art correct for the
            # neutral pose. The cross-hand cooperation line is runtime-driven.
            tag("path", d="M286 532 Q310 548 330 558", fill="none", stroke=I9, stroke_width=34, stroke_linecap="round"),
            tag("path", d="M738 538 Q714 550 694 560", fill="none", stroke=I9, stroke_width=34, stroke_linecap="round"),
            tag("path", d="M286 532 Q310 548 330 558", fill="none", stroke=primary, stroke_width=14, stroke_linecap="round"),
            tag("path", d="M738 538 Q714 550 694 560", fill="none", stroke=secondary, stroke_width=14, stroke_linecap="round"),
            # Wrist cuffs sit on the declared neutral wrist anchors near
            # (350, 575) and (674, 575), in front of the mascot.
            tag("rect", x=290, y=538, width=128, height=72, rx=32, fill=I7, stroke=I9, stroke_width=20, transform="rotate(10 354 574)"),
            tag("rect", x=606, y=538, width=128, height=72, rx=32, fill=I7, stroke=I9, stroke_width=20, transform="rotate(-10 670 574)"),
            tag("path", d="M313 551 L390 566 L385 593 L308 579 Z", fill=primary, stroke=I9, stroke_width=9, stroke_linejoin="round"),
            tag("path", d="M711 551 L634 566 L639 593 L716 579 Z", fill=secondary, stroke=I9, stroke_width=9, stroke_linejoin="round"),
            # Matching tactile buttons rest on the two neutral palms.
            tag("circle", cx=238, cy=500, r=68, fill=I7, stroke=I9, stroke_width=22),
            tag("circle", cx=786, cy=506, r=68, fill=I7, stroke=I9, stroke_width=22),
            tag("circle", cx=238, cy=500, r=43, fill=primary, stroke=I9, stroke_width=12),
            tag("circle", cx=786, cy=506, r=43, fill=secondary, stroke=I9, stroke_width=12),
            tag("circle", cx=238, cy=500, r=13, fill=PAPER),
            tag("circle", cx=786, cy=506, r=13, fill=PAPER),
            tag("path", d="M215 482 Q238 458 261 482", fill="none", stroke=PAPER, stroke_width=10, stroke_linecap="round"),
            tag("path", d="M763 488 Q786 464 809 488", fill="none", stroke=PAPER, stroke_width=10, stroke_linecap="round"),
        ]
        accent += [
            tag("circle", cx=238, cy=500, r=78, fill="none", stroke=secondary, stroke_width=10, stroke_dasharray="20 14"),
            tag("circle", cx=786, cy=506, r=78, fill="none", stroke=primary, stroke_width=10, stroke_dasharray="20 14"),
            # Outer/lower safety sockets let the runtime cable descend beside
            # the mascot before crossing below the face silhouette.
            tag("circle", cx=286, cy=579, r=21, fill=I9, stroke=primary, stroke_width=10),
            tag("circle", cx=738, cy=579, r=21, fill=I9, stroke=secondary, stroke_width=10),
            tag("circle", cx=286, cy=579, r=7, fill=PAPER),
            tag("circle", cx=738, cy=579, r=7, fill=PAPER),
            tag("path", d="M310 566 L293 579 L310 592 M714 566 L731 579 L714 592", fill="none", stroke=PAPER, stroke_width=9, stroke_linecap="round", stroke_linejoin="round"),
        ]
        glow += [
            tag("circle", cx=238, cy=500, r=88, fill="none", stroke=primary, stroke_width=24, opacity="0.22"),
            tag("circle", cx=786, cy=506, r=88, fill="none", stroke=secondary, stroke_width=24, opacity="0.22"),
            tag("circle", cx=286, cy=579, r=31, fill="none", stroke=primary, stroke_width=16, opacity="0.30"),
            tag("circle", cx=738, cy=579, r=31, fill="none", stroke=secondary, stroke_width=16, opacity="0.30"),
        ]
    elif item_id == "item_b_05":
        # A tall statement sheet lives entirely at stage right. Horizontal
        # ledger rows and opposing line trends avoid the old skyline reading.
        base += [
            tag("path", d="M738 154 H906 L974 222 V718 Q974 742 950 742 H738 Q714 742 714 718 V178 Q714 154 738 154 Z", fill=I7, stroke=I9, stroke_width=18, stroke_linejoin="round"),
            tag("path", d="M906 154 V222 H974", fill=S2, stroke=I9, stroke_width=14, stroke_linejoin="round"),
            tag("path", d="M750 238 H876 M750 270 H838", fill="none", stroke=I9, stroke_width=14, stroke_linecap="round"),
            tag("rect", x=744, y=304, width=200, height=154, rx=16, fill=S2, stroke=I9, stroke_width=12),
            tag("path", d="M768 330 V430 H924 M768 380 H924 M820 330 V430 M872 330 V430", fill="none", stroke=I9, stroke_width=8, opacity="0.72"),
            tag("path", d="M742 500 H946 M742 550 H946 M742 600 H946", fill="none", stroke=I9, stroke_width=10, stroke_linecap="round"),
            tag("circle", cx=764, cy=480, r=14, fill=S2, stroke=I9, stroke_width=8),
            tag("circle", cx=764, cy=530, r=14, fill=S2, stroke=I9, stroke_width=8),
            tag("circle", cx=764, cy=580, r=14, fill=S2, stroke=I9, stroke_width=8),
            tag("path", d="M798 480 H854 M798 530 H874 M798 580 H840", fill="none", stroke=I9, stroke_width=12, stroke_linecap="round"),
            tag("path", d="M888 480 H928 M898 530 H928 M878 580 H928", fill="none", stroke=I9, stroke_width=16, stroke_linecap="round"),
            tag("path", d="M742 630 H946 M742 646 H946", fill="none", stroke=I9, stroke_width=9, stroke_linecap="round"),
            tag("rect", x=742, y=670, width=204, height=42, rx=14, fill=S2, stroke=I9, stroke_width=10),
        ]
        accent += [
            tag("path", d="M906 154 V222 H974 Z", fill=secondary, opacity="0.82"),
            tag("path", d="M780 344 L822 356 L864 384 L912 416", fill="none", stroke=secondary, stroke_width=13, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d="M780 416 L822 402 L864 370 L912 340", fill="none", stroke=primary, stroke_width=13, stroke_linecap="round", stroke_linejoin="round"),
            *[tag("circle", cx=x, cy=y, r=8, fill=secondary) for x, y in ((780, 344), (822, 356), (864, 384), (912, 416))],
            *[tag("circle", cx=x, cy=y, r=8, fill=primary) for x, y in ((780, 416), (822, 402), (864, 370), (912, 340))],
            # Pure vector plus/minus marks give transaction semantics without
            # text, numerals, or currency glyphs.
            tag("path", d="M756 480 H772 M764 472 V488 M756 530 H772 M756 580 H772 M764 572 V588", fill="none", stroke=primary, stroke_width=6, stroke_linecap="round"),
            tag("path", d="M798 480 H850 M798 530 H870 M798 580 H836", fill="none", stroke=primary, stroke_width=7, stroke_linecap="round"),
            tag("path", d="M890 480 H928 M900 530 H928 M880 580 H928", fill="none", stroke=secondary, stroke_width=8, stroke_linecap="round"),
            tag("circle", cx=770, cy=691, r=10, fill=secondary),
            tag("circle", cx=800, cy=691, r=10, fill=primary),
            tag("path", d="M830 691 H920", fill="none", stroke=primary, stroke_width=16, stroke_linecap="round"),
        ]
        glow += [
            tag("path", d="M730 138 H914 L990 214 V728 Q990 758 960 758 H730 Q698 758 698 726 V170 Q698 138 730 138 Z", fill="none", stroke=primary, stroke_width=22, opacity="0.22", stroke_linejoin="round"),
            tag("path", d="M772 424 L822 410 L864 378 L920 332", fill="none", stroke=primary, stroke_width=24, opacity="0.20", stroke_linecap="round"),
            tag("path", d="M772 336 L822 348 L864 376 L920 424", fill="none", stroke=secondary, stroke_width=20, opacity="0.18", stroke_linecap="round"),
            tag("rect", x=728, y=656, width=232, height=70, rx=24, fill="none", stroke=secondary, stroke_width=18, opacity="0.20"),
        ]
    elif item_id == "item_c_01":
        badge_transform = (
            "translate(385 535) scale(0.70) translate(-410 -554) "
            "rotate(-4 410 554)"
        )
        approval_mark = "M382 574 L402 592 L441 550"
        base += [group("homologation_badge_base", [
            # A short clasp and bridge make the object read as physically pinned
            # to the shirt rather than as a floating interface tile.
            tag("rect", x=396, y=451, width=28, height=42, rx=9, fill=I7, stroke=I9, stroke_width=10),
            tag("rect", x=364, y=435, width=92, height=36, rx=18, fill=S2, stroke=I9, stroke_width=12),
            tag("rect", x=382, y=447, width=56, height=10, rx=5, fill=primary),
            tag("rect", x=332, y=476, width=156, height=188, rx=22, fill=I7, stroke=I9, stroke_width=18),
            tag("rect", x=349, y=493, width=122, height=154, rx=13, fill=PAPER, stroke=I9, stroke_width=8),
            tag("rect", x=361, y=507, width=98, height=22, rx=9, fill=primary, stroke=I9, stroke_width=6),
            tag("path", d="M373 518 H405 M415 518 H447", fill="none", stroke=I9, stroke_width=6, stroke_linecap="round"),
            # The official stamp remains complete and readable before any
            # channel displacement is layered over it.
            tag("circle", cx=410, cy=577, r=45, fill=primary, stroke=I9, stroke_width=10),
            tag("circle", cx=410, cy=577, r=34, fill="none", stroke=PAPER, stroke_width=5, stroke_dasharray="9 7"),
            tag("path", d=approval_mark, fill="none", stroke=I9, stroke_width=13, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d="M369 628 H451", fill="none", stroke=I9, stroke_width=8, stroke_linecap="round"),
            tag("path", d="M384 641 H436", fill="none", stroke=I9, stroke_width=6, stroke_linecap="round"),
        ], transform=badge_transform)]
        accent += [group("homologated_channel_offsets", [
            tag("rect", x=374, y=444, width=56, height=7, rx=3, fill=secondary),
            # Two bounded scan slices carry the glitch language without
            # breaking the badge silhouette or obscuring the approval mark.
            tag("rect", x=320, y=535, width=38, height=8, rx=4, fill=MAGENTA, opacity="0.88"),
            tag("rect", x=462, y=535, width=34, height=8, rx=4, fill=CYAN, opacity="0.88"),
            tag("rect", x=323, y=608, width=30, height=8, rx=4, fill=CYAN, opacity="0.82"),
            tag("rect", x=468, y=608, width=27, height=8, rx=4, fill=MAGENTA, opacity="0.82"),
            tag("path", d=approval_mark, transform="translate(-6 0)", fill="none", stroke=MAGENTA, stroke_width=7, stroke_linecap="round", stroke_linejoin="round", opacity="0.82"),
            tag("path", d=approval_mark, transform="translate(6 0)", fill="none", stroke=CYAN, stroke_width=7, stroke_linecap="round", stroke_linejoin="round", opacity="0.82"),
            tag("path", d=approval_mark, fill="none", stroke=PAPER, stroke_width=7, stroke_linecap="round", stroke_linejoin="round"),
        ], transform=badge_transform)]
        glow += [group("homologation_badge_glow", [
            tag("rect", x=320, y=463, width=180, height=214, rx=31, fill="none", stroke=primary, stroke_width=16, opacity="0.20"),
            tag("circle", cx=410, cy=577, r=56, fill="none", stroke=secondary, stroke_width=14, opacity="0.24"),
            tag("path", d="M311 539 H345 M475 539 H509", fill="none", stroke=CYAN, stroke_width=10, stroke_linecap="round", opacity="0.20"),
        ], transform=badge_transform)]
    elif item_id == "item_c_02":
        digit_segments = "M682 604 H724 M676 612 V648 M682 654 H724 M676 662 V696 M682 704 H724 M730 662 V696 M754 604 H812 M806 612 V648"
        running_legs = "M690 712 Q682 734 656 738 M716 712 Q724 732 748 730"
        pocket = "M748 650 Q792 626 838 650 L830 742 Q794 770 748 744 Z"
        base += [
            tag("path", d="M622 664 Q602 646 578 652 L596 670 L574 682 Q600 690 624 684 Z", fill=primary, stroke=I9, stroke_width=12, stroke_linejoin="round"),
            tag("path", d=running_legs, fill="none", stroke=I9, stroke_width=24, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=running_legs, fill="none", stroke=secondary, stroke_width=10, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=digit_segments, fill="none", stroke=I9, stroke_width=30, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=digit_segments, fill="none", stroke=primary, stroke_width=14, stroke_linecap="round", stroke_linejoin="round"),
            tag("circle", cx=640, cy=688, r=27, fill=secondary, stroke=I9, stroke_width=14),
            tag("circle", cx=633, cy=681, r=6, fill=PAPER, stroke=I9, stroke_width=3),
            tag("path", d=pocket, fill=I7, stroke=I9, stroke_width=18, stroke_linejoin="round"),
        ]
        accent += [
            tag("path", d="M752 650 Q792 630 834 650", fill="none", stroke=secondary, stroke_width=12, stroke_linecap="round"),
            tag("path", d="M766 674 Q794 660 820 674 L814 724 Q794 740 770 726 Z", fill="none", stroke=primary, stroke_width=9, stroke_dasharray="12 10", stroke_linejoin="round"),
            tag("path", d="M558 622 H594 M570 602 H608", fill="none", stroke=secondary, stroke_width=10, stroke_linecap="round"),
            tag("path", d="M636 650 L646 634 L654 650 Z", fill=primary, stroke=I9, stroke_width=6, stroke_linejoin="round"),
        ]
        glow += [
            tag("path", d="M616 688 Q638 724 666 696", fill="none", stroke=secondary, stroke_width=18, opacity="0.26", stroke_linecap="round"),
            tag("path", d="M668 586 H824", fill="none", stroke=primary, stroke_width=22, opacity="0.20", stroke_dasharray="34 20", stroke_linecap="round"),
            tag("path", d="M736 644 Q792 610 850 644", fill="none", stroke=secondary, stroke_width=22, opacity="0.22", stroke_linecap="round"),
        ]
        hip_fit = "translate(730 690) scale(0.78) translate(-710 -670)"
        base[:] = [group("clandestine_decimal_hip_fit", base, transform=hip_fit)]
        accent[:] = [group("clandestine_decimal_hip_fit_accent", accent, transform=hip_fit)]
        glow[:] = [group("clandestine_decimal_hip_fit_glow", glow, transform=hip_fit)]
    elif item_id == "item_c_03":
        # A worn cape is built as two independent cloth tails beneath a curved
        # shoulder mantle. The widening center split avoids the old rigid panel.
        base += [
            tag("path", d="M472 458 Q396 430 338 474 Q310 496 294 542 L272 752 Q324 798 414 812 L474 694 Q498 610 500 502 Z", fill=I7, stroke=I9, stroke_width=sw, stroke_linejoin="round"),
            tag("path", d="M552 458 Q628 430 686 474 Q714 496 730 542 L752 752 Q700 798 610 812 L550 694 Q526 610 524 502 Z", fill=I7, stroke=I9, stroke_width=sw, stroke_linejoin="round"),
            tag("path", d="M326 474 Q376 402 462 400 L512 438 L562 400 Q648 402 698 474 L656 530 Q604 486 550 492 L512 528 L474 492 Q420 486 368 530 Z", fill=S2, stroke=I9, stroke_width=sw, stroke_linejoin="round"),
            tag("path", d="M448 418 Q512 378 576 418 L550 480 Q512 456 474 480 Z", fill=I7, stroke=I9, stroke_width=14, stroke_linejoin="round"),
            tag("path", d="M340 514 Q326 630 312 746 M684 514 Q698 630 712 746", fill="none", stroke=S2, stroke_width=20, stroke_linecap="round", opacity="0.84"),
        ]
        accent += [
            tag("path", d="M344 476 Q394 420 462 420 L512 458 L562 420 Q630 420 680 476", fill="none", stroke=primary, stroke_width=14, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d="M352 516 Q340 620 324 742 M672 516 Q684 620 700 742", fill="none", stroke=secondary, stroke_width=10, stroke_dasharray="12 16", stroke_linecap="square"),
            tag("path", d="M474 520 Q474 612 444 700 M550 520 Q550 612 580 700", fill="none", stroke=primary, stroke_width=9, stroke_dasharray="10 16", stroke_linecap="square", opacity="0.88"),
            tag("rect", x=332, y=578, width=34, height=30, rx=5, fill=primary, stroke=I9, stroke_width=6),
            tag("rect", x=370, y=610, width=24, height=22, rx=4, fill=secondary, stroke=I9, stroke_width=5),
            tag("rect", x=326, y=620, width=20, height=20, rx=4, fill=secondary, stroke=I9, stroke_width=5),
            tag("rect", x=658, y=578, width=34, height=30, rx=5, fill=secondary, stroke=I9, stroke_width=6),
            tag("rect", x=630, y=610, width=24, height=22, rx=4, fill=primary, stroke=I9, stroke_width=5),
            tag("rect", x=678, y=620, width=20, height=20, rx=4, fill=primary, stroke=I9, stroke_width=5),
            tag("path", d="M418 784 Q384 792 350 778 M606 784 Q640 792 674 778", fill="none", stroke=secondary, stroke_width=10, stroke_dasharray="12 14", stroke_linecap="square"),
        ]
        glow += [
            tag("path", d="M306 474 Q372 378 462 380 L512 416 L562 380 Q652 378 718 474", fill="none", stroke=primary, stroke_width=24, stroke_linecap="round", opacity="0.22"),
            tag("path", d="M314 506 Q278 552 252 760 Q322 830 420 832 M710 506 Q746 552 772 760 Q702 830 604 832", fill="none", stroke=secondary, stroke_width=22, stroke_linecap="round", opacity="0.18"),
            tag("path", d="M488 494 Q486 620 420 806 M536 494 Q538 620 604 806", fill="none", stroke=primary, stroke_width=18, stroke_linecap="round", opacity="0.16"),
        ]
    elif item_id == "item_c_04":
        base += [group("physical_wifi_router_base", [
            tag("ellipse", cx=790, cy=912, rx=168, ry=27, fill=I9, opacity="0.42"),
            tag("path", d="M690 748 L664 548 M890 748 L916 548", fill="none", stroke=I9, stroke_width=40, stroke_linecap="round"),
            tag("path", d="M690 748 L664 548 M890 748 L916 548", fill="none", stroke=I7, stroke_width=18, stroke_linecap="round"),
            tag("circle", cx=664, cy=548, r=25, fill=I7, stroke=I9, stroke_width=12),
            tag("circle", cx=916, cy=548, r=25, fill=I7, stroke=I9, stroke_width=12),
            tag("rect", x=624, y=710, width=332, height=178, rx=36, fill=I7, stroke=I9, stroke_width=20),
            tag("path", d="M650 754 Q790 718 930 754", fill="none", stroke=S2, stroke_width=18, stroke_linecap="round"),
            tag("rect", x=657, y=872, width=58, height=38, rx=13, fill=I9),
            tag("rect", x=865, y=872, width=58, height=38, rx=13, fill=I9),
            tag("path", d="M738 804 Q790 754 842 804 M757 821 Q790 790 823 821", fill="none", stroke=primary, stroke_width=17, stroke_linecap="round"),
            tag("circle", cx=790, cy=844, r=11, fill=primary, stroke=I9, stroke_width=5),
            tag("circle", cx=680, cy=840, r=13, fill=PAPER, stroke=I9, stroke_width=7),
            tag("circle", cx=716, cy=840, r=13, fill=PAPER, stroke=I9, stroke_width=7),
        ])]
        accent += [group("router_status_and_signal", [
            tag("path", d="M690 748 L664 548 M890 748 L916 548", fill="none", stroke=primary, stroke_width=10, stroke_linecap="round"),
            tag("circle", cx=664, cy=548, r=10, fill=secondary),
            tag("circle", cx=916, cy=548, r=10, fill=secondary),
            tag("circle", cx=680, cy=840, r=7, fill=secondary),
            tag("circle", cx=716, cy=840, r=7, fill=primary),
            tag("path", d="M752 778 Q790 745 828 778", fill="none", stroke=secondary, stroke_width=9, stroke_linecap="round"),
        ])]
        glow += [group("router_searching_signal_glow", [
            tag("path", d="M718 678 Q790 608 862 678", fill="none", stroke=primary, stroke_width=18, opacity="0.22", stroke_linecap="round"),
            tag("path", d="M744 696 Q790 652 836 696", fill="none", stroke=secondary, stroke_width=14, opacity="0.28", stroke_linecap="round"),
            tag("rect", x=604, y=690, width=372, height=218, rx=52, fill="none", stroke=primary, stroke_width=18, opacity="0.18"),
        ])]
    elif item_id == "item_c_05":
        # Four interrupted corner rails read as a damaged scene frame. Every
        # stroke stops before the character-safe center of the composition.
        broken_frame = "M110 790 V590 M110 506 V300 Q110 222 188 222 H304 M720 222 H836 Q914 222 914 300 V506 M914 590 V790 M110 790 H258 M330 790 H388 M636 790 H694 M766 790 H914"
        digits_404 = "M386 134 V194 H454 M454 134 V254 M490 134 H552 M552 134 V254 M552 254 H490 M490 254 V134 M588 134 V194 H656 M656 134 V254"
        missing_horizon = "M158 642 H248 M290 642 H348 L372 620 M652 620 L676 642 H734 M776 642 H866"
        base += [
            tag("path", d=broken_frame, fill="none", stroke=I9, stroke_width=58, stroke_linecap="square", stroke_linejoin="round"),
            tag("path", d=broken_frame, fill="none", stroke=primary, stroke_width=24, stroke_linecap="square", stroke_linejoin="round"),
            tag("path", d=digits_404, fill="none", stroke=I9, stroke_width=34, stroke_linecap="square", stroke_linejoin="miter"),
            tag("path", d=digits_404, fill="none", stroke=primary, stroke_width=14, stroke_linecap="square", stroke_linejoin="miter"),
            tag("path", d=missing_horizon, fill="none", stroke=I9, stroke_width=30, stroke_linecap="square", stroke_linejoin="miter"),
            tag("path", d=missing_horizon, fill="none", stroke=secondary, stroke_width=12, stroke_linecap="square", stroke_linejoin="miter"),
        ]
        accent += [
            tag("path", d="M154 760 V612 M154 478 V326 Q154 270 210 270 H298 M726 270 H814 Q870 270 870 326 V478 M870 612 V760", fill="none", stroke=secondary, stroke_width=12, stroke_dasharray="42 24", stroke_linecap="square"),
            tag("path", d="M82 526 L110 508 L138 538 L110 566 Z M886 538 L914 508 L942 526 L914 566 Z", fill=secondary, stroke=I9, stroke_width=10, stroke_linejoin="miter"),
            tag("path", d="M260 766 L286 790 L312 758 L330 790 M694 790 L712 758 L738 790 L764 766", fill="none", stroke=secondary, stroke_width=12, stroke_linecap="square", stroke_linejoin="miter"),
            tag("path", d="M372 620 L390 606 L382 634 M652 620 L634 606 L642 634", fill="none", stroke=primary, stroke_width=10, stroke_linecap="square", stroke_linejoin="miter"),
            tag("path", d="M396 148 V184 H444 M500 148 H542 V240 H500 M598 148 V184 H646", fill="none", stroke=PAPER, stroke_width=5, stroke_linecap="square", opacity="0.72"),
        ]
        glow += [
            tag("path", d="M76 816 V604 M76 492 V282 Q76 188 170 188 H304 M720 188 H854 Q948 188 948 282 V492 M948 604 V816", fill="none", stroke=primary, stroke_width=30, stroke_linecap="square", opacity="0.20"),
            tag("path", d=digits_404, fill="none", stroke=secondary, stroke_width=30, stroke_linecap="square", stroke_linejoin="miter", opacity="0.22"),
            tag("path", d="M142 642 H372 M652 642 H882", fill="none", stroke=secondary, stroke_width=26, stroke_linecap="square", opacity="0.18"),
        ]
    elif item_id == "item_conv_01":
        # Three participant routes enter a compact over-under braid. Wide
        # radial gaps leave the mascot silhouette clean in SLOT-AURA-BACK.
        violet_route = "M160 270 C288 272 324 376 404 430 C470 474 532 444 566 492 C600 540 566 590 510 598"
        cyan_route = "M864 270 C736 272 700 376 620 430 C554 474 492 444 458 492 C424 540 458 590 514 598"
        gold_route = "M512 872 C512 748 634 704 626 594 C620 518 546 486 486 520 C430 552 430 620 478 654"
        base += [
            tag("path", d=violet_route, fill="none", stroke=I9, stroke_width=66, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=cyan_route, fill="none", stroke=I9, stroke_width=66, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=gold_route, fill="none", stroke=I9, stroke_width=66, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=violet_route, fill="none", stroke=VIOLET, stroke_width=30, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=cyan_route, fill="none", stroke=CYAN, stroke_width=30, stroke_linecap="round", stroke_linejoin="round"),
            tag("path", d=gold_route, fill="none", stroke=GOLD, stroke_width=30, stroke_linecap="round", stroke_linejoin="round"),
            tag("circle", cx=160, cy=270, r=62, fill=I7, stroke=I9, stroke_width=18),
            tag("circle", cx=160, cy=270, r=43, fill=I7, stroke=VIOLET, stroke_width=10),
            tag("circle", cx=160, cy=251, r=13, fill=PAPER, stroke=I9, stroke_width=5),
            tag("path", d="M128 294 Q160 264 192 294", fill="none", stroke=I9, stroke_width=18, stroke_linecap="round"),
            tag("path", d="M128 294 Q160 264 192 294", fill="none", stroke=PAPER, stroke_width=8, stroke_linecap="round"),
            tag("circle", cx=864, cy=270, r=62, fill=I7, stroke=I9, stroke_width=18),
            tag("circle", cx=864, cy=270, r=43, fill=I7, stroke=CYAN, stroke_width=10),
            tag("circle", cx=864, cy=251, r=13, fill=PAPER, stroke=I9, stroke_width=5),
            tag("path", d="M832 294 Q864 264 896 294", fill="none", stroke=I9, stroke_width=18, stroke_linecap="round"),
            tag("path", d="M832 294 Q864 264 896 294", fill="none", stroke=PAPER, stroke_width=8, stroke_linecap="round"),
            tag("circle", cx=512, cy=872, r=62, fill=I7, stroke=I9, stroke_width=18),
            tag("circle", cx=512, cy=872, r=43, fill=I7, stroke=GOLD, stroke_width=10),
            tag("circle", cx=512, cy=853, r=13, fill=PAPER, stroke=I9, stroke_width=5),
            tag("path", d="M480 896 Q512 866 544 896", fill="none", stroke=I9, stroke_width=18, stroke_linecap="round"),
            tag("path", d="M480 896 Q512 866 544 896", fill="none", stroke=PAPER, stroke_width=8, stroke_linecap="round"),
        ]
        accent += [
            # Redrawn spans alternate which ribbon passes above each crossing.
            tag("path", d="M620 430 C554 474 492 444 458 492", fill="none", stroke=I9, stroke_width=54, stroke_linecap="round"),
            tag("path", d="M620 430 C554 474 492 444 458 492", fill="none", stroke=CYAN, stroke_width=26, stroke_linecap="round"),
            tag("path", d="M566 492 C600 540 566 590 510 598", fill="none", stroke=I9, stroke_width=54, stroke_linecap="round"),
            tag("path", d="M566 492 C600 540 566 590 510 598", fill="none", stroke=VIOLET, stroke_width=26, stroke_linecap="round"),
            tag("path", d="M626 594 C620 518 546 486 486 520", fill="none", stroke=I9, stroke_width=54, stroke_linecap="round"),
            tag("path", d="M626 594 C620 518 546 486 486 520", fill="none", stroke=GOLD, stroke_width=26, stroke_linecap="round"),
            tag("circle", cx=160, cy=270, r=50, fill="none", stroke=PAPER, stroke_width=4, opacity="0.72"),
            tag("circle", cx=864, cy=270, r=50, fill="none", stroke=PAPER, stroke_width=4, opacity="0.72"),
            tag("circle", cx=512, cy=872, r=50, fill="none", stroke=PAPER, stroke_width=4, opacity="0.72"),
        ]
        glow += [
            tag("path", d=violet_route, fill="none", stroke=VIOLET, stroke_width=82, stroke_linecap="round", opacity="0.12"),
            tag("path", d=cyan_route, fill="none", stroke=CYAN, stroke_width=82, stroke_linecap="round", opacity="0.12"),
            tag("path", d=gold_route, fill="none", stroke=GOLD, stroke_width=82, stroke_linecap="round", opacity="0.12"),
            tag("circle", cx=160, cy=270, r=78, fill="none", stroke=VIOLET, stroke_width=18, opacity="0.18"),
            tag("circle", cx=864, cy=270, r=78, fill="none", stroke=CYAN, stroke_width=18, opacity="0.18"),
            tag("circle", cx=512, cy=872, r=78, fill="none", stroke=GOLD, stroke_width=18, opacity="0.18"),
        ]
    elif item_id == "item_conv_02":
        # Three interrupted, uneven approaches carry visual fatigue. Their last
        # bends become progressively smoother before meeting the calm hub.
        cyan_flow = "M92 292 C142 248 176 340 226 304 M260 286 C306 272 300 358 354 346 M386 356 C426 370 436 414 452 452"
        magenta_flow = "M932 306 C882 352 848 260 796 304 M762 286 C716 276 724 360 670 348 M638 360 C600 380 584 416 572 452"
        gold_flow = "M270 862 C326 838 292 754 350 732 M382 718 C426 708 388 646 436 618 M454 594 C480 584 500 572 512 560"
        for flow, color in ((cyan_flow, CYAN), (magenta_flow, MAGENTA), (gold_flow, GOLD)):
            base += [
                tag("path", d=flow, fill="none", stroke=I9, stroke_width=52, stroke_linecap="round", stroke_linejoin="round"),
                tag("path", d=flow, fill="none", stroke=color, stroke_width=20, stroke_linecap="round", stroke_linejoin="round"),
            ]
        base += [
            tag("circle", cx=512, cy=488, r=80, fill=I7, stroke=I9, stroke_width=38),
            tag("circle", cx=512, cy=488, r=68, fill=I7, stroke=MINT, stroke_width=16),
        ]
        accent += [
            tag("circle", cx=244, cy=296, r=9, fill=CYAN, stroke=I9, stroke_width=6),
            tag("circle", cx=780, cy=296, r=9, fill=MAGENTA, stroke=I9, stroke_width=6),
            tag("circle", cx=366, cy=724, r=9, fill=GOLD, stroke=I9, stroke_width=6),
            tag("path", d="M452 452 Q478 470 494 480 M572 452 Q546 470 530 480 M512 560 V514", fill="none", stroke=I9, stroke_width=30, stroke_linecap="round"),
            tag("path", d="M452 452 Q478 470 494 480", fill="none", stroke=CYAN, stroke_width=14, stroke_linecap="round"),
            tag("path", d="M572 452 Q546 470 530 480", fill="none", stroke=MAGENTA, stroke_width=14, stroke_linecap="round"),
            tag("path", d="M512 560 V514", fill="none", stroke=GOLD, stroke_width=14, stroke_linecap="round"),
            tag("circle", cx=512, cy=488, r=34, fill=I9, stroke=PAPER, stroke_width=10),
            tag("circle", cx=512, cy=488, r=13, fill=MINT),
            tag("path", d="M468 394 Q512 370 556 394 M466 580 Q512 606 558 580", fill="none", stroke=MINT, stroke_width=10, stroke_linecap="round"),
        ]
        glow += [
            tag("path", d=cyan_flow, fill="none", stroke=CYAN, stroke_width=54, stroke_linecap="round", opacity="0.16"),
            tag("path", d=magenta_flow, fill="none", stroke=MAGENTA, stroke_width=54, stroke_linecap="round", opacity="0.16"),
            tag("path", d=gold_flow, fill="none", stroke=GOLD, stroke_width=54, stroke_linecap="round", opacity="0.16"),
            tag("circle", cx=512, cy=488, r=104, fill="none", stroke=MINT, stroke_width=24, opacity="0.20"),
            tag("circle", cx=512, cy=488, r=126, fill="none", stroke=PAPER, stroke_width=8, opacity="0.14"),
        ]
    elif item_id == "item_conv_03":
        # ITEM-CONV-03 is a single oversized physical screw parked on the
        # right/back edge. Everything stays east of the mascot's central lane.
        screw_tilt = "rotate(-8 800 300)"
        cyan_tether = "M690 104 C732 126 754 156 770 184"
        magenta_tether = "M982 214 C942 214 922 238 918 276"
        gold_tether = "M976 486 C936 442 906 398 878 374"
        shaft = "M746 408 L854 408 L850 846 L800 924 L750 846 Z"
        threads = (
            "M746 482 L854 452 M746 554 L854 524 M746 626 L854 596 "
            "M746 698 L854 668 M746 770 L854 740 M750 838 L846 812"
        )
        for tether, color in ((cyan_tether, CYAN), (magenta_tether, MAGENTA), (gold_tether, GOLD)):
            base += [
                tag("path", d=tether, fill="none", stroke=I9, stroke_width=34, stroke_linecap="round"),
                tag("path", d=tether, fill="none", stroke=color, stroke_width=14, stroke_linecap="round"),
            ]
        base += [
            tag("path", d=shaft, fill=I7, stroke=I9, stroke_width=28, stroke_linejoin="round", transform=screw_tilt),
            tag("rect", x=742, y=382, width=116, height=84, rx=28, fill=S2, stroke=I9, stroke_width=24, transform=screw_tilt),
            tag("path", d=threads, fill="none", stroke=I9, stroke_width=30, stroke_linecap="round", transform=screw_tilt),
            tag("path", d=threads, fill="none", stroke=VIOLET, stroke_width=12, stroke_linecap="round", transform=screw_tilt),
            tag("circle", cx=800, cy=300, r=126, fill=S2, stroke=I9, stroke_width=30),
            tag("circle", cx=800, cy=300, r=102, fill=I7, stroke=VIOLET, stroke_width=12),
        ]
        accent += [
            tag("path", d="M800 228 V372 M728 300 H872", fill="none", stroke=I9, stroke_width=44, stroke_linecap="round"),
            tag("path", d="M800 228 V372 M728 300 H872", fill="none", stroke=PAPER, stroke_width=18, stroke_linecap="round"),
            tag("path", d="M772 438 L832 422 M764 824 L820 892", fill="none", stroke=PAPER, stroke_width=10, stroke_linecap="round", opacity="0.58", transform=screw_tilt),
            tag("circle", cx=770, cy=184, r=17, fill=CYAN, stroke=I9, stroke_width=9),
            tag("circle", cx=918, cy=276, r=17, fill=MAGENTA, stroke=I9, stroke_width=9),
            tag("circle", cx=878, cy=374, r=17, fill=GOLD, stroke=I9, stroke_width=9),
        ]
        glow += [
            tag("circle", cx=800, cy=300, r=150, fill="none", stroke=VIOLET, stroke_width=24, opacity="0.18"),
            tag("path", d=shaft, fill="none", stroke=VIOLET, stroke_width=48, stroke_linejoin="round", opacity="0.14", transform=screw_tilt),
            tag("path", d=cyan_tether, fill="none", stroke=CYAN, stroke_width=42, stroke_linecap="round", opacity="0.14"),
            tag("path", d=magenta_tether, fill="none", stroke=MAGENTA, stroke_width=42, stroke_linecap="round", opacity="0.14"),
            tag("path", d=gold_tether, fill="none", stroke=GOLD, stroke_width=42, stroke_linecap="round", opacity="0.14"),
        ]
    else:
        raise ValueError(f"No authored skin layers for {item_id}")
    return base, accent, glow


def _skin_builder(item_id: str, branch: str, variant: str) -> Callable[[AssetSpec], str]:
    primary, secondary = _skin_palette(branch)

    def build(spec: AssetSpec) -> str:
        base, accent, glow = _skin_layers(item_id, primary, secondary)
        if variant == "base":
            content = group("base", base)
        elif variant == "accent":
            content = group("accent", accent)
        elif variant == "glow":
            content = group("glow", glow)
        elif variant == "reduced":
            content = group("reduced_base", base) + group("reduced_accent", accent)
        else:
            backplate = tag("rect", x=52, y=52, width=920, height=920, rx=180, fill=I7, stroke=I9, stroke_width=28)
            cx, cy, scale = THUMB_TRANSFORMS[item_id]
            transform = f"translate(512 512) scale({scale}) translate(-{cx} -{cy})"
            content = group("thumbnail_backplate", backplate) + group("thumbnail_asset_normalized_48px", base + accent + glow, transform=transform, clip_path="url(#thumb_clip)")
            defs = '<clipPath id="thumb_clip"><rect x="70" y="70" width="884" height="884" rx="160"/></clipPath>'
            return svg_document(spec, content, defs=defs, view_box=(0, 0, 1024, 1024))
        return svg_document(spec, content, view_box=(0, 0, 1024, 1024))

    return build


def skin_specs() -> list[AssetSpec]:
    result: list[AssetSpec] = []
    for item_id, branch, slot, description in SKIN_META:
        side, subslot, offset = SKIN_ATTACHMENTS[item_id]
        for variant in ("base", "accent", "glow", "reduced", "thumb"):
            source_size = (256, 256) if variant == "thumb" else (1024, 1024)
            runtime_size = (256, 256) if variant == "thumb" else (512, 512)
            result.append(
                AssetSpec(
                    f"skin_{item_id}_{variant}",
                    "skins",
                    source_size,
                    runtime_size,
                    SLOT_PIVOTS[slot],
                    slot,
                    SLOT_Z[slot],
                    variant,
                    "lossless",
                    f"{description}; {variant} layer",
                    _skin_builder(item_id, branch, variant),
                    metadata=(
                        ("side", side),
                        ("subslot", subslot),
                        ("offsetNormalized", list(offset)),
                        ("milestoneProfile", f"{item_id}_v1"),
                        ("reducedId", f"skin_{item_id}_reduced"),
                        ("normalizedThumbnailPx", 48 if variant == "thumb" else None),
                    ),
                )
            )
    return result


FORM_COMPONENTS = {
    "01": ("outline", "glow", "thumb", "reduced"),
    "02": ("afterimage", "trail", "thumb", "reduced"),
    "03": ("weather_symbols", "ambient", "thumb", "reduced"),
    "04": ("skyline", "pulse", "thumb", "reduced"),
    "05": ("halo", "ground_link", "horizon_link", "thumb", "reduced"),
}


def _form_builder(form: str, component: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        shapes: list[str] = []
        defs = ""
        if component == "thumb":
            shapes += [tag("rect", x=60, y=60, width=2040, height=2040, rx=360, fill=I7, stroke=I9, stroke_width=54)]
        if form == "01":
            if component == "outline":
                shapes += [tag("path", d="M1080 430 C1438 430 1594 752 1538 1140 C1490 1472 1328 1688 1080 1740 C832 1688 670 1472 622 1140 C566 752 722 430 1080 430 Z", fill="none", stroke=I9, stroke_width=112), tag("path", d="M1080 430 C1438 430 1594 752 1538 1140 C1490 1472 1328 1688 1080 1740 C832 1688 670 1472 622 1140 C566 752 722 430 1080 430 Z", fill="none", stroke=CYAN, stroke_width=42)]
            elif component == "glow":
                shapes += [tag("ellipse", cx=1080, cy=1110, rx=620, ry=760, fill="none", stroke=VIOLET, stroke_width=92, opacity="0.22"), tag("circle", cx=612, cy=720, r=32, fill=CYAN), tag("circle", cx=1548, cy=1470, r=32, fill=VIOLET)]
            else:
                shapes += [tag("ellipse", cx=1080, cy=1100, rx=610, ry=750, fill="none", stroke=CYAN, stroke_width=52), tag("circle", cx=650, cy=760, r=36, fill=VIOLET), tag("circle", cx=1510, cy=1440, r=36, fill=CYAN)]
        elif form == "02":
            if component == "afterimage":
                shapes += [tag("path", d="M970 452 C1320 452 1476 760 1420 1132 C1378 1434 1230 1636 990 1700 C760 1636 612 1434 570 1132 C514 760 664 452 970 452 Z", fill=VIOLET, opacity="0.26", stroke=CYAN, stroke_width=34)]
            elif component == "trail":
                shapes += [tag("path", d="M430 1320 C650 1200 840 1350 1030 1260 C1240 1160 1380 970 1700 1050", fill="none", stroke=CYAN, stroke_width=66, opacity="0.56", stroke_linecap="round"), tag("path", d="M460 1400 C700 1300 890 1410 1110 1300 C1320 1190 1470 1080 1730 1160", fill="none", stroke=MAGENTA, stroke_width=40, opacity="0.52", stroke_linecap="round")]
            else:
                shapes += [tag("path", d="M970 500 C1290 500 1430 790 1380 1120 C1338 1400 1200 1580 990 1640 C780 1580 642 1400 600 1120 C550 790 690 500 970 500 Z", fill=VIOLET, opacity="0.28", stroke=CYAN, stroke_width=36), tag("path", d="M450 1400 C760 1220 1030 1420 1690 1080", fill="none", stroke=MAGENTA, stroke_width=48, opacity="0.62")]
        elif form == "03":
            if component == "weather_symbols":
                for row in range(5):
                    for col in range(5):
                        x = 260 + col * 390 + (row % 2) * 90
                        y = 300 + row * 360
                        if 650 < x < 1510 and 480 < y < 1650:
                            continue
                        color = CYAN if (row + col) % 2 == 0 else MAGENTA
                        if (row + col) % 3 == 0:
                            shapes.append(tag("path", d=f"M{x} {y} l70 70 l-70 70 l-70 -70 Z", fill="none", stroke=color, stroke_width=24, opacity="0.72"))
                        else:
                            shapes.append(tag("path", d=f"M{x-52} {y-44} L{x+52} {y+44}", stroke=color, stroke_width=28, stroke_linecap="round", opacity="0.72"))
            elif component == "ambient":
                defs = radial_gradient("ambient", [("0%", MAGENTA, 0.20), ("58%", VIOLET, 0.10), ("100%", I9, 0.0)])
                shapes += [tag("ellipse", cx=1080, cy=1120, rx=840, ry=920, fill="url(#ambient)"), tag("path", d="M120 510 L2040 1870", stroke=CYAN, stroke_width=42, opacity="0.10")]
            else:
                defs = radial_gradient("ambient", [("0%", MAGENTA, 0.22), ("100%", I9, 0.0)])
                shapes += [tag("ellipse", cx=1080, cy=1100, rx=800, ry=920, fill="url(#ambient)"), tag("path", d="M220 420 L620 820 M1540 420 L1940 820 M220 1700 L620 1300 M1540 1700 L1940 1300", stroke=CYAN, stroke_width=34, opacity="0.70")]
        elif form == "04":
            if component == "skyline":
                heights = (260, 420, 330, 560, 300, 480, 620, 360, 520, 280, 450)
                for idx, height in enumerate(heights):
                    x = 90 + idx * 190
                    shapes.append(tag("rect", x=x, y=1850 - height, width=120, height=height, rx=30, fill=I7, stroke=MAGENTA if idx % 2 else GOLD, stroke_width=20, opacity="0.86"))
            elif component == "pulse":
                shapes += [tag("path", d="M80 1480 Q350 1280 620 1470 T1160 1460 T1700 1450 T2080 1390", fill="none", stroke=GOLD, stroke_width=58, stroke_linecap="round"), tag("path", d="M80 1560 Q350 1360 620 1550 T1160 1540 T1700 1530 T2080 1470", fill="none", stroke=MAGENTA, stroke_width=30, opacity="0.65")]
            else:
                for idx, height in enumerate((260, 390, 310, 520, 350, 470, 280)):
                    x = 180 + idx * 280
                    shapes.append(tag("rect", x=x, y=1820 - height, width=150, height=height, rx=34, fill=I7, stroke=GOLD if idx % 2 else MAGENTA, stroke_width=20))
                shapes += [tag("path", d="M120 1480 Q420 1300 720 1480 T1320 1480 T2040 1400", fill="none", stroke=GOLD, stroke_width=44)]
        else:
            if component == "halo":
                shapes += [tag("path", d="M570 850 A570 570 0 0 1 1590 850", fill="none", stroke=I9, stroke_width=110, stroke_linecap="round"), tag("path", d="M570 850 A570 570 0 0 1 1590 850", fill="none", stroke=GOLD, stroke_width=42, stroke_linecap="round"), tag("path", d="M660 720 A480 480 0 0 1 1500 720", fill="none", stroke=CYAN, stroke_width=28, stroke_linecap="round")]
            elif component == "ground_link":
                shapes += [tag("path", d="M220 1760 Q620 1940 1080 1760 Q1540 1580 1940 1760", fill="none", stroke=I9, stroke_width=100, stroke_linecap="round"), tag("path", d="M220 1760 Q620 1940 1080 1760 Q1540 1580 1940 1760", fill="none", stroke=MAGENTA, stroke_width=36, stroke_linecap="round")]
            elif component == "horizon_link":
                shapes += [tag("path", d="M160 1480 V740 M2000 1480 V740 M160 1480 Q580 1360 1080 1480 Q1580 1600 2000 1480", fill="none", stroke=I9, stroke_width=94, stroke_linecap="round"), tag("path", d="M160 1480 V740", stroke=CYAN, stroke_width=30), tag("path", d="M2000 1480 V740", stroke=GOLD, stroke_width=30), tag("path", d="M160 1480 Q580 1360 1080 1480 Q1580 1600 2000 1480", fill="none", stroke=MAGENTA, stroke_width=30)]
            else:
                shapes += [tag("path", d="M560 850 A580 580 0 0 1 1600 850", fill="none", stroke=GOLD, stroke_width=48, stroke_linecap="round"), tag("path", d="M180 1760 Q620 1920 1080 1760 Q1540 1600 1980 1760", fill="none", stroke=MAGENTA, stroke_width=40), tag("path", d="M180 1760 V760 M1980 1760 V760", stroke=CYAN, stroke_width=32), tag("circle", cx=1080, cy=1120, r=52, fill=PAPER)]
        return svg_document(spec, group(f"form_{form}_{component}", shapes), defs=defs, view_box=(0, 0, 2160, 2160))

    return build


def form_specs() -> list[AssetSpec]:
    result: list[AssetSpec] = []
    for form, components in FORM_COMPONENTS.items():
        for component in components:
            is_thumb = component == "thumb"
            result.append(
                AssetSpec(
                    f"form_{form}_{component}",
                    "forms",
                    (256, 256) if is_thumb else (2160, 2160),
                    (256, 256) if is_thumb else (1080, 1080),
                    (0.50, 0.50),
                    None,
                    "VFX-AURA-BACK" if component not in ("trail", "weather_symbols", "pulse") else "VFX-AURA-FRONT",
                    "thumb" if is_thumb else ("reduced" if component == "reduced" else "base"),
                    "lossless",
                    f"FORM-{form} canonical {component} layer",
                    _form_builder(form, component),
                )
            )
    return result


BACKGROUND_IDS = [
    "bg_base_far", "bg_base_mid", "bg_base_near", "bg_base_grade", "bg_base_reduced",
    "bg_form_01_grade", "bg_form_01_reduced",
    *[f"bg_form_{form}_{plane}" for form in ("02", "03", "04", "05") for plane in ("far", "mid", "near", "grade", "reduced")],
]


def _background_builder(background_id: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        shapes: list[str] = []
        defs = ""
        plane = background_id.rsplit("_", 1)[-1]
        if background_id.startswith("bg_base"):
            form = "base"
        else:
            form = background_id.split("_")[2]
        if plane in ("grade", "reduced"):
            top = {"base": I9, "01": I9, "02": I7, "03": I9, "04": I9, "05": I7}[form]
            bottom = {"base": I7, "01": BV, "02": BV, "03": S2, "04": I7, "05": BV}[form]
            accent = {"base": VIOLET, "01": CYAN, "02": CYAN, "03": MAGENTA, "04": GOLD, "05": GOLD}[form]
            defs += linear_gradient("grade", [("0%", top), ("72%", bottom), ("100%", accent)], x1="0%", y1="0%", x2="0%", y2="100%")
            shapes.append(tag("rect", x=0, y=0, width=2160, height=3840, fill="url(#grade)"))
            shapes.append(tag("rect", x=0, y=0, width=2160, height=3840, fill=I9, opacity="0.18"))
        if plane == "far" or plane == "reduced":
            if form in ("base", "02"):
                shapes += [tag("path", d="M-220 820 Q420 240 1040 680 T2380 620", fill="none", stroke=VIOLET if form == "base" else CYAN, stroke_width=96, opacity="0.13"), tag("path", d="M-180 2820 Q420 2300 980 2720 T2340 2640", fill="none", stroke=BLUE, stroke_width=70, opacity="0.10")]
            elif form == "03":
                for row in range(7):
                    y = 260 + row * 480
                    shapes += [tag("path", d=f"M80 {y} L400 {y+260} M1760 {y} L2080 {y+260}", stroke=CYAN if row % 2 else MAGENTA, stroke_width=40, opacity="0.18")]
            elif form == "04":
                for idx, height in enumerate((500, 780, 620, 900, 560, 760, 980, 640)):
                    x = 60 + idx * 278
                    shapes.append(tag("rect", x=x, y=3060 - height, width=170, height=height, rx=44, fill=I7, stroke=GOLD if idx % 2 else MAGENTA, stroke_width=22, opacity="0.58"))
            elif form == "05":
                shapes += [tag("path", d="M360 1540 A820 820 0 0 1 1800 1540", fill="none", stroke=GOLD, stroke_width=54, opacity="0.36"), tag("path", d="M480 1360 A700 700 0 0 1 1680 1360", fill="none", stroke=CYAN, stroke_width=34, opacity="0.28")]
        if plane == "mid" or plane == "reduced":
            if form in ("base", "02"):
                shapes += [tag("path", d="M120 2140 Q430 1860 760 2120", fill="none", stroke=CYAN, stroke_width=54, opacity="0.20"), tag("path", d="M1400 2040 Q1760 1740 2080 2100", fill="none", stroke=MAGENTA if form == "02" else VIOLET, stroke_width=54, opacity="0.20")]
            elif form == "03":
                for idx in range(9):
                    x = 120 + (idx % 3) * 800
                    y = 420 + idx * 340
                    if 620 < x < 1540:
                        x = 120 if idx % 2 else 1880
                    shapes.append(tag("path", d=f"M{x-70} {y} L{x} {y+70} L{x+70} {y} L{x} {y-70} Z", fill="none", stroke=MAGENTA if idx % 2 else CYAN, stroke_width=24, opacity="0.34"))
            elif form == "04":
                shapes += [tag("path", d="M0 2780 Q360 2500 720 2780 T1440 2780 T2160 2680", fill="none", stroke=GOLD, stroke_width=66, opacity="0.56")]
            elif form == "05":
                shapes += [tag("path", d="M150 2900 V1540 M2010 2900 V1540", stroke=CYAN, stroke_width=42, opacity="0.34"), tag("path", d="M150 2900 Q600 2720 1080 2900 Q1560 3080 2010 2900", fill="none", stroke=MAGENTA, stroke_width=52, opacity="0.42")]
        if plane == "near" or plane == "reduced":
            if form == "03":
                shapes += [
                    tag("ellipse", cx=1080, cy=3340, rx=720, ry=168, fill=I9, opacity="0.44"),
                    tag("path", d="M140 3340 L430 3100 M1730 3400 L2050 3130", stroke=MAGENTA, stroke_width=42, stroke_linecap="round", opacity="0.50"),
                    tag("path", d="M250 3450 L380 3320 L510 3450 M1650 3450 L1780 3320 L1910 3450", fill="none", stroke=CYAN, stroke_width=28, opacity="0.42"),
                ]
            elif form == "05":
                shapes += [
                    tag("ellipse", cx=1080, cy=3340, rx=820, ry=194, fill=I9, opacity="0.50"),
                    tag("path", d="M120 3320 Q560 3120 1080 3320 Q1600 3520 2040 3320", fill="none", stroke=MAGENTA, stroke_width=44, opacity="0.48"),
                    tag("path", d="M120 3320 V3060 M2040 3320 V3060", stroke=CYAN, stroke_width=30, opacity="0.46"),
                    tag("circle", cx=1080, cy=3320, r=28, fill=GOLD, opacity="0.86"),
                ]
            else:
                shapes += [tag("ellipse", cx=1080, cy=3340, rx=760, ry=180, fill=I9, opacity="0.46"), tag("path", d="M180 3300 Q560 3180 1080 3300 Q1600 3420 1980 3300", fill="none", stroke={"base": VIOLET, "02": CYAN, "04": GOLD}.get(form, VIOLET), stroke_width=36, opacity="0.38")]
        if background_id == "bg_form_01_grade":
            defs = linear_gradient("grade", [("0%", I9), ("55%", BV), ("100%", CYAN)], x1="0%", y1="0%", x2="0%", y2="100%")
            shapes = [tag("rect", x=0, y=0, width=2160, height=3840, fill="url(#grade)"), tag("ellipse", cx=1080, cy=2140, rx=680, ry=920, fill=VIOLET, opacity="0.12")]
        return svg_document(spec, group(background_id, shapes), defs=defs, view_box=(0, 0, 2160, 3840))

    return build


def background_specs() -> list[AssetSpec]:
    result: list[AssetSpec] = []
    for asset_id in BACKGROUND_IDS:
        plane = asset_id.rsplit("_", 1)[-1]
        result.append(
            AssetSpec(
                asset_id,
                "backgrounds",
                (2160, 3840),
                (1080, 1920),
                (0.50, 0.50),
                None,
                "BG-GRADE" if plane in ("grade", "reduced") else f"BG-{plane.upper()}",
                "reduced" if plane == "reduced" else "base",
                "lossy",
                f"Portrait {asset_id} separated background plane",
                _background_builder(asset_id),
            )
        )
    return result


BRANCH_IDS = [
    *[f"branch_{branch}_{part}" for branch in ("a", "b", "c") for part in ("node", "edge", "backplate", "thumb")],
    "branch_conv_node", "branch_conv_edge", "branch_conv_backplate",
]


def _branch_builder(asset_id: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        branch = asset_id.split("_")[1]
        part = asset_id.split("_")[2]
        primary, secondary = {"a": (CYAN, BLUE), "b": (MAGENTA, CORAL), "c": (GOLD, MINT), "conv": (VIOLET, GOLD)}[branch]
        shapes: list[str] = []
        if part == "backplate":
            shapes += [tag("rect", x=42, y=42, width=428, height=428, rx=128, fill=I7, stroke=I9, stroke_width=24), tag("path", d="M86 388 Q256 304 426 388", fill="none", stroke=primary, stroke_width=22, opacity="0.38")]
        elif part == "edge":
            if branch == "a":
                shapes += [tag("path", d="M56 300 Q220 128 456 212", fill="none", stroke=I9, stroke_width=54, stroke_linecap="round"), tag("path", d="M56 300 Q220 128 456 212", fill="none", stroke=primary, stroke_width=22, stroke_linecap="round")]
            elif branch == "b":
                shapes += [tag("path", d="M42 280 Q128 188 214 280 T386 280 T470 248", fill="none", stroke=I9, stroke_width=54, stroke_linecap="round"), tag("path", d="M42 280 Q128 188 214 280 T386 280 T470 248", fill="none", stroke=primary, stroke_width=22, stroke_linecap="round")]
            elif branch == "c":
                shapes += [tag("path", d="M50 324 H160 V234 H270 V288 H382 V196 H462", fill="none", stroke=I9, stroke_width=54, stroke_linecap="round", stroke_linejoin="round"), tag("path", d="M50 324 H160 V234 H270 V288 H382 V196 H462", fill="none", stroke=primary, stroke_width=22, stroke_linecap="round", stroke_linejoin="round")]
            else:
                shapes += [tag("path", d="M50 330 L256 160 L462 330 M50 330 H462", fill="none", stroke=I9, stroke_width=58, stroke_linejoin="round"), tag("path", d="M50 330 L256 160", stroke=CYAN, stroke_width=20), tag("path", d="M256 160 L462 330", stroke=GOLD, stroke_width=20), tag("path", d="M50 330 H462", stroke=MAGENTA, stroke_width=20)]
        else:
            shapes += [tag("circle", cx=256, cy=256, r=178, fill=I7, stroke=I9, stroke_width=30)]
            if branch == "a":
                shapes += [tag("path", d="M256 106 L406 256 L256 406 L106 256 Z", fill="none", stroke=primary, stroke_width=30, stroke_linejoin="round"), tag("path", d="M156 256 Q256 166 356 256", fill="none", stroke=secondary, stroke_width=20)]
            elif branch == "b":
                shapes += [tag("circle", cx=256, cy=256, r=116, fill="none", stroke=primary, stroke_width=30), tag("path", d="M120 286 Q188 198 256 286 T392 286", fill="none", stroke=secondary, stroke_width=20)]
            elif branch == "c":
                shapes += [tag("path", d="M256 108 L402 380 H110 Z", fill="none", stroke=primary, stroke_width=30, stroke_linejoin="round"), tag("path", d="M176 304 H228 V236 H284 V272 H340", fill="none", stroke=secondary, stroke_width=20, stroke_linejoin="round")]
            else:
                shapes += [tag("path", d="M256 84 L404 170 L404 342 L256 428 L108 342 L108 170 Z", fill="none", stroke=VIOLET, stroke_width=30), tag("path", d="M256 256 L256 116 M256 256 L386 332 M256 256 L126 332", stroke_width=22, stroke=CYAN), tag("path", d="M256 256 L386 332", stroke=MAGENTA, stroke_width=22), tag("path", d="M256 256 L126 332", stroke=GOLD, stroke_width=22)]
        if part == "thumb":
            shapes.insert(0, tag("rect", x=30, y=30, width=452, height=452, rx=126, fill=I7, stroke=I9, stroke_width=24))
        return svg_document(spec, group(asset_id, shapes), view_box=(0, 0, 512, 512))

    return build


def branch_specs() -> list[AssetSpec]:
    result: list[AssetSpec] = []
    for asset_id in BRANCH_IDS:
        part = asset_id.split("_")[-1]
        result.append(
            AssetSpec(
                asset_id,
                "branches",
                (256, 256) if part == "thumb" else (512, 512),
                (256, 256) if part == "thumb" else (128, 128),
                (0.50, 0.50),
                None,
                "UI-FLUTTER",
                "thumb" if part == "thumb" else "base",
                "lossless",
                f"Aura Tree {asset_id} redundant shape identity",
                _branch_builder(asset_id),
            )
        )
    return result


VFX_IDS = ("vfx_ribbon", "vfx_spark", "vfx_orb", "vfx_contact", "vfx_trail")


def _vfx_builder(asset_id: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        defs = ""
        if asset_id == "vfx_ribbon":
            shapes = [tag("path", d="M8 92 C34 28 74 110 120 28", fill="none", stroke=I9, stroke_width=26, stroke_linecap="round"), tag("path", d="M8 92 C34 28 74 110 120 28", fill="none", stroke=CYAN, stroke_width=12, stroke_linecap="round")]
        elif asset_id == "vfx_spark":
            shapes = [tag("path", d="M64 8 L102 64 L64 120 L26 64 Z", fill=GOLD, stroke=I9, stroke_width=10, stroke_linejoin="round"), tag("path", d="M64 34 L82 64 L64 94 L46 64 Z", fill=PAPER)]
        elif asset_id == "vfx_orb":
            defs = radial_gradient("orb", [("0%", PAPER, 1.0), ("34%", VIOLET, 0.92), ("100%", CYAN, 0.0)])
            shapes = [tag("path", d="M10 106 Q42 86 74 56", fill="none", stroke=CYAN, stroke_width=16, opacity="0.48", stroke_linecap="round"), tag("circle", cx=82, cy=46, r=40, fill="url(#orb)")]
        elif asset_id == "vfx_contact":
            shapes = [tag("circle", cx=64, cy=64, r=50, fill="none", stroke=I9, stroke_width=12), tag("circle", cx=64, cy=64, r=42, fill="none", stroke=VIOLET, stroke_width=8), tag("circle", cx=64, cy=64, r=12, fill=CYAN, opacity="0.72")]
        else:
            defs = linear_gradient("trail", [("0%", CYAN), ("52%", VIOLET), ("100%", MAGENTA)], x1="0%", y1="50%", x2="100%", y2="50%")
            shapes = [tag("path", d="M8 88 Q46 28 120 58", fill="none", stroke=I9, stroke_width=28, stroke_linecap="round"), tag("path", d="M8 88 Q46 28 120 58", fill="none", stroke="url(#trail)", stroke_width=13, stroke_linecap="round")]
        return svg_document(spec, group(asset_id, shapes), defs=defs)

    return build


def vfx_specs() -> list[AssetSpec]:
    return [
        AssetSpec(asset_id, "vfx", (128, 128), (64, 64), (0.50, 0.50), None, "VFX-AURA-FRONT", "base", "lossless", f"Structured Aura particle {asset_id}", _vfx_builder(asset_id))
        for asset_id in VFX_IDS
    ]


def _digits_67(x: int = 170, y: int = 150, scale: float = 1.0, color: str = I9, width: int = 26) -> str:
    six = tag("path", d=f"M{x+76*scale:g} {y:g} C{x+10*scale:g} {y+20*scale:g} {x:g} {y+106*scale:g} {x+12*scale:g} {y+162*scale:g} C{x+28*scale:g} {y+234*scale:g} {x+124*scale:g} {y+230*scale:g} {x+136*scale:g} {y+164*scale:g} C{x+146*scale:g} {y+106*scale:g} {x+76*scale:g} {y+82*scale:g} {x+18*scale:g} {y+118*scale:g}", fill="none", stroke=color, stroke_width=width, stroke_linecap="round", stroke_linejoin="round")
    seven = tag("path", d=f"M{x+170*scale:g} {y+10*scale:g} H{x+300*scale:g} L{x+208*scale:g} {y+224*scale:g}", fill="none", stroke=color, stroke_width=width, stroke_linecap="round", stroke_linejoin="round")
    return group("digits_67", six + seven)


SEAL_IDS = ("seal_67_core", "seal_67_ring", "seal_67_cardinal", "seal_67_thumb_mask")


def _seal_builder(asset_id: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        if asset_id == "seal_67_core":
            shapes = [tag("path", d="M256 42 L428 140 L428 340 L256 438 L84 340 L84 140 Z", fill=GOLD, stroke=I9, stroke_width=28, stroke_linejoin="round"), tag("path", d="M256 82 L390 160 L390 320 L256 398 L122 320 L122 160 Z", fill=PAPER, opacity="0.90"), _digits_67(152, 154, 0.64, I9, 20)]
        elif asset_id == "seal_67_ring":
            shapes = [tag("path", d="M256 34 L444 142 L444 358 L256 466 L68 358 L68 142 Z", fill="none", stroke=GOLD, stroke_width=24, stroke_linejoin="round"), tag("path", d="M256 74 L408 162 L408 338 L256 426 L104 338 L104 162 Z", fill="none", stroke=VIOLET, stroke_width=14, stroke_dasharray="30 18")]
        elif asset_id == "seal_67_cardinal":
            shapes = [tag("path", d="M256 24 V94 M256 418 V488 M24 256 H94 M418 256 H488", stroke=GOLD, stroke_width=30, stroke_linecap="round"), tag("path", d="M92 92 L138 138 M374 374 L420 420 M420 92 L374 138 M138 374 L92 420", stroke=VIOLET, stroke_width=18, stroke_linecap="round")]
        else:
            shapes = [tag("path", d="M256 52 L420 146 L420 334 L256 428 L92 334 L92 146 Z", fill=PAPER, stroke=I9, stroke_width=30), _digits_67(152, 154, 0.64, I9, 20)]
        return svg_document(spec, group(asset_id, shapes))

    return build


def seal_specs() -> list[AssetSpec]:
    result = []
    for asset_id in SEAL_IDS:
        runtime = (48, 48) if asset_id.endswith("thumb_mask") else (128, 128)
        result.append(AssetSpec(asset_id, "seals", (512, 512), runtime, (0.50, 0.50), None, "UI-FLUTTER", "thumb" if asset_id.endswith("thumb_mask") else "base", "lossless", f"Modular rounded-hex Signal 67 component {asset_id}", _seal_builder(asset_id)))
    return result


EVENT_IDS = ("evt_purchase", "evt_milestone", "evt_transform", "evt_achievement", "evt_ascension", "evt_67")


def _event_builder(asset_id: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        base = [tag("path", d="M256 42 L428 140 L428 340 L256 438 L84 340 L84 140 Z", fill=I7, stroke=I9, stroke_width=28, stroke_linejoin="round")]
        if asset_id == "evt_purchase":
            inner = [tag("path", d="M142 266 L222 338 L374 166", fill="none", stroke=CYAN, stroke_width=42, stroke_linecap="round", stroke_linejoin="round"), tag("circle", cx=374, cy=166, r=22, fill=PAPER)]
        elif asset_id == "evt_milestone":
            inner = [tag("circle", cx=256, cy=256, r=112, fill="none", stroke=GOLD, stroke_width=34), tag("path", d="M256 112 V174 M256 338 V400 M112 256 H174 M338 256 H400", stroke=VIOLET, stroke_width=22, stroke_linecap="round")]
        elif asset_id == "evt_transform":
            inner = [tag("path", d="M256 92 L306 210 L428 256 L306 302 L256 420 L206 302 L84 256 L206 210 Z", fill=VIOLET, stroke=CYAN, stroke_width=24, stroke_linejoin="round"), tag("circle", cx=256, cy=256, r=42, fill=PAPER)]
        elif asset_id == "evt_achievement":
            inner = [tag("path", d="M256 92 L300 180 L398 194 L326 264 L344 364 L256 318 L168 364 L186 264 L114 194 L212 180 Z", fill=GOLD, stroke=VIOLET, stroke_width=22, stroke_linejoin="round")]
        elif asset_id == "evt_ascension":
            inner = [tag("path", d="M112 346 Q256 286 400 346", fill="none", stroke=MAGENTA, stroke_width=34), tag("path", d="M256 350 V142 M186 212 L256 142 L326 212", fill="none", stroke=GOLD, stroke_width=36, stroke_linecap="round", stroke_linejoin="round")]
        else:
            inner = [tag("path", d="M256 90 L402 174 L402 338 L256 422 L110 338 L110 174 Z", fill=GOLD, stroke=VIOLET, stroke_width=24), _digits_67(152, 154, 0.64, I9, 20)]
        return svg_document(spec, group(asset_id, base + inner))

    return build


def event_specs() -> list[AssetSpec]:
    return [AssetSpec(asset_id, "events", (512, 512), (192, 192), (0.50, 0.50), None, "EVENT-OVERLAY", "base", "lossless", f"Text-free event emblem {asset_id}", _event_builder(asset_id)) for asset_id in EVENT_IDS]


BADGE_META = [
    ("badge_ach_v_01", "first_shift"),
    ("badge_ach_v_02", "hands_in_motion"),
    ("badge_ach_v_03", "passive_presence"),
    ("badge_ach_v_04", "three_directions"),
    ("badge_ach_v_05", "room_noticed"),
    ("badge_ach_v_06", "bigger_sky"),
    ("badge_ach_s_01", "held_pose"),
    ("badge_ach_s_02", "quiet_hours"),
    ("badge_ach_s_03", "exact_balance"),
    ("badge_ach_s_04", "signals_stacked"),
    ("badge_ach_s_05", "routes_agree"),
    ("badge_ach_s_06", "full_spectrum"),
    ("badge_ach_s_07", "again_with_feeling"),
]


def _badge_builder(asset_id: str, concept: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        shapes = [tag("path", d="M256 34 L434 136 L434 342 L256 444 L78 342 L78 136 Z", fill=I7, stroke=I9, stroke_width=28, stroke_linejoin="round")]
        if concept == "first_shift":
            shapes += [tag("circle", cx=176, cy=278, r=62, fill=CYAN, stroke=I9, stroke_width=18), tag("circle", cx=336, cy=218, r=62, fill=MAGENTA, stroke=I9, stroke_width=18), tag("path", d="M176 192 Q256 118 336 156 M336 304 Q256 378 176 340", fill="none", stroke=VIOLET, stroke_width=24, stroke_linecap="round")]
        elif concept == "hands_in_motion":
            shapes += [tag("circle", cx=180, cy=278, r=52, fill=CYAN, stroke=I9, stroke_width=16), tag("circle", cx=332, cy=218, r=52, fill=MAGENTA, stroke=I9, stroke_width=16), tag("ellipse", cx=256, cy=256, rx=160, ry=116, fill="none", stroke=GOLD, stroke_width=20, stroke_dasharray="30 18")]
        elif concept == "passive_presence":
            shapes += [tag("path", d="M256 112 L354 210 L256 308 L158 210 Z", fill=CYAN, stroke=I9, stroke_width=22), tag("path", d="M132 340 Q256 250 380 340", fill="none", stroke=VIOLET, stroke_width=30, stroke_linecap="round"), tag("circle", cx=256, cy=340, r=24, fill=PAPER)]
        elif concept == "three_directions":
            shapes += [tag("path", d="M256 256 L256 112", stroke=CYAN, stroke_width=30, stroke_linecap="round"), tag("path", d="M256 256 L386 348", stroke=MAGENTA, stroke_width=30, stroke_linecap="round"), tag("path", d="M256 256 L126 348", stroke=GOLD, stroke_width=30, stroke_linecap="round"), tag("circle", cx=256, cy=256, r=46, fill=PAPER, stroke=I9, stroke_width=18)]
        elif concept == "room_noticed":
            shapes += [tag("path", d="M150 326 A134 134 0 0 1 362 164", fill="none", stroke=CYAN, stroke_width=34, stroke_linecap="round"), tag("circle", cx=164, cy=174, r=24, fill=VIOLET), tag("circle", cx=350, cy=338, r=24, fill=CYAN)]
        elif concept == "bigger_sky":
            shapes += [tag("path", d="M112 344 Q256 272 400 344", fill="none", stroke=MAGENTA, stroke_width=30), tag("path", d="M156 248 A110 110 0 0 1 356 248", fill="none", stroke=GOLD, stroke_width=30), tag("path", d="M256 346 V148 M198 206 L256 148 L314 206", fill="none", stroke=CYAN, stroke_width=26, stroke_linejoin="round")]
        elif concept == "held_pose":
            shapes += [tag("path", d="M168 112 H344 M168 400 H344 M190 126 Q190 214 256 256 Q322 214 322 126 M190 386 Q190 298 256 256 Q322 298 322 386", fill="none", stroke=VIOLET, stroke_width=26, stroke_linecap="round"), tag("circle", cx=256, cy=256, r=20, fill=CYAN)]
        elif concept == "quiet_hours":
            shapes += [tag("circle", cx=230, cy=212, r=112, fill=GOLD), tag("circle", cx=286, cy=174, r=112, fill=I7), tag("path", d="M116 352 Q256 294 396 352", fill="none", stroke=VIOLET, stroke_width=30)]
        elif concept == "exact_balance":
            shapes += [tag("path", d="M126 324 H386", stroke=GOLD, stroke_width=28, stroke_linecap="round"), tag("circle", cx=256, cy=324, r=44, fill=PAPER, stroke=I9, stroke_width=18), _digits_67(188, 168, 0.42, CYAN, 16)]
        elif concept == "signals_stacked":
            for offset, color in ((-54, CYAN), (0, MAGENTA), (54, GOLD)):
                shapes.append(tag("path", d=f"M{256+offset} 118 L{348+offset} 170 L{348+offset} 274 L{256+offset} 326 L{164+offset} 274 L{164+offset} 170 Z", fill="none", stroke=color, stroke_width=18, opacity="0.88"))
        elif concept == "routes_agree":
            shapes += [tag("path", d="M256 96 L402 360 H110 Z", fill="none", stroke=VIOLET, stroke_width=34), tag("path", d="M256 96 L256 264", stroke=CYAN, stroke_width=22), tag("path", d="M110 360 L256 264", stroke=GOLD, stroke_width=22), tag("path", d="M402 360 L256 264", stroke=MAGENTA, stroke_width=22), tag("circle", cx=256, cy=264, r=30, fill=PAPER)]
        elif concept == "full_spectrum":
            shapes += [tag("path", d="M256 94 L410 354 H102 Z", fill="none", stroke=I9, stroke_width=58), tag("path", d="M256 94 L410 354", stroke=CYAN, stroke_width=24), tag("path", d="M410 354 H102", stroke=MAGENTA, stroke_width=24), tag("path", d="M102 354 L256 94", stroke=GOLD, stroke_width=24), tag("path", d="M256 196 L318 304 H194 Z", fill=PAPER, opacity="0.86")]
        else:
            shapes += [tag("path", d="M128 350 Q256 286 384 350", fill="none", stroke=MAGENTA, stroke_width=28), tag("path", d="M154 286 Q256 226 358 286", fill="none", stroke=GOLD, stroke_width=28), tag("path", d="M256 350 V130 M204 182 L256 130 L308 182", fill="none", stroke=CYAN, stroke_width=26)]
        return svg_document(spec, group(asset_id, shapes))

    return build


def badge_specs() -> list[AssetSpec]:
    return [
        AssetSpec(asset_id, "badges", (512, 512), (128, 128), (0.50, 0.50), None, "UI-FLUTTER", "base", "lossless", f"Shape-redundant achievement badge {concept}", _badge_builder(asset_id, concept))
        for asset_id, concept in BADGE_META
    ]


ICON_IDS = (
    "icon_nav_play", "icon_nav_shop", "icon_nav_collection", "icon_nav_settings",
    "icon_aura_available", "icon_aura_total", "icon_passive_rate", "icon_cycle_power",
    "icon_phase_six", "icon_phase_seven", "icon_technique", "icon_aura_item",
    "icon_appearance", "icon_item_effect", "icon_transformation", "icon_seal",
    "icon_achievement", "icon_ascension", "icon_lock", "icon_info",
    "icon_backup", "icon_rewarded_ad",
)


def _icon_builder(asset_id: str) -> Callable[[AssetSpec], str]:
    def build(spec: AssetSpec) -> str:
        name = asset_id.removeprefix("icon_")
        base_attrs = {"fill": "none", "stroke": PAPER, "stroke_width": 6, "stroke_linecap": "round", "stroke_linejoin": "round"}
        shapes: list[str]
        if name == "nav_play":
            shapes = [tag("path", d="M52 8 L28 48 H46 L40 88 L70 42 H52 Z", fill=CYAN, stroke=I9, stroke_width=5)]
        elif name == "nav_shop":
            shapes = [tag("path", d="M48 16 V34 M48 34 L20 52 M48 34 L76 52 M20 52 V76 M76 52 V76", **base_attrs), tag("circle", cx=48, cy=16, r=8, fill=CYAN), tag("circle", cx=20, cy=76, r=8, fill=MAGENTA), tag("circle", cx=76, cy=76, r=8, fill=GOLD)]
        elif name == "nav_collection":
            shapes = [tag("path", d="M48 8 L58 34 L86 36 L64 54 L70 82 L48 66 L26 82 L32 54 L10 36 L38 34 Z", **base_attrs)]
        elif name == "nav_settings":
            shapes = [tag("path", d="M18 24 H78 M18 48 H78 M18 72 H78", **base_attrs), tag("circle", cx=34, cy=24, r=8, fill=CYAN), tag("circle", cx=62, cy=48, r=8, fill=MAGENTA), tag("circle", cx=42, cy=72, r=8, fill=GOLD)]
        elif name == "aura_available":
            shapes = [tag("path", d="M48 8 C72 28 80 48 72 68 C64 88 32 88 24 68 C16 48 24 28 48 8 Z", fill=VIOLET, stroke=I9, stroke_width=5), tag("path", d="M48 28 V66", stroke=PAPER, stroke_width=6, stroke_linecap="round")]
        elif name == "aura_total":
            shapes = [tag("circle", cx=48, cy=48, r=34, **base_attrs), tag("path", d="M48 24 V72 M24 48 H72", stroke=GOLD, stroke_width=6, stroke_linecap="round")]
        elif name == "passive_rate":
            shapes = [tag("circle", cx=48, cy=48, r=34, **base_attrs), tag("path", d="M48 28 V50 L64 62", stroke=CYAN, stroke_width=6, stroke_linecap="round")]
        elif name == "cycle_power":
            shapes = [tag("path", d="M20 36 Q48 10 76 36 M76 60 Q48 86 20 60", **base_attrs), tag("path", d="M70 22 L78 36 L62 38 M26 74 L18 60 L34 58", fill="none", stroke=CYAN, stroke_width=6)]
        elif name in ("phase_six", "phase_seven"):
            seven = name == "phase_seven"
            shapes = [tag("circle", cx=28, cy=62 if seven else 34, r=14, fill=CYAN if not seven else MAGENTA, stroke=I9, stroke_width=5), tag("circle", cx=68, cy=34 if seven else 62, r=14, fill=MAGENTA if seven else CYAN, stroke=I9, stroke_width=5), tag("path", d="M28 48 Q48 24 68 48" if not seven else "M28 48 Q48 72 68 48", **base_attrs)]
        elif name == "technique":
            shapes = [tag("path", d="M18 56 Q32 22 48 48 Q64 74 78 40", **base_attrs), tag("path", d="M18 74 H78", stroke=CYAN, stroke_width=6)]
        elif name == "aura_item":
            shapes = [tag("path", d="M48 10 L82 48 L48 86 L14 48 Z", **base_attrs), tag("circle", cx=48, cy=48, r=12, fill=VIOLET)]
        elif name == "appearance":
            shapes = [tag("path", d="M18 62 Q48 20 78 62 Q48 82 18 62 Z", **base_attrs), tag("circle", cx=48, cy=56, r=10, fill=CYAN)]
        elif name == "item_effect":
            shapes = [tag("path", d="M48 10 L58 38 L86 48 L58 58 L48 86 L38 58 L10 48 L38 38 Z", fill=GOLD, stroke=I9, stroke_width=5)]
        elif name == "transformation":
            shapes = [tag("path", d="M20 70 Q48 20 76 70", **base_attrs), tag("path", d="M48 12 V42", stroke=VIOLET, stroke_width=6), tag("circle", cx=48, cy=70, r=10, fill=CYAN)]
        elif name == "seal":
            shapes = [tag("path", d="M48 8 L82 28 L82 68 L48 88 L14 68 L14 28 Z", **base_attrs), tag("circle", cx=48, cy=48, r=12, fill=GOLD)]
        elif name == "achievement":
            shapes = [tag("path", d="M48 10 L58 36 L86 38 L64 56 L70 84 L48 68 L26 84 L32 56 L10 38 L38 36 Z", fill=GOLD, stroke=I9, stroke_width=5)]
        elif name == "ascension":
            shapes = [tag("path", d="M18 76 Q48 60 78 76 M48 72 V18 M30 36 L48 18 L66 36", **base_attrs)]
        elif name == "lock":
            shapes = [tag("rect", x=20, y=42, width=56, height=42, rx=10, **base_attrs), tag("path", d="M32 42 V30 Q32 14 48 14 Q64 14 64 30 V42", **base_attrs)]
        elif name == "info":
            shapes = [tag("circle", cx=48, cy=48, r=36, **base_attrs), tag("circle", cx=48, cy=30, r=4, fill=CYAN), tag("path", d="M48 44 V68", stroke=PAPER, stroke_width=6, stroke_linecap="round")]
        elif name == "backup":
            shapes = [tag("path", d="M18 18 H68 L80 30 V78 H18 Z", **base_attrs), tag("rect", x=30, y=18, width=30, height=22, **base_attrs), tag("rect", x=30, y=56, width=36, height=22, **base_attrs)]
        else:
            shapes = [tag("rect", x=12, y=22, width=72, height=52, rx=14, **base_attrs), tag("path", d="M40 34 L66 48 L40 62 Z", fill=CYAN, stroke=I9, stroke_width=4), tag("path", d="M18 16 L30 6 M78 16 L66 6", stroke=GOLD, stroke_width=6, stroke_linecap="round")]
        return svg_document(spec, group(asset_id, shapes))

    return build


def icon_specs() -> list[AssetSpec]:
    return [AssetSpec(asset_id, "icons", (96, 96), (48, 48), (0.50, 0.50), None, "UI-FLUTTER", "base", "lossless", f"Essential rounded functional glyph {asset_id}", _icon_builder(asset_id)) for asset_id in ICON_IDS]


def all_specs() -> list[AssetSpec]:
    specs = [
        *skin_specs(),
        *form_specs(),
        *background_specs(),
        *branch_specs(),
        *vfx_specs(),
        *seal_specs(),
        *event_specs(),
        *badge_specs(),
        *icon_specs(),
    ]
    ids = [spec.manifest_id for spec in specs]
    if len(ids) != len(set(ids)):
        duplicates = sorted({item for item in ids if ids.count(item) > 1})
        raise RuntimeError(f"Duplicate manifest IDs: {duplicates}")
    return specs


EXPECTED_FAMILY_COUNTS = {
    "skins": 90,
    "forms": 21,
    "backgrounds": 27,
    "branches": 15,
    "vfx": 5,
    "seals": 4,
    "events": 6,
    "badges": 13,
    "icons": 22,
}
