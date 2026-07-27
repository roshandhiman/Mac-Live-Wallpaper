import Cocoa
import AVKit
import AVFoundation
import UniformTypeIdentifiers

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var windows: [NSWindow] = []
    var players: [AVQueuePlayer] = []
    var loopers: [AVPlayerLooper] = []

    // Control window
    var controlWindow: NSWindow!
    var playPauseButton: NSButton!
    var selectVideoButton: NSButton!
    var quitButton: NSButton!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Setup control window
        setupControlWindow()

        // Auto start wallpaper with bundled video if available
        if let bundleURL = Bundle.main.url(forResource: "wallpaper", withExtension: "mp4") {
            setupWallpaper(url: bundleURL)
        }
    }

    // MARK: - Wallpaper Setup

    func setupWallpaper(url: URL) {
        // Clean old references
        windows.removeAll()
        players.removeAll()
        loopers.removeAll()

        for screen in NSScreen.screens {
            let frame = screen.frame

            // AVQueuePlayer + AVPlayerLooper for seamless loop
            let playerItem = AVPlayerItem(url: url)
            playerItem.preferredForwardBufferDuration = 5.0 // preload 5s
            let queuePlayer = AVQueuePlayer()
            let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

            // Player layer (lighter than AVPlayerView)
            let layer = AVPlayerLayer(player: queuePlayer)
            layer.frame = NSRect(origin: .zero, size: frame.size)
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.videoGravity = .resizeAspectFill

            let w = NSWindow(contentRect: frame,
                             styleMask: .borderless,
                             backing: .buffered,
                             defer: false)
            let contentView = NSView(frame: NSRect(origin: .zero, size: frame.size))
            contentView.wantsLayer = true
            contentView.layer?.addSublayer(layer)
            w.contentView = contentView

            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = false
            w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
            w.ignoresMouseEvents = true
            w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

            w.makeKeyAndOrderFront(nil)
            w.orderFrontRegardless()

            // Save references
            windows.append(w)
            players.append(queuePlayer)
            loopers.append(looper)

            // Start playback
            queuePlayer.play()
        }
    }

    // MARK: - Manual Video Selection

    func selectVideoManually() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .movie,                       // mp4, mov, m4v
            .mpeg,                        // mpg, mpeg
            UTType(filenameExtension: "mkv")! // mkv
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { [weak self] result in
            guard let self = self else { return }
            if result == .OK, let url = panel.url {
                self.setupWallpaper(url: url)
            }
        }
    }

    // MARK: - Control Window

    func setupControlWindow() {
        let width: CGFloat = 250
        let height: CGFloat = 130
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let rect = NSRect(x: 50, y: screenRect.height - height - 50, width: width, height: height)

        controlWindow = NSWindow(contentRect: rect,
                                 styleMask: [.titled, .closable, .miniaturizable],
                                 backing: .buffered,
                                 defer: false)

        controlWindow.title = "Live Wallpaper Control"
        controlWindow.level = .floating
        controlWindow.isReleasedWhenClosed = false

        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        controlWindow.contentView = content

        // Play/Pause button
        playPauseButton = NSButton(frame: NSRect(x: 20, y: 70, width: 210, height: 30))
        playPauseButton.title = "Pause"
        playPauseButton.target = self
        playPauseButton.action = #selector(playPauseTapped)
        content.addSubview(playPauseButton)

        // Select Video button
        selectVideoButton = NSButton(frame: NSRect(x: 20, y: 35, width: 210, height: 30))
        selectVideoButton.title = "Select Video"
        selectVideoButton.target = self
        selectVideoButton.action = #selector(selectVideoTapped)
        content.addSubview(selectVideoButton)

        // Quit button
        quitButton = NSButton(frame: NSRect(x: 20, y: 0, width: 210, height: 30))
        quitButton.title = "Quit App"
        quitButton.target = self
        quitButton.action = #selector(quitTapped)
        content.addSubview(quitButton)

        controlWindow.makeKeyAndOrderFront(nil)
    }

    // MARK: - Button Actions

    @objc func playPauseTapped() {
        if players.first?.timeControlStatus == .playing {
            players.forEach { $0.pause() }
            playPauseButton.title = "Play"
        } else {
            players.forEach { $0.play() }
            playPauseButton.title = "Pause"
        }
    }

    @objc func selectVideoTapped() {
        selectVideoManually()
    }

    @objc func quitTapped() {
        NSApp.terminate(nil)
    }

    // MARK: - Cleanup

    func applicationWillTerminate(_ aNotification: Notification) {
        windows.removeAll()
        players.removeAll()
        loopers.removeAll()
    }
}
