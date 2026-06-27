import SwiftUI

/// Main categories list screen.
///
/// Layout:
/// - Segmented control to switch between Expense and Income tabs
/// - List of `CategoryRowView` for the selected type
/// - `+` toolbar button → opens `CategoryFormSheet` in add mode
/// - Swipe-to-delete on custom categories
/// - Tap on custom category row → opens `CategoryFormSheet` in edit mode
struct CategoriesScreen: View {

    @State private var vm: CategoryViewModel
    /// Controls which segment (Expense / Income) is selected.
    @State private var selectedType: CategoryType = .expense

    init(vm: CategoryViewModel) {
        self._vm = State(initialValue: vm)
    }

    var body: some View {
        // TODO: NavigationStack wrapper
        // TODO: Segmented Picker bound to selectedType
        // TODO: List of CategoryRowView for the selected type:
        //         vm.expenseCategories when selectedType == .expense
        //         vm.incomeCategories  when selectedType == .income
        // TODO: .onDelete → call vm.deleteCategory(_:) (guard !isDefault)
        // TODO: .onTapGesture on custom rows → set vm.categoryToEdit, vm.showAddSheet = true
        // TODO: Toolbar (+) button → vm.resetForm(); vm.showAddSheet = true
        // TODO: .sheet(isPresented: $vm.showAddSheet) { CategoryFormSheet(vm: vm) }
        // TODO: .onAppear { vm.loadCategories() }
        // TODO: Error alert when viewState == .error(let msg)
        // TODO: Empty state view when selected list is empty
        EmptyView()
    }
}

#Preview {
    CategoriesScreen(vm: CategoryViewModel(repository: PreviewCategoryRepository()))
}

// MARK: - Preview stub

private struct PreviewCategoryRepository: CategoryRepository {
    func fetchAll() throws -> [Category] { [] }
    func fetchByType(_ type: CategoryType) throws -> [Category] { [] }
    func add(_ category: Category) throws {}
    func update(_ category: Category) throws {}
    func delete(_ category: Category) throws {}
    func seedDefaultsIfNeeded() throws {}
}
