import SwiftData
import SwiftUI

/// Main screen for browsing and managing categories.
/// Segmented control switches between Expense and Income lists.
/// `CategoryViewModel` is initialised lazily on first appear using the
/// SwiftData `ModelContext` from the environment.
struct CategoriesScreen: View {

    @Environment(\.modelContext) private var modelContext
    @State private var vm: CategoryViewModel?
    @State private var selectedType: CategoryType = .expense

    // MARK: - Derived

    private var displayedCategories: [Category] {
        guard let vm else { return [] }
        return selectedType == .expense ? vm.expenseCategories : vm.incomeCategories
    }

    private var errorMessage: String? {
        if case .error(let msg) = vm?.viewState { return msg }
        return nil
    }

    // MARK: - Body

    var body: some View {
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
                } else if let vm {
                    categoryList(vm: vm)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm?.resetForm()
                        vm?.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(vm == nil)
                }
            }
            .sheet(isPresented: Binding(
                get: { vm?.showAddSheet ?? false },
                set: { vm?.showAddSheet = $0 }
            ), onDismiss: {
                if let vm {
                    print("sheet dismissed — categories: expense=\(vm.expenseCategories.count) income=\(vm.incomeCategories.count)")
                    vm.resetForm()
                }
            }) {
                if let vm {
                    CategoryFormSheet(vm: vm)
                }
            }
            .onAppear {
                if vm == nil {
                    vm = CategoryViewModel(
                        repository: SwiftDataCategoryRepository(context: modelContext)
                    )
                    vm?.loadCategories()
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { vm?.viewState = .idle } }
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
    CategoriesScreen()
        .modelContainer(PreviewContainer.make(seeded: true))
}

#Preview("Empty") {
    CategoriesScreen()
        .modelContainer(PreviewContainer.make(seeded: false))
}

// MARK: - Preview helpers

private enum PreviewContainer {
    static func make(seeded: Bool) -> ModelContainer {
        let container = try! ModelContainer(
            for: Category.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        if seeded {
            let ctx = container.mainContext
            ctx.insert(Category(name: "Food & Dining", icon: "fork.knife",     colorHex: "#FF6B6B", type: .expense, isDefault: true))
            ctx.insert(Category(name: "Shopping",      icon: "bag.fill",       colorHex: "#45B7D1", type: .expense, isDefault: false))
            ctx.insert(Category(name: "Salary",        icon: "briefcase.fill", colorHex: "#00B894", type: .income,  isDefault: true))
        }
        return container
    }
}
