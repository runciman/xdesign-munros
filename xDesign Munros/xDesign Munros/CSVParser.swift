//
//  CSVParser.swift
//  xDesign Munros
//
//  Created by Scott Runciman on 27/01/2021.
//

import Foundation

enum CSVParser {
    enum Error: Swift.Error {
        case invalidData
    }
    
    /// Read text from a given URL, and attempts to split the text, assuming comma delimited structuring
    /// - Parameter url: The `URL` to read text from
    /// - Throws: If text cannot be read from the specified URL, an error will br thrown
    /// - Returns: A two dimensional `Array` of  `String`, representing each line, and each element within that line
    static func csvElements(from url: URL) throws -> [[String]] {
        do {
            let csvData = try Data(contentsOf: url)
            guard let csv = String(data: csvData, encoding: .ascii) else {
                throw Error.invalidData
            }
            
            //Ignore empty lines
            let lines = csv.components(separatedBy: .newlines).compactMap({ $0 != "" ? $0 : nil })
            //Do our prelimanary split by comma
            let components = lines.map({$0.components(separatedBy: ",")})
            
            var quoteEscaped = [[String]]()
            //Splitting by comma though means we would split on commas that should be escaped
            //So, after the split, search for elements which begin with the esaping quotation mark
            //and collapse all elements into a single element until the corresponding end quotation mark is found
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
