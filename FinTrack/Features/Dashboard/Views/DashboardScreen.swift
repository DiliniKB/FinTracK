import SwiftData
import SwiftUI

struct DashboardScreen: View {

    @Environment(\.modelContext) private var modelContext
    @State private var vm: DashboardViewModel?

    private var errorMessage: String? {
        if case .error(let msg) = vm?.viewState { return msg }
        return nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                if vm == nil {
                    vm = DashboardViewModel(
                        transactionRepository: SwiftDataTransactionRepository(context: modelContext),
                        budgetRepository:      SwiftDataBudgetRepository(context: modelContext)
                    )
                }
                vm?.loadDashboard()
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
    private func content(vm: DashboardViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                monthNavigator(vm: vm)

                if let summary = vm.monthlySummary {
                    MonthlySummaryCard(summary: summary)
                        .padding(.horizontal)
                }

                if vm.categoryBreakdown.isEmpty {
                    emptyCard(
                        icon:    "chart.pie",
                        message: "No expenses this month"
                    )
                    .padding(.horizontal)
                } else {
                    SpendingDonutChart(
                        breakdown:    vm.categoryBreakdown,
                        totalExpense: vm.monthlySummary?.totalExpense ?? 0
                    )
                    .padding(.horizontal)
                }

                budgetSection(vm: vm)

                recentSection(vm: vm)
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if case .loading = vm.viewState {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Month navigator

    private func monthNavigator(vm: DashboardViewModel) -> some View {
        HStack {
            Button { vm.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(vm.selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            Button { vm.goToNextMonth() } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }
            .disabled(vm.isCurrentMonth)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Budget section

    private func budgetSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Budget Health")
                .font(.headline)
                .padding(.horizontal)

            if vm.budgetProgressList.isEmpty {
                emptyCard(icon: "chart.bar", message: "No budgets set for this month")
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.budgetProgressList, id: \.budget.id) { progress in
                        DashboardBudgetRow(progress: progress)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Recent transactions section

    private func recentSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Transactions")
                .font(.headline)
                .padding(.horizontal)

            if vm.recentTransactions.isEmpty {
                emptyCard(icon: "tray", message: "No transactions this month")
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.recentTransactions.enumerated()), id: \.element.id) { idx, txn in
                        DashboardTransactionRow(transaction: txn)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        if idx < vm.recentTransactions.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty card

    private func emptyCard(icon: String, message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
