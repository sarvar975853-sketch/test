# Shadow Fight 2 — native WebKit app

A tiny native macOS app (Swift + AppKit + `WKWebView`) that loads
`https://shadowfight2.com/play/`. No Electron, no bundled Chromium — it uses
the system's built-in WebKit engine, so the app itself is only a few hundred
KB.

**Login behavior:** normal gameplay stays inside the app window. If the page
ever redirects to a sign-in provider (Google, Facebook, Apple, etc.) or opens
one in a popup, that request is handed off to your **default browser**
instead, so you log in there and the game picks up the session as usual.

## Requirements

- A Mac (this must be built *on* macOS — Xcode's Swift compiler and the
  Cocoa/WebKit frameworks aren't available on Linux/Windows).
- Xcode Command Line Tools (`xcode-select --install` if you don't have them).

## Build

```bash
cd ShadowFight2
chmod +x build.sh   # already executable, but just in case
./build.sh
```

This compiles the app twice (once for `arm64`, once for `x86_64`), merges
the two into one **universal binary** with `lipo`, packages it as
`Shadow Fight 2.app`, and ad-hoc code-signs it so Gatekeeper will let you run
it locally without a paid Apple Developer account.

Run it with:

```bash
open "Shadow Fight 2.app"
```

or just double-click it in Finder. Drag it into `/Applications` if you want
it to stick around.

## Adding a real icon (optional)

By default the app uses the generic macOS app icon. To use your own:

1. Create a `1024x1024` PNG.
2. Convert it to `.icns`:
   ```bash
   mkdir icon.iconset
   sips -z 16 16     icon.png --out icon.iconset/icon_16x16.png
   sips -z 32 32     icon.png --out icon.iconset/icon_16x16@2x.png
   sips -z 32 32     icon.png --out icon.iconset/icon_32x32.png
   sips -z 64 64     icon.png --out icon.iconset/icon_32x32@2x.png
   sips -z 128 128   icon.png --out icon.iconset/icon_128x128.png
   sips -z 256 256   icon.png --out icon.iconset/icon_128x128@2x.png
   sips -z 256 256   icon.png --out icon.iconset/icon_256x256.png
   sips -z 512 512   icon.png --out icon.iconset/icon_256x256@2x.png
   sips -z 512 512   icon.png --out icon.iconset/icon_512x512.png
   cp icon.png icon.iconset/icon_512x512@2x.png
   iconutil -c icns icon.iconset -o AppIcon.icns
   ```
3. Put the resulting `AppIcon.icns` in this same folder (next to `build.sh`)
   and re-run `./build.sh` — it's picked up automatically.

## How the domain/login logic works

`Sources/main.swift` contains one small policy:

- Any navigation whose host is `shadowfight2.com` (or a subdomain of it)
  stays inside the app.
- Any **top-level** navigation to a different host — e.g. the page
  redirecting to `accounts.google.com` for sign-in — is cancelled inside
  the app and handed to `NSWorkspace.shared.open(url)`, which opens it in
  your default browser.
- Any popup/new-window request (`window.open(...)`, `target="_blank"`,
  which is how many "Sign in with Google" buttons work) is intercepted the
  same way instead of opening a second in-app window.
- Third-party content loaded *inside* an iframe (not a full-page
  navigation) is left alone, since some sign-in widgets render that way
  and blocking it would just break them.

If you ever want to change the game URL or allowed domain, both are defined
right at the top of `main.swift`:

```swift
let gameURL = URL(string: "https://shadowfight2.com/play/")!
let gameHost = "shadowfight2.com"
```

## Notes

- This is an unsigned, unnotarized, ad-hoc build meant for your own local
  use. If macOS still complains the first time you open it, right-click the
  app → **Open** → **Open** to bypass Gatekeeper's "unidentified developer"
  warning (you only need to do this once).
- Shadow Fight 2 is a trademark of its respective owner (Nekki); this app is
  just a lightweight native shell around the public web version and isn't
  affiliated with them.
