import SwiftUI

struct HorizontalClipShape: Shape {
    var position: CGFloat

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: 0, y: 0, width: rect.width * position, height: rect.height))
        return path
    }
}

struct ComparisonSliderView: View {
    let beforeImageUrl: String
    let afterImageUrl: String
    let beforeLabel: String
    let afterLabel: String
    @Binding var isPresented: Bool
    @State private var sliderPosition: CGFloat = 0.5

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appText.ignoresSafeArea()

                    ResilientAsyncImage(urlString: beforeImageUrl, contentMode: .fit) {
                        Rectangle().fill(Color.appTextSecondary)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)

                    ResilientAsyncImage(urlString: afterImageUrl, contentMode: .fit) {
                        Rectangle().fill(Color.appTextSecondary)
                    }
                    .clipShape(HorizontalClipShape(position: sliderPosition))
                    .frame(width: geometry.size.width, height: geometry.size.height)

                    Rectangle()
                        .fill(Color.appOnAccent)
                        .frame(width: 2)
                        .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)

                    Circle()
                        .fill(Color.appOnAccent)
                        .frame(width: 32, height: 32)
                        .overlay(
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                    .font(.appCaption.weight(.bold))
                                    .foregroundStyle(Color.appText)
                                Image(systemName: "chevron.right")
                                    .font(.appCaption.weight(.bold))
                                    .foregroundStyle(Color.appText)
                            }
                        )
                        .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)

                    VStack {
                        Spacer()
                        HStack {
                            Text(beforeLabel)
                                .font(.appCaptionBold)
                                .foregroundStyle(Color.appOnAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.appText.opacity(0.6)))

                            Spacer()

                            Text(afterLabel)
                                .font(.appCaptionBold)
                                .foregroundStyle(Color.appOnAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.appText.opacity(0.6)))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }

                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    sliderPosition = min(max(value.location.x / geometry.size.width, 0), 1)
                                }
                        )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundStyle(Color.appOnAccent)
                }
            }
        }
    }
}
