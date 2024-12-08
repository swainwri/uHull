//
//  GraphTests.swift
//  uHull
//
//  Created by Steve Wainwright on 28/11/2024.
//
// ported from https://github.com/luanleonardo/uhull python library
//

import Testing
@testable import uHull
@testable internal import KDTree
@testable internal import SigmaSwiftStatistics

// MARK: Tests

struct GraphTests {
    // Defines a set of points that form a square of side 1.0.
    let square_edges: [ASEdge] = [ ASEdge(source: ASPoint(x: 0, y: 0), target: ASPoint(x: 0, y: 1)),
                                   ASEdge(source: ASPoint(x: 0, y: 1), target: ASPoint(x: 1, y: 1)),
                                   ASEdge(source: ASPoint(x: 1, y: 1), target: ASPoint(x: 1, y: 0)),
                                   ASEdge(source: ASPoint(x: 1, y: 0), target: ASPoint(x: 0, y: 0)) ]
    let edges = [ASEdge(source: ASPoint(x: 0, y: 0), target: ASPoint(x: 0, y: 1)),
                 ASEdge(source: ASPoint(x: 0, y: 1), target: ASPoint(x: 0, y: 0))]
    
    var graph: Graph?
//    var largeTree: KDTree<CGPoint> = KDTree(values: [])
//    let rangeIntervals: [(Double, Double)] = [(0.2, 0.3), (0.45, 0.75)]
//
//    var spaceTimePoints: [STPoint] = []
//    var spaceTimeTree: KDTree<STPoint> = KDTree(values: [])
//    let spaceTimeIntervals: [(Double, Double)] = [(0.2, 0.4), (0.45, 0.75), (0.15, 0.85), (0.1, 0.9)]
    
    init() {
        // do setup
        print("doing setup")
    }

    deinit {
        // do teardown
        print("doing teardown")
    }

    @Test func test_add_edge_method() -> Void {
        // Tests the add edge method of the Graph class.
        
        //      create instance of graph class
        //      define graph from edges
        graph = Graph(edgeList: self.square_edges, weightFunction: Geometry().euclidean_distance)
        
        //      graph must have 4 nodes
        #expect( graph?.count == 4 )
        
        //      set of nodes
        #expect( graph?.nodes == [ ASPoint(x: 0.0, y: 0.0), ASPoint(x: 0.0, y: 1.0), ASPoint(x: 1.0, y: 1.0), ASPoint(x: 1.0, y: 0.0) ] )
        
        //      there should be no connection between (0.0, 0.0) and (1.0, 1.0)
        let source = ASPoint(x: 0, y: 0)
        let target = ASPoint(x: 1, y: 1)
        
        if let adjacencySetSource = graph?.adjacencySet[source] {
            #expect(!adjacencySetSource.contains(target), "Edge (\(source), \(target)) already exists")
        }
        if let adjacencySetTarget = graph?.adjacencySet[target] {
            #expect(!adjacencySetTarget.contains(source), "Edge (\(target), \(source)) already exists")
        }
        
        //      weight of edge (0.0, 0.0) - (1.0, 0.0) should be 1.0
        if let weight = graph?.weight[source]?[target] {
            #expect( weight == 1.0, "Weight of edge (\(source), \(target)) is 1.0" )
        }
    }

    @Test func test_add_edge_method_assertion_error() -> Void {
    
        // Method should throw an assertion error when trying to add edge
        // that already exists.
        
        // create instance of graph class
        // define graph from edges
        graph = Graph(edgeList: square_edges, weightFunction: Geometry().euclidean_distance)
        
        for edge in edges {
            //         try adding existing edge
            let status = graph?.addEdge(edgeSource: edge.source, edgeTarget: edge.target, edgeWeight: Geometry().euclidean_distance(coord1: edge.source, coord2: edge.target))
            #expect(status == .sourceExists || status == .targetExists, "Edge already exists")
        }
    }

    @Test func test_remove_edge_method() -> Void {
        
        // Test class edge removal method.
        
        // create instance of graph class
        // define graph from edges
        graph = Graph(edgeList: square_edges, weightFunction: Geometry().euclidean_distance)
        
        for edge in edges {
            // remove edge
            let status = graph?.removeEdge(edgeSource: edge.source, edgeTarget: edge.target)
            if edge == edges[1] {
                #expect(status == .noTargetExists, "Target Edge doesn't exist")
                break
            }
            else {
                #expect(status == .success, "Edge removed")
                
                // there must be no connection between nodes in the adjacency set
                #expect(!(graph?[edge.source].contains(edge.target) ?? false), "There is  no connection between nodes in the adjacency set")
                
                // there must be no weight associated with the edge
                if let weight = graph?.weight[edge.source] {
                    #expect(!weight.contains(where: { $0.key == edge.target }), "There is no weight associated with the edge")
                }
            }
        }
    }

    @Test func test_remove_edge_method_assertion_error() -> Void {
        // Method should throw an assertion error when trying to remove
        // an edge that does not exist in the graph.
        
        // create instance of graph class
        // define graph from edges
        graph = Graph(edgeList: square_edges, weightFunction: Geometry().euclidean_distance)
        
        for edge in edges {
            // remove edge
            var status = graph?.removeEdge(edgeSource: edge.source, edgeTarget:edge.target)
            if edge == edges[1] {
                #expect(status == .noTargetExists, "Target Edge doesn't exist")
                break
            }
            else {
                #expect(status == .success, "Edge removed")
                
                //  try to remove nonexistent edge
                status = graph?.removeEdge(edgeSource: edge.source, edgeTarget: edge.target)
                #expect(status == .noSourceExists || status == .noTargetExists, "One Edge does not exist")
            }
        }
    }


    @Test func test_dijkstra_algorithm() -> Void {
        
        // Test shortest path dijkstra algorithm. Distance/cost is infinite when
        // there is no path between nodes.
        let edge_tests = [ASEdge(source: ASPoint(x: 0, y: 0), target: ASPoint(x: 0, y: 1)),
                           ASEdge(source: ASPoint(x: 0, y: 0), target: ASPoint(x: 1, y: 1)),
                           ASEdge(source: ASPoint(x: 0, y: 0), target: ASPoint(x: 0.25, y: 0.25)),
                           ASEdge(source: ASPoint(x: 0, y: 0), target: ASPoint(x: 0.75, y: 0.75))]
//        let expected_dist: [Double] = [ 1.0, 2.0, Double.infinity, Double.infinity ]
        //     create instance of graph class
        //     define graph from edges
        graph = Graph(edgeList: square_edges, weightFunction: Geometry().euclidean_distance)
        
        //     add edge to make the graph disconnected
        let source = ASPoint(x: 0.25, y: 0.25)
        let target = ASPoint(x: 0.75, y: 0.75)
        let status = graph?.addEdge(edgeSource: source, edgeTarget: target, edgeWeight: Geometry().euclidean_distance(coord1: source, coord2: target))
        #expect(status == .success, "Edge added successfully")
                                    
        //     get the shortest path distances
        var i = 0
        for edge in edge_tests {
            if let result = graph?.dijkstraAlgorithm(edgeSource: edge.source, edgeTarget: edge.target) {
                //     when there is no path between nodes, expected distance is inf.
                for dist in result.distance {
                    if dist.key == target.description {
                        #expect( dist.value == .infinity /*expected_dist[i]*/, "there is no path between nodes, expected distance is inf" )
                    }
                }
            }
            i += 1
        }
    }

    @Test func test_shortest_path_to_graph_class() -> Void {
    
        // Tests to get the shortest path between nodes.
    
        // create instance of graph class
        // define graph from edges
        graph = Graph(edgeList: square_edges, weightFunction: Geometry().euclidean_distance)
        
        // get the shortest path between nodes
        let source = ASPoint(x: 0.0, y: 0.0)
        let target = ASPoint(x: 1.0, y:0.0)
        var path = graph?.shortestPathAlgorithm(edgeSource: source, edgeTarget: target)
    
        //  there is edge connecting the nodes, so the shortest path is formed by the nodes
        //  themselves.
        #expect(path?.path == [source, target], "There is edge connecting the nodes, so the shortest path is formed by the nodes themselves")
    
        // removing the edge, the shortest path will be formed by all the points,
        // as it contains all other remaining edges.
        let status = graph?.removeEdge(edgeSource: source, edgeTarget: target)
        #expect(status == .success, "Edge removed successfully")
        path = graph?.shortestPathAlgorithm(edgeSource: source, edgeTarget: target)
        #expect(path?.path == [ASPoint(x: 0.0, y: 0.0), ASPoint(x: 0.0, y: 1.0), ASPoint(x: 1.0, y: 1.0), ASPoint(x: 1.0, y: 0.0)], "The shortest path will be formed by all the points, as it contains all other remaining edges")
    }

    @Test func test_shortest_path_to_graph_class_assertion_error() -> Void {
        
        // Function throws assertion error in two cases: when there is no path in
        // the graph connecting the two points or when one of the nodes (or both) are
        // not in the graph.
                
        // create instance of graph class
        // define graph from edges
        graph = Graph(edgeList: square_edges, weightFunction: Geometry().euclidean_distance)
        
        // add edge to make the graph disconnected
        let source = ASPoint(x: 0.25, y: 0.25)
        let target = ASPoint(x: 0.75, y: 0.75)
        let _ = graph?.addEdge(edgeSource: source, edgeTarget: target, edgeWeight: Geometry().euclidean_distance(coord1: source, coord2: target))
        
        // Try to find the shortest path between nodes of one connected component
        // and another (does not exist)
        var path = graph?.shortestPathAlgorithm(edgeSource: ASPoint(x: 0.0, y: 0.0), edgeTarget: target)
        #expect(path?.status == .nopath, "There is no path")
        
        // Try to find the shortest path between nodes that do not belong to the
        // graph (impossible)
        path = graph?.shortestPathAlgorithm(edgeSource: ASPoint(x: 11.0, y: 11.0), edgeTarget: target)
        #expect(path?.status == .impossible, "Impossible to find path")
    }
    
}
