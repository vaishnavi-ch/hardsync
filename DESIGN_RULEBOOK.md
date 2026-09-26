# HardSync Design Rules

This file is the source of truth for every HardSync screen, component, and state.
The product should feel illustrated, warm, calm, and intentionally composed. It
should resemble a premium mobile learning product rather than a generated admin
dashboard or a generic Material app.

## 1. Product character

- HardSync is a supportive conversation practice product for ambitious people.
- The interface is optimistic and reassuring, even when the content involves
  conflict, feedback, or failure.
- Use editorial hierarchy, generous breathing room, and story driven artwork.
- Keep each screen focused on one decision or one next action.
- Density is moderate. Details may be rich, but the reading path must stay clear.

## 2. Asset first rule

The artwork in `assets/illustrations`, `assets/icons`, `assets/avatars`,
`assets/badges`, and `assets/gamification` defines the brand. Use these assets as
the starting point for composition and color decisions.

### Required asset use

- Every primary screen must contain at least one relevant illustration, avatar,
  badge, progress asset, or intentionally placed illustrated icon.
- Onboarding, authentication, empty states, completion states, paywalls, learning
  paths, and progress views require a prominent illustration.
- Scenario and conversation screens use the avatar belonging to the active
  character. Do not substitute initials or a generic person silhouette when an
  avatar exists.
- Achievement states use assets from `assets/badges` or `assets/gamification`.
- Feature, category, benefit, and navigation icons use `AppIcon` with a semantic
  asset from `HardSyncAssets`.
- Select an asset because it supports the message. Never insert artwork only to
  fill empty space.

### Native icon exceptions

Use platform icons for universal controls: back, close, more, visibility,
play/pause, microphone, camera, call end, checkbox, and chevron. These controls
must remain immediately recognizable. Do not place decorative asset icons inside
critical call controls.

### Asset rendering

- Use `AppIllustration` and `AppIcon`; do not repeat raw asset paths in screens.
- Preserve image aspect ratio. Use `BoxFit.contain` by default.
- `BoxFit.cover` is allowed only for deliberate full bleed hero artwork.
- Never stretch, recolor, clip, or apply strong shadows to illustrations.
- Give hero artwork a clean spatial zone. Text may sit beside it or above it but
  must not cover faces or key visual details.
- Treat illustrations as primary composition elements. On cards wider than
  420 px, artwork should normally occupy 30 to 40 percent of the card width and
  most of its usable height.
- Do not leave a small mobile thumbnail inside a widened tablet or desktop card.
  Increase the illustration region, card depth, and heading scale together.
- On focused screens, prefer a large top hero or a balanced illustration and
  content split. Small icon wells are reserved for metadata and supporting rows.

## 3. Color system

Use `HardSyncColors`. Do not add screen specific brand colors.

| Token | Value | Role |
| --- | --- | --- |
| Cream | `#FAF8F4` | Main canvas |
| Surface | `#FFFFFF` | Elevated panels and fields |
| Ink | `#17182B` | Primary copy, dark buttons |
| Ink Muted | `#565B76` | Supporting copy and metadata |
| Violet | `#7C5CE7` | Selected states, progress, focus |
| Violet Dark | `#6547CF` | Pressed violet and small accent copy |
| Lilac Mist | `#F1EDFF` | Violet tinted surfaces |
| Lilac Border | `#E2D8FF` | Focused and selected borders |
| Apricot | `#FF8A43` | Energy, prompts, highlights |
| Apricot Mist | `#FFF0E3` | Warm tinted surfaces |
| Olive | `#65704F` | Growth, stability, positive support |
| Olive Mist | `#EDF2E7` | Growth tinted surfaces |
| Coral | `#F06F61` | Human moments, warmth, reflection |
| Coral Mist | `#FFEAE6` | Coral tinted surfaces |
| Sun | `#F5B735` | Achievement, optimism, attention |
| Sun Mist | `#FFF4D8` | Golden tinted surfaces |
| Crimson | `#D32F2F` | Destructive and error actions only |

- Pull secondary visual balance from the illustration palette.
- Violet is the main interactive accent. Ink is used for decisive primary CTAs.
- Apricot and olive support meaning; they do not compete with the primary CTA.
- Use red only when the action is destructive or the system has failed.
- Avoid neon colors, blue purple glow effects, pure black, and cold gray canvas
  colors.
- Status colors retain semantic meaning across every screen.
- Balance lilac, apricot, olive, coral, and sun tints across repeated cards and
  adjacent sections. No single decorative hue should dominate an entire page.
- Keep Violet for interaction and selection. Content cards should rotate through
  the full illustration palette according to their topic or list position.

## 4. Typography

- Display and emotional headings: **Newsreader**, weight 600 or 700.
- Interface copy, labels, buttons, fields, and metrics: **Plus Jakarta Sans**.
- Main mobile heading: 26 to 38 px, tight line height around 1.0 to 1.2.
- Section heading: 18 to 22 px.
- Body: 13.5 to 16 px with line height 1.4 to 1.5.
- Metadata and helper copy: 11 to 12.5 px.
- Keep body lines short. Aim for 35 to 60 characters.
- Sentence case is the default. Reserve uppercase and letter spacing for brief
  status labels.
- Never use serif text for buttons, tabs, fields, metadata, or dense lists.

## 5. Layout and spacing

- Build mobile first and constrain main content to 440 to 480 px on wide screens.
- Respect safe areas. The bottom CTA must remain visible above system navigation.
- Standard horizontal page padding is 20 to 24 px.
- Use an 8 px spacing rhythm, with 4 px adjustments for optical alignment.
- Major screen sections use 20 to 28 px gaps. Related elements use 6 to 12 px.
- Use one dominant hero region, followed by structured content and one clear CTA.
- Prefer whitespace, tint changes, and typography over extra containers.
- Do not put every paragraph inside a card. Cards indicate grouping or action.
- Avoid nested cards. A card may contain rows, but those rows should use spacing or
  dividers instead of additional bordered cards.
- Lists must scroll without horizontal overflow at 320 px width.
- Use `LayoutBuilder`, `Expanded`, `Flexible`, and max width constraints rather
  than device type checks or fixed screen assumptions.

## 6. Shape and depth

### Responsive behavior

- Base every transition on available width from `LayoutBuilder`, including split
  screen and resizable browser windows. Do not infer a phone or tablet model.
- Below 720 px, use the five destination bottom navigation and a single reading
  column.
- From 720 px, replace bottom navigation with a compact navigation rail. From
  1180 px, show the rail labels.
- Keep reading and form content between 440 and 520 px. Reports, dashboards, and
  grids may expand to 1000 to 1120 px when their information benefits from more
  than one column.
- Center constrained content on wide canvases and use the cream, lilac, and warm
  illustration palette in the surrounding space. Never stretch phone cards to
  fill a desktop window.
- Support portrait, landscape, desktop resizing, mouse, trackpad, keyboard focus,
  and touch without locking orientation.
- Validate at 320 x 568, 390 x 844, 430 x 932, 768 x 1024, 1024 x 768, and
  1440 x 900.

- Page cards: 18 to 24 px radius.
- Bottom sheets and large modal surfaces: 28 to 32 px top radius.
- Buttons and segmented controls: full pill or 16 to 18 px radius.
- Icon wells: 10 to 14 px radius or circular when visually appropriate.
- Use 1 px warm or lilac borders for structure.
- Shadows remain subtle and background tinted: low alpha, 8 to 24 px blur, small
  downward offset.
- Do not use neon glows, heavy black shadows, or identical elevation everywhere.

## 7. Components

### Buttons

- One primary action per screen.
- Primary actions use Ink or Violet with white Plus Jakarta Sans text.
- Secondary actions use a white or transparent surface with a visible border.
- Destructive actions use Crimson.
- Minimum touch target is 44 px; primary buttons are normally 50 to 56 px high.
- Show progress inside the action that initiated it and disable repeat submission.

### Cards

- Cards group one concept: a plan, scenario, metric cluster, partner, or action.
- Selected cards use violet borders and a lilac tint.
- Use illustration crops or illustrated icon wells to establish category identity.
- Avoid repetitive equal cards when a hero, list, or timeline communicates the
  hierarchy more clearly.

### Inputs

- Use white fields with restrained borders and 14 to 18 px radius.
- Leading icons may use native line icons for email, password, and visibility.
- Error copy appears directly below the field in Crimson.
- Focus, filled, loading, error, and disabled states must not change layout size.

### Navigation

- Bottom navigation uses Apple-style `CupertinoIcons` with five persistent destinations:
  Home, Learn, Practice, Progress, and Profile. Practice may use a raised lilac
  active treatment. Keep labels visible in every state.
- Active state uses a lilac well and violet emphasis.
- Tablet and web navigation use the same destinations, icon family, labels, and
  selected state in a side rail. Navigation structure must not change by platform.
- Back, close, and more controls remain simple native symbols in 44 px targets.
- Hide global navigation during authentication, payment, live calls, and focused
  setup flows.

## 8. State design

Every feature must account for loading, empty, error, offline, success, locked,
disabled, and partial data states.

- Loading: keep the final layout stable. Use a contextual progress element or
  skeleton; pair long operations with a relevant illustration.
- Empty: explain what belongs here and provide one useful action with a supporting
  illustration.
- Error: state what failed and how to recover. Preserve entered user data.
- Success: confirm the completed action with a concise message and celebratory
  asset when the moment is meaningful.
- Locked: explain the required plan or prerequisite without hiding the content's
  purpose.
- Destructive confirmation: name the consequence plainly and use a single red
  confirmation action.
- Backend status messages must use product language. Do not expose provider names,
  keys, stack traces, or implementation details to users.

## 9. Motion and interaction

- Motion explains state or spatial change. It is restrained and quick.
- Button feedback: 100 to 160 ms.
- Tabs, chips, and selection changes: 150 to 220 ms with ease out.
- Sheets and dialogs: 220 to 300 ms.
- Repeated controls should feel immediate. Do not animate routine navigation
  excessively.
- Prefer opacity and transform animations. Avoid layout shifting animations.
- Respect reduced motion settings.

## 10. Copy rules

- Use warm, direct language. Prefer â€œStart practiceâ€ over abstract growth slogans.
- Keep headings specific to the task.
- Do not mention internal architecture, API providers, feature flags, or test mode
  in customer facing copy.
- Avoid generic AI marketing language such as â€œrevolutionizeâ€, â€œunlock your
  potentialâ€, â€œseamlessâ€, or â€œnext generationâ€.
- Do not invent metrics, testimonials, user names, or performance claims.
- Use proper punctuation. Broken encoding is a release blocking defect.

## 11. Definition of done

A screen is complete only when:

1. Its illustration, icon, avatar, badge, and gamification choices are relevant.
2. It uses shared color and typography tokens.
3. Its primary action and reading order are immediately clear.
4. It works at 320, 390, 440, tablet, and resizable web widths.
5. Loading, empty, error, success, disabled, and locked states are designed.
6. Tap targets, contrast, focus order, and semantics are accessible.
7. No overflow, clipped artwork, corrupted text, or placeholder UI remains.
8. Static analysis, widget tests, and the production build pass.

## 12. Banned patterns

- Generic Material screen with only text, stock icons, and default components.
- Random gradients that are not derived from the illustration palette.
- Different brand palettes for authentication, subscription, and core product.
- Decorative emojis standing in for available app assets.
- Generic avatar silhouettes when a real HardSync avatar exists.
- Nested card stacks, excessive status chips, and repeated bordered boxes.
- Giant text that pushes the primary action below the fold.
- Illustrations used as tiny, meaningless decoration.
- Controls below 44 px or labels below 10.5 px.
- Hard coded colors when an equivalent `HardSyncColors` token exists.
- Raw asset paths outside `HardSyncAssets`.
