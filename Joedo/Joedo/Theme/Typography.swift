import SwiftUI

enum Typography {
    static func row(_ size: CGFloat = 20) -> Font {
        .custom("Poppins-Bold", size: size)
    }

    static func title(_ size: CGFloat = 18) -> Font {
        .custom("Poppins-SemiBold", size: size)
    }
}
