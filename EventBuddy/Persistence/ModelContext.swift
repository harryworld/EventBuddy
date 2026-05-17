import Foundation
import SwiftUI

struct FetchDescriptor<Model> {
    var predicate: Predicate<Model>?
    var sortBy: [SortDescriptor<Model>]

    init(predicate: Predicate<Model>? = nil, sortBy: [SortDescriptor<Model>] = []) {
        self.predicate = predicate
        self.sortBy = sortBy
    }
}

@MainActor
@Observable
final class ModelContext {
    private unowned let store: AppStore

    init(store: AppStore) {
        self.store = store
    }

    func reload() throws {
        try store.reload()
    }

    func insert(_ event: Event) {
        store.insert(event)
    }

    func insert(_ friend: Friend) {
        store.insert(friend)
    }

    func insert(_ profile: Profile) {
        store.insert(profile)
    }

    func delete(_ event: Event) {
        store.delete(event)
    }

    func delete(_ friend: Friend) {
        store.delete(friend)
    }

    func delete(_ profile: Profile) {
        store.delete(profile)
    }

    func delete<Model>(model: Model.Type) throws {
        switch model {
        case is Event.Type:
            store.deleteAllEvents()
        case is Friend.Type:
            store.deleteAllFriends()
        case is Profile.Type:
            store.deleteAllProfiles()
        default:
            break
        }
        try save()
    }

    func save() throws {
        try store.persistAll()
        try store.reload()
    }

    func fetch<Model>(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        let source: [Model]
        switch Model.self {
        case is Event.Type:
            source = store.events as! [Model]
        case is Friend.Type:
            source = store.friends as! [Model]
        case is Profile.Type:
            source = store.profiles as! [Model]
        default:
            source = []
        }

        let filtered = try source.filter { model in
            guard let predicate = descriptor.predicate else { return true }
            return try predicate.evaluate(model)
        }

        guard !descriptor.sortBy.isEmpty else { return filtered }
        return filtered.sorted(using: descriptor.sortBy)
    }
}

private struct ModelContextEnvironmentKey: EnvironmentKey {
    static let defaultValue: ModelContext = MainActor.assumeIsolated {
        ModelContext(store: AppStore())
    }
}

extension EnvironmentValues {
    var modelContext: ModelContext {
        get { self[ModelContextEnvironmentKey.self] }
        set { self[ModelContextEnvironmentKey.self] = newValue }
    }
}

extension View {
    func modelContainer(_ container: Any) -> some View {
        self
    }

    func modelContainer(for models: [Any.Type], inMemory: Bool = false) -> some View {
        self
    }

    func modelContainer(for model: Any.Type, inMemory: Bool = false) -> some View {
        self
    }
}

@MainActor
@Observable
final class AppEnvironment {
    let store: AppStore
    let modelContext: ModelContext

    init() {
        let store = AppStore()
        self.store = store
        self.modelContext = ModelContext(store: store)
    }
}
