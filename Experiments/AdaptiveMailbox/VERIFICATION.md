# Verification

Checked on 15 November 2026 with Xcode 27.2 (27B52), Apple Swift 6.4.2, and iOS 27.2 simulators.

## Passed

- `swift test`: 11 test functions, including 15 width-boundary cases. Checks compact/expanded/sidebar thresholds, invalid widths, accessibility-size fallback, selection validation, folder changes, Back, explicit draft discard, and close/reopen draft retention. The model-only resize test does not replace UI lifecycle testing.
- iPhone Duo simulator: app compiled, installed, launched; UI test opened a sample message, composed text, rotated with the editor open, returned to portrait, closed/reopened the draft, verified the same text and selection, navigated back, switched folders, and opened another message.
- iPad Pro 13-inch (M5) simulator: the same flow passed in a wide window. A separate test verified the list stayed interactive alongside message detail, switched the selected message, rotated, and retained that selection.
- Final UI suite counts: Duo 1 passed / 0 failed / 1 intentionally skipped wide-window test; iPad 2 passed / 0 failed / 0 skipped. Final runs reported no warnings.
- `git diff --check`.

## Not passed / not tested

- Production Proton Mail: blocked before compilation by missing SDK and ProtonCore packages. See README for exact paths and commands. No real login, sync, encryption, attachments, sending, push notifications, account switching, or production draft behavior was tested.
- Physical fold/unfold transitions and simultaneous external/internal display lifecycle have not been verified. Rotation tests are not evidence that physical fold handling works.
- Real device signing/distribution and App Store submission were not attempted.
- The third-column threshold and accessibility fallback have model coverage; no exhaustive visual/Dynamic Type or multitasking matrix has been run.
- Demo draft persistence after process termination is intentionally absent.

The experiment contains no remote CI workflow. Local test results do not imply that the upstream production suite passes.

## Screenshots

- `Evidence/duo-compact.png`: local demo inbox on the Duo primary display. The simulator rendered system controls at the side after the rotation exercise; this is not a fold-transition validation.
- `Evidence/ipad-expanded-empty.jpg`: wide-window inbox and empty reading pane on iPad.
