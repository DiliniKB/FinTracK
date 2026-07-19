import SwiftUI

struct BudgetProgressRow: View {
    let progress: BudgetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                // Category icon circle
                ZStack {
                    Circle()
                        .fill(Color(hex: progress.budget.categoryColorHex))
                        .frame(width: 36, height: 36)
                    Image(systemName: progress.budget.categoryIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }

                // Center: name + spent label
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(progress.budget.categoryName)
                            .font(.subheadline.weight(.semibold))
                        if progress.budget.isRecurring {
                            Image(systemName: "repeat")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("\(formatted(progress.spent)) spent of \(formatted(progress.budget.limitAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Percentage label
                Text("\(Int(progress.percentage * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(barColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress.barFill, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }

    private var barColor: Color {
        if progress.isOverBudget  { return .red }
        if progress.isApproaching { return .orange }
        return .green
    }

    private func formatted(_ amount: Double) -> String {
        NumberFormatter.lkr.string(from: NSNumber(value: amount)) ?? "Rs. 0.00"
    }
}
