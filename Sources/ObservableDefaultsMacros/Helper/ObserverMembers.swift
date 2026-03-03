import SwiftSyntax
import SwiftSyntaxBuilder

// Defaults observation needs both the generated observer class and the starter that
// translates ignored key paths into storage keys, so the helper returns both members.
func makeDefaultsObserverMembers(
    className: IdentifierPatternSyntax,
    caseCode: String,
    monitoredKeysLiteral: String,
    hasMainActor: Bool,
    limitToInstance: Bool,
    defaultIsolationIsMainActor: Bool,
    metas: [PersistedPropertyMeta]
) -> [DeclSyntax] {
    let observerSyntax: DeclSyntax =
        if metas.isEmpty {
            """
            private var observer: DefaultsObservation?

            /// Manages UserDefaults change observation using NotificationCenter.
            ///
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private final class DefaultsObservation: @unchecked Sendable {
                let host: \(className)
                let userDefaults: Foundation.UserDefaults
                let prefix: String
                let observableKeysBlacklist: [String]

                /// Initializes the observation with the specified parameters.
                /// - Parameters:
                ///   - host: The host instance to observe
                ///   - userDefaults: The UserDefaults instance to monitor
                ///   - prefix: The key prefix for UserDefaults keys
                ///   - observableKeysBlacklist: Keys to exclude from observation
                init(host: \(className), userDefaults: Foundation.UserDefaults, prefix: String, observableKeysBlacklist: [String]) {
                    self.host = host
                    self.userDefaults = userDefaults
                    self.prefix = prefix
                    self.observableKeysBlacklist = observableKeysBlacklist
                    // No properties to observe, so no need to register for notifications
                }

                deinit {
                    // No observer to remove
                }
            }
            """
        } else if hasMainActor {
            """
            private var observer: DefaultsObservation?

            /// Manages UserDefaults change observation using NotificationCenter.
            ///
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private final class DefaultsObservation: @unchecked Sendable {
                let host: \(className)
                let userDefaults: Foundation.UserDefaults
                let prefix: String
                let observableKeysBlacklist: [String]
                private var notificationObserver: NSObjectProtocol?

                /// Initializes the observation with the specified parameters.
                /// - Parameters:
                ///   - host: The host instance to observe
                ///   - userDefaults: The UserDefaults instance to monitor
                ///   - prefix: The key prefix for UserDefaults keys
                ///   - observableKeysBlacklist: Keys to exclude from observation
                init(host: \(className), userDefaults: Foundation.UserDefaults, prefix: String, observableKeysBlacklist: [String]) {
                    self.host = host
                    self.userDefaults = userDefaults
                    self.prefix = prefix
                    self.observableKeysBlacklist = observableKeysBlacklist

                    notificationObserver = NotificationCenter.default
                        .addObserver(
                            forName: UserDefaults.didChangeNotification,
                            object: \(raw: limitToInstance ? "userDefaults" : "nil"),
                            queue: .main
                        ) { [weak host, prefix, observableKeysBlacklist] notification in
                            guard let host else { return }
                            
                            // Check all monitored keys for changes
                            let monitoredKeys: [String] = [
                                \(raw: monitoredKeysLiteral)
                            ]

                            for key in monitoredKeys {
                                let fullKey = prefix + key
                                if !observableKeysBlacklist.contains(fullKey) {
                                    switch fullKey {
                                    \(raw: caseCode)
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                }

                \(raw: defaultIsolationIsMainActor ? "@MainActor" : "")
                deinit {
                    if let observer = notificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
            """
        } else {
            """
            private var observer: DefaultsObservation?

            /// Manages UserDefaults change observation using NotificationCenter.
            ///
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private final class DefaultsObservation: @unchecked Sendable {
                let host: \(className)
                let userDefaults: Foundation.UserDefaults
                let prefix: String
                let observableKeysBlacklist: [String]

                /// Initializes the observation with the specified parameters.
                /// - Parameters:
                ///   - host: The host instance to observe
                ///   - userDefaults: The UserDefaults instance to monitor
                ///   - prefix: The key prefix for UserDefaults keys
                ///   - observableKeysBlacklist: Keys to exclude from observation
                init(host: \(className), userDefaults: Foundation.UserDefaults, prefix: String, observableKeysBlacklist: [String]) {
                    self.host = host
                    self.userDefaults = userDefaults
                    self.prefix = prefix
                    self.observableKeysBlacklist = observableKeysBlacklist

                    NotificationCenter.default
                        .addObserver(
                            forName: UserDefaults.didChangeNotification,
                            object: \(raw: limitToInstance ? "userDefaults" : "nil"),
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
                        \(raw: monitoredKeysLiteral)
                    ]

                    for key in monitoredKeys {
                        let fullKey = prefix + key
                        if !observableKeysBlacklist.contains(fullKey) {
                            switch fullKey {
                            \(raw: caseCode)
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
            """
        }

    let observerStarterSyntax: DeclSyntax =
        if metas.isEmpty {
            """
            private func observerStarter(observableKeysBlacklist: [PartialKeyPath<\(raw: className)>] = []) {
                // No properties to observe
                observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix, observableKeysBlacklist: [])
            }
            """
        } else {
            """
            private func observerStarter(observableKeysBlacklist: [PartialKeyPath<\(raw: className)>] = []) {
                let keyList = observableKeysBlacklist.compactMap { _defaultsKeyPathMap[$0] }
                observer = DefaultsObservation(host: self, userDefaults: _userDefaults, prefix: _prefix, observableKeysBlacklist: keyList)
            }
            """
        }

    return [observerSyntax, observerStarterSyntax]
}

// Cloud observation only needs the observer class itself because initialization is
// handled directly by the generated init in ObservableCloudMacro.
func makeCloudObserverSyntax(
    className: IdentifierPatternSyntax,
    caseCode: String,
    hasMainActor: Bool,
    defaultIsolationIsMainActor: Bool
) -> DeclSyntax {
    if hasMainActor {
        return
            """
            private var _cloudObserver: CloudObservation?

            /// Manages NSUbiquitousKeyValueStore change observation for external cloud updates.
            ///
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private final class CloudObservation: @unchecked Sendable {
                let host: \(className)
                let prefix: String
                private var notificationObserver: NSObjectProtocol?

                /// Initializes the observation with the specified parameters.
                /// - Parameters:
                ///   - host: The host instance to observe
                ///   - prefix: The prefix for the NSUbiquitousKeyValueStore keys
                init(host: \(className), prefix: String) {
                    self.host = host
                    self.prefix = prefix

                    notificationObserver = NotificationCenter.default
                        .addObserver(
                            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                            object: nil,
                            queue: .main
                        ) { [weak host, prefix] notification in
                            guard let host else { return }
                            
                            guard let userInfo = notification.userInfo,
                                let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
                            else {
                                return
                            }

                            for key in changedKeys {
                                switch key {
                                \(raw: caseCode)
                                default:
                                    break
                                }
                            }
                        }
                }

                \(raw: defaultIsolationIsMainActor ? "@MainActor" : "")
                deinit {
                    if let observer = notificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
            """
    } else {
        return
            """
            private var _cloudObserver: CloudObservation?

            /// Manages NSUbiquitousKeyValueStore change observation for external cloud updates.
            ///
            /// It ensures that the observer is properly registered and deregistered when the instance is created and destroyed.
            private final class CloudObservation: @unchecked Sendable {
                let host: \(className)
                let prefix: String

                /// Initializes the observation with the specified parameters.
                /// - Parameters:
                ///   - host: The host instance to observe
                ///   - prefix: The prefix for the NSUbiquitousKeyValueStore keys
                init(host: \(className), prefix: String) {
                    self.host = host
                    self.prefix = prefix
                    NotificationCenter.default
                        .addObserver(
                            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                            object: nil,
                            queue: nil,
                            using: cloudStoreDidChange
                        )
                }

                /// Handles cloud store changes from external sources.
                /// - Parameter notification: The notification containing changed keys information
                @Sendable
                private func cloudStoreDidChange(_ notification: Foundation.Notification) {
                    guard let userInfo = notification.userInfo,
                        let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
                    else {
                        return
                    }

                    for key in changedKeys {
                        switch key {
                            \(raw: caseCode)
                            default:
                                break
                        }
                    }
                }

                deinit {
                    NotificationCenter.default.removeObserver(self)
                }
            }
            """
    }
}
