import Foundation

extension Timer {
    static func scheduleAutoCheck(
        after delay: TimeInterval,
        action: @escaping () -> Void
    ) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }
}