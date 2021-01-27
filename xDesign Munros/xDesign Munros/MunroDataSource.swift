//
//  MunroDataSource.swift
//  xDesign Munros
//
//  Created by Scott Runciman on 26/01/2021.
//

import Foundation

/// Wraps up the idea of limiting values to a certain range,  without using tricks such as`"<0 is equivalent to ignoring a given field"`
enum SearchScope<T> {
    case full
    case subset(T)
}

@frozen
enum SortDirection {
    case ascending
    case descending
}

struct SortDescriptor: Hashable {
    let key: MunroSearchRequest.SortKey
    let direction: SortDirection
}

/// A `struct` representing the results of a search for Munros
struct MunroResult: Equatable {
    let name: String
    let height: Double
    let category: MunroSearchRequest.MunroCategory
    let gridReference: String
}

struct MunroSearchRequest {
    
    enum SortKey {
        case name
        case height
    }
    
    enum MunroCategory {
        case munro
        case top
    }
    
    var fetchLimit: SearchScope<UInt> = .full
    var hillCategory: SearchScope<MunroCategory> = .full
    var maximumHeight: SearchScope<Double> = .full
    var minimumHeight: SearchScope<Double> = .full
    var sortDescriptors: [SortDescriptor] = []
}

class MunroDataSource {
    
    enum Error: Swift.Error {
        case invalidURL
        case invalidRequestValue(String)
        case invalidData
    }
    
    private let munros: [Munro]
    
    
    /// Creates an instance of `MunroDataSource`, which is populated by entries from a CSV file at a given URL
    /// - Parameter csv: The `URL` of the CSV file to load
    /// - Throws: If the `URL` is a not a local path, or if the CSV could not be parsed
    init(from csv: URL) throws {
        guard csv.isFileURL else {
            throw Error.invalidURL
        }
        
        do {
            let elements = try CSVParser.csvElements(from: csv)
            var munros = [Munro]()
            for (index, line) in elements.enumerated() {
                do {
                    let munro = try Munro(line)
                    munros.append(munro)
                } catch {
                    print("Failed to parse entry at line \(index). Failed with \(error)")
                }
            }
            self.munros = munros
        }
    }
    
    
    /// Returns instances of `MunroResult`, which match the criteria specified in the `MunroSearchRequest` instance
    /// - Parameter request: The request to use as a basis for sorting and filtering the results
    /// - Throws: Errors will be thrown if the request is not a valid request that can be performed in some way
    /// - Returns: A `Collection` of  `MunroResult`
    func munros(for request: MunroSearchRequest) throws -> [MunroResult] {
        
        try validate(request)
        
        typealias MunroRequestFilter = (MunroSearchRequest, Munro) -> Bool
        
        let hillCategoryFilter: MunroRequestFilter = { (request, munro) in
            
            guard munro.eraClassification.post1997 != .none else {
                return false
            }
            
            switch request.hillCategory {
            case .full:
                return true
            case .subset(let category):
                switch (munro.eraClassification.post1997, category) {
                //This effectively provides a mapping from the internal Munro.Classification type, to the MunroSearchRequest.MunroCategory type
                case (.munro, .munro), (.top, .top):
                    return true
                default:
                    return false
                }
            }
        }
        
        let maxHeightFilter: MunroRequestFilter = { (request, munro) in
            switch request.maximumHeight {
            case .full:
                return true
            case .subset(let maxHeight):
                return munro.heightInMetres <= maxHeight
            }
        }
        
        let minHeightFilter: MunroRequestFilter = { (request, munro) in
            switch request.minimumHeight {
            case .full:
                return true
            case .subset(let minHeight):
                return munro.heightInMetres >= minHeight
            }
        }

        //By defining these as closures ahead of time, we can avoid having to do three seperate filter calls
        var workingCopy = munros.filter({ hillCategoryFilter(request, $0) && maxHeightFilter(request, $0) && minHeightFilter(request, $0) })
        
        //By defining this here, it lets us reduce switching on sort direction at point of use
        func comparator<T: Comparable>(for direction: SortDirection) -> (T, T) -> Bool {
            switch direction {
            case .ascending:
                return { $0 < $1 }
            case .descending:
                return { $0 > $1 }
            }
        }
        
        // This will return nil if lhs and rhs are equal
        func compare<V: Comparable>(lhs: Munro, rhs: Munro, by keyPath: KeyPath<Munro, V>, using comparator:(V, V) -> Bool) -> Bool? {
            if lhs[keyPath: keyPath] == rhs[keyPath: keyPath] {
                return nil
            } else {
                return comparator(lhs[keyPath: keyPath], rhs[keyPath: keyPath])
            }
        }
        
        workingCopy.sort { (lhs, rhs) -> Bool in
            for sortDescriptor in request.sortDescriptors {
                
                //Unfortunately, we can't define a general keypath here, as we would need a Type Erased Comparable box
                // So, we need to call compare on each switch statement to avoid the compiler resolving conflicting types
                switch (sortDescriptor.key) {
                case (.name):
                    guard let result = compare(lhs: lhs, rhs: rhs, by: \Munro.name, using: comparator(for: sortDescriptor.direction)) else {
                        continue
                    }
                    return result
                case (.height):
                    guard let result = compare(lhs: lhs, rhs: rhs, by: \Munro.heightInMetres, using: comparator(for: sortDescriptor.direction)) else {
                        continue
                    }
                    return result
                }
            }
            //Need to tie break if we reach this point, as it means the two entries were same across all requested sort fields
            return false
        }

        //Always filter, then sort, then cut the batch to size, to keep results consistent and accurate
        switch request.fetchLimit {
        case .full:
            break
        case .subset(let maxSize):
            workingCopy = workingCopy.dropLast(workingCopy.count - Int(maxSize))
        }
        
        let resultCategoryMapping: (Munro.Classification) throws -> MunroSearchRequest.MunroCategory = { classification in
            switch classification {
            case .top:
                return .top
            case .munro:
                return .munro
            case .none:
                print("Munros with this category should not exist by this moment")
                throw Error.invalidData
            }
        }
        
        let results = try workingCopy.map({MunroResult(name: $0.name, height: $0.heightInMetres, category: try resultCategoryMapping($0.eraClassification.post1997), gridReference: $0.gridReference)})
        
        return results
    }
    
    private func validate(_ request: MunroSearchRequest) throws {
        switch (request.minimumHeight, request.maximumHeight) {
        case (.subset(let minHeight), .subset(let maxHeight)):
            guard minHeight <= maxHeight else {
                throw MunroDataSource.Error.invalidRequestValue("maximumHeight should be greater than, or equal, to the minimumHeight")
            }
        default:
            break
        }

        switch request.fetchLimit {
        case .full:
            break
        case .subset(let maxSize):
            guard maxSize > 0 else {
                throw MunroDataSource.Error.invalidRequestValue("fetchLimit should be greater than zero")
            }
        }
    }
}
