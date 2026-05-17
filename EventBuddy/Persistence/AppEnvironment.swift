import Foundation

@MainActor
@Observable
final class AppEnvironment {
    let appStore: AppStore
    var store: AppStore { appStore }

    init(saveDidComplete: @escaping @MainActor () -> Void = {}) {
        self.appStore = AppStore(saveDidComplete: saveDidComplete)
    }
}
