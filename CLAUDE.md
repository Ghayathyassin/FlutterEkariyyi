# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Bilingual (Arabic / English) Flutter mobile app for the LRC — Lebanon's Land Registry & Cadastre (المديرية العامة للشؤون العقارية), a government e-services client. The Dart package name is `flutter_application_1`. The whole project lives in the `FlutterEkariyyi/` subdirectory.

## Critical: non-standard entry point

The app's `main()` is **`lib/screens/main.dart`**, NOT the default `lib/main.dart` (which does not exist). Every run/build/test that launches the app must pass `-t lib/screens/main.dart`, or it will fail to find an entry point.

```bash
flutter run    -t lib/screens/main.dart
flutter build apk --release -t lib/screens/main.dart   # -> build/app/outputs/flutter-apk/app-release.apk
flutter install -t lib/screens/main.dart               # to a connected device
```

On this machine Flutter is at `C:\flutter\bin\flutter.bat` and adb at `C:\Users\gyassine\AppData\Local\Android\sdk\platform-tools\adb.exe`. The shell is PowerShell on Windows (a Bash tool is also available). Release builds print many `e: ... incompatible version of Kotlin` lines — these are **warnings**; the build still succeeds.

## Common commands

```bash
flutter pub get
flutter analyze                      # lint (flutter_lints); keep clean before building
flutter test                         # unit/widget tests (test/ dir)
flutter test test/foo_test.dart      # a single test file
```

### Localization — DO NOT run `intl_utils:generate` on this project

UI strings use `S.of(context).<key>` from `lib/generated/l10n.dart`, produced by **`intl_utils`** from the ARB files in `lib/l10n/` (`app_en.arb`, `app_ar.arb`). **`dart run intl_utils:generate` is BROKEN here and destructive** — it creates a stray `lib/l10n/intl_en.arb`, overwrites `l10n.dart`/`messages_en.dart`, and DELETES `messages_ar.dart`, causing ~280 analyzer errors + a "Multiple arb files with the same 'en' locale" runtime crash. To change a string, **hand-edit BOTH** the ARB file AND the matching generated `lib/generated/intl/messages_<locale>.dart` (add the getter to `l10n.dart` too if the key is new). Localization changes require a **hot restart**, not hot reload. Supported locales are `en`/`ar` only; locale lives in `MyApp` state, threaded as `onLocaleChange(Locale)`.

## Architecture

### Backend

All data comes from one REST host: **`https://test-app.lrc.gov.lb/api/...`** (test environment — it is intermittently unstable, so a 404/500 on a previously-working endpoint is usually server-side, not the app). Endpoints in use include `locations`, `checkproperty`, `createpayment`, `payment-session/{initiate,retrieve}`, `fees/all`, `drtrack`, `nattrack`, `invctracking/{getinvoice,getinvoicedetails}`, `areaoffices`, `books`. There is **no auth header** — the test endpoints are unauthenticated (a previously-present Azure/bearer flow was removed because the token was never actually sent).

### Navigation & screens

`SplashScreen` → `MainScreen` (language picker) → `Index` (home dashboard). Feature screens are reached via named routes registered in `main.dart` (`/index`, `/titleRegister`, `/transactionTracking`, `/titleRegisterChange`, `/feesSimulation`, `/ownershipTracking`, `/paidInvoices`); the drawer and home tiles navigate with `pushReplacementNamed`. `PersonalInformation` / `PaymentDetails` are pushed directly (they take constructor args), not via the route table.

### State

Lightweight: `provider` with two `ChangeNotifier`s registered in `main.dart` — `DrawerState` (selected drawer index, keeps the drawer highlight in sync across `pushReplacement`) and `PaymentProvider` (cart total amount). No global app-state store beyond these; most screens are self-contained `StatefulWidget`s that fetch their own data.

### Caching

Per-feature cache classes in `lib/models/` (`province_cache`, `fee_cache`, `paid_invoice_cache`) back screens with `shared_preferences`, so reference data (provinces/cazas/cadastral areas, fee tables) is fetched once and reused.

### Design system — do not hardcode styling

`lib/theme/app_theme.dart` is the single source of styling: `AppColors` (fixed brand green `#006401`, danger red `#8c0000`, confirm green `#1b8a3a`, accents `info`/`amber`, drawer colors, tints `greenTint`/`blueTint`/`amberTint`/`redTint`, `tintFor()`), `AppSpacing`, `AppRadius` (8 field / 12 button / 16 card / 20 banner / 999 pill), `AppShadows` (e0 border / e1 card / e2 sheet), `kPrimaryGradient`, `AppButtons` (**danger()=red CTA, primary()/confirm()=green confirm, neutral()=grey reset**), `AppType` (IBM Plex scale; `AppType.mono(...)` for tabular numbers). **`AppTheme.light({required bool isArabic})` is now a FUNCTION** (was a getter) — `main.dart` calls `AppTheme.light(isArabic: _locale.languageCode == 'ar')` so the base font family swaps to IBM Plex Sans Arabic in RTL. Signature painters live in `lib/theme/app_decor.dart` (`CadastralLines`, `CornerTicks`, `CornerMark`, `SurveyBaseline`, `StageState`/`stageFromCode`); shared UI atoms in `lib/widgets/register_ui.dart` (`FieldLabel`, `SectionHeader`, `CartChip`, `SummaryBar`, `StageChip`, `StageLegend`, `RegisterCard`); motion in `lib/theme/app_motion.dart` (`AppReveal`, `Pressable`, `revealStagger`, honours OS reduce-motion). Restyle against these tokens; never hardcode raw colors/text styles. The brand palette is fixed across all redesigns (only neutrals may be tuned).

### Current UI: "The Cadastral Line" redesign (IN WORKING TREE, uncommitted)

The app has been fully reskinned per a Claude Design spec — concept **"The Cadastral Line"** (calm, document-like; signature = survey linework/corner-ticks/survey-baseline). The spec bundle is at `design_handoff/redesign/design_handoff_lrc_redesign/` (`README.md` = engineering spec, `LRC Redesign Spec.dc.html` = visual board). All 12 screens are done and `flutter analyze` is clean, but it is **NOT committed** — it awaits on-device testing before commit/push. Fonts (IBM Plex Sans / Sans Arabic / Mono) come from the **`google_fonts`** dependency: they are **fetched from Google at first launch (needs network once) then cached** — a fallback font briefly shows on the very first run.

**Git restore points (tags, both pushed to origin):**
- `ui-classic-baseline` (commit `d0f4abd`) — pre-animation static UI.
- `ui-animated-checkpoint` (commit `3fd0742`) — animated design, the base this redesign sits on.
- To revert the redesign: `git reset --hard ui-animated-checkpoint`, then delete `lib/theme/app_decor.dart` + `lib/widgets/register_ui.dart` and remove `google_fonts` from pubspec.

The design brief/prompt handed to Claude Design also live in `design_handoff/` (`APP_DESIGN_BRIEF.md`, `DESIGN_PROMPT.md`).

### Shared widgets (`lib/widgets/`)

The header is unified: green `CustomAppBar` (centered logo, menu, language toggle) on every screen, with feature screens adding a white `CustomHeader` title bar below it. `SearchableDropdown` provides bilingual (AR+EN) search with `normalizeSearch()` (strips Arabic tashkeel, unifies alef/yaa/teh-marbuta) — use it for province/caza/cadastral pickers. `StageBlock` (in `stage_blocks.dart`) must be wrapped in `Expanded` by callers (it uses `width: double.infinity`; a bare `Row` will overflow). `category.dart` renders both FontAwesome and Material icons via a generic `Icon()`.

### Locations data — two disagreeing feeds

`/api/locations` (no trailing slash) is bilingual (`Name`/`NameEnglish`, `Code`/`ProviceCode`/`codeField`) and is used by `title_register` and `paid_invoices`. `/api/locations/` (trailing slash) is Arabic-only with a **different code scheme** for the same zones. They are not interchangeable — pick the feed an endpoint's codes were keyed to.

### Payments

`createpayment` returns an order id (`e_aff_id`); `e_aff_id: 0` is not a failure but a backend signal (e.g. the property was already requested — it de-duplicates per email), and the JSON `message` should be surfaced. Then `payment-session/initiate` returns a `SessionId`, and the hosted checkout opens via `url_launcher` `inAppBrowserView` at a card-brand-specific gateway host (Visa → `creditlibanais-netcommerce.gateway.mastercard.com`, MasterCard → `ap-gateway.mastercard.com`). On app resume, `payment-session/retrieve/{method}/{orderId}` confirms payment (`respMsg == "Approved"` + a non-zero `authNumber`/`transactionAmount`). All merchant credentials live on the backend only — the app bundles no payment secrets.

### Conventions

- Numbers shown to users go through `formatAmount`/`formatAmountString` in `lib/utils/format.dart` (thousands separators).
- Arabic calendar months are overridden to Levantine names (كانون الثاني، شباط، آذار، …). The override lives in `main.dart`: `_applyLevantineArabicMonths()` mutates the shared `ar` `DateSymbols.MONTHS`/`STANDALONEMONTHS`/`SHORTMONTHS`/`STANDALONESHORTMONTHS`. **A bare `main()` mutation is not enough for the Material date picker** — `GlobalMaterialLocalizations.delegate.load('ar')` reloads and replaces the cached `ar` symbols with intl's defaults (يناير/فبراير) every time the picker opens, wiping the override. The fix is `_LevantineMaterialLocalizationsDelegate` (registered BEFORE `GlobalMaterialLocalizations.delegate`, `isSupported` only for `ar`): its `load()` awaits the global delegate, then re-stamps the Levantine months on top. Do not remove that delegate or the picker reverts.
- The status bar is painted brand green app-wide via `SystemChrome.setSystemUIOverlayStyle` in `main()` and `systemOverlayStyle` on `CustomAppBar`.
- `.env` (flutter_dotenv) and `firebase_options.dart`/`google-services.json` (FCM) are config, not secrets; the app intentionally carries no payment/cloud secrets.
- Guard `setState`/`context` use after `await` with `if (mounted)`; many network handlers depend on this.

## Backend behaviors & field gotchas (learned live against the test API)

These are non-obvious facts about the test backend confirmed by hitting it directly. The endpoints are unauthenticated, so you can curl them to re-verify.

- **`createpayment` → `e_aff_id: 0` is a de-dup signal, not an error.** When the same property is requested again it returns `e_aff_id: 0` with a `message`. The de-dup is keyed to **email** (the identical property under a different email returns a fresh non-zero id). Surface the JSON `message` to the user; do not show a generic "failed to load". The backend `message` contains an unsubstituted `{0}` placeholder (a known backend bug — it should be the existing transaction id) and an HTML success-form wrapper, so it is cleaned in `personal_information.dart` via `_cleanBackendMessage()` (strips the HTML form, the `(Transaction No: {0})` fragment, and bare `{0}`).
- **Payment "paid" detection** (`payment-session/retrieve/{method}/{orderId}`) reads the actual gateway payload fields: `respMsg` (APPROVED/SUCCESS/CAPTURED/AUTHORIZED), `authNumber` (non-empty, ≠ "0"), and `transactionAmount` (> 0). Earlier code read `status`/`totalCapturedAmount`/`totalAuthorizedAmount` which **do not exist** in the response and always yielded `paid=false`. `paid = approvedMsg && authNumber valid && txnAmount > 0`.
- **Card-brand gateway hosts differ** (`_launchCheckoutUrl`): VISA → `creditlibanais-netcommerce.gateway.mastercard.com`, MasterCard → `ap-gateway.mastercard.com`, path `/checkout/pay/{SessionId}?checkoutVersion=1.0.0`.
- **Gateway errors "MSO does not have access to branded domain" / "System Error" are backend/gateway-side**, not the app — Crédit Libanais/Mastercard merchant provisioning (merchant id `04105401`). Not fixable in Flutter; the merchant must contact Crédit Libanais.
- **`block` field** (title_register + paid_invoices) accepts **letters, not just digits** — label is "Block"/"البلوك" (key `blockNo` in the ARB, value already changed). Input uses `TextInputType.text` + `TextCapitalization.characters`; the value is sent URL-encoded as a **string** (never `int.parse` it — alphanumeric blocks exist). title_register → `&blockNumber=...`, paid_invoices → `&p_block=...` (empty → `0`).
- **title_register cost is hardcoded `cost: 50000`** in the cart model, but `createpayment` computes the real amount server-side (e.g. `txtAmount`/`txtAmount1` ≈ 651000/656859). The displayed total is therefore a placeholder, not the charged amount — a backend/business reconciliation item, flagged in [[lrc-payment-known-issues]].
- **`checkproperty`** always returns HTTP 200 with `{"isValid": bool, "message": "..."}` (e.g. valid → "Property is Valid"; invalid → "Cannot extract data, the property is retired"). It carries **no price**.
- **`fees/all`** supplies fee_simulation's rates, fixed fees, and message text (cached via `feeCache`). The **calculation formulas** (`_handleSaleFees`, etc.) and the transaction-type list are **hardcoded** in `fee_simulation.dart` — only the numbers/messages come from the API.
- **`getinvoice` success path is still UNVERIFIED** — needs a known-good parcel from the backend. A plain-string 200 (e.g. "هذا العقار غير موجود…") is shown as-is instead of an error.
