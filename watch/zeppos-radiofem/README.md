# Radio FEM watch app

Prototype for `Amazfit Active 2` on `Zepp OS`.

What it does:

- Fetches `https://radio.forroemmilao.com/api/nowplaying/radiofem`
- Shows only the current track and the live listeners count
- Sends `Play`, `Pause` and volume commands to a dedicated Android phone bridge app
- Uses a circular layout sized for `466x466`
- Refreshes every `30s` and also on manual tap

Project structure:

- `app-side/index.js`: runs in the Zepp mobile companion and performs the HTTP request
- `page/index.js`: renders the watch UI and asks the side service for data or phone commands
- `app.json`: app manifest with round-screen target

Notes:

- Live metadata stays independent from the Flutter mobile app and uses the public radio endpoint through the Zepp companion layer.
- Phone playback control now targets a separate Android companion app, so the main `Radio FEM` Flutter app can stay untouched.
- The Android bridge listens on `http://127.0.0.1:43871` with the shared key `radiofem-watch-bridge-v1`.
- The WSL environment was fixed to use a local Linux `node` plus a local Linux `zeus`, so `zeus build` now works from this shell.
- The current watch icon reuses the same application icon from the Radio FEM mobile app.

Typical setup on a machine with the Zepp toolchain:

```bash
npm install
zeus preview
zeus build
```

The preview/build flow is documented in the Zepp developer docs:

- https://docs.zepp.com/docs/guides/tools/cli/overview/
- https://docs.zepp.com/docs/guides/basic/app-service/
