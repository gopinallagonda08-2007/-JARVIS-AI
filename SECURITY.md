# Security checklist

- Never place the OpenAI API key in Flutter/Dart code or inside the APK.
- Keep `OPENAI_API_KEY` only in your backend hosting provider's secret environment variables.
- Keep `JARVIS_API_TOKEN` in backend environment variables and GitHub Actions secrets.
- The mobile app's Settings screen currently expects you to paste the backend URL and JARVIS token on first launch. This token is a lightweight access gate, not a replacement for user authentication or rate limiting.
- For a public production app, add real user authentication, per-user quotas, HTTPS, request limits, monitoring, and a way to rotate/revoke tokens.
- Do not use a shared public token for an app distributed to many people.
