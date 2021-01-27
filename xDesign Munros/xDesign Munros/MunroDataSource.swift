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

enum CSVParser {
    enum Error: Swift.Error {
        case invalidData
        
    }
    
    static func csvElements(from url: URL) throws -> [[String]] {
        do {
            let csvData = try Data(contentsOf: url)
            guard let csv = String(data: csvData, encoding: .ascii) else {
                throw Error.invalidData
            }
            let lines = csv.components(separatedBy: .newlines).compactMap({ $0 != "" ? $0 : nil })
            let components = lines.map({$0.components(separatedBy: ",")})
            
            var quoteEscaped = [[String]]()
            
            for line in components {
                var searchingForEndToken = false
                let escaped: [String] = line.reduce([]) { (ongoing, component) in
                    let appendToPrevious: (String) -> [String] = { value in
                        var result = ongoing
                        result[result.count - 1] = result[result.count - 1] + "," + value
                        return result
                    }
                    
                    let createNewEntry: (String) -> [String] = { value in
                        var result = ongoing
                        result.append(value)
                        return result
                    }
                    
                    if component.hasPrefix("\"") {
                        let finalValue = String(component.suffix(from: component.index(after: component.startIndex)))
                        searchingForEndToken = true
                        return createNewEntry(finalValue)
                    } else if component.hasSuffix("\"") {
                        searchingForEndToken = false
                        let finalValue = String(component.prefix(upTo: component.index(before: component.endIndex)))
                        return appendToPrevious(finalValue)
                    } else {
                        if searchingForEndToken {
                            return appendToPrevious(component)
                        } else {
                            return createNewEntry(component)
                        }
                    }
                }
                quoteEscaped.append(escaped)
            }
            return quoteEscaped
        }
    }
}

class MunroDataSource {
    
    enum Error: Swift.Error {
        case invalidURL
        case invalidRequestValue(String)
    }
    
    private let munros: [Munro]
    
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
                return (munro.eraClassification.post1997 == category)
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

        var workingCopy = munros.filter({ hillCategoryFilter(request, $0) && maxHeightFilter(request, $0) && minHeightFilter(request, $0) })
        
        
        workingCopy.sort { (lhs, rhs) -> Bool in
            for sortDescriptor in request.sortDescriptors {
                switch (sortDescriptor.key, sortDescriptor.direction) {
                case (.name, .ascending):
                    if lhs.name == rhs.name {
                        continue
                    } else {
                        return lhs.name < rhs.name
                    }
                case (.name, .descending):
                    if lhs.name == rhs.name {
                        continue
                    } else {
                        return lhs.name > rhs.name
                    }
                case (.height, .ascending):
                    if lhs.heightInMetres == rhs.heightInMetres {
                        continue
                    } else {
                        return lhs.heightInMetres < rhs.heightInMetres
                    }
                case (.height, .descending):
                    if lhs.heightInMetres == rhs.heightInMetres {
                        continue
                    } else {
                        return lhs.heightInMetres < rhs.heightInMetres
                    }
                }
            }
            //Need to tie break if we reach this point, as it means the two entries were same across al requested sort fields
            return false
        }
        
        

        switch request.fetchLimit {
        case .full:
            break
        case .subset(let maxSize):
            workingCopy = workingCopy.dropLast(workingCopy.count - maxSize)
        }
        
        let results = workingCopy.map({MunroResult(name: $0.name, height: $0.heightInMetres, category: $0.eraClassification.post1997, gridReference: $0.gridReference)})
        
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

@frozen
enum SortDirection {
    case ascending
    case descending
}

struct SortDescriptor: Hashable {
    let key: MunroSearchRequest.SortKey
    let direction: SortDirection
}

struct MunroResult: Equatable {
    let name: String
    let height: Double
    let category: Munro.MunroClassification
    let gridReference: String
}

struct MunroSearchRequest {
    
    enum SortKey {
        case name
        case height
    }
    
    var fetchLimit: SearchScope<Int> = .full
    var hillCategory: SearchScope<Munro.MunroClassification> = .full
    var maximumHeight: SearchScope<Double> = .full
    var minimumHeight: SearchScope<Double> = .full
    var sortDescriptors: [SortDescriptor] = []
}

