import Foundation
import ObservableDefaults
import Testing

private enum Color: String {
    case red
    case green
    case blue
}

@ObservableDefaults
private class RawValueDefaultsStore {
    var color: Color = .red
}

@ObservableCloud(developmentMode: true)
private class RawValueCloudStore {
    var color: Color = .red
}

@Suite("Enum RawRepresentable Tests")
struct EnumRawRepresentableTests {
    @Test
    func defaultsEnumSupport() {
        let store = RawValueDefaultsStore()
        store.color = .green
        #expect(store.color == .green)
    }

    @Test
    func cloudEnumSupport() {
        let store = RawValueCloudStore()
        store.color = .blue
        #expect(store.color == .blue)
    }
}
