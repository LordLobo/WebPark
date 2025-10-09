//
//  ArrayExtensions.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

public extension Array {
    /// Returns true if the array contains elements
    /// 
    /// This is a more semantic alternative to `!isEmpty`
    /// - Returns: `true` if the array has one or more elements, `false` if empty
    var hasItems: Bool {
        return !isEmpty
    }
}

public extension Collection {
    /// Returns true if the collection is not empty
    /// 
    /// This provides a semantic alternative to `!isEmpty` for any Collection type
    /// - Returns: `true` if the collection has one or more elements, `false` if empty
    var hasItems: Bool {
        return !isEmpty
    }
}
