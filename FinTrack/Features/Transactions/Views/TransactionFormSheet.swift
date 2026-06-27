import SwiftUI

struct TransactionFormSheet: View {

    @Bindable var vm: TransactionViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived

    private var isEditMode: Bool { vm.transactionToEdit != nil }

    private var canSave: Bool {
        guard let amount = Double(vm.formAmount.trimmingCharacters(in: .whitespaces)) else { return false }
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
                amountSection
                typeSection
                categorySection
                dateSection
                payeeSection
                noteSection
            }
            .navigationTitle(isEditMode ? "Edit Transaction" : "New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                vm.loadCategories()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        vm.resetForm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.saveTransaction()
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

    // MARK: - Amount section

    private var amountSection: some View {
        Section("Amount") {
            HStack {
                Text("Rs.")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $vm.formAmount)
                    .keyboardType(.decimalPad)
            }
        }
    }

    // MARK: - Type section

    private var typeSection: some View {
        Section("Type") {
            Picker("Type", selection: $vm.formType) {
                ForEach(CategoryType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.formType) { _, _ in
                vm.loadCategories()
            }
        }
    }

    // MARK: - Category section

    private var categorySection: some View {
        Section("Category") {
            if vm.availableCategories.isEmpty {
                Text("No categories available")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Category", selection: $vm.formCategory) {
                    Text("Select…").tag(Optional<Category>.none)
                    ForEach(vm.availableCategories) { category in
                        Label(category.name, systemImage: category.icon)
                            .tag(Optional(category))
                    }
                }
            }
        }
    }

    // MARK: - Date section

    private var dateSection: some View {
        Section("Date") {
            DatePicker("Date", selection: $vm.formDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
        }
    }

    // MARK: - Payee section

    private var payeeSection: some View {
        Section("Payee") {
            TextField("Who paid / was paid", text: $vm.formPayee)
                .autocorrectionDisabled()
        }
    }

    // MARK: - Note section

    private var noteSection: some View {
        Section("Note") {
            TextField("Optional note", text: $vm.formNote, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
        }
    }
}

// MARK: - Preview stubs

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

#Preview("Add Mode") {
    TransactionFormSheet(vm: TransactionViewModel(
        transactionRepository: PreviewTransactionRepository(),
        categoryRepository: PreviewCategoryRepository()
    ))
}
