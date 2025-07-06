import SwiftUI

struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    let onHeightChange: (CGFloat) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                setupKeyboardObservers()
            }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: Constants.Animation.keyboardDuration)) {
                    keyboardHeight = keyboardFrame.height
                    onHeightChange(keyboardHeight)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: Constants.Animation.keyboardDuration)) {
                keyboardHeight = 0
                onHeightChange(0)
            }
        }
    }
}

extension View {
    func keyboardAware(onHeightChange: @escaping (CGFloat) -> Void) -> some View {
        modifier(KeyboardAwareModifier(onHeightChange: onHeightChange))
    }
}