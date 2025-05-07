//
//  DecorationStepView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

import Foundation
import SwiftUI
import PhotosUI

// DecorationStepView.swift
import SwiftUI
import PhotosUI

struct DecorationStepView: View {
    @EnvironmentObject var viewModel: SharingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var canvasScale: CGFloat = 0.95
    @State private var canvasOpacity: CGFloat = 0.0
    @State private var toolbarOpacity: CGFloat = 0.0
    
    // Sheet presentation states
    @State private var showTextEditorSheet = false
    @State private var showEmojiPickerSheet = false
    @State private var showStickerPickerSheet = false
    @State private var showPhotoPicker = false
    @State private var showCreativePack = false // New creative elements pack
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // Haptic generators
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let successHaptic = UINotificationFeedbackGenerator()

    // Theme colors
    private var highlightColor: Color { Color.accentColor }
    private var containerBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
    }

    // A collection of predefined stickers for quick access
    private let quickStickers = [
        "🏃‍♂️", "🚶‍♀️", "🚴‍♂️", "🏆", "🔥", "💪", "⭐️", "❤️", "👏", "🎉"
    ]
    
    // Creative sticker packs (new)
    private let creativeElements: [String: [String]] = [
        "Weather": ["☀️", "🌤", "⛅️", "🌦", "🌧", "⛈", "🌩", "🌨", "❄️", "🌬"],
        "Nature": ["🌳", "🌲", "🌴", "🌱", "🌿", "☘️", "🍀", "🌸", "🌺", "🌻"],
        "Locations": ["🏠", "🏙", "🌆", "🌃", "🌉", "🏞", "🌄", "🌅", "🏕", "⛰"],
        "Fitness": ["🏃‍♂️", "🚶‍♀️", "🚴‍♂️", "🎽", "👟", "⏱", "📊", "🥇", "🏅", "🥤"],
        "Motivation": ["🔥", "💪", "⭐️", "🏆", "🎯", "✅", "🚀", "💯", "👑", "🙌"]
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Canvas area with image and decorations
            canvasArea
                .scaleEffect(canvasScale)
                .opacity(canvasOpacity)
                .padding(.vertical, 12)
            
            // Quick sticker row for frequently used elements
            quickStickerRow
                .opacity(toolbarOpacity)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            // Selection toolbar (appears when a decoration is selected)
            if viewModel.selectedDecorationID != nil {
                selectedDecorationToolbar()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedDecorationID)
                    .opacity(toolbarOpacity)
            }

            // Main tool palette
            toolPalette()
                .opacity(toolbarOpacity)
            
            // Share button
            ShareActionButton(
                title: "Finalize & Share",
                iconName: "square.and.arrow.up.fill",
                backgroundColor: highlightColor,
                foregroundColor: .white
            ) {
                successHaptic.notificationOccurred(.success)
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    canvasScale = 0.97
                    canvasOpacity = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    viewModel.shareDecoratedImage()
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        canvasScale = 1.0
                        canvasOpacity = 1.0
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(toolbarOpacity)
            .disabled(viewModel.imageWithStats == nil || viewModel.isProcessing)
        }
        .onAppear {
            // Pre-prepare haptic generators
            lightHaptic.prepare()
            mediumHaptic.prepare()
            successHaptic.prepare()
            
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                canvasScale = 1.0
                canvasOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.4).delay(0.3)) {
                toolbarOpacity = 1.0
            }
        }
        .sheet(isPresented: $showTextEditorSheet) {
            textEditorSheetContent
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEmojiPickerSheet) {
            emojiPickerSheetContent
                .presentationDetents([.height(300), .medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreativePack) {
            creativePackSheetContent
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let scaledImage = uiImage.resized(toMaxKB: 500) ?? uiImage
                    let newDecoration = DecorationModel(type: .imageSticker, uiImage: scaledImage, initialPosition: randomInitialPosition())
                    
                    // Run on main thread since we're updating UI
                    await MainActor.run {
                        viewModel.addDecoration(newDecoration)
                        successHaptic.notificationOccurred(.success)
                    }
                }
                selectedPhotoItem = nil
            }
        }
    }

    // MARK: - Subviews
    
    private var canvasArea: some View {
        ZStack {
            if let image = viewModel.imageWithStats {
                // Main canvas with image and decorations
                VStack(spacing: 0) {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                            .overlay(
                                DecorationsOverlayView(baseImageSize: image.size)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(containerBackgroundColor)
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
            } else {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(containerBackgroundColor)
                    .frame(height: 400)
                    .padding(.horizontal, 16)
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: highlightColor))
                            
                            Text("Preparing canvas...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
            }
        }
        .aspectRatio(contentMode: .fit)
    }
    
    private var quickStickerRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(quickStickers, id: \.self) { emoji in
                    Button {
                        let newDecoration = DecorationModel(
                            type: .emoji,
                            content: emoji,
                            initialPosition: randomInitialPosition()
                        )
                        viewModel.addDecoration(newDecoration)
                        lightHaptic.impactOccurred(intensity: 0.6)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(containerBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                
                Button {
                    showEmojiPickerSheet = true
                    lightHaptic.impactOccurred()
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(highlightColor)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(containerBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func randomInitialPosition() -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: 0.3...0.7),
            y: CGFloat.random(in: 0.3...0.7)
        )
    }

    // Redesigned Tool Palette with modern card style
    @ViewBuilder
    private func toolPalette() -> some View {
        HStack(spacing: 4) {
            toolButton(icon: "textformat.abc", label: "Text") {
                viewModel.prepareTextEditorForSelected()
                showTextEditorSheet = true
                lightHaptic.impactOccurred()
            }
            
            toolButton(icon: "face.smiling.fill", label: "Emoji") {
                showEmojiPickerSheet = true
                lightHaptic.impactOccurred()
            }
            
            toolButton(icon: "sparkles.rectangle.stack.fill", label: "Elements") {
                showCreativePack = true
                lightHaptic.impactOccurred()
            }
            
            toolButton(icon: "photo.fill", label: "Photos") {
                showPhotoPicker = true
                lightHaptic.impactOccurred()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    private func toolButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(containerBackgroundColor)
                        .frame(width: 60, height: 50)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(highlightColor)
                }
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // Enhanced decoration toolbar
    @ViewBuilder
    private func selectedDecorationToolbar() -> some View {
        HStack(spacing: 6) {
            if let selectedID = viewModel.selectedDecorationID,
               let deco = viewModel.decorations.first(where: { $0.id == selectedID }),
               deco.type == .text {
                decorationToolbarButton(icon: "pencil", label: "Edit") {
                    viewModel.prepareTextEditorForSelected()
                    showTextEditorSheet = true
                    lightHaptic.impactOccurred()
                }
            }

            decorationToolbarButton(icon: "arrow.up.to.line", label: "Front") {
                viewModel.bringSelectedDecorationToFront()
                lightHaptic.impactOccurred()
            }

            decorationToolbarButton(icon: "arrow.down.to.line", label: "Back") {
                viewModel.sendSelectedDecorationToBack()
                lightHaptic.impactOccurred()
            }
            
            Spacer()
            
            Button {
                mediumHaptic.impactOccurred(intensity: 0.7)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.deleteSelectedDecoration()
                }
            } label: {
                Label("Delete", systemImage: "trash.fill")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red))
                    .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(containerBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func decorationToolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.primary)
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemGray6))
            )
        }
    }

    // MARK: - Sheet Contents
    
    private var textEditorSheetContent: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Style Your Text")
                    .font(.headline)
                    .padding(.top, 8)
                
                TextEditor(text: $viewModel.currentTextForEditor)
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .font(.custom(
                        viewModel.currentTextFontNameForEditor,
                        size: min(viewModel.currentTextFontSizeForEditor, 30) // Cap size for editor
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(spacing: 16) {
                    ColorPicker("Text Color", selection: $viewModel.currentTextColorForEditor, supportsOpacity: true)
                        .padding(.horizontal, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Font Style").font(.subheadline).bold()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach([
                                    "HelveticaNeue-Bold",
                                    "HelveticaNeue-Medium",
                                    "HelveticaNeue-Light",
                                    "AvenirNext-Bold",
                                    "AvenirNext-Medium",
                                    "Futura-Medium",
                                    "Georgia-Bold",
                                    "GillSans-SemiBold"
                                ], id: \.self) { fontName in
                                    fontButton(fontName)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Font Size").font(.subheadline).bold()
                        
                        HStack {
                            Text("Small")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $viewModel.currentTextFontSizeForEditor, in: 16...60, step: 2)
                                .accentColor(highlightColor)
                            
                            Text("Large")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                ShareActionButton(
                    title: viewModel.editingTextModel == nil ? "Add Text" : "Update Text",
                    iconName: "checkmark.circle.fill",
                    backgroundColor: highlightColor,
                    foregroundColor: .white
                ) {
                    viewModel.finalizeTextEditing()
                    successHaptic.notificationOccurred(.success)
                    showTextEditorSheet = false
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 8)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.finalizeTextEditing()
                        showTextEditorSheet = false
                    }
                }
            }
        }
    }
    
    private func fontButton(_ fontName: String) -> some View {
        Button {
            viewModel.currentTextFontNameForEditor = fontName
            lightHaptic.impactOccurred()
        } label: {
            Text("Aa")
                .font(.custom(fontName, size: 16))
                .frame(width: 50, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.currentTextFontNameForEditor == fontName ? 
                              highlightColor.opacity(0.2) : 
                              Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.currentTextFontNameForEditor == fontName ?
                                        highlightColor : Color.clear, lineWidth: 2)
                        )
                )
                .foregroundColor(viewModel.currentTextFontNameForEditor == fontName ? 
                                highlightColor : Color.primary)
        }
    }
    
    private var emojiPickerSheetContent: some View {
        VStack(spacing: 12) {
            Text("Select an Emoji")
                .font(.headline)
                .padding(.top, 12)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8), spacing: 12) {
                    ForEach(emojiCategories, id: \.category) { emojiCategory in
                        Section(header: sectionHeader(emojiCategory.category)) {
                            ForEach(emojiCategory.emojis, id: \.self) { emoji in
                                Button {
                                    let newDecoration = DecorationModel(
                                        type: .emoji,
                                        content: emoji,
                                        initialPosition: randomInitialPosition()
                                    )
                                    viewModel.addDecoration(newDecoration)
                                    lightHaptic.impactOccurred()
                                    showEmojiPickerSheet = false
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 30))
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Button("Done") {
                showEmojiPickerSheet = false
                lightHaptic.impactOccurred()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    private var creativePackSheetContent: some View {
        VStack(spacing: 16) {
            Text("Creative Elements")
                .font(.headline)
                .padding(.top, 8)
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(creativeElements.keys.sorted()), id: \.self) { category in
                        if let elements = creativeElements[category] {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(elements, id: \.self) { element in
                                            Button {
                                                let newDecoration = DecorationModel(
                                                    type: .emoji,
                                                    content: element,
                                                    initialPosition: randomInitialPosition()
                                                )
                                                viewModel.addDecoration(newDecoration)
                                                lightHaptic.impactOccurred()
                                            } label: {
                                                Text(element)
                                                    .font(.system(size: 32))
                                                    .frame(width: 55, height: 55)
                                                    .background(Circle().fill(containerBackgroundColor))
                                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            
            Button("Done") {
                showCreativePack = false
                lightHaptic.impactOccurred()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
    
    // Emoji data
    private let emojiCategories: [EmojiCategory] = [
        EmojiCategory(category: "Faces", emojis: ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😍"]),
        EmojiCategory(category: "Activity", emojis: ["🏃‍♂️", "🚶‍♀️", "🧗‍♀️", "🚴‍♂️", "🏋️‍♀️", "⛹️‍♂️", "🤸‍♀️", "🏄‍♂️", "🏊‍♀️", "⛷"]),
        EmojiCategory(category: "Nature", emojis: ["🌲", "🌴", "🍀", "🌺", "🌸", "🌼", "🌈", "☀️", "⭐️", "🌙"]),
        EmojiCategory(category: "Objects", emojis: ["⌚️", "📱", "💻", "📷", "🎮", "🎧", "🎬", "⚽️", "🏀", "🏈"]),
        EmojiCategory(category: "Symbols", emojis: ["❤️", "🧡", "💛", "💚", "💙", "💜", "💯", "✅", "❌", "🚫"])
    ]
}

struct EmojiCategory {
    let category: String
    let emojis: [String]
}

// Extension to resize UIImage
extension UIImage {
    func resized(toMaxKB maxKBSize: Int) -> UIImage? {
        guard let jpegData = self.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        
        // If already small enough, return self
        if jpegData.count <= maxKBSize * 1024 {
            return self
        }
        
        // Resize by reducing scale
        var compressionQuality: CGFloat = 0.9
        var resultData = jpegData
        
        while resultData.count > maxKBSize * 1024 && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            resultData = self.jpegData(compressionQuality: compressionQuality) ?? resultData
        }
        
        // If compression alone was sufficient
        if resultData.count <= maxKBSize * 1024 {
            return UIImage(data: resultData)
        }
        
        // Otherwise, resize the image dimensions
        var size = self.size
        let factor: CGFloat = 0.7 // 70% of original dimensions
        
        while resultData.count > maxKBSize * 1024 && size.width > 50 && size.height > 50 {
            size = CGSize(width: size.width * factor, height: size.height * factor)
            
            let renderer = UIGraphicsImageRenderer(size: size)
            let resizedImage = renderer.image { _ in
                self.draw(in: CGRect(origin: .zero, size: size))
            }
            
            resultData = resizedImage.jpegData(compressionQuality: compressionQuality) ?? resultData
        }
        
        return UIImage(data: resultData)
    }
}
