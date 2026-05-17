**Ligith Theme — App Design**

**Overview**: Ligith is a bright, friendly, high-contrast light theme optimized for clarity, speed, and accessibility. This document captures the visual tokens, component guidance, and implementation notes for the app's Flutter UI.

**Color Palette**:
- **Primary:** #0066FF : Primary action (buttons, links)
- **Primary Variant:** #0047CC : Hover/active
- **Accent:** #00D1B2 : Positive states, badges
- **Warn:** #FF8A00 : Warnings and minor alerts
- **Error:** #E03E3E : Errors and destructive actions
- **Background:** #FFFFFF : App background
- **Surface:** #F7F9FC : Cards and surfaces
- **Border:** #E6EEF9 : Subtle dividers
- **Muted / Text Secondary:** #6B7280 : Secondary text
- **High-contrast Text:** #0B1220 : Primary text
- **Shadow color:** rgba(11,18,32,0.06) : Soft elevation shadow

**Typography**:
- **Font family:** Inter (system fallback: Roboto / San Francisco)
- **Scale:**
  - **Display / H1:** 28sp / 36px / 700
  - **H2:** 22sp / 28px / 600
  - **H3:** 18sp / 22px / 600
  - **Body / Base:** 16sp / 18px / 400
  - **Small:** 14sp / 16px / 400
  - **Caption:** 12sp / 14px / 400
- **Line height:** 1.4 for body, 1.2 for headings

**Spacing & Layout**:
- **Base unit:** 8px
- **Small spacing:** 8px
- **Medium spacing:** 16px
- **Large spacing:** 24-32px
- Use 16px horizontal padding for lists and cards.

**Elevation & Surfaces**:
- **Surface elevation 1 (cards):** background #FFFFFF, shadow 0 1px 4px rgba(11,18,32,0.04)
- **Surface elevation 2 (dialogs):** background #FFFFFF, shadow 0 6px 16px rgba(11,18,32,0.08)

**Component Guidelines**:
- **Primary Button:** Primary color background, white text, 12px vertical padding, 8px radius. Use primary variant for pressed state.
- **Secondary Button:** Transparent background, primary color text, 1px border of `Border` token.
- **Ghost Button:** Text-only with subtle hover underline for inline actions.
- **Inputs:** White surface, 1px `Border` stroke, 8px padding, 6px radius. On focus show 2px primary outline (use `Primary Variant` with 0.14 alpha overlay).
- **Cards:** Use `Surface` color, 12px padding, 8px radius. Keep info density moderate.
- **Lists:** Use dividers at 1px `Border`. Provide left-aligned avatars.
- **Toasts / Snackbar:** Use `High-contrast Text` on `Primary` for success or `Error` backgrounds when needed. Keep duration 3–5s.

**KYC / Sensitive Flows**:
- Use a compact, stepper-like layout with progress indicator at top.
- File previews: card surface with 3:4 crop, filename, and small action icons (download/delete).
- Status states: Pending (accent subtle), In Progress (primary), Manual Review (warn), Verified (accent), Rejected (error). Use clear microcopy: e.g., "Manual review required — upload clearer image." 
- Do not display Approve/Reject for `VERIFIED` or `REJECTED` states (buttons disabled/hidden).

**Notifications & Reminders**:
- Use unobtrusive banners for non-critical notes.
- For WhatsApp reminders, use neutral copy and provide action buttons linking to invoice or tenant details.

**Icons & Imagery**:
- Use 24px grid for primary icons; 20px for inline icons.
- Choose rounded iconography matching the 8px radius language.
- Store assets in `assets/icons/ligith/` and export at 1x/2x/3x for mobile.

**Accessibility**:
- Maintain contrast ratio >= 4.5:1 for body text.
- Provide focus rings for keyboard nav on all interactive elements.
- Support larger text (Scale 1.2x) without layout breakage.
- Ensure touch targets >= 44x44px.

**Motion & Interaction**:
- Use 100–160ms standard easing for micro-interactions; 200ms for modal transitions.
- Avoid heavy motion on KYC or verification flows; prefer subtle fades.

**Tokens (JSON example)**

```json
{
  "color": {
    "primary": "#0066FF",
    "primaryVariant": "#0047CC",
    "accent": "#00D1B2",
    "warn": "#FF8A00",
    "error": "#E03E3E",
    "background": "#FFFFFF",
    "surface": "#F7F9FC",
    "border": "#E6EEF9",
    "textPrimary": "#0B1220",
    "textSecondary": "#6B7280"
  },
  "radius": { "sm": 6, "md": 8, "lg": 12 },
  "spacing": { "base": 8, "sm": 8, "md": 16, "lg": 24 },
  "typography": { "fontFamily": "Inter", "baseSize": 16 }
}
```

**Flutter Implementation (notes)**:
- Centralize tokens in `lib/core/design/tokens.dart` as constants and a `LigithTheme` class exposing `ThemeData`.
- Provide `ThemeData` with `ColorScheme` mapped from tokens and `TextTheme` based on the scale above.
- Use `MaterialStateProperty` for button states to keep pressed/disabled styles consistent.
- Example file to add: `lib/core/design/ligith_theme.dart` that exports `ThemeData ligithTheme(BuildContext)`.

**Developer Handoff**:
- Add sketches for primary screens: Home, Tenant Details (KYC tab), Invoice list, Admin KYC review.
- Export icons and a token JSON (above) to repository under `athidihub/assets/design/ligith/`.

**Next steps**:
- Implement `lib/core/design/ligith_theme.dart` and two example screens.
- Add unit/widget tests verifying theme colors on critical widgets.
- Create a small design QA checklist (contrast, spacing, responsiveness).

If you want, I can now scaffold `lib/core/design/ligith_theme.dart` and add a token constants file and example widget usage.
