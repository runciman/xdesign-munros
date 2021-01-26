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
    
    func munros(for request: MunroSearchRequest) -> [MunroResult] {
        var workingCopy = munros.filter({$0.eraClassification.post1997 != .none })
        
        switch request.hillCategory {
        case .full:
            break
        case .subset(let category):
            workingCopy = workingCopy.filter({ $0.eraClassification.post1997 == category})
        }
        
        switch request.maximumHeight {
        case .full:
            break
        case .subset(let maxHeight):
            workingCopy = workingCopy.filter({ $0.heightInMetres <= maxHeight})
        }
        
        switch request.minimumHeight {
        case .full:
            break
        case .subset(let minHeight):
            workingCopy = workingCopy.filter({ $0.heightInMetres >= minHeight})
        }
        
        // TODO - sorting...
        
        

        switch request.fetchLimit {
        case .full:
            break
        case .subset(let maxSize):
            workingCopy = workingCopy.dropLast(workingCopy.count - maxSize)
        }
        
        let results = workingCopy.map({MunroResult(name: $0.name, height: $0.heightInMetres, category: $0.eraClassification.post1997, gridReference: $0.gridReference)})
        
        return results
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

struct MunroSearchRequest {
    var fetchLimit: SearchScope<Int> = .full
    var hillCategory: SearchScope<Munro.MunroClassification> = .full
    var maximumHeight: SearchScope<Double> = .full
    var minimumHeight: SearchScope<Double> = .full
}
