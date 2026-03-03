final class CloudObserveFirstFixture {
    var theme: String {
        get {
            access(keyPath: \.theme)
            if _developmentMode_ {
                return _theme
            } else {
                let key = _prefix + "theme"
                return NSUbiquitousKeyValueStoreWrapper.default.getValue(key, _default_value_of_theme)
            }
        }
        set {
            if _developmentMode_ {
                let currentValue = _theme
                guard shouldSetValue(newValue, currentValue) else {
                    return
                }
                withMutation(keyPath: \.theme) {
                    _theme = newValue
                }
            } else {
                let key = _prefix + "theme"
                let store = NSUbiquitousKeyValueStoreWrapper.default
                let currentValue = store.getValue(key, _theme)
                guard shouldSetValue(newValue, currentValue) else {
                    return
                }
                store.setValue(key, newValue)
                if _syncImmediately {
                    _ = store.synchronize()
                }
                withMutation(keyPath: \.theme) {
                    _theme = newValue
                }
            }
        }
    }

    private  var _theme: String = "light"

    // initial value storage, never change after initialization
    private let _default_value_of_theme: String  = "light"

    var ephemeral: String {
        @storageRestrictions(initializes: _ephemeral)
        init(initialValue) {
            _ephemeral = initialValue
        }
        get {
            access(keyPath: \.ephemeral)
            return _ephemeral
        }
        set {
            // Only set the value if it has changed, reduce the view re-evaluation
            guard shouldSetValue(newValue, _ephemeral) else {
                return
            }
            withMutation(keyPath: \.ephemeral) {
                _ephemeral = newValue
            }
        }
        _modify {
            access(keyPath: \.ephemeral)
            _$observationRegistrar.willSet(self, keyPath: \.ephemeral)
            defer {
                _$observationRegistrar.didSet(self, keyPath: \.ephemeral)
            }
            yield &_ephemeral
        }
    }

    private  var _ephemeral: String = "scratch"

    internal let _$observationRegistrar = Observation.ObservationRegistrar()

    internal nonisolated func access<Member>(keyPath: KeyPath<CloudObserveFirstFixture, Member>) {
      _$observationRegistrar.access(self, keyPath: keyPath)
    }

    /// Performs a mutation on the specified keyPath and notifies observers.
    /// - Parameters:
    ///   - keyPath: The key path to the property being mutated
    ///   - mutation: The mutation closure to execute
    /// - Returns: The result of the mutation closure
    internal nonisolated func withMutation<Member, T>(keyPath: KeyPath<CloudObserveFirstFixture, Member>, _ mutation: () throws -> T) rethrows -> T {
      try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }

    /// Prefix for the NSUbiquitousKeyValueStore key. The default value is an empty string.
    /// Note: The prefix must not contain '.' characters.
    private var _prefix: String = ""

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

    /// Controls whether to call `NSUbiquitousKeyValueStore.synchronize()` immediately after setting a value.
    ///
    /// When set to `true`, changes are immediately synchronized with iCloud.
    /// When set to `false`, synchronization follows the system's default behavior.
    ///
    /// - Note: Immediate synchronization can impact performance but ensures data consistency.
    /// - Important: Default value is `false`.
    private var _syncImmediately = false

    /// Determines whether the instance operates in development or production mode.
    ///
    /// - Development mode: Uses memory storage for testing and development, avoiding CloudKit container requirements.
    /// - Production mode: Uses NSUbiquitousKeyValueStore for actual cloud data storage.
    ///
    /// Development mode is automatically enabled when:
    /// - Explicitly set via initializer parameter
    /// - Running in SwiftUI Previews (XCODE_RUNNING_FOR_PREVIEWS environment variable)
    /// - OBSERVABLE_DEFAULTS_DEV_MODE environment variable is set to "true"
    ///
    /// - Important: Default value is `false` (production mode).
    private var _developmentMode: Bool = true
    public var _developmentMode_: Bool {
        if _developmentMode
            || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["OBSERVABLE_DEFAULTS_DEV_MODE"] == "true"
        {
            true
        } else {
            false
        }
    }

    private var _cloudObserver: CloudObservation?

    /// Manages NSUbiquitousKeyValueStore change observation for external cloud updates.
    ///
    /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
    private final class CloudObservation: @unchecked Sendable {
        weak var host: CloudObserveFirstFixture?
        let prefix: String
        private var notificationObserver: NSObjectProtocol?

        /// Initializes the observation with the specified parameters.
        /// - Parameters:
        ///   - host: The host instance to observe
        ///   - prefix: The prefix for the NSUbiquitousKeyValueStore keys
        init(host: CloudObserveFirstFixture, prefix: String) {
            self.host = host
            self.prefix = prefix
            notificationObserver = NotificationCenter.default
                .addObserver(
                    forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                    object: nil,
                    queue: nil,
                    using: { [weak self] notification in
                        self?.cloudStoreDidChange(notification)
                    })
        }

        /// Handles cloud store changes from external sources.
        /// - Parameter notification: The notification containing changed keys information
        @Sendable
        private func cloudStoreDidChange(_ notification: Foundation.Notification) {
            guard let host else {
                return
            }

            guard let userInfo = notification.userInfo,
                let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            else {
                return
            }

            for key in changedKeys {
                switch key {
                    case prefix + "theme":
                    host._$observationRegistrar.withMutation(of: host, keyPath: \.theme) {
                    }
                    default:
                        break
                }
            }
        }

        deinit {
            if let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    public init(
        prefix: String? = nil,
        syncImmediately: Bool = false,
        developmentMode: Bool = true
    ) {
        if let prefix {
            _prefix = prefix
        }
        _syncImmediately = syncImmediately
        _developmentMode = developmentMode
        assert(!_prefix.contains("."), "Prefix '\(_prefix)' should not contain '.' to avoid KVO issues!")
        if !_developmentMode_ {
            _cloudObserver = CloudObservation(host: self, prefix: _prefix)
        } else {
            #if DEBUG
            print("Development mode is enabled, using memory storage for testing and development.")
            #endif
        }
    }
}

extension CloudObserveFirstFixture: Observation.Observable {
}