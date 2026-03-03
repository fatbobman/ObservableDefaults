final class DefaultsObserveFirstFixture {
    var transient: String {
        @storageRestrictions(initializes: _transient)
        init(initialValue) {
            _transient = initialValue
        }
        get {
            access(keyPath: \.transient)
            return _transient
        }
        set {
            // Only set the value if it has changed, reduce the view re-evaluation
            guard shouldSetValue(newValue, _transient) else {
                return
            }
            withMutation(keyPath: \.transient) {
                _transient = newValue
            }
        }
        _modify {
            access(keyPath: \.transient)
            _$observationRegistrar.willSet(self, keyPath: \.transient)
            defer {
                _$observationRegistrar.didSet(self, keyPath: \.transient)
            }
            yield &_transient
        }
    }

    private  var _transient: String = "local"
    var persisted: String {
        get {
            access(keyPath: \.persisted)
            let key = _prefix + "stored_name"
            return UserDefaultsWrapper.getValue(key, _default_value_of_persisted, _userDefaults)
        }
        set {
            let key = _prefix + "stored_name"
            let currentValue = UserDefaultsWrapper.getValue(key, _persisted, _userDefaults)
            // Only set the value if it has changed, reduce the view re-evaluation
            guard shouldSetValue(newValue, currentValue) else {
                return
            }
            if _isExternalNotificationDisabled ||
            _ignoredKeyPathsForExternalUpdates.contains(\.persisted) ||
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                withMutation(keyPath: \.persisted) {
                    UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                     _persisted = newValue
                }
            } else {
                UserDefaultsWrapper.setValue(key, newValue, _userDefaults)
                _persisted = newValue
            }
        }
    }

    private  var _persisted: String = "fat"

    // initial value storage, never change after initialization
    private let _default_value_of_persisted: String  = "fat"
    var derived: String = "ignore"

    internal let _$observationRegistrar = Observation.ObservationRegistrar()

    internal nonisolated func access<Member>(keyPath: KeyPath<DefaultsObserveFirstFixture, Member>) {
      _$observationRegistrar.access(self, keyPath: keyPath)
    }

    /// Performs a mutation on the specified keyPath and notifies observers.
    /// - Parameters:
    ///   - keyPath: The key path to the property being mutated
    ///   - mutation: The mutation closure to execute
    /// - Returns: The result of the mutation closure
    internal nonisolated func withMutation<Member, T>(keyPath: KeyPath<DefaultsObserveFirstFixture, Member>, _ mutation: () throws -> T) rethrows -> T {
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

    private let _defaultsKeyPathMap: [PartialKeyPath<DefaultsObserveFirstFixture>: String] = [\DefaultsObserveFirstFixture.persisted: "stored_name"]
    private var _ignoredKeyPathsForExternalUpdates: [PartialKeyPath<DefaultsObserveFirstFixture>] = []

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
        let host: DefaultsObserveFirstFixture
        let userDefaults: Foundation.UserDefaults
        let prefix: String
        let observableKeysBlacklist: [String]

        /// Initializes the observation with the specified parameters.
        /// - Parameters:
        ///   - host: The host instance to observe
        ///   - userDefaults: The UserDefaults instance to monitor
        ///   - prefix: The key prefix for UserDefaults keys
        ///   - observableKeysBlacklist: Keys to exclude from observation
        init(host: DefaultsObserveFirstFixture, userDefaults: Foundation.UserDefaults, prefix: String, observableKeysBlacklist: [String]) {
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
            // Check all monitored keys for changes
            let monitoredKeys: [String] = [
                "stored_name"
            ]

            for key in monitoredKeys {
                let fullKey = prefix + key
                if !observableKeysBlacklist.contains(fullKey) {
                    switch fullKey {
                    case prefix + "stored_name":
        let newValue = UserDefaultsWrapper.getValue(fullKey, host._default_value_of_persisted, host._userDefaults)
        if host.shouldSetValue(newValue, host._persisted) {
            host._persisted = newValue
            host._$observationRegistrar.withMutation(of: host, keyPath: \.persisted) {}
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

    private func observerStarter(observableKeysBlacklist: [PartialKeyPath<DefaultsObserveFirstFixture>] = []) {
        let keyList = observableKeysBlacklist.compactMap {
            _defaultsKeyPathMap[$0]
        }
        observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix, observableKeysBlacklist: keyList)
    }

    public init(
        userDefaults: Foundation.UserDefaults? = nil,
        ignoreExternalChanges: Bool? = nil,
        prefix: String? = nil,
        ignoredKeyPathsForExternalUpdates: [PartialKeyPath<DefaultsObserveFirstFixture>] = []
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

extension DefaultsObserveFirstFixture: Observation.Observable {
}