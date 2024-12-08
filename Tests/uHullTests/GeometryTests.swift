//
//  GeometryTests.swift
//  uHull
//
//  Created by Steve Wainwright on 06/12/2024.
//

import Testing
@testable import uHull
@testable internal import KDTree
@testable internal import SigmaSwiftStatistics

// MARK: Tests

class GeometryTests {
    
    // Defines a set of points that form a simple square-shaped polygon of side 1.0.
    let coordinates_points: [ASPoint] =  [ ASPoint(x: 0, y: 0), ASPoint(x: 0, y: 1), ASPoint(x: 1, y: 1), ASPoint(x: 1, y: 0) ]

    init() {
        // do setup
        print("doing setup")
    }

    deinit {
        // do teardown
        print("doing teardown")
    }

    @Test func test_euclidean_distance() {
        // Calculate the Euclidean distance between coordinates.
        
        let x = ASPoint(x: 4, y: 0)
        let y = ASPoint(x: 0, y: 3)

        #expect(Geometry().euclidean_distance(coord1: x, coord2: y) == 5, "Euclidean distance between \(x) and \(y) is 5")
    }
}
