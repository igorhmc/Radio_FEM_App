# Radio FEM Watch Bridge

Android companion app for the Zepp watch project.

What it does:

- runs a foreground service on the phone
- exposes a local HTTP bridge at `http://127.0.0.1:43871`
- plays the Radio FEM live stream directly on the phone
- accepts `play-live`, `pause`, `volume-up`, and `volume-down`

Why it exists:

- the main Flutter app stays focused on live radio, schedule, podcasts, and contact pages
- the watch integration becomes an additional Android app instead of changing the main app

Build:

```bash
cd android
./gradlew :watchbridge:assembleDebug
```
