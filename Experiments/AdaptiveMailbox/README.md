# Adaptive mailbox experiment

**This is a working local UI prototype, not a working Proton Mail client.** It has sample messages, no login, no network traffic, and no send action. Drafts survive layout changes and sheet dismissal in the running process, not app termination. Upstream production code is untouched.

## Run on a Mac

Requirements: Xcode, its command-line tools, an installed iOS simulator, and XcodeGen. No third-party package dependencies are needed for this experiment.

```sh
cd Experiments/AdaptiveMailbox
swift test
xcodegen generate
open AdaptiveMailboxDemo.xcodeproj
```

Select the `AdaptiveMailboxDemo` scheme and an iOS simulator, then Run. The app is named **Mail Layout Lab**. Device signing is deliberately disabled in this simulator-only project.

```sh
xcodebuild -project AdaptiveMailboxDemo.xcodeproj -scheme AdaptiveMailboxDemo \
  -destination 'platform=iOS Simulator,name=iPhone Duo' CODE_SIGNING_ALLOWED=NO test
```

Use an available simulator name if that device is absent. Also run the test suite on a wide iPad simulator to exercise the two-column layout.

## Layout and state

- Under 640 points: inbox or selected message, with an explicit Back button.
- From 640 points: 280-point mailbox list beside the selected message.
- From 1180 points: an additional 220-point folders sidebar.
- Accessibility Dynamic Type: single column for readability.
- Uses the available window width, not a device-model string. Thresholds are prototype choices, not claims about hardware specifications.
- Selection and draft text live in one observable session outside layout branches. The composer presentation lives outside the resizing subtree.
- Folder changes clear selection, but preserve the draft. Closing retains the draft; Discard explicitly removes it.

## Production build blocker

Baseline: `ProtonMail/ios-mail` commit `701463fe45` (7.10.0 source), SDK pin `0.165.4`.

Running unmodified `xcodegen generate` fails with four invalid local packages:

- `ProtonPackages/et-protoncore/platform/apple/Payments/PaymentsNG`
- `ProtonPackages/et-protoncore/platform/apple/Payments/PaymentsUI`
- `ProtonPackages/et-protoncore/platform/apple/ProtonCoreET`
- `ProtonPackages/proton_app_uniffi`

Consequently `xcodebuild -project ProtonMail.xcodeproj ... build` exits 66 because the project cannot be generated. The referenced `scripts/templates/IDETemplateMacros.plist` post-generation input is absent too.

[Upstream README](https://github.com/ProtonMail/ios-mail/blob/701463fe45/README.md) explicitly says the SDK distribution is internal and the public application cannot currently be built directly.

Follow-up correction: the exact SDK version **is publicly tagged** at [mail-uniffi-v0.165.4](https://github.com/ProtonMail/clients/tree/mail-uniffi-v0.165.4), commit `6ef4ff39677fd5cbbc7fcd986b6b0d1b773073f7`. The earlier comparison with the latest SDK was not sufficient to establish a version blocker. The exact tag still does not contain the missing Apple packages and its Cargo lockfile uses additional Proton-registry dependencies. See the [production dependency investigation](../../PRODUCTION_BUILDABILITY.md). No private infrastructure was contacted and no authentication/crypto stubs were substituted.

## Integration path when upstream dependencies become available

1. Reproduce an unmodified simulator build with the exact SDK pin and the missing Apple packages.
2. Replace `MailboxScreen`'s single-stack shell with a window-width-aware layout, keeping the existing `MailboxModel`, `DraftPresenter`, and `ConversationDetailSeed` pipeline as the authoritative state. Do not replace encryption, account management, or persistence with this demo model.
3. Reconcile compact navigation with selected message state, including notification-opened messages, folder switching, next-conversation actions, and Back behavior.
4. Test fold/unfold and multitasking transitions with a real draft, attachment sheets, search, account switching, accessibility text, and authentication interruption.

## License

New experiment files are GPL-3.0-or-later; see `COPYING`. Existing Proton copyright and licensing notices in the fork are unchanged. The Rust source was inspected, not copied or vendored; its separate licensing still applies if incorporated later.
