import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

@main
struct YurakabeApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var window: NSWindow?
    private var buttons: [NSButton] = []
    private var importButton: NSButton?
    private var statusLabel: NSTextField?
    private let menu = NSMenu()
    private let modes = [("everywhere", "Desktop + lock screen"), ("lockOnly", "Lock screen only"), ("still", "Solid color only")]
    private let documents = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Containers/io.github.soynyuu.yurakabe.extension/Data/Documents", isDirectory: true)
    private var selectedMode: String {
        guard let data = try? Data(contentsOf: documents.appendingPathComponent("playback-mode.json")),
              let mode = try? JSONDecoder().decode(String.self, from: data), modes.contains(where: { $0.0 == mode }) else { return "lockOnly" }
        return mode
    }

    func applicationDidFinishLaunching(_: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "play.rectangle", accessibilityDescription: "Yurakabe")
        item.button?.toolTip = "ゆらかべ · Yurakabe"
        item.menu = menu
        menu.delegate = self
        statusItem = item
        refresh()
        showSettings()
    }

    func application(_: NSApplication, open urls: [URL]) {
        showSettings()
        if urls.contains(where: { $0.scheme == "yurakabe" && $0.host == "add-video" }) { addVideo() }
    }

    func menuWillOpen(_: NSMenu) { refresh() }
    private func refresh() {
        menu.removeAllItems()
        menu.addItem(NSMenuItem(title: "ゆらかべ · Yurakabe", action: nil, keyEquivalent: ""))
        for (index, mode) in modes.enumerated() {
            let item = NSMenuItem(title: mode.1, action: #selector(selectMenuMode(_:)), keyEquivalent: "")
            item.tag = index; item.target = self; item.state = selectedMode == mode.0 ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())
        for (title, action, key) in [("Settings…", #selector(showSettings), ","), ("Add Video…", #selector(addVideo), "o"),
                                     ("Open Wallpaper Settings…", #selector(openWallpaperSettings), ""),
                                     ("Show Menu at Login", #selector(toggleStartup), ""),
                                     ("Quit Menu (wallpaper continues)", #selector(quit), "q")] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.target = self
            if action == #selector(toggleStartup) { item.state = SMAppService.mainApp.status == .enabled ? .on : .off }
            menu.addItem(item)
        }
        for button in buttons { button.state = modes[button.tag].0 == selectedMode ? .on : .off }
    }

    private func save<T: Encodable>(_ value: T, filename: String) {
        do {
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            try JSONEncoder().encode(value).write(to: documents.appendingPathComponent(filename), options: .atomic)
            notify("prefsChanged")
            refresh()
        } catch { NSAlert(error: error).runModal() }
    }
    private func notify(_ event: String) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(("io.github.soynyuu.yurakabe." + event) as CFString), nil, nil, true)
    }
    @objc private func selectMenuMode(_ sender: NSMenuItem) { save(modes[sender.tag].0, filename: "playback-mode.json") }
    @objc private func selectButtonMode(_ sender: NSButton) { save(modes[sender.tag].0, filename: "playback-mode.json") }
    @objc private func changeColor(_ sender: NSColorWell) {
        guard let color = sender.color.usingColorSpace(.sRGB) else { return }
        save([Double(color.redComponent), Double(color.greenComponent), Double(color.blueComponent)], filename: "desktop-color.json")
    }
    @objc private func toggleStartup() {
        Task {
            do {
                if SMAppService.mainApp.status == .enabled { try await SMAppService.mainApp.unregister() }
                else { try SMAppService.mainApp.register() }
                refresh()
            } catch { NSAlert(error: error).runModal() }
        }
    }
    @objc private func openWallpaperSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension")!)
    }
    @objc private func addVideo() {
        guard importButton?.isEnabled != false else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let source = panel.url else { return }
        importButton?.isEnabled = false
        statusLabel?.stringValue = "Importing… The full video is copied locally."
        Task {
            defer { importButton?.isEnabled = true }
            do {
                let entry = try await LibraryStore(documents: documents).importVideo(from: source)
                notify("libraryChanged")
                statusLabel?.stringValue = "Added \(entry.name). Select it under Yurakabe in Wallpaper Settings."
            } catch {
                statusLabel?.stringValue = "Import failed. Your existing videos are unchanged."
                NSAlert(error: error).runModal()
            }
        }
    }
    @objc private func showSettings() {
        if window == nil {
            let view = NSStackView()
            view.orientation = .vertical; view.alignment = .leading; view.spacing = 14
            view.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
            let heading = NSTextField(labelWithString: "ゆらかべ · Yurakabe")
            heading.font = .boldSystemFont(ofSize: 22)
            view.addArrangedSubview(heading)
            let note = NSTextField(wrappingLabelWithString: "Bring your own video. Choose where it moves.\nSilent playback. Full frame, with black bars when needed.")
            note.textColor = .secondaryLabelColor
            view.addArrangedSubview(note)
            for (index, mode) in modes.enumerated() {
                let button = NSButton(radioButtonWithTitle: mode.1, target: self, action: #selector(selectButtonMode(_:)))
                button.tag = index; buttons.append(button); view.addArrangedSubview(button)
            }
            let color = NSColorWell()
            color.color = NSColor(srgbRed: 35/255, green: 35/255, blue: 35/255, alpha: 1)
            if let data = try? Data(contentsOf: documents.appendingPathComponent("desktop-color.json")),
               let rgb = try? JSONDecoder().decode([Double].self, from: data), rgb.count == 3 {
                color.color = NSColor(srgbRed: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
            }
            color.target = self; color.action = #selector(changeColor(_:))
            let row = NSStackView(views: [NSTextField(labelWithString: "Static background"), color])
            row.spacing = 12; view.addArrangedSubview(row)
            let add = NSButton(title: "Add Video…", target: self, action: #selector(addVideo))
            importButton = add
            view.addArrangedSubview(NSStackView(views: [add, NSButton(title: "Open Wallpaper Settings…", target: self, action: #selector(openWallpaperSettings))]))
            let status = NSTextField(wrappingLabelWithString: "Add a video, then select it in System Settings → Wallpaper → Yurakabe. Keep your existing screen saver selected separately.")
            status.textColor = .secondaryLabelColor; status.font = .systemFont(ofSize: 12)
            status.widthAnchor.constraint(lessThanOrEqualToConstant: 442).isActive = true
            statusLabel = status; view.addArrangedSubview(status)
            let result = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 490, height: 370), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            result.title = "Yurakabe"; result.isReleasedWhenClosed = false
            result.contentView = view; result.center(); window = result
        }
        refresh(); window?.makeKeyAndOrderFront(nil); NSApp.activate()
    }
    @objc private func quit() { NSApp.terminate(nil) }
}
