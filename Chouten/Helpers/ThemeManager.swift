//
//  ThemeManager.swift
//  Architecture
//
//  Created by Inumaki on 22.06.24.
//

import UIKit

 struct ThemeColor {
     var light: UIColor
     var dark: UIColor

     init(light: UIColor, dark: UIColor) {
        self.light = light
        self.dark = dark
    }
}

 enum ThemeColorEnum {
    case bg
    case container
    case overlay
    case fg
    case border
    case accent
}

 class ThemeManager {
     static let shared = ThemeManager()

     var bg: ThemeColor
     var container: ThemeColor
     var overlay: ThemeColor
     var fg: ThemeColor
     var border: ThemeColor
     var accent: Int

     let accentColors: [UIColor] = [
        .systemIndigo, .systemRed, .systemGreen, .systemBlue, .systemYellow, .systemOrange
    ]

     let accentColorNames: [String] = [
        "Indigo", "Red", "Green", "Blue", "Yellow", "Orange"
    ]

    private init() {
        // Default theme
        self.bg = ThemeColor(
            light: UIColor(hex: "#EFEFEF"),
            dark: UIColor(hex: "#0c0c0c")
        )
        self.container = ThemeColor(
            light: UIColor(hex: "#FFFFFF"),
            dark: UIColor(hex: "#171717")
        )
        self.overlay = ThemeColor(
            light: UIColor(hex: "#E4E4E4"),
            dark: UIColor(hex: "#272727")
        )
        self.fg = ThemeColor(
            light: UIColor(hex: "#0c0c0c"),
            dark: UIColor(hex: "#d4d4d4")
        )
        self.border = ThemeColor(
            light: UIColor(hex: "#BBBBBB"),
            dark: UIColor(hex: "#3B3B3B")
        )
        self.accent = 0
    }

     func getColor(for type: ThemeColorEnum, light: Bool? = nil) -> UIColor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first

        let currentStyle = window?.overrideUserInterfaceStyle // UIScreen.main.traitCollection.userInterfaceStyle
        switch type {
        case .bg:
            if let light {
                return light ? bg.light : bg.dark
            }
            return currentStyle == .light ? bg.light : bg.dark
        case .container:
            if let light {
                return light ? container.light : container.dark
            }
            return currentStyle == .light ? container.light : container.dark
        case .overlay:
            if let light {
                return light ? overlay.light : overlay.dark
            }
            return currentStyle == .light ? overlay.light : overlay.dark
        case .fg:
            if let light {
                return light ? fg.light : fg.dark
            }
            return currentStyle == .light ? fg.light : fg.dark
        case .border:
            if let light {
                return light ? border.light : border.dark
            }
            return currentStyle == .light ? border.light : border.dark
        case .accent:
            return accentColors[accent]
        }
    }

    // swiftlint:disable function_parameter_count
    func applyTheme(bg: ThemeColor, container: ThemeColor, overlay: ThemeColor, fg: ThemeColor, border: ThemeColor, accent: Int) {
        self.bg = bg
        self.container = container
        self.overlay = overlay
        self.fg = fg
        self.border = border
        self.accent = accent

        // Notify the app that the theme has changed
        NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
    }
    // swiftlint:enable function_parameter_count

    func applyTheme(fromFile path: String) { }
}