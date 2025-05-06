//
//  StickerImageRenderer.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/5/25.
//

import Foundation
import UIKit

/// A provider class for stickers that can be added to the route share
class StickersProvider {
    /// List of all available sticker IDs
    static let allStickers: [String] = [
        "medal_gold", "medal_silver", "medal_bronze",
        "trophy", "star", "heart",
        "thumbs_up", "fire", "lightning",
        "runner", "cyclist", "walker",
        "mountain", "tree", "sun",
        "water", "flag", "finish_line",
        "shoe", "clock", "stopwatch",
        "muscle", "sweat", "celebrate"
    ]
    
    /// Returns a UIImage for the requested sticker ID
    /// - Parameter id: The ID of the sticker to retrieve
    /// - Returns: A UIImage if found, nil otherwise
    static func getSticker(id: String) -> UIImage? {
        // In a real implementation, this would load from an asset catalog or similar
        // For this example, we'll generate simple placeholder images
        
        switch id {
        case "medal_gold":
            return createCircleSticker(color: UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0), text: "🥇")
        case "medal_silver":
            return createCircleSticker(color: UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0), text: "🥈")
        case "medal_bronze":
            return createCircleSticker(color: UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0), text: "🥉")
        case "trophy":
            return createCircleSticker(color: UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0), text: "🏆")
        case "star":
            return createCircleSticker(color: UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0), text: "⭐")
        case "heart":
            return createCircleSticker(color: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0), text: "❤️")
        case "thumbs_up":
            return createCircleSticker(color: UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0), text: "👍")
        case "fire":
            return createCircleSticker(color: UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0), text: "🔥")
        case "lightning":
            return createCircleSticker(color: UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0), text: "⚡")
        case "runner":
            return createCircleSticker(color: UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0), text: "🏃")
        case "cyclist":
            return createCircleSticker(color: UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0), text: "🚴")
        case "walker":
            return createCircleSticker(color: UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0), text: "🚶")
        case "mountain":
            return createCircleSticker(color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), text: "🏔️")
        case "tree":
            return createCircleSticker(color: UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0), text: "🌳")
        case "sun":
            return createCircleSticker(color: UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0), text: "☀️")
        case "water":
            return createCircleSticker(color: UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0), text: "💧")
        case "flag":
            return createCircleSticker(color: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0), text: "🚩")
        case "finish_line":
            return createCircleSticker(color: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), text: "🏁")
        case "shoe":
            return createCircleSticker(color: UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0), text: "👟")
        case "clock":
            return createCircleSticker(color: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0), text: "🕒")
        case "stopwatch":
            return createCircleSticker(color: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0), text: "⏱️")
        case "muscle":
            return createCircleSticker(color: UIColor(red: 0.8, green: 0.6, blue: 0.5, alpha: 1.0), text: "💪")
        case "sweat":
            return createCircleSticker(color: UIColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 1.0), text: "💦")
        case "celebrate":
            return createCircleSticker(color: UIColor(red: 0.9, green: 0.5, blue: 0.9, alpha: 1.0), text: "🎉")
        default:
            return createCircleSticker(color: UIColor.lightGray, text: "?")
        }
    }
    
    /// Creates a simple circular sticker with an emoji
    /// - Parameters:
    ///   - color: The background color for the sticker
    ///   - text: The emoji or text to display
    /// - Returns: A rendered UIImage
    private static func createCircleSticker(color: UIColor, text: String) -> UIImage {
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background circle
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fillEllipse(in: rect.insetBy(dx: 5, dy: 5))
            
            // Draw white border
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(6)
            context.cgContext.strokeEllipse(in: rect.insetBy(dx: 8, dy: 8))
            
            // Draw emoji/text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60),
                .paragraphStyle: paragraphStyle
            ]
            
            let textRect = rect.insetBy(dx: 10, dy: 10)
            (text as NSString).draw(in: CGRect(
                x: textRect.origin.x,
                y: textRect.origin.y + (textRect.height - 70) / 2,
                width: textRect.width,
                height: 70
            ), withAttributes: attributes)
        }
    }
}
