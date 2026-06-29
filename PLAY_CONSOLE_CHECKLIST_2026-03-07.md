# Play Console Checklist

Package: `com.forroemmilao.radiofem`

Current release:
- Track: `production`
- Status: `completed`
- Version: `1.0.30+10035`
- Promoted from `beta` to `production` on 2026-06-29 with Gradle Play Publisher.

What was completed from the repository:
- Android App Bundle signed and uploaded to Play Console.
- Version `1.0.30+10035` promoted to production.
- English-only (`en-US`) store listing prepared with icon, feature graphic, updated screenshots, title, short description, and full description.
- Contact email and website prepared in `android/app/src/main/play/`.
- Privacy policy page prepared in `docs/privacy-policy/index.html`.
- Play Console edits were committed successfully by the publishing service account.

Manual Play Console review items:

1. Privacy policy
- Public URL confirmed:
  - `https://radio.forroemmilao.com/privacy-policy.html`
- Fallback copy in repo:
  - `docs/privacy-policy/index.html`

2. Play Console mandatory forms
- `Dashboard > Set up your app`
- `Policy and programs > App content`
- Keep complete and submitted:
  - Privacy policy URL
  - App access
  - Ads declaration
  - Content rating
  - Target audience and content
  - Data safety
  - News apps only if applicable

3. Review Store listing
- Open `Grow > Store presence > Main store listing`
- Confirm:
  - App name: `Radio FEM`
  - Category: `Music & Audio`
  - Contact email: `info@radio.forroemmilao.com`
  - Website: `https://radio.forroemmilao.com`
- Privacy policy URL to use:
  - `https://radio.forroemmilao.com/privacy-policy.html`

Suggested Data safety review basis from the current codebase:
- No account creation or login.
- No ads SDK.
- No direct collection of name, email, phone, contacts, location, photos, files, messages, or payment data inside the app.
- App accesses public radio stream, schedule, podcasts, and external links.
- Playback uses foreground media service.

Files prepared for Play metadata:
- `android/app/src/main/play/`
- `android/app/src/main/play/listings/en-US/`
- `android/app/src/main/play/release-notes/`
- `PLAYSTORE_MATERIALS_radio_fem_v1.0.7.md`
