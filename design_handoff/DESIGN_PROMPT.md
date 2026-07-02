# Prompt to give to the design assistant

> Copy everything in the box below into your design conversation, and **attach
> `APP_DESIGN_BRIEF.md`** (and any screenshots you have) alongside it. If the
> tool can't take an attachment, paste the brief's contents above the prompt.

---

```
You are my design lead. I'm redesigning the mobile UI of a government app — the
LRC (Lebanon Land Registry & Cadastre) e‑services app. The full context, screen
inventory, and hard constraints are in the attached APP_DESIGN_BRIEF.md — read it
first and treat it as the source of truth. I've also attached screenshots of the
current app for reference.

GOAL
Give this app a distinctive, modern, trustworthy visual identity that still feels
like an official government registry — calm, precise, credible — not a flashy
consumer app. Improve on the current look; don't just reskin it. Spend your
boldness on ONE memorable signature element rooted in the subject matter (land,
parcels, deeds, cadastral maps, official records) and keep everything else quiet
and disciplined.

NON‑NEGOTIABLE CONSTRAINTS (from the brief — do not violate)
1. Keep the brand palette EXACTLY: primary green #006401 / #004d01, action red
   #8c0000, grey #6f6f6f, accent blue #549fd7, amber #e6a700, success #1b8a3a,
   dark drawer #1f1f1f. You may only adjust NEUTRALS (backgrounds, surfaces,
   hairlines) and use tints/shades of these same hues. Introduce NO new brand
   colors. Semantics: green = primary/official, RED = the main call‑to‑action
   (not error), grey = reset/secondary, blue/amber = status.
2. Bilingual English + Arabic. Every screen must be shown in BOTH left‑to‑right
   (English) and fully mirrored right‑to‑left (Arabic). RTL is first‑class.
3. RESPONSIVE on all sizes. Provide specs/mockups at three widths: compact phone
   (~320–359dp), standard phone (360–599dp), and tablet (≥600dp, where the home
   grid goes 2→3 columns). Nothing may overflow small screens; respect safe
   areas/notches and OS text scaling. Note landscape behavior where relevant.
4. Functionality, screens, fields, and flows are FIXED — this is visual/UX only.
   Same inputs, same buttons, same order.
5. Accessibility: WCAG‑AA text contrast, ~44–48dp tap targets, visible focus,
   and motion that degrades gracefully when "reduce motion" is on. Keep any
   animation lightweight. Font must be bundleable (system Segoe UI today; if you
   swap it, name a Google/OSS font that supports Arabic + Latin well).

WHAT TO DELIVER
A) A concise design direction / rationale + the ONE signature element.
B) A design‑token sheet: color usage map, type scale (families, sizes, weights,
   line‑height, tracking), spacing scale, corner‑radius scale, shadow/elevation
   language, icon style.
C) Component specs (all states: default/focus/error/disabled/loading/empty/
   success) for: masthead/app bar, in‑screen header, side drawer, home service
   tile (must tile 2‑up and 3‑up), searchable dropdown, text field + label,
   buttons (primary‑red / secondary‑grey / confirm‑green, full‑width & paired),
   data card (row + stacked column), stage/status block + legend + progress bar,
   summary/total bar (tabular figures), chips (cart counter), selectable payment
   cards, snackbars, dialogs, and the date picker.
D) Screen mockups for the 12 screens listed in the brief — at minimum: Splash,
   Language picker, Home, Side drawer, Title Register (form + cart + total),
   Personal Information (form + payment‑method), Payment Details (receipt), Fees
   Simulation (breakdown table), Transaction Tracking (stages + progress), and
   Paid Invoices (search + results). Show each at phone width, plus tablet for
   Home and one form; show RTL for Home and one form at minimum, ideally all.
E) Motion notes (subtle, reduce‑motion‑safe).

HOW TO WORK
First propose the direction as a short plan: palette usage, typography pairing,
layout concept, and the signature element — with tiny ASCII wireframes to compare
options. Check it against the brief and call out anything that reads like a
generic default, then revise. Only after the direction is solid, produce the full
token sheet, component specs, and mockups.

FORMAT OF THE HANDBACK
I will implement this in Flutter (Material 3). Give me something I can translate
directly into design tokens and shared widgets: concrete hex values, dp sizes,
font sizes/weights, radii, and spacing — not vague adjectives. A structured
written spec is fine if full mockups aren't possible; annotated mockups + spec is
ideal.
```

---

## After you get the design back
Bring the designer's output (mockups, token sheet, and/or written spec) back to
me here. I'll:
1. Map it onto `lib/theme/app_theme.dart` tokens (colors/type/spacing/radii/
   shadows) and the shared widgets first, so the whole app shifts at once.
2. Apply per‑screen specifics, keeping every screen **responsive** (compact
   phone → tablet), **RTL‑correct**, and **analyzer‑clean**.
3. Do it on a branch/checkpoint so we can compare against the current animated
   design and revert instantly if needed.
