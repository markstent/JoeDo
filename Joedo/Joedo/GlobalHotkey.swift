import AppKit
import Carbon

// A system-wide keyboard shortcut — fires even when Joedo is in the
// background. Uses Carbon's RegisterEventHotKey, which is old but still
// the only sanctioned way to do this without Accessibility permissions.
final class GlobalHotkey {
    private var hotKeyRef: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let callback: () -> Void

    // Track every instance by its hotKeyID so the C trampoline can look up
    // the right Swift instance when the event fires.
    private static var registry: [UInt32: GlobalHotkey] = [:]
    private static var nextID: UInt32 = 1

    private let myID: UInt32

    /// - parameter keyCode: Virtual key code (e.g. kVK_ANSI_J from Carbon).
    /// - parameter modifiers: Carbon modifier flags (cmdKey / optionKey / etc).
    init(keyCode: UInt32, modifiers: UInt32, callback: @escaping () -> Void) {
        self.callback = callback
        self.myID = Self.nextID
        Self.nextID += 1
        Self.registry[myID] = self
        register(keyCode: keyCode, modifiers: modifiers)
    }

    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let h = handler { RemoveEventHandler(h) }
        Self.registry[myID] = nil
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if status == noErr, let instance = GlobalHotkey.registry[hotKeyID.id] {
                    DispatchQueue.main.async { instance.callback() }
                }
                return noErr
            },
            1,
            &eventSpec,
            nil,
            &handler
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x4A4F4544 /* 'JOED' */), id: myID)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
