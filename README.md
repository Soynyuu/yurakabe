# ゆらかべ · Yurakabe

**Your wallpaper, with a little movement.**

A small, free and open-source macOS app for silent video wallpapers. Choose motion on your desktop and lock screen, on the lock screen alone, or switch to a solid color.

[日本語](README.ja.md) · [MIT license](LICENSE) · [Upstream credits](THIRD_PARTY_NOTICES.md)

## Status

**Experimental, source release.** Targets macOS 26 and later; developed with Xcode 26.6 on Apple silicon / macOS 27. This uses Apple's **private WallpaperExtensionKit interfaces**, inherited from [Phosphene](https://github.com/kageroumado/phosphene). An OS update can break it. This is not an Apple-supported wallpaper API, and the app is not notarized.

The original prototype's actual lock-screen video playback and return to a solid desktop were confirmed manually. The generalized build has automated policy, geometry, loop-position and synthetic-video import tests. Sleep/wake, repeated lock/unlock, and the final framing change still need end-to-end visual verification. Do not interpret a successful build as proof of compatibility with every macOS version or display.

## What it does

| Mode | Unlocked desktop | Lock screen |
| --- | --- | --- |
| Desktop + lock screen | Video | Video |
| Lock screen only | Solid color | Video |
| Solid color only | Solid color | Solid color |

- Import your own H.264 or HEVC MOV / MP4 video. The complete file is copied; no 30-second limit or re-encoding.
- The rendering pipeline reads only video tracks. Audio is never played.
- Fit the entire frame with black bars instead of cropping it. There is currently no fill/crop mode.
- Choose the solid background color. “Static” currently means a solid color, not an arbitrary image.
- A menu-bar companion changes preferences; macOS hosts the wallpaper extension. Quitting the menu does not stop the wallpaper.
- Login startup is opt-in. No updater, analytics, accounts, downloads, or third-party package dependencies.

The app does not change your screen-saver selection or write the system wallpaper catalog. Activation is an explicit selection in System Settings. macOS may offer to pair a wallpaper with a screen saver; keep your existing screen saver selected if you want to preserve it.

## Build and try

Requirements: a Mac running macOS 26+, full Xcode 26.6 or later selected as the developer directory, and Git. Command Line Tools alone are insufficient.

```sh
git clone https://github.com/Soynyuu/yurakabe.git
cd yurakabe
./scripts/test.sh
./scripts/build.sh
```

The script creates `build/Build/Products/Release/Yurakabe.app`, signs it locally with an ad-hoc signature, and verifies that signature. It does **not** install or activate the wallpaper, disable Gatekeeper, or change system security settings. This local signature is not Developer ID signing or notarization; downloaded copies can be blocked by Gatekeeper. Build from source for now.

1. Copy the built app to `/Applications` using Finder, then open it.
2. Click **Add Video…** and choose a local video. Allow the copy to finish.
3. Click **Open Wallpaper Settings…**. Find **Yurakabe**, and select the imported video. If the section is absent, close and reopen System Settings; check **General → Login Items & Extensions** for the wallpaper extension if needed.
4. In Yurakabe, choose a playback mode and static background color. The mode applies to all displays/Spaces using this provider; choose the wallpaper for each display/Space as needed in System Settings.
5. Test a real lock with Control–Command–Q, unlock, and check both results. Screen Saver preview is not a lock-screen test.

Import currently rejects rotation metadata and codecs other than H.264/HEVC. Export rotated phone footage with the orientation baked into the pixels first. Use square-pixel SDR video for the first test; HDR color reproduction and unusual aspect-ratio metadata are not validated. Protected/DRM media is unsupported. No videos are bundled or downloaded by the app.

## Stop and remove

1. In **System Settings → Wallpaper**, choose your previous wallpaper or color on every display/Space where Yurakabe is selected. This stops using the extension and restores normal system behavior.
2. Check **Screen Saver** and reselect your preferred screen saver if you manually changed it during setup.
3. Turn off **Show Menu at Login**, quit Yurakabe, and move the app to Trash.
4. Optionally remove only `~/Library/Containers/io.github.soynyuu.yurakabe.extension` after quitting. This deletes Yurakabe's imported copies, thumbnails and preferences, not your source video files.

Remember or screenshot your previous wallpaper choices before activating. The app does not capture or automatically restore your old wallpaper, and never replaces the system's entire configuration from a backup.

To remove one imported video, use its removable tile in Wallpaper Settings. Select a different wallpaper before deleting a currently used video. **Manage Library** in the tile context menu opens Yurakabe's companion window.

## Performance and privacy

Video decoding uses CPU/GPU resources and power. Cost depends on resolution, frame rate, codec, and number of displays. Lock-only mode pauses desktop playback and releases readers after a short delay; the extension can remain resident. There is no promise of zero performance impact. Start with 1080p / 30 fps and use static mode when battery life matters.

All imports, preferences and local diagnostic logs live in the extension's container, under `Data/Documents`. Imports take extra disk space. Logs rotate and may contain video names and paths; inspect and redact them before sharing an issue. The application has no telemetry or network client.

## Development

- `Yurakabe/`: menu, settings window and atomic video import.
- `YurakabeExtension/`: macOS wallpaper provider, playback pipeline and policy.
- `Tests/`: executable Swift contract tests, including a generated one-second video fixture.
- `scripts/`: reproducible local build and test commands.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the manual verification matrix and attribution expectations. CI builds and tests without installing or activating a wallpaper. No automated test unlocks the user's session.

## Credits

This is a derivative of **[Phosphene by kageroumado](https://github.com/kageroumado/phosphene)**, not an independently invented wallpaper engine. The extension, private-interface shims, and much of the renderer come from its MIT-licensed source. Yurakabe adds a focused companion, a lock-only/static mode policy, solid-color controls, explicit aspect fitting and local import flow. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the exact upstream revision.

“ゆらかべ” combines *yurayura* (gently moving) and *kabe* (wall). Licensed under MIT. Your media remains yours and is not covered by this source-code license.
