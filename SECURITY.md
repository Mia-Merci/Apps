# Security

CodexQuotaBar reads local Codex authentication data to request quota usage.

## Reporting a vulnerability

If you find a security issue, please report it privately instead of opening a public issue that includes sensitive details.

## Token handling expectations

- Do not commit real `auth.json` files.
- Do not paste access tokens into issues, screenshots, logs, or pull requests.
- Do not add logging that prints request headers or authentication payloads.
- If a token is accidentally exposed, rotate or revoke the affected login immediately.

## Unofficial integration

CodexQuotaBar uses an unofficial local Codex usage endpoint. Treat endpoint changes, authentication changes, or unexpected response formats as compatibility issues unless they expose private data.
