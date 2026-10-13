import AppKit
import GridCore

enum Screens {
    /// All attached screens in `NSScreen.screens` order; index 0 is the menu-bar screen.
    static func current() -> [ScreenInfo] {
        NSScreen.screens.enumerated().map { index, screen in
            ScreenInfo(
                name: screen.localizedName,
                frame: Rect(screen.frame),
                visibleFrame: Rect(screen.visibleFrame),
                isMain: index == 0,
                isBuiltin: isBuiltin(screen)
            )
        }
    }

    private static func isBuiltin(_ screen: NSScreen) -> Bool {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return false
        }
        return CGDisplayIsBuiltin(number.uint32Value) != 0
    }
}

enum MenuBar {
    /// Height macOS keeps free for the menu bar on every screen; 0 when it auto-hides.
    static func height() -> Double {
        UserDefaults.standard.bool(forKey: "_HIHideMenuBar") ? 0 : Double(NSStatusBar.system.thickness)
    }
}

enum StageManager {
    /// The strip to keep free, read from the Stage Manager and Dock preferences.
    static func strip(width: Double) -> StageStrip? {
        let windowManager = UserDefaults(suiteName: "com.apple.WindowManager")
        return stageStrip(
            enabled: windowManager?.bool(forKey: "GloballyEnabled") ?? false,
            autoHide: windowManager?.bool(forKey: "AutoHide") ?? false,
            dockOrientation: UserDefaults(suiteName: "com.apple.dock")?.string(forKey: "orientation"),
            width: width
        )
    }
}

extension Rect {
    init(_ rect: CGRect) {
        self.init(x: Double(rect.origin.x), y: Double(rect.origin.y),
                  width: Double(rect.size.width), height: Double(rect.size.height))
    }
}
