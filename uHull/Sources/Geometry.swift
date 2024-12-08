//
//  Geometry.swift
//  uHull-iOS-Swift
//
//  Created by Steve Wainwright on 22/11/2024.
//  Copyright © 2024 whichtoolface.com. All rights reserved.
//
// ported from https://github.com/luanleonardo/uhull python library
//

import Foundation

public class Geometry {
    
    public init() {
        
    }
    
    public func euclidean_distance(coord1: ASPoint, coord2: ASPoint) -> Double {
        
        //    Calculate the Euclidean distance between coordinates.
        //
        //    Parameters
        //    ----------
        //    coord1
        //        Tuple of coordinates of the source point.
        //    coord2
        //        Tuple of coordinates of the target point.
        //
        //    Returns
        //    -------
        //    double
        //        Euclid distance between source and target points.
        //
        //    References
        //    ----------
        //    .. [1] Euclidean distance, https://en.wikipedia.org/wiki/Euclidean_distance
        
        return sqrt(pow(coord1.x - coord2.x, 2) + pow(coord1.y - coord2.y, 2))
    }
    
    public func haversine_distance(coord1: ASPoint, coord2: ASPoint) -> Double {
        
        //    Calculate the Haversine distance between coordinates.
        //
        //    The Haversine (or great circle) distance is the angular distance
        //    between two points on the surface of a sphere. The first coordinate of
        //    each point is assumed to be the longitude, the second is the latitude.
        //
        //    Parameters
        //    ----------
        //    coord1
        //        Tuple of coordinates of the source point.
        //    coord2
        //        Tuple of coordinates of the target point.
        //
        //    Returns
        //    -------
        //    float
        //        Haversine distance between coordinates in kilometers.
        //
        //    References
        //    ----------
        //    .. [1] Haversine formula, https://en.wikipedia.org/wiki/Haversine_formula
        
        //     Coordinates in decimal degrees (e.g. 2.89078, 12.79797)
        let longitude1 = coord1.x, latitude1 = coord1.y
        let longitude2 = coord1.x, latitude2 = coord1.y
        
        //  radius of Earth in kilometers
        let radius_earth: Double = 6371000.0 / 1000.0
        
        //  Haversine Formula
        let phi_1 = latitude1 / 180 * .pi
        let phi_2 = latitude2 / 180 * .pi
        let delta_phi = phi_2 - phi_2
        let delta_lambda = (longitude2 - longitude1) / 180 * .pi
        let a = pow(sin(delta_phi / 2.0), 2.0) + cos(phi_1) * cos(phi_2) * pow(sin(delta_lambda / 2.0), 2.0)
        let c = 2 * atan2(sqrt(a), sqrt(1.0 - a))
        
        //     output distance in kilometers
        return radius_earth * c
    }
    
    func delaunay_triangulation(coordinates_points: [ASPoint]) -> [[ASPoint]] {
        
        //    Get a Delaunay triangulation from the coordinates of the points.
        //
        //    Parameters
        //    ----------
        //    coordinates_points
        //        List of point coordinates.
        //
        //    Returns
        //    -------
        //    Array of ASPoint with three point coordinates, representing the vertex points of triangles.
        //
        //    References
        //    ----------
        //    .. [1] Delaunay triangulation,
        //    https://en.wikipedia.org/wiki/Delaunay_triangulation
        //    .. [2] scipy.spatial.Delaunay,
        //    https://docs.scipy.org/doc/scipy/reference/generated/scipy.spatial.Delaunay.html
        let delaunay = Delaunay()
        let triangles = delaunay.triangulate(coordinates_points.map({ Point(x: $0.x, y: $0.y) }))
        
        return triangles.map({ ([ASPoint(x: $0.point1.x, y: $0.point1.y), ASPoint(x: $0.point2.x, y: $0.point2.y), ASPoint(x: $0.point3.x, y: $0.point3.y)]) })
    }
    
    func area_of_polygon(coordinates_polygon_vertices: [ASPoint]) -> Double {
        
        //    Calculate area of polygon using Shoelace formula.
        //
        //    Parameters
        //    ----------
        //    coordinates_polygon_vertices
        //        Array of ASPoint representing the coordinates of the polygon's vertices.
        //
        //    Returns
        //    -------
        //    Double
        //        Area of polygon calculated using Shoelace Formula.
        //
        //    References
        //    ----------
        //    .. [1] Shoelace formula, https://en.wikipedia.org/wiki/Shoelace_formula#Other_formulas
        //    get coordinates of vertices
        
//      variation of the Shoelace formula, see [1].
        var area: Double = 0.0
        for i in 1..<coordinates_polygon_vertices.count - 1 {
            area += coordinates_polygon_vertices[i].x * (coordinates_polygon_vertices[i+1].y - coordinates_polygon_vertices[i-1].y)
        }
        
        //Return area
        return 0.5 * abs(area)
    }
}
