//
//  Munro.swift
//  xDesign Munros
//
//  Created by Scott Runciman on 24/01/2021.
//

import Foundation


struct Munro {
    
    enum MunroClassification: String {
        case munro = "MUN"
        case top = "TOP"
        case none = ""
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
    
    var runningNumber: Int
    var doBIHNumber: Int
    var streetmapURL: URL
    var geographURL: URL
    var hillBaggingURL: URL
    var name: String
    var smcSection: Int
    var rhbSection: String
    var section: Double
    var heightInMetres: Double
    var heightInFeet: Double
    var mapOneFiftyScale: String
    var mapOneTwentyFiveScale: String
    var gridReference: String
    var gridReferenceXY: String
    var xCoordinate: Int
    var yCoordinate: Int
    var eraClassification: EraClassification
    var comments: String
}

extension Munro {
    
    enum Error: Swift.Error {
        case nonCSVString
        case missingEntries
        case typeMismatch(entryName: String)
    }
    
    init<T>(_ entries: [T]) throws where T: StringProtocol {
        guard entries.count == 29 else {
            throw Munro.Error.missingEntries
        }
        
        func value<T: StringProtocol, V>(value: T, as type: V.Type) throws -> V {
            
            let finalValue: V?
            switch V.self {
            case is String.Type:
                finalValue = String(value) as? V
            case is Int.Type:
                finalValue = Int(value) as? V
            case is Double.Type:
                finalValue = Double(value) as? V
            case is URL.Type:
                finalValue = URL(string: String(value).replacingOccurrences(of: "\"", with: "")) as? V
            default:
                throw Munro.Error.missingEntries
            }
            
            guard let unwrapped = finalValue else {
                throw Munro.Error.typeMismatch(entryName: "Found \(T.self) instead of \(V.self)")
            }
            return unwrapped
        }
        
        
        runningNumber = try value(value: entries[0], as: Int.self)
        doBIHNumber = try value(value: entries[1], as: Int.self)
        streetmapURL = try value(value: entries[2], as: URL.self)
        geographURL = try value(value: entries[3], as: URL.self)
        hillBaggingURL = try value(value: entries[4], as: URL.self)
        name = try value(value: entries[5], as: String.self)
        smcSection = try value(value: entries[6], as: Int.self)
        rhbSection = try value(value: entries[7], as: String.self)
        section = try value(value: entries[8], as: Double.self)
        heightInMetres = try value(value: entries[9], as: Double.self)
        heightInFeet = try value(value: entries[10], as: Double.self)
        mapOneFiftyScale = try value(value: entries[11], as: String.self)
        mapOneTwentyFiveScale = try value(value: entries[12], as: String.self)
        gridReference = try value(value: entries[13], as: String.self)
        gridReferenceXY = try value(value: entries[14], as: String.self)
        xCoordinate = try value(value: entries[15], as: Int.self)
        yCoordinate = try value(value: entries[16], as: Int.self)
        
        let year1891 = MunroClassification(rawValue: String(entries[17])) ?? MunroClassification.none
        let year1921 = MunroClassification(rawValue: String(entries[18])) ?? MunroClassification.none
        let year1933 = MunroClassification(rawValue: String(entries[19])) ?? MunroClassification.none
        let year1953 = MunroClassification(rawValue: String(entries[20])) ?? MunroClassification.none
        let year1969 = MunroClassification(rawValue: String(entries[21])) ?? MunroClassification.none
        let year1974 = MunroClassification(rawValue: String(entries[22])) ?? MunroClassification.none
        let year1981 = MunroClassification(rawValue: String(entries[23])) ?? MunroClassification.none
        let year1984 = MunroClassification(rawValue: String(entries[24])) ?? MunroClassification.none
        let year1990 = MunroClassification(rawValue: String(entries[25])) ?? MunroClassification.none
        let year1997 = MunroClassification(rawValue: String(entries[26])) ?? MunroClassification.none
        let post1997 = MunroClassification(rawValue: String(entries[27])) ?? MunroClassification.none
        
        eraClassification = EraClassification(year1891: year1891, year1921: year1921, year1933: year1933, year1953: year1953, year1969: year1969, year1974: year1974, year1981: year1981, year1984: year1984, year1990: year1990, year1997: year1997, post1997: post1997)
        
        comments = try value(value: entries[28], as: String.self)
    }
}
