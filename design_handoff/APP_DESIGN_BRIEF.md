# LRC e‑Services — App Design Brief (context for the designer)

> Attach this file to the design request. It describes **what the app is, what it
> contains, and its current shape**, plus the **hard constraints** any new design
> must respect. It is the single source of truth for the redesign. Screens and
> functionality are fixed — this is a **visual/UX redesign only**.

---

## 1. What this app is

- **Product:** Official mobile app for the **LRC — Lebanon's Land Registry &
  Cadastre** (Arabic: **المديرية العامة للشؤون العقارية**). A **government
  e‑services** client: citizens and professionals request property records, pay
  fees, simulate transaction costs, and track applications.
- **Platform:** **Flutter** (Android + iOS), **Material 3**, single light theme.
- **Bilingual:** **English + Arabic**, switchable anywhere via a top‑bar toggle.
  Arabic must render **full RTL** (mirrored layout). This is a first‑class
  requirement, not an afterthought.
- **Audience:** general public *and* professionals (notaries, lawyers,
  surveyors). Tone should read **trustworthy, official, calm, precise** — a
  government registry, not a consumer fintech app.
- **Assets available:** three logo PNGs — `logo.png` (splash), `logoMain.png`
  (language screen, full mark), `logoHeader.png` (white logo for the green
  masthead).

---

## 2. HARD CONSTRAINTS (must not change)

### 2.1 Brand palette — FIXED exact hex values
The green identity and the functional colors are locked. **Do not introduce new
brand hues.** You may adjust only **neutrals** (backgrounds/surfaces/hairlines)
and use tints/shades *of these same hues*.

| Role | Hex |
|---|---|
| Primary green | `#006401` |
| Primary green (dark) | `#004d01` |
| Danger / action red | `#8c0000` |
| Danger red (dark) | `#6e0000` |
| Neutral grey (secondary buttons) | `#6f6f6f` |
| Accent blue (drawer selection / info) | `#549fd7` |
| Accent amber/gold (status "in progress") | `#e6a700` |
| Success green | `#1b8a3a` |
| Drawer background (dark) | `#1f1f1f` |
| Scaffold background | `#f4f6f8` |
| Surface | `#ffffff` |
| Text primary | `#1f2933` |
| Text secondary | `#6b7280` |
| Hairline border | `#e3e8ee` |

Semantics: **green = primary/official**, **red = the main call‑to‑action**
(Add / Calculate / Show result / Login — note red is *action*, not error here),
**grey = reset/secondary**, **blue/amber = status accents**.

### 2.2 Typography
- Bundled font is **Segoe UI** (system sans). If you propose a different
  typeface it must be a **bundleable web/desktop font** (Google Fonts is fine).
  Keep it highly legible for Arabic *and* Latin, and note the exact families.
- Must handle **OS text scaling** (Dynamic Type / font‑size settings) without
  breaking layout.

### 2.3 Responsiveness — REQUIRED across all screen sizes
The redesign **must fit and look right on every size**. Provide specs/mockups for
at least these breakpoints, in **both LTR and RTL**:
- **Compact phone** — ~320–359 dp wide (small/older devices).
- **Standard phone** — 360–599 dp wide (primary target).
- **Tablet / expanded** — ≥ 600 dp wide (the home grid already goes 2→3
  columns here; other screens should use max content width / centered columns).
- Consider **landscape** and **safe areas / notches** (status bar is painted
  brand green; content sits under a `SafeArea`).
- No fixed pixel widths that overflow small screens; text uses auto‑sizing/
  ellipsis where space is tight.

### 2.4 Behavior / accessibility (keep)
- **Functionality, screens, fields, and flows are unchanged.** Same inputs,
  same buttons, same order. Redesign the *look*, not the *logic*.
- Min tap target ≈ **44–48 dp**. Visible keyboard focus. Sufficient contrast
  (WCAG AA for text). **Respect OS "reduce motion."**
- Prefer **lightweight motion** and no heavy new dependencies.

---

## 3. Current shape / design language (what exists today)

A clean but fairly generic Material look, with a light motion layer:
- **Masthead:** green gradient app bar, **centered white logo**, hamburger menu
  (start side), language toggle (end side). Status bar tinted green.
- **In‑screen header:** a white title strip *below* the app bar on every feature
  screen — a back button + the screen title.
- **Body:** light‑grey scaffold; **white cards** with hairline borders + soft
  shadows; rounded corners (12–24 dp).
- **Side drawer:** **dark** panel, green gradient header with logo, menu list,
  blue highlight on the selected item, version footer.
- **Forms:** labeled **searchable dropdowns** (bilingual search) + text fields;
  a **red primary button** + **grey reset button** side by side.
- **Data display:** "title : value" **cards** (row layout, and a stacked column
  layout for longer records).
- **Motion (already present):** fade/slide **entrance reveals**, **staggered**
  grid/list cascades, **press‑to‑scale** on tappables, **zoom** page
  transitions. Everything degrades to no‑motion when reduce‑motion is on.

The redesign may **keep or reinvent** any of this, as long as the constraints in
§2 hold. Treat the current look as the baseline to improve on, not a template to
copy.

---

## 4. Screen inventory (12 screens) — purpose, elements, shape

Wireframes are rough ASCII (LTR). Mirror horizontally for RTL Arabic.

### 4.1 Splash
Purpose: brand load screen (~3 s).
```
        ┌───────────────┐
        │   ( ⊙ logo )  │   white circle, soft shadow
        │               │
        │      ◌        │   green spinner
        └───────────────┘
   gradient: white → light‑grey
```

### 4.2 Language picker (MainScreen)
Purpose: choose EN/AR, then enter the app.
```
   ( ⊙ logoMain )                 springy logo
   Choose your language
   اختر لغتك
   ┌───────────────────────────┐
   │ [🌐] English               →│
   │      Continue in English    │
   └───────────────────────────┘
   ┌───────────────────────────┐
   │ [🌐] العربية               →│
   │      المتابعة باللغة العربية │
   └───────────────────────────┘
```

### 4.3 Home / dashboard (Index)  ← flagship
Purpose: launchpad to the 6 services.
```
 ▛ green app bar: [≡]  (white logo)  [EN|ع] ▟
 ┌───────────────────────────────────────┐
 │ LAND REGISTRY & CADASTRE (eyebrow)     │  green welcome banner
 │ Welcome / مرحباً بك                     │
 └───────────────────────────────────────┘
 ┌────────────┐ ┌────────────┐
 │ [icon]     │ │ [icon]     │   2 columns (phone),
 │ Title      │ │ Transaction│   3 columns (tablet).
 │ Register   │ │ Tracking   │   Fits screen, no scroll.
 └────────────┘ └────────────┘
 ┌────────────┐ ┌────────────┐
 │ Title Reg. │ │ Fees       │
 │ Changes    │ │ Simulation │
 └────────────┘ └────────────┘
 ┌────────────┐ ┌────────────┐
 │ Ownership  │ │ Paid       │
 │ Tracking   │ │ Invoices   │
 └────────────┘ └────────────┘
```
6 services + their accents today: **Title Register** (green), **Transaction
Tracking** (blue), **Title Register Changes** (amber), **Fees Simulation**
(red), **Ownership Tracking** (blue), **Paid Invoices** (green, uses a custom
"L.L" currency mark icon).

### 4.4 Side drawer (navigation)
```
 ┌─ green header: (white logo) ─┐
 │  Land Registry & Cadastre    │
 ├──────────────────────────────┤
 │ ⌂ Home                        │  dark panel,
 │ ▤ Title Register              │  blue highlight
 │ ✔ Transaction Tracking        │  on active row
 │ 🧮 Fees Simulation            │
 │ ✎ Title Register Changes      │
 │ 👣 Ownership Req. Tracking     │
 │ 🧾 Paid Invoices              │
 ├──────────────────────────────┤
 │ 🛡 LRC • v1.0                  │
 └──────────────────────────────┘
```

### 4.5 Title Register (request property records → pay)
Purpose: build a "cart" of properties, then continue to payment.
Elements: cart counter chip; **Location**: Province, Caza, Cadastral Zone
(searchable dropdowns); **Property details**: Parcel No, Unit No, Block;
**Add** (red) / **Reset** (grey); a list of added properties as **swipe‑to‑delete
cards**; a **Total** bar (red); **Submit** (green).

### 4.6 Personal Information (applicant + payment method)
Purpose: collect the payer's details and card brand, then open checkout.
Elements: cart chip; form card — First name, Last name, Telephone, Email,
Confirm Email, City, Address (each with a leading icon); **Payment method**
selector = two selectable **Visa / Mastercard** cards; **Proceed** (green) /
**Reset**; a full‑screen "Confirming your payment…" overlay after returning
from the gateway.

### 4.7 Payment Details (confirmation / receipt)
Purpose: show the recorded order.
Elements: **success banner** (green, check icon, "request recorded, keep your
ID"); an **order record card** (ID, First/Last name, Telephone, Email, City,
Address); **Back to Home** button (green).

### 4.8 Fees Simulation (cost calculator)
Purpose: estimate transaction fees.
Elements: **Transaction type** dropdown (Sale, Construction, Construction &
Subdivisions, Subdivisions, Lien, Lien removal, Easement, Inheritance,
Notation); **Value (L.L)** input; a **"Lebanese nationality"** checkbox (Sale
only); **Calculate** (red) / **Reset**; a **fee breakdown** — a list of
`label : amount` rows ending in a highlighted **Total** row; a **footnote note**
(legal text pulled from the API).

### 4.9 Transaction Tracking (application status)
Purpose: look up a filed transaction and see its progress.
Elements: **Area office** dropdown; **Application date** (date picker);
**Application number**; **Show result** (red) / **Reset**; a **status legend**;
a **progress bar**; **4 stage blocks** in a row — *Area Officer, Registrar,
Recorder, Assistant Registrar* — each colored by state (**grey = pending,
amber = in progress, green = done**); **detail cards** (Action date, Staff,
Status); a status/message line.

### 4.10 Ownership Request Tracking
Purpose: track an ownership request (analogous to 4.9, keyed by applicant
identifiers rather than area‑office/app‑number). Same visual family: a lookup
**form**, then **staged progress** + **detail cards**. Design it as a sibling of
Transaction Tracking.

### 4.11 Title Register Changes (account login — stub)
Purpose: gate for registered‑user changes (currently non‑functional buttons).
Elements: **Username**, **Password** (obscured), **Login** (red, full‑width),
**Forgot password?** and **Register** links. White background.

### 4.12 Paid Invoices (invoice lookup)
Purpose: find paid invoices for a property.
Elements: **Location**: Province, Caza, Cadastral Zone (searchable); **Search
details**: Parcel No, Unit No, Block; a **"Moral entity"** checkbox that swaps
the identity fields — checked → **Party** field; unchecked → **Year of birth,
Registration place, Registration number**; **Show result** (red) / **Reset**;
**results** — an intro line + **invoice cards** (Area office, Application date,
Application no, Transaction type); a **Show details / Hide details** toggle
(red) revealing **invoice detail cards** (Invoice date/no/amount/status,
Payment date, Notification date).

---

## 5. Shared components to design ONCE, consistently
The app is component‑driven; redesign these and every screen follows:
1. **Masthead / app bar** (logo, menu, language toggle, green status bar).
2. **In‑screen header / title bar** (back + title).
3. **Side drawer** (header, menu rows, active state, footer).
4. **Service tile** (home grid; icon + accent + title; must tile 2‑up and 3‑up).
5. **Searchable dropdown field** (label, value, chevron, search sheet).
6. **Text input** + **field label** (with leading icon; error/focus states).
7. **Buttons** — primary (red action), secondary (grey), confirm (green),
   full‑width and paired variants; pressed/disabled/loading states.
8. **Data card** — "title : value" in row and stacked‑column forms.
9. **Stage / status block** + **status legend** + **progress bar** (tracking).
10. **Summary / Total bar** (amount emphasis; tabular figures).
11. **Chips** (cart counter) and **selectable cards** (payment method).
12. **States**: empty, loading (spinner/skeleton), error, success banner,
    snackbars, dialogs, and the Material **date picker** (Arabic uses Levantine
    month names).
13. **Language tiles** (language screen) and the **language toggle**.

---

## 6. What to deliver back (so it's easy to implement in Flutter)
Please produce, in **both LTR (English) and mirrored RTL (Arabic)**, at **phone
and tablet** widths:
- A **design‑token sheet**: color usage map (within the fixed hexes + neutral
  latitude), **type scale** (families, sizes, weights, line‑height, letter‑
  spacing), **spacing** scale, **corner‑radius** scale, **elevation/shadow**
  language, **icon** style.
- **Component specs** for every item in §5 (all states).
- **Screen mockups** for the 12 screens in §4 (at least: home, a form screen, a
  results/tracking screen, a data/receipt screen — ideally all).
- **Motion notes** (lightweight; must degrade with reduce‑motion).
- A short **rationale** and, if helpful, a **signature element** that gives the
  app a memorable, subject‑appropriate identity (land/records/cadastre world).

Deliver as annotated mockups + the token/component spec (or a structured written
spec I can translate directly into `app_theme.dart` tokens and shared widgets).
