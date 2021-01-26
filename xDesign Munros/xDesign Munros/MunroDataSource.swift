//
//  MunroDataSource.swift
//  xDesign Munros
//
//  Created by Scott Runciman on 26/01/2021.
//

import Foundation

enum SearchScope<T> {
    case full
    case subset(T)
}

class MunroDataSource {
    
    
    init(from csv: URL) {
        
    }
    
    func munros(for reqquest: MunroSearchRequest) -> [MunroResult] {
        return []
    }
}

@frozen
enum SortDirection {
    case ascending
    case descending
}

struct SortDescriptor<K, V>: Hashable {
    let keyPath: KeyPath<K, V>
    let direction: SortDirection
}
struct MunroResult {
    let name: String
    let height: Double
    let category: Munro.MunroClassification
    let gridReference: String
}

class MunroSearchRequest {
    var fetchLimit: SearchScope<Int> = .full
    var hillCategory: SearchScope<Munro.MunroClassification> = .full
    var maximumHeight: SearchScope<Int> = .full
    var minimumHeight: SearchScope<Int> = .full
    var sortCriteria: SortDescriptor<MunroResult, String> = SortDescriptor(keyPath: \MunroResult.name, direction: .ascending)
}
