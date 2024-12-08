//
//  Graph.swift
//  uHull-iOS-Swift
//
//  Created by Steve Wainwright on 24/11/2024.
//  Copyright © 2024 whichtoolface.com. All rights reserved.
//
// ported from https://github.com/luanleonardo/uhull python library
//

import Foundation
import CoreGraphics

class Graph {
    
    /**
     *  @brief Enumeration of Graph Adjacency status
     **/
    enum GraphAdjacencyStatus {
        case success
        case sourceExists
        case targetExists
        case noSourceExists
        case noTargetExists
        
        var description: String {
            get {
                switch self {
                    case .success:
                        return "success"
                    case .sourceExists:
                        return "source already exists"
                    case .targetExists:
                        return "target already exists"
                    case .noSourceExists:
                        return "source doesn't exists"
                    case .noTargetExists:
                        return "target doesn't exists"
                }
            }
        }
    }
    
    /**
     *  @brief Enumeration of Graph Path status
     **/
    enum GraphPathStatus {
        case success
        case impossible
        case nopath
        
        var description: String {
            get {
                switch self {
                    case .success:
                        return "success"
                    case .impossible:
                        return "Impossible to find path between nodes that do not belong to the graph"
                    case .nopath:
                        return "There is no path connecting these nodes "
                }
            }
        }
    }
    
    var adjacencySet: [ASPoint: Set<ASPoint>] = [:]
    var weight: [ASPoint: [ASPoint : Double]] = [:]
    var nodes: Set<ASPoint> = []
    
    init(edgeList: [ASEdge], weightFunction: (ASPoint, ASPoint) -> Double) {
//    A utility class for edge-induced graph structure, supports edge addition
//    and removal operations.
        for edge in edgeList {
            let _ = addEdge(edgeSource: edge.source, edgeTarget: edge.target, edgeWeight: weightFunction(edge.source, edge.target))
        }
    }
    
    subscript(node: ASPoint) -> Set<ASPoint> {
        return adjacencySet[node] ?? Set<ASPoint>()
    }
    
    var count: Int {
        return nodes.count
    }
    
    func addEdge(edgeSource: ASPoint, edgeTarget: ASPoint, edgeWeight: Double) -> GraphAdjacencyStatus {
//    Adds nodes and edges to the undirected graph's adjacency set, as well as
//            calculates the weight of the added edge.
//
//            Parameters
//            ----------
//            edge_source
//                Tuple with the coordinates of the source of the edge.
//            edge_target
//                Tuple with the coordinates of the target of the edge.
//            edge_weight
//                A weight for the edge formed by the nodes.
//
//            Returns
//            -------
//            None
//                Returns None
//
//            Raises
//            ------
//            AssertionError
//                If the edge already exists in the adjacency list of the undirected graph.
//
//            assertions about edge existence
        if let adjacencySetEdgeSource = adjacencySet[edgeSource] {
            if adjacencySetEdgeSource.contains(edgeTarget) {
                print("Edge (\(edgeSource), \(edgeTarget)) already exists")
                return .sourceExists
            }
        }
        if let adjacencySetEdgeTarget = adjacencySet[edgeTarget] {
            if adjacencySetEdgeTarget.contains(edgeSource) {
                print("Edge (\(edgeTarget), \(edgeSource)) already exists")
                return .targetExists
            }
        }
        
        nodes.insert(edgeSource)
        nodes.insert(edgeTarget)
        
        adjacencySet[edgeSource, default: Set<ASPoint>()].insert(edgeTarget)
        adjacencySet[edgeTarget, default: Set<ASPoint>()].insert(edgeSource)
        
        weight[edgeSource, default: [:]][edgeTarget] = edgeWeight
        weight[edgeTarget, default: [:]][edgeSource] = edgeWeight
        
        return .success
    }
    
    func removeEdge(edgeSource: ASPoint, edgeTarget: ASPoint) -> GraphAdjacencyStatus {
//    Remove edge from undirected graph adjacency set. In addition, it removes
//            the cost associated with the edge removed from the cost matrix.
//
//            Parameters
//            ----------
//            edge_source
//                Tuple with the coordinates of the source of the edge.
//            edge_target
//                Tuple with the coordinates of the target of the edge.
//
//            Returns
//            -------
//            None
//                Returns None
//
//            Raises
//            ------
//            AssertionError
//                If the edge does not exist in the adjacency list of the undirected graph.
//
//            assertions
        if adjacencySet[edgeSource] == nil {
            print("No edge (\(edgeSource)")
            return .noSourceExists
        }
        else if let adjacencySetEdgeSource = adjacencySet[edgeSource], !adjacencySetEdgeSource.contains(edgeTarget) {
            print("No edge (\(edgeSource), \(edgeTarget)) to remove")
            return .noTargetExists
        }
        if adjacencySet[edgeTarget] == nil {
            print("No edge (\(edgeTarget)")
            return .noTargetExists
        }
        else if let adjacencySetEdgeTarget = adjacencySet[edgeTarget], !adjacencySetEdgeTarget.contains(edgeSource) {
            print("No edge (\(edgeTarget), \(edgeSource)) to remove")
            return .noSourceExists
        }
        
        adjacencySet[edgeSource]?.remove(edgeTarget)
        adjacencySet[edgeTarget]?.remove(edgeSource)
        
        weight[edgeSource]?.removeValue(forKey: edgeTarget)
        weight[edgeTarget]?.removeValue(forKey: edgeSource)
        return .success
    }
    
    func dijkstraAlgorithm(edgeSource: ASPoint, edgeTarget: ASPoint) -> (distance: [String: Double], predecessors: [String: ASPoint]) {
//        Dijkstra's algorithm for the shortest path problem between a single source
//            and all destinations with edges of non-negative weights. The funtions allows
//            the computation of the shortest paths to each and every destination, if a
//            particular destination is not specified when the function is invoked.
//
//            Parameters
//            ----------
//            graph
//                An instance of the Graph class, an undirected weighted graph represented
//                by adjacency set.
//            edge_source
//                Tuple with the coordinates of the source of the edge.
//            edge_target
//                Tuple with the coordinates of the target of the edge.
//
//            Returns
//            -------
//            Tuple[Dict, Dict]
//                distance:
//                    Dictionary where each key represents a destination node and the value represents
//                    the shortest path distance/cost between the source node and the key node.
//                predecessors:
//                    Dictionary where each key represents a target node and the value represents the
//                    predecessor node on the shortest path between the source node and the key node.
        var explored: Set<String> = []
        var distance: [String: Double] = [:]
        
        for node in self.nodes {
            distance[node.description] = (node == edgeSource) ? 0.0 : Double.infinity
        }
        
        var heap: [(Double, ASPoint)] = [(distance[edgeSource.description] ?? 0.0, edgeSource)]
        var predecessors: [String: ASPoint] = [:]
        
        while !heap.isEmpty {
            let (distanceNode, node) = heap.removeFirst()
            
            if node == edgeTarget {
                break
            }
            
            for neighbor in self[node] {
                let distanceNeighbor = distanceNode + self.weight[node]![neighbor]!
                if !explored.contains(neighbor.description) && distanceNeighbor < distance[neighbor.description]! {
                    explored.insert(neighbor.description)
                    distance[neighbor.description] = distanceNeighbor
                    heap.append((distance[neighbor.description]!, neighbor))
                    predecessors[neighbor.description] = node
                }
            }
        }
        
        return (distance, predecessors)
    }
    
    func shortestPathAlgorithm(edgeSource: ASPoint, edgeTarget: ASPoint) -> (path: [ASPoint], status: GraphPathStatus) {
        
//        It uses Dijkstra's algorithm to obtain the shortest path between the source node
//            and the destination node. The obtained path is represented by a list of coordinates
//            of the nodes, where the first coordinate of the list is the source node and the
//            last coordinate of the list is the target node.
//
//            Parameters
//            ----------
//            graph
//                An instance of the Graph class, an undirected weighted graph represented
//                by adjacency set.
//            edge_source
//                Tuple with the coordinates of the source of the edge.
//            edge_target
//                Tuple with the coordinates of the target of the edge.
//
//            Returns
//            -------
//            List[Tuple]
//                A list of coordinates of the nodes, where the first coordinate of the list is
//                the source node and the last coordinate of the list is the target node.
//
//            Raises
//            ------
//            AssertionError
//                If the source node or destination node does not belong to the graph.
//                If there is no path between source node and destination node.
//
//            assertion about both nodes belong to the graph
        if !self.nodes.contains(edgeSource) || !self.nodes.contains(edgeTarget) {
            print("Impossible to find path between nodes that do not belong to the graph")
            return ([], .impossible)
        }
        
        let (distances, predecessors) = dijkstraAlgorithm(edgeSource: edgeSource, edgeTarget: edgeTarget)
        
        if distances[edgeTarget.description] == Double.infinity {
            print("There is no path connecting node \(edgeSource) to node \(edgeTarget)")
            return ([], .nopath)
        }
        
        var path: [ASPoint] = [edgeTarget]
        if var currentEdge = predecessors[edgeTarget.description] {
            path.append(currentEdge)
            
            while currentEdge != edgeSource {
                if let _currentEdge = predecessors[currentEdge.description] {
                    path.append(_currentEdge)
                    currentEdge = _currentEdge
                }
                else {
                    currentEdge = edgeSource
                }
            }
        }
        
        return (path.reversed(), .success)
    }
}
