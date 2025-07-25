import SwiftUI

struct HomeView: View {
    @State private var showPhotoPicker = false
    @State private var inputImage: UIImage?
    @State private var masks: [EmojiMask] = []
    @State private var showShareSheet = false
    @State private var composedImage: UIImage?
    @State private var showSaveAlert = false
    @State private var saveResultMessage = ""
    @State private var imageDisplaySize = CGSize.zero

    var body: some View {

        
        NavigationView {
            VStack {
                if let image = inputImage {
                    VStack {
                        GeometryReader { geo in
                            ZStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                    // Add double-tap gesture to background to add a new emoji
                                    .contentShape(Rectangle())
                                    .gesture(
                                        TapGesture(count: 2)
                                            .onEnded { location in
                                                // location is not provided by TapGesture, so use simultaneous gesture
                                            }
                                    )
                                    .onAppear {
                                        imageDisplaySize = geo.size  // Capture the display size
                                    }
                                    .onChange(of: geo.size) { newSize in
                                        imageDisplaySize = newSize   // Update if size changes
                                    }
                                ForEach($masks) { $mask in
                                    EmojiOverlayView(mask: $mask, imageSize: image.size, displaySize: geo.size) {
                                        masks.removeAll { $0.id == mask.id }
                                    }
                                }
                            }
                            // Use simultaneous gesture to get tap location
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        // Add a new emoji at the center of the image
                                        let center = CGPoint(x: image.size.width / 2, y: image.size.height / 2)
                                        let size = min(image.size.width, image.size.height) / 4
                                        let newMask = EmojiMask(center: center, size: size, emojiIndex: 0)
                                        masks.append(newMask)
                                    }
                            )
                        }
                        .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 400)

                        HStack {
                            Button("Select New Image") {
                                inputImage = nil
                                masks = []
                            }
                            .buttonStyle(.bordered)

                            Button("Save to Photos") {
                                if let image = inputImage {
                                    print("DEBUG: Before debug")
                                    ImageComposer.debugMaskSizes(image: image, masks: masks)
                                    print("DEBUG: After debug")
                                    if let composed = ImageComposer.compose(image: image, masks: masks, displaySize: imageDisplaySize) {
                                        UIImageWriteToSavedPhotosAlbum(composed, nil, nil, nil)
                                        saveResultMessage = "Image saved to your Photos!"
                                        showSaveAlert = true
                                    } else {
                                        saveResultMessage = "Failed to create image."
                                        showSaveAlert = true
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top)
                    }
                } else {
                    Spacer()
                    Button("Select Photo") {
                        showPhotoPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Face Masq")
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(image: $inputImage)
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = composedImage {
                    SaveShareSheet(image: image)
                }
            }
            .alert(isPresented: $showSaveAlert) {
                Alert(title: Text("Save Image"), message: Text(saveResultMessage), dismissButton: .default(Text("OK")))
            }
            .onChange(of: inputImage) { newImage in
                if let image = newImage {
                    FaceDetector.detectFaces(in: image) { rects in
                        print("Detected face rects:", rects)
    
                        // let minEmojiSize: CGFloat = max(20, min(image.size.width, image.size.height) * 0.02)
                        // let maxEmojiSize: CGFloat = max(120, min(image.size.width, image.size.height) * 0.15)

                        let newMasks = rects.map { rect in
                            // Calculate what percentage of the image this face takes up
                            let faceArea = rect.width * rect.height
                            let imageArea = image.size.width * image.size.height
                            let faceToImageRatio = faceArea / imageArea
                            
                            print("Face area ratio: \(faceToImageRatio)")
                            
                            // Dynamically adjust emoji size based on how big the face is
                            let emojiSizePercentage: CGFloat
                            if faceToImageRatio > 0.20 {        // Face > 20% of image (very close selfie)
                                emojiSizePercentage = 0.05
                            } else if faceToImageRatio > 0.10 { // Face > 10% of image (close selfie)
                                emojiSizePercentage = 0.25
                            } else if faceToImageRatio > 0.05 { // Face > 5% of image (medium shot)
                                emojiSizePercentage = 0.25
                            } else {                            // Face < 5% of image (distant shot)
                                emojiSizePercentage = 0.25
                            }

                            
                    
                            let faceSize = min(rect.width, rect.height) * emojiSizePercentage

                            // Set absolute min/max limits (as backup safety)
                            let imageMinDimension = min(image.size.width, image.size.height)
                            let absoluteMin: CGFloat = imageMinDimension * 0.005  // .5% minimum
                            let absoluteMax: CGFloat = imageMinDimension * 0.08   // 8% maximum
                            
                            let clampedSize = min(max(faceSize, absoluteMin), absoluteMax) * 0.50


                            print("Face size: \(min(rect.width, rect.height)), percentage: \(emojiSizePercentage), final emoji size: \(clampedSize)")
                            print("Emoji Size:", clampedSize)
                            return EmojiMask(
                                center: CGPoint(x: rect.midX, y: rect.midY),
                                size: clampedSize,
                                emojiIndex: 0
                            )
                        }
                        DispatchQueue.main.async {
                            self.masks = newMasks
                        }
                    }
                } else {
                    masks = []
                }
            }
        }
    }
} 
