import SwiftUI

/// Sheet presented for both adding and editing a category.
/// Mode is determined by `vm.categoryToEdit`:
///   - `nil`     → Add mode  (title: "New Category")
///   - non-nil   → Edit mode (title: "Edit Category")
///
/// Fields:
/// - Name text field (required, max 30 chars)
/// - Type picker: Expense / Income
/// - Icon picker: scrollable grid of SF Symbol names
/// - Color picker: preset palette of 10 hex colors
/// - Save / Cancel buttons
struct CategoryFormSheet: View {

    @Bindable var vm: CategoryViewModel
    @Environment(\.dismiss) private var dismiss

    /// Preset icon options shown in the icon picker grid.
    private let iconOptions: [String] = [
        "fork.knife", "car.fill", "bag.fill", "tv.fill",
        "heart.fill", "bolt.fill", "book.fill", "ellipsis.circle.fill",
        "briefcase.fill", "laptopcomputer", "chart.line.uptrend.xyaxis",
        "gift.fill", "house.fill", "airplane", "tram.fill",
        "cross.fill", "dumbbell.fill", "music.note", "pawprint.fill",
        "tag.fill"
        // TODO: Expand with more SF Symbols as needed
    ]

    /// Preset color palette shown in the color picker.
    private let colorOptions: [String] = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FF6B9D", "#FFEAA7", "#A29BFE", "#B2BEC3",
        "#00B894", "#6C5CE7"
    ]

    private var isEditMode: Bool { vm.categoryToEdit != nil }

    var body: some View {
        // TODO: NavigationStack
        // TODO: Form with sections:
        //   Section("Name"):
        //     TextField("Category name", text: $vm.formName)
        //       .characterLimit(30)  — enforce in onChange
        //
        //   Section("Type"):
        //     Picker("Type", selection: $vm.formType) { ... }
        //       .pickerStyle(.segmented)
        //
        //   Section("Icon"):
        //     LazyVGrid of SF Symbol buttons bound to vm.formIcon
        //     Selected icon shown with accent color
        //
        //   Section("Color"):
        //     LazyHGrid / HStack of color circle buttons bound to vm.formColor
        //     Selected color shows a checkmark overlay
        //
        // TODO: Toolbar:
        //   Leading: Cancel → dismiss + vm.resetForm()
        //   Trailing: Save  → vm.saveCategory(); dismiss on success
        //
        // TODO: Disable Save when vm.formName.trimmed.isEmpty
        // TODO: Error alert when vm.viewState == .error(let msg)
        EmptyView()
    }
}

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
        name: "Shopping",
        icon: "bag.fill",
        colorHex: "#45B7D1",
        type: .expense,
        isDefault: false
    )
}
