import SwiftSyntax
import SwiftSyntaxBuilder

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
