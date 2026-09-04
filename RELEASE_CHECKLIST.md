# Release checklist

Before publishing CodexQuotaBar on GitHub:

- [ ] Quit the running menu bar app and run the latest build from Xcode.
- [ ] Confirm the menu bar cookie silhouette is visible in light mode, dark mode, and selected/highlighted state.
- [ ] Confirm the popover glass background looks acceptable over both light and colorful wallpapers.
- [ ] Confirm live Codex quota sync works after signing in to Codex Desktop.
- [ ] Run `Scripts/probe-codex-usage.mjs` and verify it does not print tokens.
- [ ] Run `Scripts/build-app.sh` and confirm `outputs/CodexQuotaBar.app` launches.
- [ ] Add screenshots or a short GIF to the README.
- [ ] Choose a license before public release, such as MIT or Apache-2.0.
- [ ] Review `PRIVACY.md`.
- [ ] Create the GitHub repository.
- [ ] Create a first release zip from `outputs/CodexQuotaBar.app`.

Suggested first tag:

```text
v0.1.0
```
