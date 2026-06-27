import SwiftUI

/// Main screen for browsing and managing categories.
/// Segmented control switches between Expense and Income lists.
struct CategoriesScreen: View {

    @State private var vm: CategoryViewModel
    @State private var selectedType: CategoryType = .expense

    init(vm: CategoryViewModel) {
        self._vm = State(initialValue: vm)
    }

    // MARK: - Derived

    private var displayedCategories: [Category] {
        selectedType == .expense ? vm.expenseCategories : vm.incomeCategories
    }

    private var errorMessage: String? {
        if case .error(let msg) = vm.viewState { return msg }
        return nil
    }

    // MARK: - Body

    var body: some View {
        // @Bindable shadows self.vm so $vm.property bindings compile correctly
        // against the @Observable class while @State owns the lifetime.
        @Bindable var vm = vm

        NavigationStack {
            VStack(spacing: 0) {
                Picker("Category Type", selection: $selectedType) {
                    ForEach(CategoryType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                if displayedCategories.isEmpty {
                    emptyState
                } else {
                    categoryList(vm: vm)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.resetForm()
                        vm.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $vm.showAddSheet, onDismiss: { vm.resetForm() }) {
                CategoryFormSheet(vm: vm)
            }
            .onAppear {
                vm.loadCategories()
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

    // MARK: - Category list

    private func categoryList(vm: CategoryViewModel) -> some View {
        List {
            ForEach(displayedCategories) { category in
                CategoryRowView(
                    category: category,
                    onEdit: category.isDefault ? nil : {
                        // Pre-populate form fields for edit mode.
                        vm.categoryToEdit = category
                        vm.formName       = category.name
                        vm.formIcon       = category.icon
                        vm.formColor      = category.colorHex
                        vm.formType       = category.type
                        vm.showAddSheet   = true
                    }
                )
                .deleteDisabled(category.isDefault)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    vm.deleteCategory(displayedCategories[index])
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            "No \(selectedType.displayName) Categories",
            systemImage: "tag.slash",
            description: Text("Tap + to create a \(selectedType.displayName.lowercased()) category.")
        )
    }
}

// MARK: - Preview

#Preview("With categories") {
    CategoriesScreen(vm: CategoryViewModel(repository: PreviewCategoryRepository(seeded: true)))
}

#Preview("Empty") {
    CategoriesScreen(vm: CategoryViewModel(repository: PreviewCategoryRepository(seeded: false)))
}

// MARK: - Preview stub

private struct PreviewCategoryRepository: CategoryRepository {
    let seeded: Bool

    func fetchAll() throws -> [Category] { seeded ? Self.samples : [] }
    func fetchByType(_ type: CategoryType) throws -> [Category] {
        seeded ? Self.samples.filter { $0.type == type } : []
    }
    func add(_ category: Category) throws {}
    func update(_ category: Category) throws {}
    func delete(_ category: Category) throws {}
    func seedDefaultsIfNeeded() throws {}

    private static let samples: [Category] = [
        Category(name: "Food & Dining", icon: "fork.knife",    colorHex: "#FF6B6B", type: .expense, isDefault: true),
        Category(name: "Shopping",      icon: "bag.fill",      colorHex: "#45B7D1", type: .expense, isDefault: false),
        Category(name: "Salary",        icon: "briefcase.fill", colorHex: "#00B894", type: .income,  isDefault: true),
    ]
}
