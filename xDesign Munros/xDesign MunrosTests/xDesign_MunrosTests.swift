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
            let munros = try datasource.munros(for: request)
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
            let munros = try datasource.munros(for: request)
            
            let allMunrosRequest = MunroSearchRequest()
            let allMunros = try datasource.munros(for: allMunrosRequest)
            XCTAssertEqual(allMunros.count, 509)
            
            XCTAssertEqual(allMunros.dropLast(509 - 25), munros)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testSortingReturnsAlphabetisedNames() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            var request = MunroSearchRequest()
            request.sortDescriptors = [SortDescriptor(key: .name, direction: .ascending)]
            let munros = try datasource.munros(for: request)
            
            XCTAssertEqual(munros.first?.name, "A\' Bhuidheanach Bheag")
            XCTAssertEqual(munros.last?.name, "Tom a\' Choinich - Tom a\' Choinich Beag")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testFetchLimitAppliesToSortedEntries() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            var request = MunroSearchRequest()
            request.fetchLimit = .subset(25)
            request.sortDescriptors = [SortDescriptor(key: .name, direction: .ascending)]
            let munros = try datasource.munros(for: request)
            
            XCTAssertEqual(munros.first?.name, "A\' Bhuidheanach Bheag")
            XCTAssertEqual(munros.last?.name, "An Socach")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testMultipleSortDescriptorsApplyInOrder() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            var request = MunroSearchRequest()
            request.fetchLimit = .subset(5)
            request.sortDescriptors = [SortDescriptor(key: .height, direction: .ascending), SortDescriptor(key: .name, direction: .descending)]
            let munros = try datasource.munros(for: request)
            
            XCTAssertEqual(munros[0].name, "Mullach Coire nan Cisteachan [Carn na Caim South Top]")
            XCTAssertEqual(munros[1].name, "Beinn Teallach")
            
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testMinHeightGreaterThanMaxHeightRequestThrowsError() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            var request = MunroSearchRequest()
            request.maximumHeight = .subset(4)
            request.minimumHeight = .subset(5)
            XCTAssertThrowsError(try datasource.munros(for: request))
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testFetchLimitLessThanZeroThrowsError() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            var request = MunroSearchRequest()
            request.fetchLimit = .subset(0)
            XCTAssertThrowsError(try datasource.munros(for: request))
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testHillCategoryReturnsMatchingResults() {
        guard let file =  Bundle(for: type(of: self)).url(forResource: "munrotab_v6.2", withExtension: "csv") else {
            XCTFail("No resource found for expected URL")
            return
        }
        
        do {
            let datasource = try MunroDataSource(from: file)
            var request = MunroSearchRequest()
            request.hillCategory = .subset(.top)
            let munros = try datasource.munros(for: request)
            XCTAssertEqual(munros.filter({ $0.category != .top }).count, 0)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

}
