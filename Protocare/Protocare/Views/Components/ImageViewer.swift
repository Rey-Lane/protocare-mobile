import SwiftUI
import UIKit

struct ImageViewer: View {
    let image: UIImage
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .pinchToZoom()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

struct AsyncImageViewer: View {
    let imageUrl: String
    var onCompare: (() -> Void)? = nil
    @Binding var isPresented: Bool
    @StateObject private var loader = ResilientAsyncImageLoader()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = loader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .pinchToZoom()
                } else if loader.image == nil {
                    ProgressView()
                        .foregroundStyle(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if let onCompare {
                            Button {
                                onCompare()
                            } label: {
                                Image(systemName: "square.split.2x1")
                            }
                            .foregroundStyle(.white)
                        }
                        Button("Done") {
                            isPresented = false
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
        }
        .task {
            loader.load(urlString: imageUrl)
        }
    }
}

// Pinch to zoom modifier
struct PinchToZoom: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        withAnimation {
                            if scale < 1.0 {
                                scale = 1.0
                            }
                            lastScale = scale
                        }
                    }
            )
    }
}

extension View {
    func pinchToZoom() -> some View {
        modifier(PinchToZoom())
    }
}
