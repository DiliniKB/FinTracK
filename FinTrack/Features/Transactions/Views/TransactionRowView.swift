import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon circle
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.categoryColorHex))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.categoryIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }

            // Center: category + payee
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.categoryName)
                    .font(.subheadline.weight(.semibold))
                if !transaction.payee.isEmpty {
                    Text(transaction.payee)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Amount
            Text(formattedAmount)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.type == .income ? Color.green : Color.red)
        }
        .padding(.vertical, 4)
    }

    private var formattedAmount: String {
        let prefix = transaction.type == .income ? "+" : "-"
        let formatted = NumberFormatter.lkr.string(from: NSNumber(value: transaction.amount)) ?? "Rs. 0.00"
        return "\(prefix)\(formatted)"
    }
}
