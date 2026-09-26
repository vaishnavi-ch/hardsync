# Design System: hardsync (Leadership Practice & Scenario Rehearsals)

## 1. Overview & Aesthetic Vision
hardsync is an executive leadership conversation rehearsal app designed to feel psychologically safe, warm, editorial, and human-centric. Rather than sterile tech dashboards or dark neon AI interfaces, it leverages the aesthetic of high-end editorial stationery, calm executive consulting lounges, and grounded mindfulness sanctuaries.

## 2. Color Palette
```css
:root {
  /* Surfaces & Backgrounds */
  --color-cream: #FAF8F4;        /* Primary background canvas */
  --color-surface: #FFFFFF;      /* Card & container surfaces */
  --color-border: #E8E4DA;       /* Hairline borders & subtle dividers */
  
  /* Primary & Accents */
  --color-primary: #557662;      /* Deep sage green (growth, composure, primary CTAs) */
  --color-primary-hover: #4A6855;
  --color-accent: #C76A47;       /* Warm terracotta / coral (energy, action, recording) */
  --color-accent-hover: #B55D3C;

  /* Typography & Neutrals */
  --color-dark: #1C2420;         /* Primary anchor text (deep forest charcoal) */
  --color-muted: #626C66;        /* Supportive secondary metadata & timestamps */
  
  /* Badges & Special */
  --color-streak-bg: #F8F1E2;    /* Warm honey linen */
  --color-streak-text: #A26217;  /* Amber brown streak text */
  --color-streak-border: #ECD9BD;
}
```

## 3. Typography
- **Headings & Display:** `Newsreader`, Georgia, serif (Weight: 400, 500, 600)
  - Editorial, warm, introspective, dignified.
  - Tracking: `-0.015em` to `-0.02em`.
- **Body & Functional UI:** `Plus Jakarta Sans`, -apple-system, BlinkMacSystemFont, sans-serif
  - Clean, open apertures, highly legible at small sizes.
  - Tracking: tight (`-0.01em`).

## 4. Elevation, Radii & Layout
- **Container Width:** Max `428px` centered mobile viewport with subtle ambient shadow.
- **Border Radius:**
  - Full pills: `rounded-full` (`9999px`) for chips, badges, and primary action buttons.
  - Cards: `rounded-2xl` (`16px` to `20px`).
  - Inputs & Small Containers: `rounded-xl` (`12px`).
- **Depth:** Soft 1px border stroke (`#E8E4DA`), zero heavy black drop shadows; relies on diffused warmth: `0 4px 20px -4px rgba(28, 36, 32, 0.04)`.

## 5. Standard Component Guidelines
- **Primary Buttons:** Deep sage background (`#557662`), crisp white text, full pill geometry (`rounded-full`), `48px` to `52px` height.
- **Secondary Buttons / Ghost:** White or cream background, 1px `#E8E4DA` border, dark forest text (`#1C2420`).
- **Callout & Insight Cards:** Pure white (`#FFFFFF`) with delicate 1px `#E8E4DA` stroke, subtle padding (`1.25rem` to `1.5rem`).
- **Avatars & Personas:** Circular frame with subtle border, high-res human portraits in warm natural lighting.

## 6. Design System Notes for Stitch Generation
```markdown
**DESIGN SYSTEM (REQUIRED):**
- Aesthetic: Warm, calm editorial executive coach interface.
- Canvas Background: #FAF8F4 (brand cream).
- Card Surfaces: #FFFFFF with 1px border #E8E4DA.
- Primary Action Color: #557662 (deep muted sage).
- Accent Color: #C76A47 (warm clay terracotta).
- Primary Text: #1C2420 (deep dark forest).
- Muted Text: #626C66.
- Typography: Headline font is Newsreader (editorial serif), Body font is Plus Jakarta Sans.
- Geometry: Soft rounded curves (rounded-2xl for cards, rounded-full for buttons and status chips).
- Mobile Viewport: 390px to 428px fluid layout.
```
