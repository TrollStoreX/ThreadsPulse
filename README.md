# ThreadsPulse

**English** | [繁體中文](README.zh-TW.md)

An iOS tweak for Threads (`com.burbn.barcelona`). Current version: **1.18.2**

No jailbreak needed: build your own Threads IPA with ThreadsPulse injected using GitHub Actions, then install it with your own signing tool.

## Features

| Section | Feature | Description |
|---|---|---|
| Ads & Privacy | Block Ads | Hide sponsored posts in the feed |
| | Remove URL Tracking | Strip `xmt`, `igshid`, `utm_*` and more when copying, sharing or opening links, and unwrap `l.threads.com` redirects |
| Clipboard Links | Detect Copied Links | When you come back or switch accounts, detect a copied Threads link and open that post |
| | When a Link Is Found | **Ask** shows a prompt (Top / Middle / Bottom); **Auto-open** opens it right away |
| Download | Download Button | ↓ at the top-right of a post: tap to download all photos and videos; long-press to download only photos or only videos |
| | Download Original-Size Photos | Fetches the original resolution from threads.com; WebP is converted to JPEG for Photos |
| | Download Original-Size Profile Pictures | Long-press a profile picture on a profile, or open it full screen and tap ↓ |
| Home Feed | Keep Feed Position | Coming back from the background won't refresh the home feed or jump to the top. Keep for 10 min / 30 min / No Limit |
| | Disable Pull to Refresh | Pulling down at the top of the home feed won't refresh it |
| | Home Tab: Don't Scroll to Top | When you're scrolled down, tapping the Home tab keeps you where you were |
| | Home Tab: Don't Refresh | When you're at the top, tapping the Home tab won't load new posts |
| Interface | Keep Tab Bar Visible | The tab bar at the bottom no longer hides while scrolling |
| | Hide Follow Suggestions | Stop the "Suggested for you" sheet from popping up |
| | Copy Profile Info | On a profile, long-press the name, username, bio or profile picture to copy the name, username or bio |
| Video | Default Playback Speed | 1x / 1.25x / 1.5x / 2x |
| Interactions | Like Confirmation | Ask before a like is sent, to prevent accidental taps |
| Time | Post Time Format | Relative / Date & Time / With Seconds |
| Backup | Export / Import Settings | JSON file |
| Advanced | Sideload Compatibility Fix | Keeps you signed in and app group data working after re-signing. Turns itself off on the original signature (jailbreak) |
| | Debug Hints | Shows `[TP]` hints when features are active, to find out which one broke after a Threads update |

**Settings**: tap **〰 Pulse** at the top-right of Threads' Settings page, or long-press anywhere with three fingers for 1 second.

---

## Build your own IPA with GitHub Actions (no jailbreak, recommended)

### What you need

1. **A decrypted Threads IPA.** This project does **not** provide Threads itself. The App Store version is encrypted and won't work; you need a decrypted IPA.
2. **A direct download link to the IPA.** Put the IPA somewhere it can be downloaded directly (for example, a Dropbox link ending in `?dl=1`). Opening the link in a browser should start the download, not show a web page.
3. **A signing tool** to install the IPA on your phone. Your tool decides which variant to pick (see below).

### Two variants

| Variant | For | Contents |
|---|---|---|
| **sideload** | Certificate signing: ESign, Feather, Sideloadly with a paid developer account, etc. | Keeps Threads' own extensions (widgets, share, etc.) and adds the "Open in Threads" Safari extension |
| **noplugins** | **Free Apple IDs** with SideStore, AltStore, etc. | Removes all extensions. Free accounts can't sign extensions and have a limited number of App IDs |

**"Open in Threads" Safari extension**: a sideloaded Threads can't receive universal links, so tapping a threads.com link in Safari just stays on the web page. This extension turns threads.com / threads.net links into Threads app links and opens them: posts open the post, profiles open the profile.
After installing, go to **Settings › Apps › Safari › Extensions** (on iOS 17 and earlier: **Settings › Safari › Extensions**), turn on "Open in Threads", and allow it on threads.com.

### Set up your own repo (pick one)

| Method | Pros | Cons |
|---|---|---|
| **Fork** (easiest) | One click; tap **Sync fork** to get new versions | A fork is always **public** |
| **Import repository** (private) | Can be **private**, so only you can get the IPA | Re-import to get new versions |

- **Fork**: click **Fork** at the top-right of this project's page → **Create fork**.
  > **Anyone signed in to GitHub can download the Artifacts of a public repo**, and the IPA you build contains Threads itself. If you fork, save the IPA link as a Secret (see below) and delete the Artifact from the run page after downloading the IPA.
- **Import repository**: click **＋** at the top-right of GitHub → **Import repository**, paste this project's URL into **Your old repository's clone URL**, set **Privacy** to **Private** → **Begin import**.
  > Actions in private repos have a monthly free-minutes limit (macOS minutes count 10×). One build takes about 5–10 minutes.

### Steps

1. Open your repo → **Actions** tab. On a fork, first click "I understand my workflows, go ahead and enable them".
2. (Recommended) Save the IPA link as a Secret: **Settings → Secrets and variables → Actions → New repository secret**, name it `DECRYPTED_IPA_URL`, and paste the IPA link as the value.
3. Select **Build IPA** on the left → **Run workflow** on the right:
   - **ipa_url**: the IPA link. Leave it empty if you set the Secret.
   - **variant**: `both` (default, builds both), `sideload` or `noplugins`.
4. Click **Run workflow**. It takes about 5–10 minutes.
5. Open the run, and at the bottom under **Artifacts**, download `Threads <version> + ThreadsPulse <version> sideload` or `… noplugins`. Unzip it to get the IPA.
6. Install it with your signing tool. Artifacts are deleted automatically after 3 days.

**Common errors**

| Error (shown in Chinese) | Meaning | Cause |
|---|---|---|
| 下載的檔案不是 IPA | The downloaded file isn't an IPA | The link opens a web page instead of downloading directly |
| 這個 IPA 尚未解密 | This IPA isn't decrypted | It's the encrypted App Store version; use a decrypted IPA |
| 執行檔的 header 空間不足 | Not enough header space in the executable | Very rare; please report your Threads version |

> Please don't upload the IPA to a public Release or anywhere public.

---

## Other ways to build

### GitHub Actions: tweak only (Build)

Pushing to `main` / `master`, opening a pull request, or running **Build** → **Run workflow** in Actions produces:

| File | Use |
|---|---|
| `ThreadsPulse sideload <version>.zip` | For manual injection: `ThreadsPulse.dylib`, `ThreadsPulse.bundle`, `OpenThreadsSafariExtension.appex` (goes into the app's `PlugIns/`; leave it out for free accounts) |
| `ThreadsPulse rootless <version>.deb` | Rootless jailbreak (Dopamine / palera1n rootless) |
| `ThreadsPulse rootful <version>.deb` | Rootful jailbreak |

Pushing a tag that starts with `v` also creates a Release with these three files (Threads itself is not included):

```bash
git tag v1.18.2
git push origin v1.18.2
```

### Build locally

Requires [Theos](https://theos.dev) (macOS or Linux).

```bash
export THEOS=~/theos
make FINALPACKAGE=1            # dylib only: .theos/obj/ThreadsPulse.dylib
make package FINALPACKAGE=1    # .deb (jailbreak)
make -C OpenThreadsSafariExtension FINALPACKAGE=1   # Safari extension → OpenThreadsSafariExtension/.theos/obj/

# Inject into a decrypted IPA (only needs Python 3 and zip / unzip)
BUNDLE="layout/Library/Application Support/ThreadsPulse/ThreadsPulse.bundle"
# sideload variant
python3 scripts/inject_ipa.py -i Threads.ipa -d .theos/obj/ThreadsPulse.dylib -b "$BUNDLE" \
  --appex OpenThreadsSafariExtension/.theos/obj/OpenThreadsSafariExtension.appex -o sideload.ipa
# noplugins variant
python3 scripts/inject_ipa.py -i Threads.ipa -d .theos/obj/ThreadsPulse.dylib -b "$BUNDLE" \
  --no-plugins -o noplugins.ipa
```

- Rootless jailbreak: uncomment `THEOS_PACKAGE_SCHEME = rootless` in the `Makefile`.
- Uses the Logos `internal` generator to hook through the ObjC runtime directly, so it **doesn't depend on CydiaSubstrate / ElleKit** and nothing extra needs to be injected.
- The version number is defined only in `TPVersion.h` (also update `ThreadsPulse.bundle/Info.plist`). The iOS SDK and minimum iOS version are set by `SDK_VERSION` and `MIN_IOS` in the workflows.

### What `inject_ipa.py` does

1. Unpacks the IPA and copies `ThreadsPulse.dylib` into `Threads.app/Frameworks/` and `ThreadsPulse.bundle` into `Threads.app/`.
2. Adds an `LC_LOAD_DYLIB` load command (`@executable_path/Frameworks/ThreadsPulse.dylib`) to the Threads executable, skipping it if already there.
3. Checks that the app is decrypted (`cryptid` in `LC_ENCRYPTION_INFO_64`) and stops if it isn't.
4. `--appex` copies an extension into `PlugIns/` (removing any signing data inside it); `--no-plugins` removes `PlugIns/`, `Extensions/` and `Watch/`.
5. Repacks an **unsigned** IPA for your signing tool to sign.

It only uses the Python standard library; nothing else to install.

---

## Project structure

```
ThreadsPulse/
├── Makefile
├── control                         Package info
├── ThreadsPulse.plist              Injection target (com.burbn.barcelona)
├── Tweak.x                         All hooks (Logos)
├── TPPrefs.h/.m                    Settings storage, defaults, export / import
├── TPURLCleaner.h/.m               URL tracking removal
├── TPDownloader.h/.m               URL selection, downloads, WebP → JPEG, diagnostics
├── TPHUD.h/.m                      Progress view, toasts, prompt banner
├── TPUI.h/.m                       Round frosted buttons, long-press menus, haptics
├── TPSettingsViewController.h/.m   Settings page (data model between TP_MODEL_BEGIN and TP_MODEL_END)
├── TPLocalization.h/.m             TPL() localization
├── TPSideloadFix.h/.m              Sideload compatibility fix (keychain, app groups)
├── TPVersion.h                     Version number (change it only here)
├── scripts/inject_ipa.py           Injects the tweak into an IPA
├── OpenThreadsSafariExtension/     "Open in Threads" Safari extension (sideload variant only)
│   ├── OpenInThreadsHandler.m      Native side (only lets the extension load)
│   └── Resources/                  content.js (link conversion and redirect), manifest.json, icons
├── .github/
│   ├── actions/setup-theos/        Shared: installs Theos and the iOS SDK
│   └── workflows/
│       ├── build.yml               Builds the tweak (zip / deb)
│       └── build-ipa.yml           Builds and injects the IPA
└── layout/Library/Application Support/ThreadsPulse/ThreadsPulse.bundle/
    ├── Info.plist
    ├── en.lproj/Localizable.strings
    └── zh-Hant.lproj/Localizable.strings
```

## Localization

- The code always uses `TPL(@"English text")`; **the English text is the key**, and it's shown as-is when no translation exists.
- The language follows the system: Traditional Chinese uses `zh-Hant`, everything else uses `en`.
- To add a language, copy `en.lproj` (for example to `ja.lproj`), translate it, and add the language code to `CFBundleLocalizations` in `Info.plist`.

## Implementation notes

- **Swift classes**: hooked by mangled name (for example `_TtC6BCNUFI12BCNUFIButton`), with ivars read through the runtime. Pointers and classes are validated before reading Swift enum memory, to avoid crashes.
- **Batch download**: reads every item from the carousel cell's data model (`BCNFeedMediaViewModel` → `IGPhoto` / `IGVideo`), unaffected by cell reuse.
- **Original-size photos / profile pictures**: fetches `https://www.threads.com/t/<code>` or `/@<username>` and picks the largest candidate from the page JSON by matching file names.
- **Clipboard**: first checks for a URL with `detectPatternsForPatterns:` (no paste prompt); the content is only read when you tap Open or use Auto-open. The link is handed to Threads through `NSUserActivity` (BrowsingWeb).
- **Account switching**: hooks `IGAccountSwitcher` and checks the clipboard 1.5 s after the last switch event; 0.8 s after returning from another app.
- **Keep Feed Position**: passes 0 seconds to `applicationWillWarmStartWithTimeIntervalSinceBackgrounded:` (home feed and `BCNAppViewController`), sets the feed's `lastBgTime` to now before it comes to the foreground, and raises the server thresholds in `IGFeedRefreshInstructionsStore` to the keep time.
- **Pull to refresh**: in the home feed's `scrollViewDidScroll:`, the offset is kept from going past the top while dragging, so the refresh control never triggers.
- **Home tab**: with the new tab bar (`BCNLucentTabBarCoordinator`), re-selecting the same tab first checks whether the feed is at the top, then decides whether Threads gets to handle the tap (`tabBarController:shouldSelectTab:`, `didSelectTab:previousTab:`, `handleTabBarDoubleTap:`). The legacy tab bar (`BCNLegacyTabBarController`) decides in Swift where it can't be intercepted, so the tap time is recorded and upward scrolls / refreshes of the feed are blocked for 1 s. These fallback hooks are only installed the first time the legacy tab bar is tapped.
- **Keep Tab Bar Visible**: keeps `scrollViewDidScroll:` / `scrollViewDidEndScrolling:` from reaching `BCNLucentTabBarCoordinator`, and sets iOS 26's `tabBarMinimizeBehavior` to never.
- **Sideload Compatibility Fix**: on load, stores a probe item in the keychain and reads back the access group the system actually assigned. It only activates when the Team ID isn't Meta's (`MH9GU9K5PX`). It rewrites `SecItemAdd` / `CopyMatching` / `Update` / `Delete` in the symbol pointer tables of the app's own images (main executable and `Frameworks/`) to swap Threads' access groups for the usable one, and falls back to `Library/ThreadsPulseAppGroups/<group>` when `containerURLForSecurityApplicationGroupIdentifier:` returns nil. Threads doesn't use iCloud, so CloudKit isn't touched.
- **Copy Profile Info**: copies the name (`fullNameLabel`), username (`usernameLabel`, without `@`) or bio. Adds long-press gestures to the profile picture, `fullNameLabel`, `usernameLabel` and `IGProfileBioView` in `BCNProfileHeaderView`. The full bio comes from `_fullCollapsibleBioString` (when collapsed) or `_stringForView`. When the feature is off the gestures don't begin, so Threads' own long-press works as usual.
- **Hide Follow Suggestions**: intercepts `presentViewController:` when `BCNUserRecommendationsViewController` is presented as a sheet; pushed pages aren't affected.

## Notes

1. When Threads updates and renames a method, the matching hook silently stops working (no crash). Turn on Debug Hints to see which one.
2. This project doesn't include or distribute Threads itself or any Meta code.
3. Modifying the app and blocking ads may violate Threads' Terms of Service. Use at your own risk.
4. Downloaded content is for personal use only; please respect the original creators.

## Author

h4x_0x30vm · [Ko-fi](https://ko-fi.com/mumuisdog)

© 2026 h4x_0x30vm. All rights reserved.
