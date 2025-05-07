import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    var applicationActivities: [UIActivity]? = nil
    var completion: (([Any]?, Bool) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        
        if let excludedTypes = excludedActivityTypes {
            controller.excludedActivityTypes = excludedTypes
        }
        
        // Configure the completion handler
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            // Call the completion handler with the returned items and completion status
            completion?(returnedItems, completed)
        }
        
        // iPad configuration
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView() // Required for iPad
            popover.permittedArrowDirections = []
            popover.canOverlapSourceViewRect = true
        }
        
        // Set the UIActivityViewController's transition style for a more modern look
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .coverVertical
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Update configuration if needed
    }
}

// Convenience extension to exclude common activity types
extension ShareSheet {
    static func standard(items: [Any], completion: (([Any]?, Bool) -> Void)? = nil) -> ShareSheet {
        ShareSheet(
            items: items,
            excludedActivityTypes: [
                .assignToContact,
                .addToReadingList,
                .openInIBooks,
                .saveToCameraRoll
            ],
            completion: completion
        )
    }
    
    static func socialShare(items: [Any], completion: (([Any]?, Bool) -> Void)? = nil) -> ShareSheet {
        // Optimized for social sharing (keeps primarily social sharing options)
        ShareSheet(
            items: items,
            excludedActivityTypes: [
                .assignToContact,
                .addToReadingList,
                .openInIBooks,
                .saveToCameraRoll,
                .print,
                .markupAsPDF
            ],
            completion: completion
        )
    }
}
