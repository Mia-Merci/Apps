# Privacy

CodexQuotaBar is a local macOS menu bar app for displaying Codex quota usage.

## What it reads

The app reads the local Codex authentication file:

```text
~/.codex/auth.json
```

If `CODEX_HOME` is set, it reads:

```text
$CODEX_HOME/auth.json
```

It uses the access token and account id from that file to request Codex usage data from:

```text
https://chatgpt.com/backend-api/wham/usage
```

## What it stores

The app stores only local UI preferences, such as the selected cookie topping style, using macOS user defaults.

If live usage sync is unavailable, it may read a local fallback file from:

```text
~/Library/Application Support/CodexQuotaBar/usage.json
```

## What it does not do

- It does not upload your Codex token to any third-party server.
- It does not display your token in the UI.
- It does not log your token.
- It does not include analytics or telemetry.
- It does not sell, share, or collect personal data.

## Important note

CodexQuotaBar uses an unofficial local Codex integration. The usage endpoint or response format may change without notice.
