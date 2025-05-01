// This portion of code is derived from UserDefaultsObservation
// Source: https://github.com/tgeisse/UserDefaultsObservation
// The original code is licensed under the MIT License.

/*
 Copyright (c) 2024 Taylor Geisse

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation

public struct UserDefaultsWrapper<Value> {
    private init() {}

    // MARK: - Get Values

    public nonisolated static func getValue(_ key: String, _ defaultValue: Value, _ store: UserDefaults) -> Value
    where Value: RawRepresentable, Value.RawValue: UserDefaultsPropertyListValue {
        guard let rawValue = store.object(forKey: key) as? Value.RawValue else {
            return defaultValue
        }
        return Value(rawValue: rawValue) ?? defaultValue
    }

    public nonisolated static func getValue<R>(_ key: String, _ defaultValue: Value, _ store: UserDefaults) -> Value
    where Value == R?, R: RawRepresentable, R.RawValue: UserDefaultsPropertyListValue {
        guard let rawValue = store.object(forKey: key) as? R.RawValue else {
            return defaultValue
        }
        return R(rawValue: rawValue) ?? defaultValue
    }

    public nonisolated static func getValue(_ key: String, _ defaultValue: Value, _ store: UserDefaults) -> Value
    where Value: UserDefaultsPropertyListValue {
        return store.object(forKey: key) as? Value ?? defaultValue
    }

    public nonisolated static func getValue<R>(_ key: String, _ defaultValue: Value, _ store: UserDefaults) -> Value
    where Value == R?, R: UserDefaultsPropertyListValue {
        return store.object(forKey: key) as? R ?? defaultValue
    }

    public nonisolated static func getValue(_ key: String, _ defaultValue: Value, _ store: UserDefaults) -> Value
    where Value: CodableUserDefaultsPropertyListValue {
        guard let data = store.data(forKey: key) else {
            return defaultValue
        }
        
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            return defaultValue
        }
    }

    // MARK: - Set Values

    public nonisolated static func setValue(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value: RawRepresentable, Value.RawValue: UserDefaultsPropertyListValue {
        store.set(newValue.rawValue, forKey: key)
    }

    public nonisolated static func setValue<R>(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value == R?, R: RawRepresentable, R.RawValue: UserDefaultsPropertyListValue {
        store.set(newValue?.rawValue, forKey: key)
    }

    public nonisolated static func setValue(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value: UserDefaultsPropertyListValue {
        store.set(newValue, forKey: key)
    }

    public nonisolated static func setValue<R>(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value == R?, R: UserDefaultsPropertyListValue {
        store.set(newValue, forKey: key)
    }

    public nonisolated static func setValue(_ key: String, _ newValue: Value, _ store: UserDefaults)
    where Value: CodableUserDefaultsPropertyListValue {
        guard let data = try? JSONEncoder().encode(newValue) else { return }
        store.set(data, forKey: key)
    }
}
