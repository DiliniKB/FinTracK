import Charts
import SwiftUI

struct SpendingDonutChart: View {
    let breakdown: [CategorySpend]
    let totalExpense: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .padding(.horizontal)

            Chart(breakdown) { item in
                SectorMark(
                    angle:        .value("Amount", item.amount),
                    innerRadius:  .ratio(0.55),
                    angularInset: 2
                )
                .foregroundStyle(Color(hex: item.colorHex))
                .cornerRadius(4)
            }
            .chartBackground { _ in
                VStack(spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(NumberFormatter.lkr.string(from: NSNumber(value: totalExpense)) ?? "Rs. 0")
                        .font(.subheadline.weight(.bold))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 220)
            .padding(.horizontal)

            // Legend
            VStack(spacing: 6) {
                ForEach(breakdown) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        Text(NumberFormatter.lkr.string(from: NSNumber(value: item.amount)) ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(Int(item.percentage * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
