import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var vm: ProfileViewModel
    let api: AuthAPI
    let authStore: AuthStore

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var displayName: String = ""
    @State private var showImagePicker = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteFinalConfirmation = false
    @State private var deleteConfirmationText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    avatarCard
                    infoCard
                    dangerCard
                }
                .padding(.horizontal, AppSpacing.pagePadding)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveProfile() }
                    }
                    .disabled(vm.isSaving || displayName.isEmpty)
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showDeleteFinalConfirmation = true
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This cannot be undone.")
            }
            .alert("Type DELETE to confirm", isPresented: $showDeleteFinalConfirmation) {
                TextField("DELETE", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) { deleteConfirmationText = "" }
                Button("Delete Forever", role: .destructive) {
                    guard deleteConfirmationText == "DELETE" else { return }
                    Task { await vm.deleteAccount() }
                    deleteConfirmationText = ""
                }
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    guard let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    let compressed = compressImage(image)
                    await MainActor.run {
                        avatarImage = image
                    }
                    await vm.uploadProfileImage(imageData: compressed)
                }
            }
            .overlay {
                if vm.isSaving || vm.isDeleting {
                    ProgressView()
                        .tint(Color.appOnAccent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appText.opacity(0.3))
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                displayName = vm.profile.name
            }
        }
    }

    // MARK: - Avatar Card

    private var avatarCard: some View {
        VStack(spacing: 16) {
            ZStack {
                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                } else if let urlString = vm.profile.avatarURL {
                    ResilientAsyncImage(urlString: urlString, contentMode: .fill) {
                        initialsView(size: 96)
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                } else {
                    initialsView(size: 96)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.appCaption.weight(.medium))
                            .foregroundStyle(Color.appOnAccent)
                    }
                    .offset(x: 4, y: 4)
            }
            .onTapGesture { showImagePicker = true }

            Text("Change Photo")
                .font(.appBody.weight(.medium))
                .foregroundStyle(Color.appPrimaryDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private func initialsView(size: CGFloat) -> some View {
        Circle()
            .fill(Color.appPrimary.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 2)
            )
            .overlay {
                Text(vm.profile.initials)
                    .font(.appScreenTitle)
                    .foregroundStyle(Color.appPrimaryDark)
            }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("PERSONAL INFO")

            editableFieldRow(
                icon: "person.fill",
                label: "Name",
                text: $displayName,
                iconBg: Color.appPrimary.opacity(0.15),
                iconFg: Color.appPrimaryDark
            )

            divider

            readOnlyFieldRow(
                icon: "envelope.fill",
                label: "Email",
                value: vm.profile.email
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    // MARK: - Danger Card

    private var dangerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ACCOUNT")

            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.appBody)
                        .foregroundStyle(Color.appOnAccent)
                        .frame(width: 34, height: 34)
                        .background(Color.appError)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete Account")
                            .font(.appCardTitle)
                            .foregroundStyle(Color.appError)
                        Text("Permanently remove all data")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.appCaptionBold)
                        .foregroundStyle(Color.appBorder)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    // MARK: - Shared Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.appCaptionBold)
            .foregroundStyle(Color.appTextSecondary)
            .textCase(.uppercase)
            .padding(.bottom, 8)
    }

    private func editableFieldRow(
        icon: String,
        label: String,
        text: Binding<String>,
        iconBg: Color,
        iconFg: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.appBody)
                .foregroundStyle(iconFg)
                .frame(width: 34, height: 34)
                .background(iconBg)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))

            TextField(label, text: text)
                .font(.appBody)

            Spacer()
        }
        .padding(.vertical, 12)
    }

    private func readOnlyFieldRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.appBody)
                .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                .frame(width: 34, height: 34)
                .background(Color.appTextSecondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                Text(value)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary.opacity(0.4))
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Divider()
            .padding(.leading, 48)
            .foregroundStyle(Color.appBorder)
    }

    // MARK: - Actions

    private func saveProfile() async {
        guard displayName != vm.profile.name else {
            dismiss()
            return
        }
        await vm.updateProfile(name: displayName)
        if vm.errorMessage == nil {
            dismiss()
        }
    }

    private func compressImage(_ image: UIImage) -> Data {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return Data() }
        let maxSize = 5 * 1024 * 1024
        if data.count > maxSize,
           let smaller = image.jpegData(compressionQuality: 0.5) {
            return smaller
        }
        return data
    }
}

#Preview {
    let api = APIClient(baseURL: URL(string: "http://localhost:8000/v1")!)
    EditProfileView(
        vm: ProfileViewModel(api: api, authStore: AuthStore()),
        api: api,
        authStore: AuthStore()
    )
}
