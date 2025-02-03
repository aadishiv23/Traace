////
////  LigiPhotoPicker.swift
////  Plore
////
////  Created by Aadi Shiv Malhotra on 2/2/25.
////
//
//import Foundation
//import SwiftUI
//import PhotosUI
//
//// MARK: - LigiPhotoPicker API Component
//
//// -----------------------------------------------------------------------------
//// MARK: - LigiPhotoPicker API Component & Editor
//// -----------------------------------------------------------------------------
//
//import SwiftUI
//import PhotosUI
//
//// MARK: - LigiPhotoPicker API Component
//
///// LigiPhotoPicker wraps a PHPicker and then presents an editor.
///// In this version, the user may only drag/pinch the photo behind a fixed viewfinder,
///// and may choose a square or circular viewfinder. Outside the viewfinder, the image is dimmed.
///// A Cancel button is available, and when “Done” is tapped a smooth green outline animates
///// along the viewfinder border and then the whole image fades green before returning.
//public struct LigiPhotoPicker: View {
//    @Binding var selectedImage: UIImage?
//    
//    @State private var showPicker: Bool = false
//    @State private var imageForEditing: UIImage? = nil
//    
//    public init(selectedImage: Binding<UIImage?>) {
//        self._selectedImage = selectedImage
//    }
//    
//    public var body: some View {
//        VStack(spacing: 20) {
//            if let image = selectedImage {
//                Image(uiImage: image)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(maxWidth: .infinity, maxHeight: 300)
//                    .cornerRadius(12)
//                    .shadow(radius: 10)
//                    .padding()
//            } else {
//                ZStack {
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(
//                            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
//                                           startPoint: .topLeading,
//                                           endPoint: .bottomTrailing)
//                        )
//                        .frame(height: 300)
//                        .shadow(radius: 10)
//                    Text("No Image Selected")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                }
//                .padding()
//            }
//            
//            Button(action: { showPicker = true }) {
//                Text("Select Photo")
//                    .fontWeight(.bold)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(
//                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
//                                       startPoint: .leading,
//                                       endPoint: .trailing)
//                    )
//                    .foregroundColor(.white)
//                    .cornerRadius(12)
//                    .padding(.horizontal)
//            }
//        }
//        .sheet(isPresented: $showPicker) {
//            PhotoPicker(selectedImage: $imageForEditing, isPresented: $showPicker)
//        }
//        .fullScreenCover(isPresented: Binding(
//            get: { imageForEditing != nil },
//            set: { if !$0 { imageForEditing = nil } }
//        )) {
//            if let image = imageForEditing {
//                LigiPhotoEditorView(
//                    originalImage: image,
//                    onComplete: { edited in
//                        selectedImage = edited
//                        imageForEditing = nil
//                    },
//                    onCancel: { imageForEditing = nil }
//                )
//            }
//        }
//    }
//}
//
//// MARK: - PhotoPicker (PHPickerViewController wrapper)
//
//struct PhotoPicker: UIViewControllerRepresentable {
//    @Binding var selectedImage: UIImage?
//    @Binding var isPresented: Bool
//    
//    func makeUIViewController(context: Context) -> PHPickerViewController {
//        var configuration = PHPickerConfiguration(photoLibrary: .shared())
//        configuration.filter = .images
//        configuration.selectionLimit = 1
//        let picker = PHPickerViewController(configuration: configuration)
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
//    
//    func makeCoordinator() -> Coordinator { Coordinator(self) }
//    
//    class Coordinator: NSObject, PHPickerViewControllerDelegate {
//        let parent: PhotoPicker
//        init(_ parent: PhotoPicker) { self.parent = parent }
//        
//        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//            parent.isPresented = false
//            guard let provider = results.first?.itemProvider,
//                  provider.canLoadObject(ofClass: UIImage.self)
//            else { return }
//            provider.loadObject(ofClass: UIImage.self) { image, _ in
//                if let uiImage = image as? UIImage {
//                    DispatchQueue.main.async {
//                        self.parent.selectedImage = uiImage
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - LigiPhotoEditorView
//
//struct LigiPhotoEditorView: View {
//    let originalImage: UIImage
//    var onComplete: (UIImage) -> Void
//    var onCancel: () -> Void
//    
//    // The crop viewfinder (in view coordinates)
//    @State private var cropRect: CGRect = .zero
//    // The displayed image frame (computed from the original image and current gestures)
//    @State private var imageFrame: CGRect = .zero
//    
//    // States for dragging and scaling the photo
//    @State private var imageOffset: CGSize = .zero
//    @State private var imageScale: CGFloat = 1.0
//    
//    // Crop shape: square or circle.
//    enum CropShape { case square, circle }
//    @State private var cropShape: CropShape = .square
//    
//    // Animation states for the “Done” sequence.
//    @State private var animateOutline: Bool = false
//    @State private var greenFillOpacity: Double = 0.0
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                // Base background
//                Color.black.ignoresSafeArea()
//                
//                // Photo layer with drag & pinch gestures.
//                Image(uiImage: originalImage)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .scaleEffect(imageScale)
//                    .offset(imageOffset)
//                    .frame(width: geometry.size.width, height: geometry.size.height)
//                    .gesture(
//                        DragGesture()
//                            .onChanged { value in
//                                imageOffset = value.translation
//                            }
//                            .onEnded { value in
//                                imageOffset = value.translation
//                            }
//                    )
//                    .simultaneousGesture(
//                        MagnificationGesture()
//                            .onChanged { value in
//                                imageScale = value
//                            }
//                            .onEnded { value in
//                                imageScale = value
//                            }
//                    )
//                    // Capture the displayed image frame.
//                    .background(
//                        GeometryReader { _ in
//                            Color.clear.onAppear {
//                                let imageSize = originalImage.size
//                                let baseScale = min(geometry.size.width / imageSize.width,
//                                                    geometry.size.height / imageSize.height)
//                                let displayedWidth = imageSize.width * baseScale * imageScale
//                                let displayedHeight = imageSize.height * baseScale * imageScale
//                                let x = (geometry.size.width - displayedWidth) / 2 + imageOffset.width
//                                let y = (geometry.size.height - displayedHeight) / 2 + imageOffset.height
//                                self.imageFrame = CGRect(x: x, y: y, width: displayedWidth, height: displayedHeight)
//                                
//                                // Initialize the viewfinder if not already set.
//                                if cropRect == .zero {
//                                    let side = min(displayedWidth, displayedHeight) * 0.8
//                                    cropRect = CGRect(x: geometry.size.width/2 - side/2,
//                                                      y: geometry.size.height/2 - side/2,
//                                                      width: side,
//                                                      height: side)
//                                }
//                            }
//                        }
//                    )
//                
//                // Dim the area outside the viewfinder and draw its border.
//                CropViewfinderOverlay(cropRect: cropRect, cropShape: cropShape)
//                    .frame(width: geometry.size.width, height: geometry.size.height)
//                
//                // The green outline animation (when activated).
//                if animateOutline {
//                    GreenOutlineAnimation(cropRect: cropRect, cropShape: cropShape)
//                }
//                
//                // The full green fill overlay (for the final effect).
//                Color.green
//                    .opacity(greenFillOpacity)
//                    .ignoresSafeArea()
//                
//                // UI Controls.
//                VStack {
//                    HStack {
//                        Button(action: { onCancel() }) {
//                            Text("Cancel")
//                                .padding(8)
//                                .background(Color.black.opacity(0.5))
//                                .foregroundColor(.white)
//                                .cornerRadius(8)
//                        }
//                        Spacer()
//                        // Picker for selecting the viewfinder shape.
//                        Picker("Shape", selection: $cropShape) {
//                            Text("Square").tag(CropShape.square)
//                            Text("Circle").tag(CropShape.circle)
//                        }
//                        .pickerStyle(SegmentedPickerStyle())
//                        .frame(width: 200)
//                    }
//                    .padding(.top, 100)
//                    .padding(.horizontal)
//                    
//                    Spacer()
//                    
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            let cropped = cropImage()
//                            // Begin the green outline animation.
//                            animateOutline = true
//                            // After 1 second, animate the full green fill.
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                withAnimation(Animation.linear(duration: 0.5)) {
//                                    greenFillOpacity = 1.0
//                                }
//                                // After the green fill animation, complete the process.
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                    onComplete(cropped)
//                                }
//                            }
//                        }) {
//                            Text("Done")
//                                .fontWeight(.bold)
//                                .padding()
//                                .frame(width: 120)
//                                .background(
//                                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
//                                                   startPoint: .leading,
//                                                   endPoint: .trailing)
//                                )
//                                .foregroundColor(.white)
//                                .cornerRadius(12)
//                        }
//                        Spacer()
//                    }
//                    .padding(.bottom, 30)
//                }
//            }
//        }
//    }
//    
//    // Crop the image using the current viewfinder (cropRect) and image frame.
//    func cropImage() -> UIImage {
//        guard let cgImage = originalImage.cgImage else { return originalImage }
//        let imageSize = originalImage.size
//        
//        // Determine the scale factors between the original image and its displayed frame.
//        let scaleX = imageSize.width / imageFrame.width
//        let scaleY = imageSize.height / imageFrame.height
//        
//        // Map cropRect (in view coordinates) to image coordinates.
//        let normalizedX = (cropRect.origin.x - imageFrame.origin.x) * scaleX
//        let normalizedY = (cropRect.origin.y - imageFrame.origin.y) * scaleY
//        let normalizedWidth = cropRect.width * scaleX
//        let normalizedHeight = cropRect.height * scaleY
//        
//        let croppingRect = CGRect(x: normalizedX,
//                                  y: normalizedY,
//                                  width: normalizedWidth,
//                                  height: normalizedHeight)
//        
//        guard let croppedCgImage = cgImage.cropping(to: croppingRect) else { return originalImage }
//        let croppedImage = UIImage(cgImage: croppedCgImage,
//                                   scale: originalImage.scale,
//                                   orientation: originalImage.imageOrientation)
//        
//        // If a circular crop is selected, mask the image accordingly.
//        if cropShape == .circle {
//            return circularImage(from: croppedImage)
//        } else {
//            return croppedImage
//        }
//    }
//    
//    // Masks an image into a circle.
//    func circularImage(from image: UIImage) -> UIImage {
//        let diameter = min(image.size.width, image.size.height)
//        let squareRect = CGRect(x: (image.size.width - diameter) / 2,
//                                y: (image.size.height - diameter) / 2,
//                                width: diameter,
//                                height: diameter)
//        UIGraphicsBeginImageContextWithOptions(squareRect.size, false, image.scale)
//        let context = UIGraphicsGetCurrentContext()!
//        context.addEllipse(in: CGRect(origin: .zero, size: squareRect.size))
//        context.clip()
//        image.draw(in: CGRect(x: -squareRect.origin.x,
//                              y: -squareRect.origin.y,
//                              width: image.size.width,
//                              height: image.size.height))
//        let circularImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return circularImage
//    }
//}
//
//// MARK: - CropViewfinderOverlay
//
///// Draws a fixed viewfinder (square or circle) at cropRect while dimming the rest of the image.
//struct CropViewfinderOverlay: View {
//    let cropRect: CGRect
//    let cropShape: LigiPhotoEditorView.CropShape
//    
//    var body: some View {
//        GeometryReader { geometry in
//            let fullRect = geometry.frame(in: .local)
//            // Draw a dimming overlay with a cutout.
//            Path { path in
//                path.addRect(fullRect)
//                if cropShape == .square {
//                    path.addRect(cropRect)
//                } else {
//                    path.addEllipse(in: cropRect)
//                }
//            }
//            .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))
//            // Draw the viewfinder border.
//            Group {
//                if cropShape == .square {
//                    Rectangle()
//                        .stroke(Color.white, lineWidth: 2)
//                        .frame(width: cropRect.width, height: cropRect.height)
//                        .position(x: cropRect.midX, y: cropRect.midY)
//                } else {
//                    Circle()
//                        .stroke(Color.white, lineWidth: 2)
//                        .frame(width: cropRect.width, height: cropRect.height)
//                        .position(x: cropRect.midX, y: cropRect.midY)
//                }
//            }
//        }
//        .allowsHitTesting(false)
//    }
//}
//
//// MARK: - GreenOutlineAnimation
//
///// Animates a smooth green outline along the viewfinder border.
//struct GreenOutlineAnimation: View {
//    let cropRect: CGRect
//    let cropShape: LigiPhotoEditorView.CropShape
//    @State private var trimEnd: CGFloat = 0.0
//    
//    var body: some View {
//        Group {
//            if cropShape == .square {
//                Rectangle()
//                    .trim(from: 0, to: trimEnd)
//                    .stroke(Color.green, lineWidth: 4)
//                    .frame(width: cropRect.width, height: cropRect.height)
//                    .position(x: cropRect.midX, y: cropRect.midY)
//            } else {
//                Circle()
//                    .trim(from: 0, to: trimEnd)
//                    .stroke(Color.green, lineWidth: 4)
//                    .frame(width: cropRect.width, height: cropRect.height)
//                    .position(x: cropRect.midX, y: cropRect.midY)
//            }
//        }
//        .onAppear {
//            withAnimation(Animation.linear(duration: 1.0)) {
//                trimEnd = 1.0
//            }
//        }
//    }
//}
