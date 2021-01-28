//
//  SortDescriptor.swift
//  xDesign Munros
//
//  Created by Scott Runciman on 28/01/2021.
//

import Foundation

/// Providers a wrapper around sorting `Comparable` values from an instance of a `KeyPath`
public struct SortDescriptor<Key> {
    
    @frozen
    /// The order in which sort results should be returned
    public enum Order {
        case ascending
        case descending
    }
    
    @frozen
    /// Describes the result of a comparison
    public enum Comparison {
        case equal
        case lessThan
        case greaterThan
        
        /// The standard library sort function uses `true` for "greater than", and `false` for "less than"
        /// This `init` provides a mapping from those values to an instance of `Self`
        /// - Parameter stdlibComparison: The `Bool` value to use as the basis for `Self`
        init(from stdlibComparison: Bool) {
            if stdlibComparison {
                self = .greaterThan
            } else {
                self = .lessThan
            }
        }
    }
    
    /// Performs a comparson between two instances of `Key`, and returns the result as an instance of `Comparison`
    public let compare: (Key, Key) -> Comparison
    
    /// Creates an instance of `Self`, that is able to perform a sort based on `keyPath`
    /// - Parameters:
    ///   - keyPath: The `KeyPath` which should be sorted on. Must point to a `Comparable`
    ///   - direction: The direction in which results should be ordered
    public init<Value: Comparable>(sort keyPath: KeyPath<Key, Value>, in direction: Order) {
        compare = { (lhs, rhs) in
            
            if lhs[keyPath: keyPath] == rhs[keyPath: keyPath] {
                return .equal
            }
            
            switch direction {
            case .ascending:
                return Comparison(from: lhs[keyPath: keyPath] < rhs[keyPath: keyPath])
            case .descending:
                return Comparison(from: lhs[keyPath: keyPath] > rhs[keyPath: keyPath])
            }
        }
    }
}
