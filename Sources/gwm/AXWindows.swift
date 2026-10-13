import AppKit
import ApplicationServices
import GridCore

enum Accessibility {
    /// Prompts for Accessibility permission (once) and fails if it isn't granted.
    static func requireTrust() throws {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else { throw GwmError.accessibilityDenied }
    }
}

struct AXWindow: Hashable {
    let element: AXUIElement

    static func == (lhs: AXWindow, rhs: AXWindow) -> Bool { CFEqual(lhs.element, rhs.element) }
    func hash(into hasher: inout Hasher) { hasher.combine(CFHash(element)) }

    var title: String {
        let title = attribute(kAXTitleAttribute) as? String ?? ""
        return title.isEmpty ? "(untitled)" : title
    }

    /// Standard window, not minimized, not in native fullscreen.
    var isTileable: Bool {
        attribute(kAXSubroleAttribute) as? String == kAXStandardWindowSubrole
            && attribute(kAXMinimizedAttribute) as? Bool != true
            && attribute("AXFullScreen") as? Bool != true
    }

    /// Current frame in AX coordinates.
    var frame: Rect? {
        guard let origin = point(kAXPositionAttribute), let size = size(kAXSizeAttribute) else { return nil }
        return Rect(x: Double(origin.x), y: Double(origin.y), width: Double(size.width), height: Double(size.height))
    }

    /// Position → size → position (a resize can be clamped by the display the window
    /// is still on), then returns the frame the window actually ended up with.
    @discardableResult
    func apply(_ rect: Rect) -> Rect? {
        let origin = CGPoint(x: rect.x, y: rect.y)
        set(kAXPositionAttribute, origin, type: .cgPoint)
        set(kAXSizeAttribute, CGSize(width: rect.width, height: rect.height), type: .cgSize)
        set(kAXPositionAttribute, origin, type: .cgPoint)
        return frame
    }

    func close() {
        guard let button = attribute(kAXCloseButtonAttribute), CFGetTypeID(button) == AXUIElementGetTypeID() else { return }
        AXUIElementPerformAction(button as! AXUIElement, kAXPressAction as CFString)
    }

    private func attribute(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func axValue(_ name: String) -> AXValue? {
        guard let value = attribute(name), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue)
    }

    private func point(_ name: String) -> CGPoint? {
        var point = CGPoint.zero
        guard let value = axValue(name), AXValueGetValue(value, .cgPoint, &point) else { return nil }
        return point
    }

    private func size(_ name: String) -> CGSize? {
        var size = CGSize.zero
        guard let value = axValue(name), AXValueGetValue(value, .cgSize, &size) else { return nil }
        return size
    }

    private func set<T: BitwiseCopyable>(_ name: String, _ value: T, type: AXValueType) {
        var value = value
        guard let axValue = AXValueCreate(type, &value) else { return }
        AXUIElementSetAttributeValue(element, name as CFString, axValue)
    }
}

struct GhosttyApp {
    let pid: pid_t
    let element: AXUIElement

    init(pid: pid_t) {
        self.pid = pid
        self.element = AXUIElementCreateApplication(pid)
    }

    static func running() -> GhosttyApp? {
        NSRunningApplication.runningApplications(withBundleIdentifier: GhosttyScript.bundleID)
            .first { !$0.isTerminated }
            .map { GhosttyApp(pid: $0.processIdentifier) }
    }

    /// Ghostty's tileable windows (see `AXWindow.isTileable`).
    func windows() -> [AXWindow] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &value) == .success,
              let elements = value as? [AXUIElement] else { return [] }
        return elements.map(AXWindow.init).filter(\.isTileable)
    }
}

/// Moves `window` into `frame`; warns (and carries on) if Ghostty doesn't accept it.
func place(_ window: AXWindow, at frame: Rect) {
    let actual = window.apply(frame)
    if actual?.isClose(to: frame) != true {
        warn("Ghostty did not accept \(frame) for '\(window.title)' (got \(actual?.description ?? "unknown")).")
    }
}
