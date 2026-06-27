import Foundation

struct BudgetProgress {
    let budget: Budget
    let spent: Double

    var remaining: Double  { budget.limitAmount - spent }
    var percentage: Double { min(spent / budget.limitAmount, 1.0) }
    var isOverBudget: Bool { spent > budget.limitAmount }
    var isApproaching: Bool { percentage >= 0.8 && !isOverBudget }
}
