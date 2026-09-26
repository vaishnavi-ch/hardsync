# HardSync UI and State Test Report

Date: 2026-09-25

## Automated coverage

The permanent Flutter suite now verifies:

- Home at 320Ã—568 and 430Ã—932
- Progress Overview, Insights, and Badges
- Custom scenario start, situation, persona, and review states
- Lesson Learn, Takeaways, Example, Reflect, Recap, Check, incorrect answer,
  retry, correct answer, and completion states
- Session preparation at 320Ã—568 with text, voice, and video modes visible
- Paywall at 320Ã—568 and 430Ã—932
- Authentication, password reset, scenario catalog, subscription permissions,
  credits, telemetry, debrief generation, and call lifecycle regressions

## Defects found and fixed

- Home progress hero overflow at compact width
- Home metric cards overflow at compact width
- Home learning and practice cards overflow at compact width
- Lesson reflection visual overflow
- Session preparation header overflow
- Session scenario badges overflow
- Session talking-points header overflow
- Session role selector header overflow
- Session primary action overflow
- Paywall hero overflow
- Paywall plan-card overflow
- Paywall restore footer overflow
- Session preparation old green controls replaced by the HardSync violet,
  lilac, navy, cream, apricot, and olive palette

## Results

- Flutter analyzer: no issues
- Automated tests: 27 passed
- Production web build: successful

## Platform-owned purchase dialog

The `Test Store Purchase` sheet shown by the billing test environment is owned
by the store or RevenueCat test layer. Application typography, colors, spacing,
and illustrations cannot style that system dialog. HardSync controls the
paywall before it opens and the success, cancellation, and failure states after
it closes.

## Known build note

The JavaScript web release builds successfully. Flutter's optional WebAssembly
dry run reports that the existing replay and Tavus web adapters use `dart:html`
and `dart:js_util`. This does not block the current JavaScript web build.
