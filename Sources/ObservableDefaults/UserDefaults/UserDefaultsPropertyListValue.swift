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

/// A protocol that defines types that can be stored in UserDefaults as property list values.
/// Property list values are the fundamental data types that can be serialized and stored
/// in UserDefaults, including primitives, collections, and some Foundation types.
/// - Note: All conforming types must also be Equatable to support value comparison
public protocol UserDefaultsPropertyListValue: Equatable {}

// MARK: - Data Types

/// NSData conforms to UserDefaultsPropertyListValue as it's a fundamental property list type
extension NSData: UserDefaultsPropertyListValue {}

/// Data conforms to UserDefaultsPropertyListValue as it's a fundamental property list type
extension Data: UserDefaultsPropertyListValue {}

// MARK: - String Types

/// NSString conforms to UserDefaultsPropertyListValue as it's a fundamental property list type
extension NSString: UserDefaultsPropertyListValue {}

/// String conforms to UserDefaultsPropertyListValue as it's a fundamental property list type
extension String: UserDefaultsPropertyListValue {}

// MARK: - URL Types

/// NSURL conforms to UserDefaultsPropertyListValue as it can be stored in property lists
extension NSURL: UserDefaultsPropertyListValue {}

/// URL conforms to UserDefaultsPropertyListValue as it can be stored in property lists
extension URL: UserDefaultsPropertyListValue {}

// MARK: - Date Types

/// NSDate conforms to UserDefaultsPropertyListValue as it's a fundamental property list type
extension NSDate: UserDefaultsPropertyListValue {}

/// Date conforms to UserDefaultsPropertyListValue as it's a fundamental property list type
extension Date: UserDefaultsPropertyListValue {}

// MARK: - Number Types

/// NSNumber conforms to UserDefaultsPropertyListValue as it's a fundamental property list type
extension NSNumber: UserDefaultsPropertyListValue {}

/// Bool conforms to UserDefaultsPropertyListValue as it can be stored as a number in property lists
extension Bool: UserDefaultsPropertyListValue {}

/// Int conforms to UserDefaultsPropertyListValue as it can be stored as a number in property lists
extension Int: UserDefaultsPropertyListValue {}

/// Int8 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property lists
extension Int8: UserDefaultsPropertyListValue {}

/// Int16 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension Int16: UserDefaultsPropertyListValue {}

/// Int32 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension Int32: UserDefaultsPropertyListValue {}

/// Int64 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension Int64: UserDefaultsPropertyListValue {}

/// UInt conforms to UserDefaultsPropertyListValue as it can be stored as a number in property lists
extension UInt: UserDefaultsPropertyListValue {}

/// UInt8 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension UInt8: UserDefaultsPropertyListValue {}

/// UInt16 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension UInt16: UserDefaultsPropertyListValue {}

/// UInt32 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension UInt32: UserDefaultsPropertyListValue {}

/// UInt64 conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension UInt64: UserDefaultsPropertyListValue {}

/// Double conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension Double: UserDefaultsPropertyListValue {}

/// Float conforms to UserDefaultsPropertyListValue as it can be stored as a number in property
/// lists
extension Float: UserDefaultsPropertyListValue {}

// MARK: - Collection Types

/// Array conforms to UserDefaultsPropertyListValue when its elements also conform to
/// UserDefaultsPropertyListValue.
/// This allows arrays of supported types to be stored directly in UserDefaults.
/// - Note: All elements must be property list compatible for the array to be storable
extension Array: UserDefaultsPropertyListValue where Element: UserDefaultsPropertyListValue {}

/// Dictionary conforms to UserDefaultsPropertyListValue when it has String keys and property list
/// compatible values.
/// This allows dictionaries with string keys and supported value types to be stored directly in
/// UserDefaults.
/// - Note: Keys must be String and values must be property list compatible for the dictionary to be
/// storable
extension Dictionary: UserDefaultsPropertyListValue where Key == String,
Value: UserDefaultsPropertyListValue {}

// MARK: - Optional Types

/// Optional conforms to UserDefaultsPropertyListValue when its wrapped type also conforms to
/// UserDefaultsPropertyListValue.
/// This allows optional property list compatible types to be stored directly in UserDefaults.
/// - Note: The wrapped type must be property list compatible for the optional to be storable
extension Optional: UserDefaultsPropertyListValue where Wrapped: UserDefaultsPropertyListValue {}
