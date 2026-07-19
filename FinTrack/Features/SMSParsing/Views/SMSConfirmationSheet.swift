import SwiftUI

struct SMSConfirmationSheet: View {

    @Environment(\.modelContext) private var modelContext

    let result: ParsedSMSResult
    let coordinator: SMSCoordinator
    let categoryRepository: any CategoryRepository
    let transactionRepository: any TransactionRepository

    // MARK: - Editable form state

    @State private var formAmount: String
    @State private var formType: CategoryType
    @State private var formPayee: String
    @State private var formDate: Date
    @State private var formBank: DetectedBank
    @State private var formCategory: Category? = nil
    @State private var availableCategories: [Category] = []
    @State private var showRawSMS = false
    @State private var saveError: String? = nil

    // MARK: - Init

    init(
        result:                ParsedSMSResult,
        coordinator:           SMSCoordinator,
        categoryRepository:    any CategoryRepository,
        transactionRepository: any TransactionRepository
    ) {
        self.result                = result
        self.coordinator           = coordinator
        self.categoryRepository    = categoryRepository
        self.transactionRepository = transactionRepository
        _formAmount = State(initialValue: String(format: "%.2f", result.amount))
        _formType   = State(initialValue: result.type)
        _formPayee  = State(initialValue: result.payee)
        _formDate   = State(initialValue: result.date)
        _formBank   = State(initialValue: result.bank)
    }

    // MARK: - Derived

    private var canSave: Bool {
        guard let amount = Double(formAmount.trimmingCharacters(in: .whitespaces)) else { return false }
        return amount > 0 && formCategory != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                bankSection
                amountSection
                typeSection
                categorySection
                payeeSection
                dateSection
                rawSMSSection
            }
            .navigationTitle("Confirm Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadCategories() }
            .onChange(of: formType) { _, _ in loadCategories() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Discard", role: .destructive) {
                        coordinator.dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
            .alert("Could Not Save", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var bankSection: some View {
        Section("Source") {
            HStack {
                Picker(selection: $formBank) {
                    ForEach(DetectedBank.allCases, id: \.self) { bank in
                        Text(bank.rawValue).tag(bank)
                    }
                } label: {
                    Image(systemName: "building.columns")
                        .foregroundStyle(.secondary)
                }
                confidenceBadge
            }
        }
    }

    private var confidenceBadge: some View {
        let pct = Int(result.confidence * 100)
        let color: Color = result.confidence >= 0.8 ? .green
                         : result.confidence >= 0.5 ? .orange
                         : .red
        return Text("\(pct)% confidence")
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
    }

    private var amountSection: some View {
        Section("Amount") {
            if result.isForeignCurrency {
                HStack {
                    Text("Original")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(result.originalCurrency) \(String(format: "%.2f", result.originalAmount))")
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("LKR")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $formAmount)
                    .keyboardType(.decimalPad)
            }
            if result.isForeignCurrency {
                Text("Rate fetched live. Verify before saving.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var typeSection: some View {
        Section("Type") {
            Picker("Type", selection: $formType) {
                ForEach(CategoryType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var categorySection: some View {
        Section("Category") {
            if availableCategories.isEmpty {
                Text("No categories for this type")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Category", selection: $formCategory) {
                    Text("Select…").tag(Optional<Category>.none)
                    ForEach(availableCategories) { cat in
                        Label(cat.name, systemImage: cat.icon)
                            .tag(Optional(cat))
                    }
                }
            }
        }
    }

    private var payeeSection: some View {
        Section("Payee / Merchant") {
            TextField("Merchant name", text: $formPayee)
                .autocorrectionDisabled()
        }
    }

    private var dateSection: some View {
        Section("Date") {
            DatePicker("Date", selection: $formDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
        }
    }

    private var rawSMSSection: some View {
        Section {
            DisclosureGroup("Raw SMS", isExpanded: $showRawSMS) {
                Text(result.rawSMS)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func loadCategories() {
        availableCategories = (try? categoryRepository.fetchByType(formType)) ?? []
        // Pre-select suggested category if it matches the current type
        if let suggestedId = result.suggestedCategoryId,
           formCategory == nil {
            formCategory = availableCategories.first { $0.id == suggestedId }
        } else if let current = formCategory, !availableCategories.contains(where: { $0.id == current.id }) {
            formCategory = nil
        }
    }

    private func save() {
        let trimmed = formAmount.trimmingCharacters(in: .whitespaces)
        guard let amount = Double(trimmed), amount > 0, let category = formCategory else { return }
        do {
            try coordinator.confirmAndSave(
                amount:     amount,
                type:       formType,
                category:   category,
                payee:      formPayee,
                date:       formDate,
                bank:       formBank,
                repository: transactionRepository
            )
        } catch {
            saveError = error.localizedDescription
        }
    }
}
