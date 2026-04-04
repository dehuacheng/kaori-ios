import SwiftUI
import PhotosUI

struct PhotoPickerButton: View {
    @Binding var imageData: Data?
    @Environment(Localizer.self) private var L
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    Label(L.t("shared.camera"), systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(L.t("shared.library"), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if imageData != nil {
                    Button(role: .destructive) {
                        imageData = nil
                        selectedItem = nil
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $imageData)
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let jpeg = resized(image).jpegData(compressionQuality: 0.8) {
                    imageData = jpeg
                }
            }
        }
    }
}

struct MultiPhotoPickerButton: View {
    @Binding var imagesData: [Data]
    @Environment(Localizer.self) private var L
    @State private var showCamera = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 12) {
            if !imagesData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(imagesData.enumerated()), id: \.offset) { index, data in
                            if let uiImage = UIImage(data: data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Button {
                                        imagesData.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .red)
                                            .font(.title3)
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                }
                .frame(height: 110)
            }

            HStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    Label(L.t("shared.camera"), systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                    Label(L.t("shared.library"), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if !imagesData.isEmpty {
                    Button(role: .destructive) {
                        imagesData.removeAll()
                        selectedItems.removeAll()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: Binding(
                get: { nil },
                set: { data in
                    if let data { imagesData.append(data) }
                }
            ))
        }
        .onChange(of: selectedItems) { _, items in
            Task {
                var newData: [Data] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let jpeg = resized(image).jpegData(compressionQuality: 0.8) {
                        newData.append(jpeg)
                    }
                }
                imagesData = newData
            }
        }
    }
}

private func resized(_ image: UIImage, maxDimension: CGFloat = 1600) -> UIImage {
    let size = image.size
    guard max(size.width, size.height) > maxDimension else { return image }
    let scale = maxDimension / max(size.width, size.height)
    let newSize = CGSize(width: size.width * scale, height: size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let jpeg = resized(image).jpegData(compressionQuality: 0.8) {
                parent.imageData = jpeg
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
