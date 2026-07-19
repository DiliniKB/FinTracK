import SwiftData
import SwiftUI

struct TransactionsScreen: View {

    @Environment(\.modelContext) private var modelContext
    @State private var vm: TransactionViewModel?

    // Used only as a change detector — @Query observes SwiftData inserts/deletes
    // so we can reload the ViewModel snapshot whenever the store changes.
    @Query private var queryTransactions: [Transaction]

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
            .onChange(of: queryTransactions.count) { _, _ in
                vm?.loadTransactions()
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
            monthNavigator(vm: vm)

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
                emptyState(vm: vm)
            } else {
                transactionList(vm: vm)
            }
        }
        .overlay {
            if case .loading = vm.viewState {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Month navigator

    private func monthNavigator(vm: TransactionViewModel) -> some View {
        HStack {
            Button {
                vm.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(vm.selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                vm.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }
            .disabled(vm.isCurrentMonth)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
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

    private func emptyState(vm: TransactionViewModel) -> some View {
        let monthName = vm.selectedMonth.formatted(.dateTime.month(.wide))
        let label = vm.selectedFilter == .all ? "transactions" : vm.selectedFilter.rawValue.lowercased() + " transactions"
        return ContentUnavailableView(
            "No \(label) in \(monthName)",
            systemImage: "tray",
            description: Text(vm.isCurrentMonth ? "Tap + to log your first transaction." : "Nothing recorded for this month.")
        )
    }

    // MARK: - Date header

    private func headerLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.day().month(.wide).year())
    }
}

