import SwiftUI

/// Add / Edit sheet for a category.
/// Mode is driven by `vm.categoryToEdit`:
///   - `nil`     → "New Category"
///   - non-nil   → "Edit Category"
struct CategoryFormSheet: View {

    @Bindable var vm: CategoryViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Picker data

    private let iconOptions: [String] = [
        "fork.knife", "car.fill", "bag.fill", "tv.fill",
        "heart.fill", "bolt.fill", "book.fill", "ellipsis.circle.fill",
        "briefcase.fill", "laptopcomputer", "chart.line.uptrend.xyaxis",
        "gift.fill", "house.fill", "airplane", "tram.fill",
        "cross.fill", "dumbbell.fill", "music.note", "pawprint.fill",
        "tag.fill", "cart.fill", "cup.and.saucer.fill", "bus.fill",
        "building.2.fill", "creditcard.fill"
    ]

    private let colorOptions: [String] = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FF6B9D", "#FFEAA7", "#A29BFE", "#B2BEC3",
        "#00B894", "#6C5CE7"
    ]

    private let iconColumns  = Array(repeating: GridItem(.flexible()), count: 5)
    private let colorColumns = Array(repeating: GridItem(.flexible()), count: 5)

    // MARK: - Derived

    private var isEditMode: Bool { vm.categoryToEdit != nil }

    private var canSave: Bool {
        !vm.formName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var errorMessage: String? {
        if case .error(let msg) = vm.viewState { return msg }
        return nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                iconSection
                colorSection
            }
            .navigationTitle(isEditMode ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.saveCategory()
                        // vm.saveCategory() sets showAddSheet = false on success,
                        // which dismisses this sheet via the binding in CategoriesScreen.
                        // On error, vm.viewState = .error(msg) and the alert appears.
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { vm.viewState = .idle } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Details section

    private var detailsSection: some View {
        Section("Details") {
            TextField("Category name", text: $vm.formName)
                .autocorrectionDisabled()
                .onChange(of: vm.formName) { _, newValue in
                    // Enforce 30-character limit without waiting for Save.
                    if newValue.count > 30 {
                        vm.formName = String(newValue.prefix(30))
                    }
                }

            Picker("Type", selection: $vm.formType) {
                ForEach(CategoryType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Icon section

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: iconColumns, spacing: 12) {
                ForEach(iconOptions, id: \.self) { icon in
                    let isSelected = vm.formIcon == icon
                    Button {
                        vm.formIcon = icon
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                                .frame(height: 48)
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Color section

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: colorColumns, spacing: 12) {
                ForEach(colorOptions, id: \.self) { hex in
                    let isSelected = vm.formColor == hex
                    Button {
                        vm.formColor = hex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 40, height: 40)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Previews

#Preview("Add Mode") {
    CategoryFormSheet(vm: CategoryViewModel(repository: PreviewCategoryRepository()))
}

#Preview("Edit Mode") {
    let vm = CategoryViewModel(repository: PreviewCategoryRepository())
    vm.categoryToEdit = .previewCustom
    vm.formName  = "Shopping"
    vm.formIcon  = "bag.fill"
    vm.formColor = "#45B7D1"
    vm.formType  = .expense
    return CategoryFormSheet(vm: vm)
}

// MARK: - Preview stubs

private struct PreviewCategoryRepository: CategoryRepository {
    func fetchAll() throws -> [Category] { [] }
    func fetchByType(_ type: CategoryType) throws -> [Category] { [] }
    func add(_ category: Category) throws {}
    func update(_ category: Category) throws {}
    func delete(_ category: Category) throws {}
    func seedDefaultsIfNeeded() throws {}
}

private extension Category {
    static let previewCustom = Category(
        name: "Shopping", icon: "bag.fill", colorHex: "#45B7D1",
        type: .expense, isDefault: false
    )
}
