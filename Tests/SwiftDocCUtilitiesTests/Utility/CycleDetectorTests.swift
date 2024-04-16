/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SwiftDocC

final class CycleDetectorTests: XCTestCase {

    func testGraphsWithoutCycles() throws {
        do {
            // 8───▶0◀───2
            //      │
            //      ▼
            // 1───▶6    7
            //      │    │
            //      ▼    ▼
            // 5───▶3◀───4
            let graph = TestGraph(
                nodes: (0...8).map { .init(id: $0) },
                edges: [
                    .init(from: 0, to: 6),
                    .init(from: 1, to: 6),
                    .init(from: 2, to: 0),
                    // no edge from node 3
                    .init(from: 4, to: 3),
                    .init(from: 5, to: 3),
                    .init(from: 6, to: 3),
                    .init(from: 7, to: 4),
                    .init(from: 8, to: 0),
                ]
            )
            for nodeID in 0...8 {
                let cycle = CycleDetector.detectedCycleInDirectedGraph(
                    from: graph.nodes[nodeID],
                    linkedNodes: { graph.destinations(from: $0) }
                )
                XCTAssertNil(cycle, "Should not have found a cycle")
            }
        }
        
        do {
            // This graph doesn't have cycles but it has patterns where `𝑥ₙ = 𝑥₂ₙ` which looks like a cycle to the algorithm.
            
            // 0────┐   5────┐
            // │    │   ▲    │
            // ▼    ▼   │    ▼
            // 1───▶3───┼───▶4
            // │    ▲   │    │
            // │    │   ▼    ▼
            // └───▶2   6───▶7
            let graph = TestGraph(
                nodes: (0...7).map { .init(id: $0) },
                edges: [
                    .init(from: 0, to: 1),
                    .init(from: 0, to: 3),
                    .init(from: 1, to: 2),
                    .init(from: 1, to: 3),
                    .init(from: 2, to: 3),
                    .init(from: 3, to: 4),
                    .init(from: 3, to: 5),
                    .init(from: 3, to: 6),
                    .init(from: 4, to: 7),
                    .init(from: 5, to: 4),
                    .init(from: 6, to: 7),
                ]
            )
            for nodeID in 0...7 {
                let cycle = CycleDetector.detectedCycleInDirectedGraph(
                    from: graph.nodes[nodeID],
                    linkedNodes: { graph.destinations(from: $0) }
                )
                XCTAssertNil(cycle, "Should not have found a cycle \(nodeID)")
            }
        }
    }
    
    func testGraphsWithCycles() throws {
        do {
            // 8───▶0◀───2    7
            //      │         │
            //      ▼         ▼
            // 5    6◀───1    4──┐
            // │    │    ▲    ▲  │
            // │    ▼    │    └──┘
            // └───▶3────┘
            let graph = TestGraph(
                nodes: (0...8).map { .init(id: $0) },
                edges: [
                    .init(from: 0, to: 6),
                    .init(from: 1, to: 6),
                    .init(from: 2, to: 0),
                    .init(from: 3, to: 1),
                    .init(from: 4, to: 4),
                    .init(from: 5, to: 3),
                    .init(from: 6, to: 3),
                    .init(from: 7, to: 4),
                    .init(from: 8, to: 0),
                ]
            )
            for nodeID in [8,0,2,6] {
                let cycle = CycleDetector.detectedCycleInDirectedGraph(
                    from: graph.nodes[nodeID],
                    linkedNodes: { graph.destinations(from: $0) }
                )
                
                XCTAssertNotNil(cycle, "Should have found a cycle")
                let cycleIDs = try XCTUnwrap(cycle).map(\.id)
                
                XCTAssertEqual(cycleIDs, [6,3,1], "Starting from node \(nodeID), the cycle should start at node 6")
            }
            
            for nodeID in [3,5] {
                let cycle = CycleDetector.detectedCycleInDirectedGraph(
                    from: graph.nodes[nodeID],
                    linkedNodes: { graph.destinations(from: $0) }
                )
                
                XCTAssertNotNil(cycle, "Should have found a cycle")
                let cycleIDs = try XCTUnwrap(cycle).map(\.id)
                
                XCTAssertEqual(cycleIDs, [3,1,6], "Starting from node \(nodeID), the cycle should start at node 3")
            }
            
            for nodeID in [7,4] {
                let cycle = CycleDetector.detectedCycleInDirectedGraph(
                    from: graph.nodes[nodeID],
                    linkedNodes: { graph.destinations(from: $0) }
                )
                
                XCTAssertNotNil(cycle, "Should have found a cycle")
                let cycleIDs = try XCTUnwrap(cycle).map(\.id)
                
                XCTAssertEqual(cycleIDs, [4], "Starting from node \(nodeID), the cycle should start at node 3")
            }
            
            let cycle = CycleDetector.detectedCycleInDirectedGraph(
                from: graph.nodes[1],
                linkedNodes: { graph.destinations(from: $0) }
            )
            
            XCTAssertNotNil(cycle, "Should have found a cycle")
            let cycleIDs = try XCTUnwrap(cycle).map(\.id)
            
            XCTAssertEqual(cycleIDs, [1,6,3], "Starting from node 1, the cycle should start at node 1")
        }
        
        do {
            // 8───▶0◀───2
            //      │
            //      ▼
            // 5───▶6───▶3    4──┐
            // ▲         │    ▲  │
            // │         ▼    └──┘
            // └────7◀───1
            let graph = TestGraph(
                nodes: (0...8).map { .init(id: $0) },
                edges: [
                    .init(from: 0, to: 6),
                    .init(from: 1, to: 7),
                    .init(from: 2, to: 0),
                    .init(from: 3, to: 1),
                    .init(from: 4, to: 4),
                    .init(from: 5, to: 6),
                    .init(from: 6, to: 3),
                    .init(from: 7, to: 5),
                    .init(from: 8, to: 0),
                ]
            )
            for nodeID in [8,0,2,6] {
                let cycle = CycleDetector.detectedCycleInDirectedGraph(
                    from: graph.nodes[nodeID],
                    linkedNodes: { graph.destinations(from: $0) }
                )
                
                XCTAssertNotNil(cycle, "Should have found a cycle")
                let cycleIDs = try XCTUnwrap(cycle).map(\.id)
                
                XCTAssertEqual(cycleIDs, [6,3,1,7,5], "Starting from node \(nodeID), the cycle should start at node 6")
            }
            
            let cycleFrom4 = try XCTUnwrap(CycleDetector.detectedCycleInDirectedGraph(
                from: graph.nodes[4],
                linkedNodes: { graph.destinations(from: $0) }
            ))
            XCTAssertEqual(cycleFrom4.map(\.id), [4], "Starting from node 4, the cycle should start at node 4")
            
            let cycleFrom3 = try XCTUnwrap(CycleDetector.detectedCycleInDirectedGraph(
                from: graph.nodes[3],
                linkedNodes: { graph.destinations(from: $0) }
            ))
            XCTAssertEqual(cycleFrom3.map(\.id), [3,1,7,5,6], "Starting from node 3, the cycle should start at node 3")
            
            let cycleFrom1 = try XCTUnwrap(CycleDetector.detectedCycleInDirectedGraph(
                from: graph.nodes[1],
                linkedNodes: { graph.destinations(from: $0) }
            ))
            XCTAssertEqual(cycleFrom1.map(\.id), [1,7,5,6,3], "Starting from node 1, the cycle should start at node 1")
            
            let cycleFrom7 = try XCTUnwrap(CycleDetector.detectedCycleInDirectedGraph(
                from: graph.nodes[7],
                linkedNodes: { graph.destinations(from: $0) }
            ))
            XCTAssertEqual(cycleFrom7.map(\.id), [7,5,6,3,1], "Starting from node 7, the cycle should start at node 7")
            
             let cycleFrom5 = try XCTUnwrap(CycleDetector.detectedCycleInDirectedGraph(
                from: graph.nodes[5],
                linkedNodes: { graph.destinations(from: $0) }
            ))
            XCTAssertEqual(cycleFrom5.map(\.id), [5,6,3,1,7], "Starting from node 5, the cycle should start at node 5")
        }
    }
}

private struct TestGraph {
    struct Node: Equatable {
        let id: Int
    }
    struct Edge {
        var from, to: Int
    }
    var nodes: [Node]
    var edges: [Edge]
    
    func destinations(from node: Node) -> [Node] {
        let relevantEdges = edges.filter { $0.from == node.id }
        let destinationIDs = Set(relevantEdges.map(\.to))
        return nodes.filter { destinationIDs.contains($0.id) }
    }
}
