//
//  Munro.swift
//  xDesign Munros
//
//  Created by Scott Runciman on 24/01/2021.
//

import Foundation


struct Munro {
    
    enum MunroClassification {
        case munro
        case top
        case none
    }
    
    struct EraClassification {
        let year1891: MunroClassification
        let year1921: MunroClassification
        let year1933: MunroClassification
        let year1953: MunroClassification
        let year1969: MunroClassification
        let year1974: MunroClassification
        let year1981: MunroClassification
        let year1984: MunroClassification
        let year1990: MunroClassification
        let year1997: MunroClassification
        let post1997: MunroClassification
    }
    
    let runningNumber: Int
    let doBIHNumber: Int
    let streetmapURL: URL
    let geographURL: URL
    let hillBaggingURL: URL
    let name: String
    let smcSection: Int
    let rhbSection: String
    let section: Double
    let heightInMetres: Int
    let heightInFeet: Int
    let mapOneFiftyScale: String
    let mapOneTwentyFiveScale: String
    let gridReference: String
    let gridReferenceXY: String
    let xCoordinate: Int
    let yCoordinate: Int

    let eraClassification: EraClassification
    let comments: String
}
