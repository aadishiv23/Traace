//
//  SharingViewModel.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

// SharingViewModel.swift

import Combine
import HealthKit // For HKWorkoutActivityType
import MapKit // For MKMapType
import SwiftUI // For Color, Angle
import UIKit // For UIImage

@MainActor
class SharingViewModel: ObservableObject {

    // MARK: - Published Properties for UI State

    @Published var currentStep: SharingStep = .loadingInitialSnapshot
    @Published var route: RouteInfo // The route being shared
    @Published var baseMapImage: UIImage? // Snapshot with route and markers, no stats card
    @Published var imageWithStats: UIImage? // baseMapImage + stats overlay
    @Published var finalImageToShare: UIImage? // imageWithStats + decorations

    @Published var selectedLayout: StatLayoutPreset = .defaultCardBottom
    @Published var decorations: [DecorationModel] = []
    @Published var selectedDecorationID: DecorationModel.ID?

    @Published var isProcessing: Bool = false // For generic loading states
    @Published var showShareSheetView: Bool = false // Triggers the system share sheet
    @Published var mapTypeForSnapshot: MKMapType = .standard
    @Published var userMessage: String? // For displaying messages like "Loading...", "Error..."
    
    // Animation and user feedback properties
    @Published var transitionInProgress: Bool = false

    // State for Text Decoration Editor
    @Published var editingTextModel: DecorationModel? // Holds the text decoration being edited, or nil if new
    @Published var currentTextForEditor: String = ""
    @Published var currentTextColorForEditor: Color = .white
    @Published var currentTextFontNameForEditor: String = "HelveticaNeue-Bold" // Default font
    @Published var currentTextFontSizeForEditor: CGFloat = 30 // Default font size

    // MARK: - Private Properties

    private var routeColorTheme: RouteColorTheme
    private var cancellables = Set<AnyCancellable>()
    
    // Haptic feedback generators
    private let lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedbackGenerator = UINotificationFeedbackGenerator()

    // MARK: - Callbacks

    var dismissFlow: (() -> Void)? // Action to dismiss the entire sharing flow
    var onShareCompleted: (([Any]?, Bool) -> Void)?

    // MARK: - Initialization

    init(route: RouteInfo, routeColorTheme: RouteColorTheme, initialMapStyle: MapStyle) {
        self.route = route
        self.routeColorTheme = routeColorTheme
        self.mapTypeForSnapshot = .standard
        
        // Prepare haptic generators
        lightFeedbackGenerator.prepare()
        mediumFeedbackGenerator.prepare()
        successFeedbackGenerator.prepare()

        // Observe changes to selectedDecorationID to update text editor state
        $selectedDecorationID
            .combineLatest($decorations) // Also react if decorations array itself changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedID, decorationsList in
                guard let self else {
                    return
                }
                if let id = selectedID,
                   let deco = decorationsList.first(where: { $0.id == id }),
                   deco.type == .text
                {
                    // An existing text decoration is selected
                    self.editingTextModel = deco
                    self.currentTextForEditor = deco.content
                    self.currentTextColorForEditor = deco.color
                    self.currentTextFontNameForEditor = deco.fontName
                    self.currentTextFontSizeForEditor = deco.fontSize
                    
                    // Light haptic feedback when selecting a decoration
                    self.lightFeedbackGenerator.impactOccurred()
                } else {
                    // No decoration selected, or a non-text decoration is selected
                    self.editingTextModel = nil
                    // Optionally reset editor fields to defaults for a "new text" state if desired,
                    // but prepareTextEditorForSelected() handles this better.
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Flow Control / Navigation

    func start() {
        currentStep = .loadingInitialSnapshot
        isProcessing = true
        userMessage = "Generating route preview..."

        MapSnapshotGenerator.generateBaseShareImage(
            route: route,
            mapType: mapTypeForSnapshot,
            routeColorTheme: routeColorTheme
        ) { [weak self] image in
            guard let self else {
                return
            }
            // Ensure updates are on main thread if completion isn't already
            DispatchQueue.main.async {
                self.baseMapImage = image
                self.isProcessing = false
                self.userMessage = nil
                if image != nil {
                    // Subtle success haptic feedback
                    self.successFeedbackGenerator.notificationOccurred(.success)
                    
                    self.currentStep = .previewInitial
                    // Pre-render image with default stats layout for faster "Share Default" or initial view
                    self.renderAndSetImageWithStats(layout: self.selectedLayout)
                } else {
                    self.userMessage = "Failed to generate map preview. Please try again."
                    // Error haptic feedback
                    self.successFeedbackGenerator.notificationOccurred(.error)
                    // Optionally auto-dismiss or provide a dismiss button
                }
            }
        }
    }

    func goToLayoutCustomization() {
        guard baseMapImage != nil else {
            userMessage = "Base map image not ready."
            successFeedbackGenerator.notificationOccurred(.error)
            return
        }
        
        // Ensure we don't trigger multiple transitions
        guard !transitionInProgress else { return }
        transitionInProgress = true
        
        // Medium haptic feedback for navigation
        mediumFeedbackGenerator.impactOccurred()
        
        // Add a short delay to allow animations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.currentStep = .layoutCustomization
            if self.imageWithStats == nil { // If not already rendered (e.g. from .previewInitial)
                self.renderAndSetImageWithStats(layout: self.selectedLayout)
            }
            
            // Reset transition flag after a delay to match animation timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transitionInProgress = false
            }
        }
    }

    func goToDecoration() {
        guard imageWithStats != nil else {
            userMessage = "Styled image not ready. Applying style first..."
            renderAndSetImageWithStats(layout: selectedLayout) { [weak self] success in
                if success {
                    self?.currentStep = .decoration
                } else {
                    self?.userMessage = "Error preparing image for decoration."
                    self?.successFeedbackGenerator.notificationOccurred(.error)
                }
            }
            return
        }
        
        // Ensure we don't trigger multiple transitions
        guard !transitionInProgress else { return }
        transitionInProgress = true
        
        // Medium haptic feedback for navigation
        mediumFeedbackGenerator.impactOccurred()
        
        // Add a short delay to allow animations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.currentStep = .decoration
            
            // Reset transition flag after a delay to match animation timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transitionInProgress = false
            }
        }
    }

    func goBack() {
        // Ensure we don't trigger multiple transitions
        guard !transitionInProgress else { return }
        transitionInProgress = true
        
        // Light haptic feedback for back navigation
        lightFeedbackGenerator.impactOccurred()
        
        // Clear selection when going back from decoration step to avoid stale state
        if currentStep == .decoration {
            selectedDecorationID = nil
        }

        // Add a short delay to allow animations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            switch self.currentStep {
            case .decoration:
                self.currentStep = .layoutCustomization
            case .layoutCustomization:
                self.currentStep = .previewInitial
            case .previewInitial, .loadingInitialSnapshot:
                self.dismissFlow?() // Dismiss the entire sharing UI
            }
            
            // Reset transition flag after a delay to match animation timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transitionInProgress = false
            }
        }
    }

    func updateMapType(_ newMapType: MKMapType) {
        guard mapTypeForSnapshot != newMapType else {
            return
        }
        
        // Medium haptic feedback for map type change
        mediumFeedbackGenerator.impactOccurred()
        
        mapTypeForSnapshot = newMapType
        // Regenerate base image and subsequent images
        baseMapImage = nil
        imageWithStats = nil
        finalImageToShare = nil
        // Reset decorations as image context changes significantly. User might want to keep them,
        // but positions and appearance relative to map features would be off.
        // Consider asking user if they want to try to keep decorations. For now, reset.
        decorations.removeAll()
        selectedDecorationID = nil

        start() // Restart the process with the new map type
    }

    // MARK: - Image Generation Logic

    private func renderImageWithStats(layout: StatLayoutPreset, completion: @escaping (UIImage?) -> Void) {
        guard let base = baseMapImage else {
            completion(nil)
            return
        }
        isProcessing = true
        userMessage = "Applying style..."

        // The StatOverlayView needs the routeColorTheme
        let statsOverlay = StatOverlayView(
            route: route,
            layout: layout,
            routeColorTheme: routeColorTheme // Pass the theme here
        )

        Task { // Swift Concurrency for image rendering
            let renderedImage = await ImageRenderer.renderAndComposite(
                baseImage: base,
                overlayView: AnyView(statsOverlay), // AnyView to type-erase
                overlaySize: base.size // Overlay should match base image size
            )
            DispatchQueue.main.async { // Update UI on main thread
                self.isProcessing = false
                self.userMessage = nil
                completion(renderedImage)
            }
        }
    }

    func renderAndSetImageWithStats(layout: StatLayoutPreset, completion: ((Bool) -> Void)? = nil) {
        selectedLayout = layout // Update selected layout
        renderImageWithStats(layout: layout) { [weak self] image in
            self?.imageWithStats = image
            completion?(image != nil) // Report success/failure
        }
    }

    func renderFinalImage(completion: @escaping (UIImage?) -> Void) {
        guard let baseWithStats = imageWithStats else {
            userMessage = "Styled image not available. Rendering first..."
            renderAndSetImageWithStats(layout: selectedLayout) { [weak self] success in
                guard let self, success, let newBaseWithStats = imageWithStats else {
                    self?.userMessage = "Failed to prepare base for final image."
                    completion(nil)
                    return
                }
                actuallyRenderFinalImage(baseWithStats: newBaseWithStats, completion: completion)
            }
            return
        }
        actuallyRenderFinalImage(baseWithStats: baseWithStats, completion: completion)
    }

    private func actuallyRenderFinalImage(baseWithStats: UIImage, completion: @escaping (UIImage?) -> Void) {
        isProcessing = true
        userMessage = "Finalizing image..."

        let decorationsOverlay = DecorationsOverlayView(
            baseImageSize: baseWithStats.size
        )
        // Note: If DecorationsOverlayView relies on @EnvironmentObject VM, ensure it's set up correctly,
        // or pass necessary data directly. For rendering, it just needs decorations and size.

        Task {
            // 2. Pass the view to the ImageRenderer, ensuring that the `viewModel` (self)
            //    is injected as an environment object for this rendering instance.
            let finalImg = await ImageRenderer.renderAndComposite(
                baseImage: baseWithStats,
                overlayView: AnyView(decorationsOverlay.environmentObject(self)), // <<< CORRECTED LINE
                overlaySize: baseWithStats.size
            )

            DispatchQueue.main.async {
                self.isProcessing = false
                self.userMessage = nil
                self.finalImageToShare = finalImg // Store the final image
                completion(finalImg)
            }
        }
    }

    // MARK: - Sharing Actions

    func shareDefault() {
        // Ensure we have an image to share
        guard let image = imageWithStats ?? baseMapImage else {
            userMessage = "No image available to share."
            successFeedbackGenerator.notificationOccurred(.error)
            return
        }
        
        // Success haptic feedback for sharing
        successFeedbackGenerator.notificationOccurred(.success)
        
        // Set the final image to share
        finalImageToShare = image
        
        // Show the share sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showShareSheetView = true
        }
    }
    
    func shareCurrentLayout() { // Shares baseMapImage + current stat layout (no decorations)
        guard imageWithStats != nil else {
            userMessage = "Styled image not ready. Applying style first..."
            renderAndSetImageWithStats(layout: selectedLayout) { [weak self] success in
                guard let self, success, let image = imageWithStats else {
                    self?.userMessage = "Failed to prepare image with current style."
                    self?.successFeedbackGenerator.notificationOccurred(.error)
                    return
                }
                
                // Success haptic feedback
                self.successFeedbackGenerator.notificationOccurred(.success)
                
                finalImageToShare = image
                
                // Show the share sheet with a slight delay for animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showShareSheetView = true
                }
            }
            return
        }
        
        // Success haptic feedback
        successFeedbackGenerator.notificationOccurred(.success)
        
        finalImageToShare = imageWithStats
        
        // Show the share sheet with a slight delay for animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showShareSheetView = true
        }
    }
 
    func shareDecoratedImage() { // Renders with decorations and then shares
        renderFinalImage { [weak self] image in
            if image != nil { // finalImageToShare is already set by renderFinalImage
                // Success haptic feedback
                self?.successFeedbackGenerator.notificationOccurred(.success)
                
                // Show the share sheet with a slight delay for animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.showShareSheetView = true
                }
            } else {
                self?.userMessage = "Failed to create final decorated image."
                self?.successFeedbackGenerator.notificationOccurred(.error)
            }
        }
    }
    
    func shareCustomized() {
        // Ensure we have a customized image to share
        guard let image = finalImageToShare ?? imageWithStats ?? baseMapImage else {
            userMessage = "No image available to share."
            successFeedbackGenerator.notificationOccurred(.error)
            return
        }
        
        // Success haptic feedback for sharing
        successFeedbackGenerator.notificationOccurred(.success)
        
        // Show the share sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showShareSheetView = true
        }
    }

    // MARK: - Decoration Management

    func addDecoration(_ deco: DecorationModel) {
        var newDeco = deco
        // For new items, set them as selected to allow immediate interaction/editing.
        decorations.append(newDeco)
        selectedDecorationID = newDeco.id // Auto-select new decoration
    }

    /// This method is primarily for updates coming from DraggableResizableView gestures
    func updateDecorationProperties(_ deco: DecorationModel) {
        if let index = decorations.firstIndex(where: { $0.id == deco.id }) {
            decorations[index] = deco
        }
    }

    func deleteSelectedDecoration() {
        guard let selectedID = selectedDecorationID else {
            return
        }
        decorations.removeAll(where: { $0.id == selectedID })
        selectedDecorationID = nil // Deselect
    }

    func bringSelectedDecorationToFront() {
        guard let selectedID = selectedDecorationID,
              let index = decorations.firstIndex(where: { $0.id == selectedID })
        else {
            return
        }
        let deco = decorations.remove(at: index)
        decorations.append(deco) // Appending moves it to the end (drawn last/on top in ZStack)
    }

    func sendSelectedDecorationToBack() {
        guard let selectedID = selectedDecorationID,
              let index = decorations.firstIndex(where: { $0.id == selectedID })
        else {
            return
        }
        let deco = decorations.remove(at: index)
        decorations.insert(deco, at: 0) // Inserting at 0 moves it to the beginning (drawn first/bottom in ZStack)
    }

    // MARK: - Text Decoration Editor Specific Methods

    /// Call this when user intends to add new text or edit existing text
    func prepareTextEditorForSelected() {
        if let selectedID = selectedDecorationID,
           let deco = decorations.first(where: { $0.id == selectedID }),
           deco.type == .text
        {
            // Editing existing text decoration - state already updated by sink
            // editingTextModel, currentTextForEditor, etc. should be set.
        } else {
            // Preparing for a NEW text decoration
            editingTextModel = nil // Clear any previous editing model
            currentTextForEditor = ""
            currentTextColorForEditor = .white // Default color for new text
            currentTextFontNameForEditor = "HelveticaNeue-Bold" // Default font
            currentTextFontSizeForEditor = 30 // Default size
        }
    }

    /// Call this when user finishes text editing (e.g., taps "Done" in a sheet)
    func finalizeTextEditing() {
        // Trim whitespace for empty check and for the content itself
        let trimmedContent = currentTextForEditor.trimmingCharacters(in: .whitespacesAndNewlines)

        if var modelToEdit = editingTextModel, // Is there an existing text model being edited?
           let index = decorations.firstIndex(where: { $0.id == modelToEdit.id })
        {
            // Update existing decoration
            if trimmedContent.isEmpty { // If user cleared text, delete the decoration
                deleteSelectedDecoration() // This will also clear editingTextModel via sink
            } else {
                decorations[index].content = trimmedContent
                decorations[index].color = currentTextColorForEditor
                decorations[index].fontName = currentTextFontNameForEditor
                decorations[index].fontSize = currentTextFontSizeForEditor
                editingTextModel = decorations[index] // Ensure editingTextModel refers to the updated one
            }
        } else if !trimmedContent.isEmpty {
            // Add new decoration (because editingTextModel was nil and content is not empty)
            var newDeco = DecorationModel(type: .text, content: trimmedContent)
            newDeco.color = currentTextColorForEditor
            newDeco.fontName = currentTextFontNameForEditor
            newDeco.fontSize = currentTextFontSizeForEditor
            // newDeco.position will be default center, user can move it after adding
            addDecoration(newDeco) // This will also select the new decoration
        }
        // No need to explicitly clear editor fields like currentTextForEditor here,
        // as prepareTextEditorForSelected() or the sink on selectedDecorationID will handle it.
    }
}
