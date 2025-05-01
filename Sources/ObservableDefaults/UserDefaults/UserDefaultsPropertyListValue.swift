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

public protocol UserDefaultsPropertyListValue: Equatable {}

public protocol CodableUserDefaultsPropertyListValue: UserDefaultsPropertyListValue, Codable { }

extension NSData: UserDefaultsPropertyListValue {}
extension Data: UserDefaultsPropertyListValue {}

extension NSString: UserDefaultsPropertyListValue {}
extension String: UserDefaultsPropertyListValue {}

extension NSURL: UserDefaultsPropertyListValue {}
extension URL: UserDefaultsPropertyListValue {}

extension NSDate: UserDefaultsPropertyListValue {}
extension Date: UserDefaultsPropertyListValue {}

extension NSNumber: UserDefaultsPropertyListValue {}
extension Bool: UserDefaultsPropertyListValue {}
extension Int: UserDefaultsPropertyListValue {}
extension Int8: UserDefaultsPropertyListValue {}
extension Int16: UserDefaultsPropertyListValue {}
extension Int32: UserDefaultsPropertyListValue {}
extension Int64: UserDefaultsPropertyListValue {}
extension UInt: UserDefaultsPropertyListValue {}
extension UInt8: UserDefaultsPropertyListValue {}
extension UInt16: UserDefaultsPropertyListValue {}
extension UInt32: UserDefaultsPropertyListValue {}
extension UInt64: UserDefaultsPropertyListValue {}
extension Double: UserDefaultsPropertyListValue {}
extension Float: UserDefaultsPropertyListValue {}

extension Array: UserDefaultsPropertyListValue where Element: UserDefaultsPropertyListValue {}
extension Dictionary: UserDefaultsPropertyListValue where Key == String, Value: UserDefaultsPropertyListValue {}
