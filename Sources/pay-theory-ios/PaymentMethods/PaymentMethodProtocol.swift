//
//  PaymentMethodProtocol.swift
//  PayTheory
//
//  Created by Austin Zani on 8/9/24.
//

import SwiftUI

public protocol PaymentMethod: ObservableObject {
    var isVisible: Bool { get set }
    var isValid: Bool { get set }
}


struct VisibilityTracker<T: PaymentMethod>: ViewModifier {
    @ObservedObject var paymentMethod: T
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                paymentMethod.isVisible = true
            }
            .onDisappear {
                paymentMethod.isVisible = false
            }
    }
}

extension View {
    func trackVisibility<T: PaymentMethod>(_ paymentMethod: T) -> some View {
        self.modifier(VisibilityTracker(paymentMethod: paymentMethod))
    }
}
