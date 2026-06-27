import SwiftUI

/// A single row in the categories list.
/// Shows a colored icon circle, the category name, and an edit chevron
/// for custom (non-default) categories.
struct CategoryRowView: View {

    let category: Category
    /// Non-nil only for custom categories. Nil hides the edit chevron.
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Colored icon circle
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text(category.name)
                .font(.body)

            Spacer()

            if !category.isDefault {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        // Extend tap target across the full row width.
        .contentShape(Rectangle())
        .onTapGesture {
            guard !category.isDefault else { return }
            onEdit?()
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        CategoryRowView(
            category: .previewCustom,
            onEdit: { }
        )
        CategoryRowView(
            category: .previewDefault,
            onEdit: nil
        )
    }
}

private extension Category {
    static let previewCustom = Category(
        name: "Shopping", icon: "bag.fill", colorHex: "#45B7D1",
        type: .expense, isDefault: false
    )
    static let previewDefault = Category(
        name: "Salary", icon: "briefcase.fill", colorHex: "#00B894",
        type: .income, isDefault: true
    )
}
