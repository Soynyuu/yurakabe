# Contributing

Build with `./scripts/build.sh` and run `./scripts/test.sh`. Keep changes focused, preserve upstream MIT attribution, and include reproduction steps for behavior changes. Do not commit media, container preferences, wallpaper databases, personal paths or diagnostic logs.

## Manual release checks

These require a real Mac and a person who can unlock it. Record the OS build, hardware and display setup; do not mark unchecked steps as passed.

- Import H.264 and HEVC clips; verify complete duration and silent playback.
- Check all three modes and color changes on desktop and lock screen.
- Switch landscape and portrait clips, including multiple displays and scaled resolutions. All edges must remain visible with appropriate bars.
- Lock/unlock three times, sleep/wake once, and play across two loop boundaries. Pause after multiple loops and verify resumed motion.
- Quit/reopen the menu and verify preferences persist; verify login startup is opt-in.
- Verify the previously selected screen saver remains selected.
- Select a normal wallpaper before uninstalling; verify the normal desktop and lock screen return.

CI covers compilation and deterministic logic/import tests only. It cannot validate the private wallpaper host or real lock-screen composition.

## Architecture

The companion copies imports transactionally into a UUID folder in the extension container. A metadata file is the library contract. Darwin notifications prompt reloads; the macOS provider publishes tiles to Wallpaper Settings. Users activate tiles through the system UI. No wallpaper database patching or administrator helper is used.

The extension reads compressed video samples through AVFoundation and displays them through AVSampleBufferDisplayLayer. It never reads audio tracks. Mode preferences gate visibility and playback, and the solid overlay covers paused video in static modes. The initial release uses a shared mode across every display using this provider.
