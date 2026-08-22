import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var onImageSelected: ((UIImage, Data) -> Void)?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            guard let result = results.first else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }

                guard let image = object as? UIImage else { return }

                // Compress image to JPEG with quality 0.8
                guard let compressedData = image.jpegData(compressionQuality: 0.8) else { return }

                // Check size limit (5MB)
                let maxSize = 5 * 1024 * 1024 // 5MB in bytes
                let finalData: Data
                if compressedData.count > maxSize {
                    // Further compress if needed
                    guard let smallerData = image.jpegData(compressionQuality: 0.5) else { return }
                    finalData = smallerData
                } else {
                    finalData = compressedData
                }

                DispatchQueue.main.async {
                    self?.parent.selectedImage = image
                    self?.parent.onImageSelected?(image, finalData)
                }
            }
        }
    }
}
