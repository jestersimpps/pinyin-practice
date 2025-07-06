//
//  cleanpinyinApp.swift
//  cleanpinyin
//
//  Created by jestersimpps on 6/12/25.
//

import SwiftUI

@main
struct cleanpinyinApp: App {
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            SetupView()
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch preferredColorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
