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
            XCTFail("No resource found for expected URL")
            return
        }
        
        XCTAssertNoThrow(try MunroDataSource(from: file))
    }
    
    func testDefaultSearchReturnsAllResults() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            let request = MunroSearchRequest()
            let munros = datasource.munros(for: request)
            XCTAssertEqual(munros.count, 509)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testSearchLimitsResultsToRequestedBatchSize() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            var request = MunroSearchRequest()
            request.fetchLimit = .subset(25)
            let munros = datasource.munros(for: request)
            
            let allMunrosRequest = MunroSearchRequest()
            let allMunros = datasource.munros(for: allMunrosRequest)
            XCTAssertEqual(allMunros.count, 509)
            
            XCTAssertEqual(allMunros.dropLast(509 - 25), munros)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

}
