import SwiftData
import SwiftUI

struct TransactionsScreen: View {

    @Environment(\.modelContext) private var modelContext
    @State private var vm: TransactionViewModel?

    // MARK: - Derived

    private var errorMessage: String? {
        if case .error(let msg) = vm?.viewState { return msg }
        return nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Transactions")
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
                vm?.resetForm()
            }) {
                if let vm {
                    TransactionFormSheet(vm: vm)
                }
            }
            .onAppear {
                if vm == nil {
                    let repo = SwiftDataTransactionRepository(context: modelContext)
                    let catRepo = SwiftDataCategoryRepository(context: modelContext)
                    vm = TransactionViewModel(
                        transactionRepository: repo,
                        categoryRepository: catRepo
                    )
                }
                vm?.loadTransactions()
                vm?.loadCategories()
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

    // MARK: - Content

    @ViewBuilder
    private func content(vm: TransactionViewModel) -> some View {
        VStack(spacing: 0) {
            if let summary = vm.monthlySummary {
                MonthlySummaryCard(summary: summary)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }

            Picker("Filter", selection: Binding(
                get: { vm.selectedFilter },
                set: {
                    vm.selectedFilter = $0
                    vm.loadTransactions()
                }
            )) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if vm.groupedTransactions.isEmpty {
                emptyState(filter: vm.selectedFilter)
            } else {
                transactionList(vm: vm)
            }
        }
    }

    // MARK: - Transaction list

    private func transactionList(vm: TransactionViewModel) -> some View {
        List {
            ForEach(vm.groupedTransactions, id: \.date) { group in
                Section(header: Text(headerLabel(for: group.date))) {
                    ForEach(group.transactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.populateForm(from: transaction)
                                vm.showAddSheet = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.deleteTransaction(transaction)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty state

    private func emptyState(filter: TransactionFilter) -> some View {
        ContentUnavailableView(
            "No \(filter.rawValue) Transactions",
            systemImage: "tray",
            description: Text("Tap + to log your first transaction.")
        )
    }

    // MARK: - Date header

    private func headerLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.day().month(.wide).year())
    }
}

// MARK: - Monthly summary card

private struct MonthlySummaryCard: View {
    let summary: MonthlySummary

    var body: some View {
        HStack {
            summaryItem(label: "Income",  amount: summary.totalIncome,  color: .green)
            Divider().frame(height: 32)
            summaryItem(label: "Expense", amount: summary.totalExpense, color: .red)
            Divider().frame(height: 32)
            summaryItem(label: "Net",     amount: summary.net,          color: summary.net >= 0 ? .green : .red)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func summaryItem(label: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(NumberFormatter.lkr.string(from: NSNumber(value: amount)) ?? "Rs. 0.00")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}
