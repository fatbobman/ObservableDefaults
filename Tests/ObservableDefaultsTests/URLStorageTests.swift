import Foundation
import ObservableDefaults
import Testing

private let defaultURL = URL(string: "https://example.com/default")!
private let updatedURL = URL(string: "https://example.com/updated?source=defaults")!
private let optionalURL = URL(string: "file:///tmp/observable-defaults-url")!
private let registeredURL = URL(string: "https://example.com/registered")!

@ObservableDefaults(prefix: "URL_defaults_")
private class DefaultsURLStore {
    var homepage = defaultURL
    var optionalHomepage: URL?
    var nsHomepage = defaultURL as NSURL
    var optionalNSHomepage: NSURL?
}

@ObservableCloud(prefix: "URL_cloud_")
private class CloudURLStore {
    var homepage = defaultURL
    var optionalHomepage: URL?
    var nsHomepage = defaultURL as NSURL
    var optionalNSHomepage: NSURL?
}

@Suite("URL Storage Tests", .serialized)
struct URLStorageTests {
    @Test("Defaults: URL values store as JSON data and round-trip")
    func defaultsURLRoundTripsThroughData() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = DefaultsURLStore(userDefaults: userDefaults)

        store.homepage = updatedURL
        #expect(store.homepage == updatedURL)
        #expect(storedURL(in: userDefaults, key: "URL_defaults_homepage") == updatedURL)
        #expect(userDefaults.object(forKey: "URL_defaults_homepage") is Data)

        let reloaded = DefaultsURLStore(userDefaults: userDefaults)
        #expect(reloaded.homepage == updatedURL)
    }

    @Test("Defaults: optional URL removes storage and falls back deterministically")
    func defaultsOptionalURLRemovalAndFallback() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = DefaultsURLStore(userDefaults: userDefaults)

        store.optionalHomepage = optionalURL
        #expect(store.optionalHomepage == optionalURL)
        #expect(storedURL(in: userDefaults, key: "URL_defaults_optionalHomepage") == optionalURL)

        store.optionalHomepage = nil
        #expect(store.optionalHomepage == nil)
        #expect(userDefaults.object(forKey: "URL_defaults_optionalHomepage") == nil)

        userDefaults.register(defaults: [
            "URL_defaults_optionalHomepage": encodedURLData(registeredURL)
        ])
        store.optionalHomepage = optionalURL
        userDefaults.removeObject(forKey: "URL_defaults_optionalHomepage")
        #expect(store.optionalHomepage == registeredURL)
    }

    @Test("Defaults: NSURL values store through URL data representation")
    func defaultsNSURLRoundTripsThroughData() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        let store = DefaultsURLStore(userDefaults: userDefaults)

        store.nsHomepage = updatedURL as NSURL
        #expect(store.nsHomepage.absoluteString == updatedURL.absoluteString)
        #expect(storedURL(in: userDefaults, key: "URL_defaults_nsHomepage") == updatedURL)

        store.optionalNSHomepage = optionalURL as NSURL
        #expect(store.optionalNSHomepage?.absoluteString == optionalURL.absoluteString)
        #expect(storedURL(in: userDefaults, key: "URL_defaults_optionalNSHomepage") == optionalURL)

        store.optionalNSHomepage = nil
        #expect(store.optionalNSHomepage == nil)
        #expect(userDefaults.object(forKey: "URL_defaults_optionalNSHomepage") == nil)
    }

    @Test("Defaults: removed URL key falls back to registered default before model default")
    func defaultsURLRemovalUsesRegisteredDefault() {
        let userDefaults = UserDefaults.getTestInstance(suiteName: #function)
        userDefaults.register(defaults: [
            "URL_defaults_homepage": encodedURLData(registeredURL)
        ])
        let store = DefaultsURLStore(userDefaults: userDefaults)

        #expect(store.homepage == registeredURL)
        store.homepage = updatedURL

        userDefaults.removeObject(forKey: "URL_defaults_homepage")
        #expect(store.homepage == registeredURL)
    }

    #if swift(>=6.1)
        @Test("Cloud: URL and NSURL values use the same JSON data representation", .testMode)
        func cloudURLValuesUseDataRepresentation() {
            UserDefaults.clearMock()
            let store = CloudURLStore(developmentMode: false)

            store.homepage = updatedURL
            #expect(store.homepage == updatedURL)
            #expect(storedURL(in: UserDefaults.mock, key: "URL_cloud_homepage") == updatedURL)

            store.optionalHomepage = optionalURL
            #expect(store.optionalHomepage == optionalURL)
            #expect(storedURL(in: UserDefaults.mock, key: "URL_cloud_optionalHomepage") == optionalURL)

            store.nsHomepage = updatedURL as NSURL
            #expect(store.nsHomepage.absoluteString == updatedURL.absoluteString)
            #expect(storedURL(in: UserDefaults.mock, key: "URL_cloud_nsHomepage") == updatedURL)

            store.optionalNSHomepage = optionalURL as NSURL
            #expect(store.optionalNSHomepage?.absoluteString == optionalURL.absoluteString)
            #expect(storedURL(in: UserDefaults.mock, key: "URL_cloud_optionalNSHomepage") == optionalURL)

            store.optionalHomepage = nil
            store.optionalNSHomepage = nil
            #expect(UserDefaults.mock.object(forKey: "URL_cloud_optionalHomepage") == nil)
            #expect(UserDefaults.mock.object(forKey: "URL_cloud_optionalNSHomepage") == nil)
        }
    #endif

    private func storedURL(in userDefaults: UserDefaults, key: String) -> URL? {
        guard let data = userDefaults.object(forKey: key) as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(URL.self, from: data)
    }

    private func encodedURLData(_ url: URL) -> Data {
        try! JSONEncoder().encode(url)
    }
}
