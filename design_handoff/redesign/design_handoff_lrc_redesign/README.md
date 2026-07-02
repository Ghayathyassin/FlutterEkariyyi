# Handoff: LRC e‑Services — Mobile UI Redesign ("The Cadastral Line")

## Overview
Visual/UX redesign of the LRC (Lebanon Land Registry & Cadastre) government e‑services
app. Target stack: **Flutter, Material 3, single light theme, bilingual EN + Arabic (full RTL)**.
Functionality, screens, fields, and flows are **unchanged** — this is look & feel only.

Design concept: **"The Cadastral Line."** Calm, precise, document‑like. Boldness is
concentrated in ONE signature (survey linework); everything else is quiet Material 3.

## About the design files
The file `LRC Redesign Spec.dc.html` in this bundle is a **design reference created in HTML** —
a spec board + annotated mockups showing intended look, tokens, components, and all 12 screens
(phone/tablet, LTR/RTL). It is **not production code to copy**. Recreate these designs in the
Flutter app using Material 3 idioms (`ThemeData`, `ColorScheme`, `TextTheme`, shared widgets).
Where this repo already has patterns/widgets, prefer them; only the *visual system* below is new.

## Fidelity
**High‑fidelity.** Exact hex, dp, font sizes/weights, radii, spacing, and states are specified
below and should be reproduced faithfully. Fonts and icons are named, bundleable OSS.

---

## Signature element (the ONE bold move)
**Cadastral parcel linework**, rendered in white over the green banner:
- **Hero:** faint parcel‑boundary lines behind the green welcome banner on Home.
- **Accent:** L‑shaped **corner registration ticks** frame "record" moments (receipt card,
  completed tracking stage).
- **Progress:** Transaction/Ownership tracking uses a **survey baseline** (thin line + station
  nodes) instead of a stock Material progress bar.

Implementation: draw with `CustomPaint` (a few polylines at ~18–20% opacity white) clipped to the
banner's rounded rect. Corner ticks = 4 small 2dp L brackets in `#006401` at card corners.

---

## Design tokens

### Colors — FIXED brand palette (do not add hues; only neutrals were tuned)
| Role | Hex | Usage |
|---|---|---|
| Primary green | `#006401` | Masthead, banner, identity, cadastral lines, primary accents |
| Primary green dark | `#004d01` | Gradient end, status bar |
| Action red | `#8c0000` | The ONE primary CTA per screen (Add / Calculate / Show result / Login) — **action, not error** |
| Action red dark | `#6e0000` | Red pressed state |
| Confirm / success green | `#1b8a3a` | Submit / Proceed, success banner, "stage done" |
| Neutral grey | `#6f6f6f` | Reset / secondary buttons |
| Accent blue | `#549fd7` | Drawer active row, info status, links |
| Accent amber | `#e6a700` | Status "in progress" (text form `#b3830a` for AA on tint) |
| Drawer dark | `#1f1f1f` | Side drawer background |
| Scaffold bg | `#f4f6f8` | App background |
| Surface | `#ffffff` | Cards, sheets, fields |
| Text primary | `#1f2933` | Body / headings |
| Text secondary | `#6b7280` | Labels, captions |
| Hairline | `#e3e8ee` | Card/field borders, dividers |
| Green tint | `#eaf3ea` | Icon chip bg, selected field, total-of-fees bar |
| Blue tint | `#e7f1fa` | Icon chip bg (blue services), info banner |
| Amber tint | `#fdf3d7` | Icon chip bg (amber service) |
| Red tint | `#fbeaea` | Icon chip bg (red service), error field bg |
| Disabled text | `#9aa4b0` / `#c2cad3` | Placeholder / disabled |

**Contrast notes (AA):** amber text on tint uses `#b3830a`, not `#e6a700`. White on all brand
solids passes. Red `#8c0000` on white passes for button labels.

### Typography (bundle these; replace Segoe UI)
- **IBM Plex Sans** — Latin UI text.
- **IBM Plex Sans Arabic** — all Arabic/RTL text (same family feel, first‑class Arabic).
- **IBM Plex Mono** — data only: reference IDs, parcel/unit/block numbers, and monetary amounts
  (use `fontFeatures: [FontFeature.tabularFigures()]`).

Type scale (family, px→dp, weight, letter‑spacing, line‑height):
| Token | Size | Weight | Tracking | Line‑height |
|---|---|---|---|---|
| Display | 28 | 600 | −0.4 | 1.15 |
| Title | 22 | 600 | −0.2 | 1.25 |
| Section | 17 | 600 | 0 | 1.4 |
| Body | 15 | 400 | 0 | 1.5 |
| Label | 13 | 500 | +0.1 | 1.4 |
| Eyebrow | 11 | 500 | +2.0, UPPERCASE | 1.4 |
| Mono/data | 15–16 | 500 | 0 | 1.4, tabular |

All sizes must honor OS text scaling (`MediaQuery.textScaler`); layouts use min‑height + wrap +
ellipsis, never fixed text heights.

### Spacing — 4dp base
`4, 8, 12, 16, 24, 32`. Screen padding 16 (phone), 24 (tablet). Card inner padding 14.

### Corner radius
`8` fields · `12` buttons · `16` cards · `20` home banner · `999` chips/pills.

### Elevation
- e0 = 1dp hairline border `#e3e8ee`, no shadow (most cards/fields).
- e1 = card lift: `0 1px 2px rgba(31,41,51,.06), 0 2px 8px rgba(31,41,51,.05)` (Home tiles).
- e2 = sheets/dialogs: `0 6px 16px rgba(31,41,51,.12)`.

### Icons
**Material Symbols Rounded**, weight 400, 24dp, FILL 0 (outlined); FILL 1 only when active.
Service icon map: Title Register `menu_book` · Transaction Tracking `fact_check` ·
Title Register Changes `edit_document` · Fees Simulation `calculate` ·
Ownership Tracking `vpn_key` · Paid Invoices `receipt_long`. Also: menu `menu`, back `arrow_back`
(RTL `arrow_forward`), drawer home `home`, dropdown `expand_more`, search `search`,
delete `delete`, date `calendar_month`, info `info`, password `visibility`, footer `verified_user`,
row chevron `chevron_right`. Min tap target 44–48 dp.

---

## Components (all states)

**Masthead / app bar.** Green gradient `135deg #006401→#004d01`; status bar painted `#004d01`
under SafeArea. Left `menu` (or `arrow_back` on feature screens), centered white logo
(`logoHeader.png`), right language pill `EN | ع`. Height ~48dp + status.

**In‑screen header.** White strip below masthead, hairline bottom border, back icon + title
(Section 17/600). Feature screens only.

**Side drawer.** Bg `#1f1f1f`. Green gradient header with logo + "Land Registry & Cadastre".
Rows 44dp min, icon + label `#c7ccd1`. **Active row:** bg `rgba(84,159,215,.18)`, 3dp left rule
`#549fd7`, white text. Footer: `verified_user` + "LRC · v1.0", top hairline `rgba(255,255,255,.08)`.

**Home service tile (Option E — chosen).** White card, radius 16, e1 shadow, padding 14,
height 118 (phone) / 122 (tablet). Contents: 44dp accent‑tint chip with 24dp Material Symbol in
the service accent color; below, title 13.5/600 + one‑line description 10.5/`#6b7280`.
Grid: **2 columns** phone, **3 columns** tablet (≥600dp), gap 13–14, content max‑width centered
on tablet. Pressed = scale 0.96. (Chosen from 5 explored directions; A–D were dropped.)

**Searchable dropdown.** Field: 52dp, radius 8, hairline, leading icon, value, trailing
`expand_more`. Tapping opens a bottom sheet (radius 16 top, e2): search input row (bilingual) +
scrollable options; selected option bg `#eaf3ea`, text `#006401` 500.

**Text field + label.** Label 13/500 `#6b7280` above. Field 52dp, radius 8, leading icon.
States: default hairline `#e3e8ee`; **focus** 2dp `#006401` + 3dp glow `rgba(0,100,1,.12)`;
**error** 1.5dp `#8c0000`, bg `#fbeaea`, helper text `#8c0000` 12; **disabled** bg `#f7f9fb`,
text `#c2cad3`.

**Buttons.** Height 52dp (44dp min inline), radius 12, label 15/600.
- Primary **red** `#8c0000` (Add/Calculate/Show/Login) — pressed `#6e0000` + scale 0.96.
- Confirm **green** `#1b8a3a` (Submit/Proceed).
- Secondary **grey** `#6f6f6f` (Reset).
- Disabled: bg `#e3d0d0`/muted, text muted. Loading: 14dp spinner + label.
- Paired = Reset (flex 1) + primary (flex ~1.4) in a row, gap 8–10.

**Data card.** Row form: "label `#6b7280` : value (mono if numeric)", hairline dividers.
Stacked form for long values (address): small label + wrapped value.

**Stage/status + legend + survey baseline.** Legend dots: pending `#c9d2dc`, in‑progress
`#e6a700`, done `#1b8a3a`. Baseline: 3dp track `#e3e8ee`, filled portion `#1b8a3a`, station nodes
12dp circles colored by state with 2dp white ring. 4 stage chips (Area Officer, Registrar,
Recorder, Assistant Registrar): done = bg `#eaf6ee`/border `#b9dfc6`/text `#1b8a3a`; in‑progress =
`#fff6e0`/`#f0d798`/`#b3830a`; pending = `#f4f6f8`/`#e3e8ee`/`#9aa4b0`.

**Summary / total bar.** Red bar `#8c0000`, white, radius 12: "TOTAL · n" + mono tabular amount +
"L.L". Fees total variant = green tint `#eaf3ea` bg, `#cfe3cf` border, `#006401` text. Sticky at
bottom with a top fade to scaffold.

**Chips.** Cart counter pill: bg `#eaf3ea`, text `#006401` 600, with a 20dp green circle count
badge (mono). Empty = grey. Pulse scale 1.06 on change.

**Selectable payment cards.** Visa / Mastercard. Selected = 2dp `#006401`, bg `#eaf3ea`, check
badge top‑right. Unselected = hairline, muted text.

**Feedback.** Success banner: bg `#eaf6ee`, border `#b9dfc6`, green check circle + message.
Snackbar: bg `#1f1f1f`, white text, action in `#549fd7`. Dialog: white, radius 14, e2, title +
body + right‑aligned text actions (Cancel grey / destructive red). Empty: dashed `#cbd4de` border,
muted centered text. Loading: spinner or skeleton.

**Date picker.** Material date picker themed to green primary; Arabic uses Levantine month names.

---

## Screens (12) — all in the design file, phone + (Home/Title Register) tablet, LTR + RTL

1. **Splash** — white circle logo + green spinner over white→grey gradient with faint parcel field (~3s).
2. **Language picker** — logo, "Choose your language / اختر لغتك", two tiles (English, العربية) with `language` icon + chevron.
3. **Home** — masthead, green greeting banner (parcel linework), Option‑E service grid (2‑up phone / 3‑up tablet).
4. **Side drawer** — dark panel, green header, 7 rows, blue active row, version footer.
5. **Title Register** — cart chip; Location (Province/Caza/Zone dropdowns); Property details (Parcel/Unit/Block); Reset(grey)+Add(red); added‑property swipe‑delete cards; sticky red Total; green Submit.
6. **Personal Information** — iconed fields (First/Last name, Telephone, Email, Confirm Email, City, Address); Payment method = Visa/Mastercard selectable cards; Reset + green Proceed; "Confirming payment…" full‑screen overlay after gateway.
7. **Payment Details (receipt)** — green success banner; record card with corner registration ticks (Reference ID mono, name, phone, email, city, address); green Back to Home.
8. **Fees Simulation** — Transaction type dropdown (Sale, Construction, Construction & Subdivisions, Subdivisions, Lien, Lien removal, Easement, Inheritance, Notation); Value (L.L); "Lebanese nationality" checkbox (Sale only); Reset + red Calculate; fee breakdown rows → highlighted green Total; API footnote.
9. **Transaction Tracking** — Area office dropdown; Application date (date picker); Application number; Reset + red Show result; legend; survey‑baseline progress; 4 stage chips; detail card(s); status line.
10. **Ownership Request Tracking** — sibling of #9, keyed by applicant identifiers; same lookup → staged progress + detail cards; blue info line.
11. **Title Register Changes (login)** — white bg; `edit_document` mark; Username; Password (obscured, `visibility` toggle); red full‑width Login; blue "Forgot password?" + "Register" links (currently non‑functional).
12. **Paid Invoices** — Location (Province/Caza/Zone) + Parcel/Unit/Block; "Moral entity" checkbox swaps identity fields (checked → Party; unchecked → Year of birth, Registration place, Registration number); Reset + red Show result; results intro + invoice cards (Area office, App date, App no, Transaction type); red Show/Hide details toggle → invoice detail cards (Invoice date/no/amount/status, Payment date, Notification date).

## Interactions & behavior
- Navigation and flows are the **existing** ones — do not change order, fields, or logic.
- One primary **red** action per action screen; **grey** Reset beside it; **green** confirms/advances.
- Cart chip + Total update on add/remove; swipe‑to‑delete on added cards with Undo snackbar.
- Fees "Lebanese nationality" checkbox shows only for Sale; Paid Invoices "Moral entity" swaps fields.
- Tracking: state drives node/stage colors; detail cards reflect latest stage.

## Responsive
- **Compact phone (~320–359dp):** 2‑col grid; fields may stack; ellipsis where tight; nothing overflows.
- **Standard phone (360–599dp):** primary target (mockups drawn at ~320 to prove the tight case).
- **Tablet (≥600dp):** Home grid 3‑up; forms use two columns / centered max content width (~720dp).
- Landscape: content scrolls; sticky total/CTA stays pinned; banner height reduces.
- Respect SafeArea/notches; status bar `#004d01`.

## Motion (lightweight, reduce‑motion‑safe)
Opacity/transform only, 120–300ms; wrap so `MediaQuery.disableAnimations` collapses to instant.
- Entrance reveal: fade + rise 8dp, 220ms easeOutCubic.
- Home grid cascade: 40ms stagger, ≤240ms total.
- Press‑to‑scale: 0.96, 120ms (tiles + buttons); off → color‑only feedback.
- Signature baseline draw: fill L→R (R→L in RTL), 300ms, once; off → static fill.
- Cart/total bump: scale 1.06, 160ms.
- Page transition: shared‑axis / gentle zoom (RTL flips direction); off → cross‑fade/cut.

## Assets
- Logos (provided by product): `logo.png` (splash), `logoMain.png` (language screen),
  `logoHeader.png` (white, masthead). Not in this bundle — use the app's real PNGs; the mockups
  show white "LRC" placeholders.
- Icons: Material Symbols Rounded (Google Fonts / `material_symbols_icons` pkg or bundled font).
- Fonts: IBM Plex Sans, IBM Plex Sans Arabic, IBM Plex Mono (Google Fonts / OFL — bundle via `pubspec` `fonts:`).

## Files
- `LRC Redesign Spec.dc.html` — full spec board: direction, tokens, component specs (all states),
  all 12 screens (LTR + RTL, phone + tablet for Home & Title Register), motion notes. Open in a
  browser to view. It is a design reference, not shippable code.
