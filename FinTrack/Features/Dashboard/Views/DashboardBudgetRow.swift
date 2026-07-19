import SwiftUI

struct DashboardBudgetRow: View {
    let progress: BudgetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(progress.budget.categoryName)
                    .font(.subheadline)
                if progress.budget.isRecurring {
                    Image(systemName: "repeat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(progress.percentage * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemFill))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress.barFill, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 2)
    }

    private var barColor: Color {
        if progress.isOverBudget  { return .red }
        if progress.isApproaching { return .orange }
        return .green
    }
}
