# JARVIS AI — Android project

A beginner-friendly Flutter Android app with:
- AI chat through a private FastAPI backend
- Speech-to-text microphone input
- Text-to-speech with Male / Female voice preference
- Local conversation history
- User-controlled personal memory
- Optional web search through the OpenAI Responses API
- GitHub Actions workflow to build a release APK in the cloud

## Important
This ZIP contains the complete app source and backend, not a precompiled APK.
The APK must be built after you add your own OpenAI API key and deploy the backend.
Never put your OpenAI API key inside the Android app.

## What you need
- A GitHub account (you can use the mobile browser)
- An OpenAI API key and API billing enabled
- A free cloud host that can run a Python web service, or another server you control
- An Android phone with internet access

## Part A — Deploy the private AI backend

1. Extract this ZIP.
2. Create a GitHub repository named `jarvis-ai`.
3. Upload the contents of this folder to that repository.
4. On your cloud Python host, create a new Web Service from the GitHub repository.
5. Set the service's **Root Directory** to `backend`.
6. Set Build Command to: `pip install -r requirements.txt`
7. Set Start Command to: `uvicorn main:app --host 0.0.0.0 --port $PORT`
8. Add environment variables:
   - `OPENAI_API_KEY` = your secret API key
   - `OPENAI_MODEL` = `gpt-6-luna` (change if this model is not enabled for your API project)
   - `JARVIS_API_TOKEN` = a long random secret string you create
9. Deploy. Copy the public service URL, for example `https://your-service.example.com`.
10. Visit `https://YOUR-SERVICE-URL/health` to confirm it returns `{"status":"ok"}`.

Do not paste your API key into the Android app, GitHub source files, screenshots, or chat messages. Put it only in the backend host's secret environment-variable settings.

## Part B — Build the Android APK using GitHub Actions

1. Open the **Actions** tab in your GitHub repository.
2. Choose **Build JARVIS Android APK** and press **Run workflow**.
3. Wait for the workflow to finish successfully.
4. Open the completed workflow run, scroll to **Artifacts**, and download `jarvis-release-apk`.
5. Extract the downloaded artifact ZIP. It contains `app-release.apk`.
6. Open `app-release.apk` on your Android phone and follow Android's install prompts.

The workflow creates the Android platform scaffolding with Flutter, then builds the APK. The first build can take several minutes.

## Part C — First launch

1. Install and open JARVIS.
2. Tap the gear icon and confirm the backend URL and API token are set.
3. Choose Male or Female voice.
4. Allow microphone permission when Android asks.
5. Send a test message: `Hello JARVIS`.
6. Try the microphone button and speak a short sentence.

## Notes and limitations

- The selected voice depends on the speech voices installed on your Android device. The app asks Android's text-to-speech engine for a male/female preference; if the requested voice is unavailable, the engine may use its default voice.
- Conversation history and saved memory are stored locally on this phone. They are sent to your backend only as needed to answer a message.
- Web search is optional and uses the Responses API's built-in `web_search` tool. Availability and billing depend on your OpenAI API project.
- The app does not silently control your phone. App launching and other device actions need additional Android permissions and explicit implementation.
- For this personal prototype, the JARVIS access token is entered in the app's Settings. A token embedded or stored on a phone can be extracted by a determined person; do not distribute this single-user build publicly. Use real per-user authentication and rate limits before public release.
- This is a starter project. Test it before relying on it for important tasks.
