# Play Console Checklist

Package: `com.forroemmilao.radiofem`

Current release:
- Track: `internal`
- Status: `draft`
- Version: `1.0.5+10005`

What was completed from the repository:
- Android App Bundle signed and uploaded to Play Console.
- `en-US` store listing prepared with icon, feature graphic, screenshots, title, short description, and full description.
- `pt-BR` store listing prepared locally in `android/app/src/main/play/listings/pt-BR`.
- Contact email and website prepared in `android/app/src/main/play/`.
- Privacy policy page prepared in `docs/privacy-policy/index.html`.

What still needs Play Console UI access:

1. Fix service account permissions
- Open `Play Console > Users and permissions`.
- Grant the publishing service account app-level access for:
  - Store presence
  - App content
  - Release to testing tracks
- The current service account can upload bundles, but it cannot commit store listing edits.

2. Publish the privacy policy at a public URL
- Public URL confirmed:
  - `https://radio.forroemmilao.com/privacy-policy.html`
- Fallback copy in repo:
  - `docs/privacy-policy/index.html`

3. Complete Play Console mandatory forms
- `Dashboard > Set up your app`
- `Policy and programs > App content`
- Complete and submit:
  - Privacy policy URL
  - App access
  - Ads declaration
  - Content rating
  - Target audience and content
  - Data safety
  - News apps only if applicable

4. Review Store listing
- Open `Grow > Store presence > Main store listing`
- Confirm:
  - App name: `Radio FEM`
  - Category: `Music & Audio`
  - Contact email: `info@radio.forroemmilao.com`
  - Website: `https://radio.forroemmilao.com`
- Add the privacy policy URL after it is public.
- Privacy policy URL to use:
  - `https://radio.forroemmilao.com/privacy-policy.html`

5. Move out of draft when Play Console shows all checks complete
- Keep the current internal release as `draft` until all required declarations are accepted.
- After the app is no longer marked as draft, a new release can be sent as `completed` to `internal`, `closed`, or `production`.

Suggested Data safety review basis from the current codebase:
- No account creation or login.
- No ads SDK.
- No direct collection of name, email, phone, contacts, location, photos, files, messages, or payment data inside the app.
- App accesses public radio stream, schedule, podcasts, and external links.
- Playback uses foreground media service.

Files prepared for Play metadata:
- `android/app/src/main/play/`
- `android/app/src/main/play/listings/en-US/`
- `android/app/src/main/play/listings/pt-BR/`
- `android/app/src/main/play/release-notes/`
