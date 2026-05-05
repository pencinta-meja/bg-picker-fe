//
//  HapticManager.swift
//  bg-picker
//
//  Created by Danniel on 05/05/26.
//

import CoreHaptics
import UIKit

final class HapticManager {
    
    static let shared = HapticManager()
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    func success() {
        notification(.success)
    }
    
    func warning() {
        notification(.warning)
    }
    
    func error() {
        notification(.error)
    }
    
    func light() {
        impact(.light)
    }
    
    func medium() {
        impact(.medium)
    }
    
    func heavy() {
        impact(.heavy)
    }
    
    func soft() {
        impact(.soft)
    }
    
    func rigid() {
        impact(.rigid)
    }
}
