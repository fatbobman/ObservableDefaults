final class DefaultsBasicFixture {
    var name: String {
        get {
            access(keyPath: \.name)
            let key = _prefix + "name"
            return UserDefaultsWrapper.getValue(key, _default_value_of_name, _userDefaults)
        }
        set {
            let key = _prefix + "name"
            let currentValue = UserDefaultsWrapper.getValue(key, _name, _userDefaults)
            // Only set the value if it has changed, reduce the view re-evaluation
            guard shouldSetValue(newValue, currentValue) else {
                return
            }
            if _isExternalNotificationDisabled ||
            _ignoredKeyPathsForExternalUpdates.contains(\.name) ||
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                withMutation(keyPath: \.name) {
                    UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                     _name = newValue
                }
            } else {
                UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                _name = newValue
            }
        }
    }

    private  var _name: String = "fat"

    // initial value storage, never change after initialization
    private let _default_value_of_name: String  = "fat"
    var age: Int {
        get {
            access(keyPath: \.age)
            let key = _prefix + "age"
            return UserDefaultsWrapper.getValue(key, _default_value_of_age, _userDefaults)
        }
        set {
            let key = _prefix + "age"
            let currentValue = UserDefaultsWrapper.getValue(key, _age, _userDefaults)
            // Only set the value if it has changed, reduce the view re-evaluation
            guard shouldSetValue(newValue, currentValue) else {
                return
            }
            if _isExternalNotificationDisabled ||
            _ignoredKeyPathsForExternalUpdates.contains(\.age) ||
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                withMutation(keyPath: \.age) {
                    UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                     _age = newValue
                }
            } else {
                UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                _age = newValue
            }
        }
    }

    private  var _age: Int = 20

    // initial value storage, never change after initialization
    private let _default_value_of_age: Int  = 20

    internal let _$observationRegistrar = Observation.ObservationRegistrar()

    internal nonisolated func access<Member>(keyPath: KeyPath<DefaultsBasicFixture, Member>) {
      _$observationRegistrar.access(self, keyPath: keyPath)
    }

    /// Performs a mutation on the specified keyPath and notifies observers.
    /// - Parameters:
    ///   - keyPath: The key path to the property being mutated
    ///   - mutation: The mutation closure to execute
    /// - Returns: The result of the mutation closure
    internal nonisolated func withMutation<Member, T>(keyPath: KeyPath<DefaultsBasicFixture, Member>, _ mutation: () throws -> T) rethrows -> T {
      try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }

    private var _userDefaults: Foundation.UserDefaults = Foundation.UserDefaults.standard

    /// Determines whether the instance responds to UserDefaults modifications made externally.
    /// When set to `true`, the instance ignores notifications from changes made to UserDefaults
    /// by other parts of the application or other processes.
    /// When set to `false`, the instance will respond to all UserDefaults changes, regardless of their origin.
    ///
    /// - Note: This flag is particularly useful in scenarios where you want to avoid
    ///   recursive or unnecessary updates when the instance itself is modifying UserDefaults.
    ///
    /// - Important: Default value is `false`.
    private var _isExternalNotificationDisabled: Bool = false

    /// Prefix for the UserDefaults key. The default value is an empty string.
    /// Note: The prefix must not contain '.' characters.
    private var _prefix: String = ""

    private let _defaultsKeyPathMap: [PartialKeyPath<DefaultsBasicFixture>: String] = [\DefaultsBasicFixture.name: "name", \DefaultsBasicFixture.age: "age"]
    private var _ignoredKeyPathsForExternalUpdates: [PartialKeyPath<DefaultsBasicFixture>] = []

    private nonisolated func shouldSetValue<T>(_ lhs: T, _ rhs: T) -> Bool {
       true
    }

    private nonisolated func shouldSetValue<T: Equatable>(_ lhs: T, _ rhs: T) -> Bool {
       lhs != rhs
    }

    private nonisolated func shouldSetValue<T: AnyObject>(_ lhs: T, _ rhs: T) -> Bool {
       lhs !== rhs
    }

    private nonisolated func shouldSetValue<T: Equatable & AnyObject>(_ lhs: T, _ rhs: T) -> Bool {
        lhs != rhs
    }

    private var observer: DefaultsObservation?

    /// Manages UserDefaults change observation using NotificationCenter.
    ///
    /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
    private final class DefaultsObservation: @unchecked Sendable {
        weak var host: DefaultsBasicFixture?
        let userDefaults: Foundation.UserDefaults
        let prefix: String
        let observableKeysBlacklist: [String]

        /// Initializes the observation with the specified parameters.
        /// - Parameters:
        ///   - host: The host instance to observe
        ///   - userDefaults: The UserDefaults instance to monitor
        ///   - prefix: The key prefix for UserDefaults keys
        ///   - observableKeysBlacklist: Keys to exclude from observation
        init(host: DefaultsBasicFixture, userDefaults: Foundation.UserDefaults, prefix: String, observableKeysBlacklist: [String]) {
            self.host = host
            self.userDefaults = userDefaults
            self.prefix = prefix
            self.observableKeysBlacklist = observableKeysBlacklist

            NotificationCenter.default
                .addObserver(
                    forName: UserDefaults.didChangeNotification,
                    object: userDefaults,
                    queue: nil,
                    using: userDefaultsDidChange
                )
        }

        /// Handles UserDefaults changes from external sources.
        /// - Parameter notification: The notification containing change information
        @Sendable
        private func userDefaultsDidChange(_ notification: Foundation.Notification) {
            guard let host else {
                return
            }

            // Check all monitored keys for changes
            let monitoredKeys: [String] = [
                "name", "age"
            ]

            for key in monitoredKeys {
                let fullKey = prefix + key
                if !observableKeysBlacklist.contains(fullKey) {
                    switch fullKey {
                    case prefix + "name":
        let newValue = UserDefaultsWrapper.getValue(fullKey, host._default_value_of_name, host._userDefaults)
        if host.shouldSetValue(newValue, host._name) {
            host._name = newValue
            host._$observationRegistrar.withMutation(of: host, keyPath: \.name) {
            }
        }
                    case prefix + "age":
                        let newValue = UserDefaultsWrapper.getValue(fullKey, host._default_value_of_age, host._userDefaults)
                        if host.shouldSetValue(newValue, host._age) {
                            host._age = newValue
                            host._$observationRegistrar.withMutation(of: host, keyPath: \.age) {
                            }
                        }
                    default:
                        break
                    }
                }
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }

    private func observerStarter(observableKeysBlacklist: [PartialKeyPath<DefaultsBasicFixture>] = []) {
        let keyList = observableKeysBlacklist.compactMap {
            _defaultsKeyPathMap[$0]
        }
        observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix, observableKeysBlacklist: keyList)
    }

    public init(
        userDefaults: Foundation.UserDefaults? = nil,
        ignoreExternalChanges: Bool? = nil,
        prefix: String? = nil,
        ignoredKeyPathsForExternalUpdates: [PartialKeyPath<DefaultsBasicFixture>] = []
    ) {
        if let userDefaults {
            _userDefaults = userDefaults
        }
        if let ignoreExternalChanges {
            _isExternalNotificationDisabled = ignoreExternalChanges
        }
        if let prefix {
            _prefix = prefix
        }
        _ignoredKeyPathsForExternalUpdates = ignoredKeyPathsForExternalUpdates
        assert(!_prefix.contains("."), "Prefix '\(_prefix)' should not contain '.' to avoid KVO issues!")
        if !_isExternalNotificationDisabled {
            observerStarter(observableKeysBlacklist: ignoredKeyPathsForExternalUpdates)
        }
    }
}

extension DefaultsBasicFixture: Observation.Observable {
}