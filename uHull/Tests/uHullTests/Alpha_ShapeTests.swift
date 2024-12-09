//
//  Alpha_ShapeTests.swift
//  uHull
//
//  Created by Steve Wainwright on 06/12/2024.
//
// ported from https://github.com/luanleonardo/uhull python library
//

import Testing
import Foundation
@testable import uHull
@testable internal import KDTree
@testable internal import SigmaSwiftStatistics

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let tests = Alpha_ShapeTests()
    
    tests.tests_get_alpha_shape_polygons_in_square_set()
    tests.tests_get_alpha_shape_polygons_in_circular_crown_set()
    
}


// MARK: Tests

struct Alpha_ShapeTests {
    
    private var _coordinates_square_set: [ASPoint] = Array(repeating: ASPoint(x: 0, y: 0), count: 5000)
    private var _coordinates_circle_set: [ASPoint] = []

    var coordinates_square_set: [ASPoint] {
        get {
            return _coordinates_square_set;
        }
    }
    
    var circular_crown_set: [ASPoint] {
        // Coordinates of a circular crown like set, formed from the difference between
        // concentric circles in (2.0, 2.0) of areas 2 * pi and pi.
        get {
            return _coordinates_circle_set
        }
    }
    
    init() {
        // do setup
        print("doing setup")
        //Coordinates of a set of 5k points, similar to a square of side 4.
        for i in 0..<5000 {
            _coordinates_square_set[i].x = 4 * Double.random(in: 0...1)
            _coordinates_square_set[i].y = 4 * Double.random(in: 0...1)
        }
        
    }

    deinit {
        // do teardown
        print("doing teardown")
    }

    // check if the point is on the circular crown
    private func _is_circular_crown_point(point: ASPoint, center: ASPoint) -> Bool {
        let distance = Geometry().euclidean_distance(coord1: point, coord2: center)
        return distance > 1.0 && distance < sqrt(2.0)
    }

    @Test("Tests get alpha_shape_polygons in square_set") func tests_get_alpha_shape_polygons_in_square_set() {
        //    Test get alpha shapes polygons in the set similar to a square of side 4.
        
        // get alpha shape polygons of the square set
        if let polygons = Alpha_Shape().getAlphaShapePolygons(coordinates_points: coordinates_square_set, alpha: 1.5, distance: Geometry().euclidean_distance) {
            
            // at least one alpha form must be returned
            #expect( polygons.count > 0, "at least one alpha form must be returned" )
            
            //  the largest area alpha shape should have an area close to that of a
            //  square of side 4
            #expect( abs(Geometry().area_of_polygon(coordinates_polygon_vertices: polygons[0]) - 15.5) < 0.5, "the largest area alpha shape should have an area close to that of a square of side 4" )
        }
    }

    @Test func tests_get_alpha_shape_polygons_in_circular_crown_set() {
        // Test get alpha shape polygons in the circular crown set.
        // center of circles
        let center_circles = ASPoint(x: 2, y: 2)
        // returns points on the circular crown
        _coordinates_circle_set = _coordinates_square_set.filter({ _is_circular_crown_point(point: $0, center: center_circles) })
        
        // get alpha shape polygons from circular crown set
        if let polygons = Alpha_Shape().getAlphaShapePolygons(coordinates_points: circular_crown_set, alpha: 1.5, distance: Geometry().euclidean_distance) {
            
            // at least two alpha shapes must be returned, one for the outermost points
            // (similar to the circle with the largest area 2pi) and another shape for the
            // innermost points (similar to the circle with the smallest area pi).
            #expect( polygons.count >= 2 , "At least two alpha shapes must be returned" )
            
            // the largest-area alpha shape must have an area less than 2pi (area of the
            // largest circle) and greater than pi (area of the smallest circle).
            
            let largest_area = Geometry().area_of_polygon(coordinates_polygon_vertices: polygons[0])
            #expect( largest_area > .pi && largest_area < 2 * .pi, "The largest-area alpha shape must have an area less than 2pi and greater than pi." )
            
            // the second largest-area alpha shape must have an area smaller than the first
            // (obvious) and greater than pi (area of the smaller circle).
            let second_largest_area = Geometry().area_of_polygon(coordinates_polygon_vertices: polygons[1])
            #expect( second_largest_area > .pi && second_largest_area < largest_area, "the largest area alpha shape should have an area close to that of a square of side 4" )
        }
        else {
            print("Failed to generate polygons from a circular crown set")
        }
    }
}
