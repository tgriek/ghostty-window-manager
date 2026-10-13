/// A display as seen by AppKit. Frames are in Cocoa coordinates
/// (origin bottom-left of the primary screen, y grows upward).
public struct ScreenInfo: Equatable, Sendable {
    public var name: String
    public var frame: Rect
    public var visibleFrame: Rect
    /// The menu-bar screen (`NSScreen.screens[0]`), not the key-window screen.
    public var isMain: Bool
    public var isBuiltin: Bool

    public init(name: String, frame: Rect, visibleFrame: Rect, isMain: Bool, isBuiltin: Bool) {
        self.name = name
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.isMain = isMain
        self.isBuiltin = isBuiltin
    }
}

public enum DisplayPreference: Equatable, Sendable, CustomStringConvertible {
    case widest
    case main
    /// 1-based position in `NSScreen.screens`.
    case index(Int)

    public static func parse(_ text: String) -> DisplayPreference? {
        switch text.lowercased() {
        case "widest": return .widest
        case "main": return .main
        default:
            guard !text.isEmpty, text.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let index = Int(text), index >= 1 else { return nil }
            return .index(index)
        }
    }

    public var description: String {
        switch self {
        case .widest: return "widest"
        case .main: return "main"
        case let .index(index): return String(index)
        }
    }
}

public struct ScreenChoice: Equatable, Sendable {
    public let screen: ScreenInfo
    public let notice: String?
}

public func pickScreen(_ screens: [ScreenInfo], _ preference: DisplayPreference) throws -> ScreenChoice {
    guard let first = screens.first else { throw GridError.noScreens }
    switch preference {
    case .widest:
        var widest = first
        for screen in screens.dropFirst() where screen.frame.width > widest.frame.width {
            widest = screen
        }
        let notice = screens.count == 1 && widest.isBuiltin
            ? "Only the built-in display (\(widest.name)) is attached; using it."
            : nil
        return ScreenChoice(screen: widest, notice: notice)
    case .main:
        return ScreenChoice(screen: screens.first(where: \.isMain) ?? first, notice: nil)
    case let .index(index):
        guard (1...screens.count).contains(index) else {
            throw GridError.noSuchDisplay(index: index, available: screens.count)
        }
        return ScreenChoice(screen: screens[index - 1], notice: nil)
    }
}

/// Height of the primary (menu-bar) screen — the pivot between Cocoa and AX coordinates.
public func primaryHeight(_ screens: [ScreenInfo]) -> Double {
    precondition(!screens.isEmpty, "primaryHeight needs at least one screen")
    return (screens.first(where: \.isMain) ?? screens[0]).frame.height
}

/// Cocoa (bottom-left origin, y up) → AX (top-left origin of the primary screen, y down).
public func cocoaToAX(_ rect: Rect, primaryHeight: Double) -> Rect {
    Rect(x: rect.x, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
}

public enum StripSide: Equatable, Sendable {
    case left, right
}

/// Space kept free for the Stage Manager strip, which macOS does not exclude from `visibleFrame`.
public struct StageStrip: Equatable, Sendable {
    public let width: Double
    public let side: StripSide

    public init(width: Double, side: StripSide) {
        self.width = width
        self.side = side
    }
}

/// The strip to reserve, or `nil` when Stage Manager is off, its strip auto-hides, or `width <= 0`.
/// The strip sits on the left unless the Dock is on the left, which pushes it to the right.
public func stageStrip(enabled: Bool, autoHide: Bool, dockOrientation: String?, width: Double) -> StageStrip? {
    guard enabled, !autoHide, width > 0 else { return nil }
    return StageStrip(width: width, side: dockOrientation == "left" ? .right : .left)
}

public func reservingStageStrip(_ area: Rect, _ strip: StageStrip) -> Rect {
    let width = min(max(strip.width, 0), area.width)
    switch strip.side {
    case .left:
        return Rect(x: area.x + width, y: area.y, width: area.width - width, height: area.height)
    case .right:
        return Rect(x: area.x, y: area.y, width: area.width - width, height: area.height)
    }
}

/// The screen's `visibleFrame` (Cocoa coordinates), with its top trimmed so it starts at
/// least `menuBarHeight` below the screen's top edge. macOS keeps windows below the menu
/// bar on every display, but a secondary screen's `visibleFrame` can still include it.
/// Pass 0 when the menu bar auto-hides.
public func layoutFrame(of screen: ScreenInfo, menuBarHeight: Double) -> Rect {
    let visible = screen.visibleFrame
    let top = min(visible.maxY, screen.frame.maxY - menuBarHeight)
    return Rect(x: visible.x, y: visible.y, width: visible.width, height: max(0, top - visible.y))
}
