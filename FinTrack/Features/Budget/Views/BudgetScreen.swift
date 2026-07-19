import SwiftData
import SwiftUI

struct BudgetScreen: View {

    @Environment(\.modelContext) private var modelContext
    @State private var vm: BudgetViewModel?

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
            .navigationTitle("Budgets")
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
                vm?.loadBudgets()
            }) {
                if let vm {
                    BudgetFormSheet(vm: vm, availableCategories: vm.unbudgetedCategories)
                }
            }
            .onAppear {
                if vm == nil {
                    let budgetRepo      = SwiftDataBudgetRepository(context: modelContext)
                    let txnRepo         = SwiftDataTransactionRepository(context: modelContext)
                    let catRepo         = SwiftDataCategoryRepository(context: modelContext)
                    let alertService    = LocalBudgetAlertService(repository: budgetRepo)
                    vm = BudgetViewModel(
                        budgetRepository:      budgetRepo,
                        transactionRepository: txnRepo,
                        categoryRepository:    catRepo,
                        alertService:          alertService
                    )
                    Task { await vm?.requestAlertPermission() }
                }
                vm?.loadBudgets()
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
    private func content(vm: BudgetViewModel) -> some View {
        VStack(spacing: 0) {
            monthNavigator(vm: vm)
                .padding(.horizontal)
                .padding(.vertical, 10)

            if vm.budgetProgressList.isEmpty && vm.unbudgetedCategories.isEmpty {
                emptyState
            } else {
                budgetList(vm: vm)
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

    private func monthNavigator(vm: BudgetViewModel) -> some View {
        HStack {
            Button {
                vm.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            Spacer()
            Text(vm.selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            Button {
                vm.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
        }
    }

    // MARK: - Budget list

    private func budgetList(vm: BudgetViewModel) -> some View {
        List {
            if !vm.budgetProgressList.isEmpty {
                Section("Budgeted") {
                    ForEach(vm.budgetProgressList, id: \.budget.id) { progress in
                        BudgetProgressRow(progress: progress)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.budgetToEdit    = progress.budget
                                vm.formLimitAmount = String(progress.budget.limitAmount)
                                vm.formIsRecurring = progress.budget.isRecurring
                                vm.formCategory    = vm.allExpenseCategories.first {
                                    $0.id == progress.budget.categoryId
                                }
                                vm.showAddSheet = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.deleteBudget(progress.budget)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            if !vm.unbudgetedCategories.isEmpty {
                Section("No Budget Set") {
                    ForEach(vm.unbudgetedCategories) { category in
                        unbudgetedRow(category: category, vm: vm)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Unbudgeted row

    private func unbudgetedRow(category: Category, vm: BudgetViewModel) -> some View {
        Button {
            vm.resetForm()
            vm.formCategory = category
            vm.showAddSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex))
                        .frame(width: 36, height: 36)
                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text(category.name)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            "No Budgets",
            systemImage: "chart.bar",
            description: Text("Tap + to set a spending limit for an expense category.")
        )
    }
}
