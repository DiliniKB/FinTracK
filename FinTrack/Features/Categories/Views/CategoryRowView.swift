import SwiftUI

/// A single row in the categories list.
///
/// Layout:
/// - Colored circle containing the category's SF Symbol icon
/// - Category name
/// - Edit button (custom categories only)
/// - Trailing swipe-to-delete handled by the parent `List`
struct CategoryRowView: View {

    let category: Category
    /// Called when the user taps the edit button. Nil for default categories.
    var onEdit: (() -> Void)?

    var body: some View {
        // TODO: HStack:
        //   - Colored circle icon:
        //       Circle filled with Color(hex: category.colorHex)
        //       SF Symbol Image(systemName: category.icon) in white
        //   - Text(category.name)
        //   - Spacer()
        //   - If !category.isDefault: edit pencil button that calls onEdit?()
        EmptyView()
    }
}

#Preview {
    List {
        CategoryRowView(
            category: .preview,
            onEdit: {}
        )
        CategoryRowView(
            category: .previewDefault,
            onEdit: nil
        )
    }
}

// MARK: - Preview helpers

private extension Category {
    static let preview = Category(
        name: "Shopping",
        icon: "bag.fill",
        colorHex: "#45B7D1",
        type: .expense,
        isDefault: false
    )
    static let previewDefault = Category(
        name: "Salary",
        icon: "briefcase.fill",
        colorHex: "#00B894",
        type: .income,
        isDefault: true
    )
}
