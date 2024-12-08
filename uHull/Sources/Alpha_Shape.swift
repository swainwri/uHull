//
//  Alpha_Shape.swift
//  uHull-iOS-Swift
//
//  Created by Steve Wainwright on 23/11/2024.
//  Copyright © 2024 whichtoolface.com. All rights reserved.
//
// ported from https://github.com/luanleonardo/uhull python library
//

import Foundation
import SigmaSwiftStatistics

public struct ASPoint: Hashable {
    
    public var x: Double
    public var y: Double
    
    public init (x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public var description: String {
        return "\(x.roundToSignficantDigits(9)): \(y.roundToSignficantDigits(9))"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

public struct ASEdge: Hashable {
    public let source: ASPoint
    public let target: ASPoint
    
    public init(source: ASPoint, target: ASPoint) {
        self.source = source
        self.target = target
    }
    
    public var description: String {
        return "\(source.x.roundToSignficantDigits(9)): \(source.y.roundToSignficantDigits(9)) \(target.x.roundToSignficantDigits(9)): \(target.y.roundToSignficantDigits(9))"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(target)
    }
}

public class Alpha_Shape {
    
    public init() {
        
    }

    private func _getAlphaTriangulation(coordinates_points: [ASPoint], alpha: Double = 1.5, distance: ( (ASPoint, ASPoint) -> Double) = Geometry().haversine_distance) -> [[ASPoint]]? {
        
        //        Provides an alpha triangulation of the coordinates points given. The triangulation has
        //        the following property: the lengths of the sides of each triangle are within a special
        //        interval, called the Tukey fence, whose 'width' of the interval is determined using
        //        the given alpha parameter. The length of each side of the triangles is calculated
        //        using the given distance function.
        //
        //        Parameters
        //        ----------
        //        coordinates_points
        //            Array of Double coordinates. Coordinates are represented by tuples of two numerical values.
        //
        //        alpha
        //            Float value responsible for determining the 'width' of Tukey's fence.
        //
        //        distance
        //            Function that receives two tuples of coordinates of vertices and obtains a
        //            measure of distance between the vertices. By default, we use the Haversine
        //            distance function, as we assume that the coordinates of the vertices are of
        //            the form (lng, lat).
        //
        //        Returns
        //        -------
        //        [ASPoint]
        //            A list of alpha triangle vertices coordinates. A triangle is considered to be
        //            alpha if the length of all its sides is within the Tukey fence of 'width'
        //            determined by alpha.
        
        //        References
        //        ----------
        //        .. [1] Tukey's fences, https://en.wikipedia.org/wiki/Outlier#Tukey's_fences
        //        .. [2] Identifying Outliers: IQR Method, https://online.stat.psu.edu/stat200/lesson/3/3.2
        //        .. [3] Why “1.5” in IQR Method of Outlier Detection?,
        //        https://towardsdatascience.com/why-1-5-in-iqr-method-of-outlier-detection-5d07fdc82097
        //
        //        Notes
        //        -----
        //        The function performs the following steps to obtain an alpha triangulation:
        //        1. Get Delauney triangulation;
        //        2. Get triangle information, such as vertex coordinates and side lengths;
        //        3. Get the Tukey's fence for the given alpha (a.k.a alpha fence);
        //        4. Return only alpha triangles.
        // Step 1: get Delauney triangulation;
        let triangulation = Geometry().delaunay_triangulation(coordinates_points: coordinates_points)
        
        // Step 2: get triangle information, such as vertex coordinates and side lengths;
//        var triangulationInfo: [String: Array<Any>] = [:]
        
        var lengths_list: [Double] = []
        var coordinatesAndLengths: [([ASPoint], [Double])] = []
        for coordinates in triangulation {
            // coordinates of each vertex of the triangle
            let (p1, p2, p3) = (coordinates[0], coordinates[1], coordinates[2])
                
            // lengths of triangle sides
            let lengths = [distance(p1, p2), distance(p2, p3), distance(p3, p1)]
                
            // save triangle information
            lengths_list.append(contentsOf: lengths)
            coordinatesAndLengths.append((coordinates, lengths))
        }
//        triangulationInfo["lengths"] = lengths_list
//        triangulationInfo["coordinatesAndLengths"] = coordinatesAndLengths
        
        // Step 3: get the Tukey's fence for the given alpha (a.k.a alpha fence);
        if /*let lengthsList = triangulationInfo["lengthsList"] as? [Double],
           let coordinatesAndLengths = triangulationInfo["coordinatesAndLengths"] as? [([ASPoint], [Double])],*/
            let q25 = Sigma.quantiles.method7(lengths_list, probability: 0.25),
            let q75 = Sigma.quantiles.method7(lengths_list, probability: 0.75) {
            let intrQr = q75 - q25
            let minAcceptableLength = q25 - (alpha * intrQr)
            let maxAcceptableLength = q75 + (alpha * intrQr)
            
            // Step 4: return only alpha triangles, that is, triangles whose side lengths are inside the alpha fence.
            func isAlphaTriangle(triangleSidesLength: [Double]) -> Bool {
                return triangleSidesLength.allSatisfy { minAcceptableLength < $0 && $0 < maxAcceptableLength }
            }
            
            return coordinatesAndLengths.compactMap({ (coordinates, lengths) in
                isAlphaTriangle(triangleSidesLength: lengths) ? coordinates : nil
            })
        }
        else {
           return nil
        }
    }

    private func _getAlphaShapeEdges(coordinates_points: [ASPoint], alpha: Double = 1.5, distance: ( (ASPoint, ASPoint) -> Double) = Geometry().haversine_distance) -> [ASEdge]? {
    
    //        Gets a list of the boundary edges of each alpha triangle, in an alpha triangulation of
    //        the given point coordinates. Edges are represented by tuples of tuples, which represent
    //        the coordinates of each extreme vertex of the edge, from the source vertice to the
    //        destination (target) vertice.
    //
    //        Parameters
    //        ----------
    //        coordinates_points
    //            List of point coordinates. Coordinates are represented by tuples of two numerical values.
    //
    //        alpha
    //            Float value responsible for determining the 'width' of Tukey's fence.
    //
    //        distance
    //            Function that receives two tuples of coordinates of vertices and obtains a
    //            measure of distance between the vertices. By default, we use the Haversine
    //            distance function, as we assume that the coordinates of the vertices are of
    //            the form (lng, lat).
    //
    //        Returns
    //        -------
    //        [Double]
    //            A list of the boundary edges of each alpha triangle, in an alpha triangulation of
    //            the given point coordinates. Edges are represented by tuples of tuples, which represent
    //            the coordinates of each extreme vertex of the edge, from the source vertice to the
    //            destination (target) vertice
    //
    //        See Also
    //        --------
    //        _get_alpha_triangulation : Provides an alpha triangulation of the coordinates points given.
    //
    //        Notes
    //        -----
    //        The function performs the following steps to obtain the edges:
    //            1. Get alpha triangulation of the coordinates points given;
    //            2. returns only the boundary edges of each alpha triangle from the obtained
    //            alpha triangulation for the given set of point coordinates.
    
        // Step 1: get alpha triangulation;
        if let alphaTriangulation = _getAlphaTriangulation(coordinates_points: coordinates_points, alpha: alpha, distance: distance) {
            
            // Step 2: Return only the boundary edges of each alpha triangle from the
            // obtained alpha triangulation for the given set of point coordinates.
            func saveBoundaryEdges(edgesSaved: inout Set<ASEdge>, edgeSource: ASPoint, edgeTarget: ASPoint) {
                /*
                 Saves only boundary edges.
                 
                 Notes
                 -----
                 Edges that are not boundaries will be shared by two triangles, as both
                 have the same orientation it is guaranteed that we will pass through
                 these edges in both directions. To identify a non-boundary edge, it is
                 sufficient to check whether the edge or its reverse has been saved in
                 the set and, if so, remove it. Following these steps, only the border
                 edges will remain in the set.
                 */
                let edge = ASEdge(source: edgeSource, target: edgeTarget)
                let edgeReversed = ASEdge(source: edgeTarget, target: edgeSource)
                if edgesSaved.contains(edge) || edgesSaved.contains(edgeReversed) {
                    if !edgesSaved.contains(edgeReversed) {
                        print("Can't go twice over same directed edge right?")
                    }
                    else {
                        edgesSaved.remove(edgeReversed)
                        //print("(\(edgeReversed.source.x), \(edgeReversed.source.y)), (\(edgeReversed.target.x), \(edgeReversed.target.y))");
                    }
                    return
                }
                edgesSaved.insert(edge)
            }
            
            var alphaShapeEdgesSet: Set<ASEdge> = []
            
            for ps in alphaTriangulation {
                saveBoundaryEdges(edgesSaved: &alphaShapeEdgesSet, edgeSource: ps[0], edgeTarget: ps[1])
                saveBoundaryEdges(edgesSaved: &alphaShapeEdgesSet, edgeSource: ps[1], edgeTarget: ps[2])
                saveBoundaryEdges(edgesSaved: &alphaShapeEdgesSet, edgeSource: ps[2], edgeTarget: ps[0])
            }
            return Array(alphaShapeEdgesSet)
        }
        else {
            return nil
        }
    }

    public func getAlphaShapePolygons(coordinates_points: [ASPoint], alpha: Double = 1.5, distance: ((ASPoint, ASPoint) -> Double) = Geometry().haversine_distance) -> [[ASPoint]]? {
        
        //        Provides a list of polygons, sorted in descending order by their areas, representing the
        //        concave hull of the given set of coordinates. The implemented algorithm uses a strategy
        //        based on the alpha shape algorithm, which is obtained from a special triangulation of the
        //        set of coordinates. This triangulation is strongly influenced by the value of the alpha
        //        parameter and the given distance function.
        //
        //        Parameters
        //        ----------
        //        coordinates_points
        //            List of point coordinates. Coordinates are represented by tuples of two numerical values.
        //
        //        alpha
        //            Float value responsible for determining the 'width' of Tukey's fence.
        //
        //        distance
        //            Function that receives two tuples of coordinates of vertices and obtains a
        //            measure of distance between the vertices. By default, we use the Haversine
        //            distance function, as we assume that the coordinates of the vertices are of
        //            the form (lng, lat).
        //
        //        Returns
        //        -------
        //        [[ASPoint]]
        //            Returns list of alpha shape polygons in descending order by polygon area.
        //
        //        See Also
        //        --------
        //        _get_alpha_shape_edges : Gets a list of the boundary edges of each alpha triangle, in an
        //            alpha triangulation of the given point coordinates.
        //
        //        Notes
        //        -----
        //        The function performs the following steps to obtain the alpha shape polygon list:
        //
        //            1. Gets a list of the boundary edges of each alpha triangle, in an alpha
        //            triangulation of the given point coordinates.
        //
        //            2. Defines an undirected graph, induced by the boundary alpha vertices and
        //            non-negative edge weights computed with the distance function.
        //
        //            3. Create alpha shape polygon list with following substeps:
        //                3.1 A random edge is selected, its extreme points memorized and the edge
        //                removed from the graph.
        //
        //                3.2 The shortest path from one memorized extreme point to the other
        //                is obtained. With this path, we form a polygon of the alpha shape by adding
        //                the first point to the end of the path.
        //
        //                3.3 After that all waypoints are removed from the set of points to be
        //                explored. And then add the obtained polygon to the polygon list of the
        //                alpha shape.
        //
        //            4. Returns list of alpha shape polygons in descending order by polygon area.
        //
        //        References
        //        ----------
        //        .. [1] D. Kalinina et. al., "Computing concave hull with closed curve smoothing:
        //        performance, concaveness measure and applications",
        //        https://doi.org/10.1016/j.procs.2018.08.258
        //        .. [2] D. Kalinina et. al., "Concave Hull GitHub repository.",
        //        https://github.com/dkalinina/Concave_Hull.
        if let alphaShapeEdges = _getAlphaShapeEdges(coordinates_points: coordinates_points, alpha: alpha, distance: distance) {
            
            let graph = Graph(edgeList: alphaShapeEdges, weightFunction: distance)
            var nodesToExplore = Set(graph.nodes)
            
            var alphaShapePolygonsList: [[ASPoint]] = []
            
            while !nodesToExplore.isEmpty {
                
                if let edge_source = nodesToExplore.popFirst() {
                    if let edge_target = graph.adjacencySet[edge_source]?.first {
                        let _ = graph.removeEdge(edgeSource: edge_source, edgeTarget: edge_target)
                        
                        var polygonVertices = graph.shortestPathAlgorithm(edgeSource: edge_source, edgeTarget: edge_target)
                        polygonVertices.path.append(edge_source)
                        
                        for vertice in polygonVertices.path {
                            nodesToExplore.remove(vertice)
                        }
                        
                        alphaShapePolygonsList.append(polygonVertices.path)
                    }
                    else{
                        continue
                    }
                }
                else {
                    break
                }
            }
            
            alphaShapePolygonsList.sort(by: { Geometry().area_of_polygon(coordinates_polygon_vertices: $0) > Geometry().area_of_polygon(coordinates_polygon_vertices:$1) })
            
            return alphaShapePolygonsList
        }
        else {
            return nil
        }
    }
}

extension Double {
    public func roundToSignficantDigits(_ digits: Int) -> Double {
        let multiplier = pow(10.0, Double(digits))
        return (self * multiplier).rounded() / multiplier
    }
}
