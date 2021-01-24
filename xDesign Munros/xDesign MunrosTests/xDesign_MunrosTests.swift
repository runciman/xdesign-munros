//
//  xDesign_MunrosTests.swift
//  xDesign MunrosTests
//
//  Created by Scott Runciman on 24/01/2021.
//

import XCTest
@testable import xDesign_Munros

class xDesign_MunrosTests: XCTestCase {

    func testModelCreation() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail()
            return
        }
        
        var munros = [Munro]()
        do {
            let csvData = try Data(contentsOf: file)
            let csv = String(data: csvData, encoding: .ascii)!
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
            

            for line in quoteEscaped {
                do {
                    let munro = try Munro(line)
                    munros.append(munro)
                } catch {
                    print(error)
                }

            }
        } catch {
            XCTFail()
            print(error)
        }
        
        XCTAssertEqual(munros.count, 602)
        
    }

}
