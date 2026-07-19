import SwiftUI

struct BudgetFormSheet: View {

    @Bindable var vm: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Available categories for the picker
    // In add mode: expense categories not yet budgeted for the month.
    // In edit mode: all expense categories (allow re-selecting).
    let availableCategories: [Category]

    // MARK: - Derived

    private var isEditMode: Bool { vm.budgetToEdit != nil }

    private var canSave: Bool {
        guard let amount = Double(vm.formLimitAmount.trimmingCharacters(in: .whitespaces)) else { return false }
        return amount > 0 && vm.formCategory != nil
    }

    private var errorMessage: String? {
        if case .error(let msg) = vm.viewState { return msg }
        return nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                categorySection
                amountSection
                recurringSection
                monthSection
            }
            .navigationTitle(isEditMode ? "Edit Budget" : "New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        vm.resetForm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.saveBudget()
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

    // MARK: - Category section

    private var categorySection: some View {
        Section("Category") {
            if availableCategories.isEmpty && !isEditMode {
                Text("All expense categories have budgets for this month.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Category", selection: $vm.formCategory) {
                    Text("Select…").tag(Optional<Category>.none)
                    ForEach(availableCategories) { cat in
                        Label(cat.name, systemImage: cat.icon).tag(Optional(cat))
                    }
                }
                .disabled(isEditMode)
            }
        }
    }

    // MARK: - Amount section

    private var amountSection: some View {
        Section("Monthly Limit") {
            HStack {
                Text("Rs.")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $vm.formLimitAmount)
                    .keyboardType(.decimalPad)
            }
        }
    }

    // MARK: - Recurring section

    private var recurringSection: some View {
        Section {
            Toggle("Repeat every month", isOn: $vm.formIsRecurring)
        } footer: {
            Text(vm.formIsRecurring
                 ? "This budget will auto-carry to the next month."
                 : "This budget applies to this month only.")
        }
    }

    // MARK: - Month section (read-only)

    private var monthSection: some View {
        Section("Month") {
            Text(vm.selectedMonth.formatted(.dateTime.month(.wide).year()))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview stubs

private struct PreviewBudgetRepository: BudgetRepository {
    func fetchAll() throws -> [Budget] { [] }
    func fetchByMonth(_ date: Date) throws -> [Budget] { [] }
    func fetchByCategory(_ categoryId: UUID, month: Date) throws -> Budget? { nil }
    func add(_ budget: Budget) throws {}
    func update(_ budget: Budget) throws {}
    func delete(_ budget: Budget) throws {}
}

private struct PreviewTransactionRepository: TransactionRepository {
    func fetchAll() throws -> [Transaction] { [] }
    func fetchByType(_ type: CategoryType) throws -> [Transaction] { [] }
    func fetchByMonth(_ date: Date) throws -> [Transaction] { [] }
    func add(_ transaction: Transaction) throws {}
    func update(_ transaction: Transaction) throws {}
    func delete(_ transaction: Transaction) throws {}
}

private struct PreviewCategoryRepository: CategoryRepository {
    func fetchAll() throws -> [Category] { [] }
    func fetchByType(_ type: CategoryType) throws -> [Category] { [] }
    func add(_ category: Category) throws {}
    func update(_ category: Category) throws {}
    func delete(_ category: Category) throws {}
    func seedDefaultsIfNeeded() throws {}
}

private struct PreviewAlertService: BudgetAlertService {
    func requestPermission() async {}
    func scheduleApproachingAlert(for budget: Budget, spent: Double) async {}
    func cancelAlert(for budgetId: UUID) {}
}

#Preview("Add Mode") {
    let vm = BudgetViewModel(
        budgetRepository: PreviewBudgetRepository(),
        transactionRepository: PreviewTransactionRepository(),
        categoryRepository: PreviewCategoryRepository(),
        alertService: PreviewAlertService()
    )
    return BudgetFormSheet(vm: vm, availableCategories: [])
}
