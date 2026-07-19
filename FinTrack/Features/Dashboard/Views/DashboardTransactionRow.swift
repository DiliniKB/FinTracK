import SwiftUI

struct DashboardTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.categoryColorHex))
                    .frame(width: 32, height: 32)
                Image(systemName: transaction.categoryIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.payee.isEmpty ? transaction.categoryName : transaction.payee)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(transaction.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(amountLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.type == .income ? .green : .red)
        }
    }

    private var amountLabel: String {
        let prefix = transaction.type == .income ? "+" : "-"
        let formatted = NumberFormatter.lkr.string(from: NSNumber(value: transaction.amount)) ?? "Rs. 0.00"
        return prefix + formatted
    }
}
