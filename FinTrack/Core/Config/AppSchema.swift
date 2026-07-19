import SwiftData

// MARK: - V1 (initial release)
// Models: Category, Transaction (bank: String?), Budget (isRecurring: Bool)

enum AppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [
        Category.self,
        Transaction.self,
        Budget.self,
    ]
}

// MARK: - Migration plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        AppSchemaV1.self,
    ]
    // No stages yet — V1 is the baseline.
    // When adding V2: append AppSchemaV2.self above and add a MigrationStage here.
    static let stages: [MigrationStage] = []
}
