/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

/// A type that detects cycles in directed graphs.
enum CycleDetector<Node: Equatable> {
    
    /// Detects and returns a cycle in the directed graph.
    /// - Parameters:
    ///   - startingNode: The node in the graph to start searching for cycles from.
    ///   - linkedNodes: A function that returns the linked destination nodes for a given node in the directed graph.
    /// - Returns: The cycle, or `nil` of the graph doesn't contain a cycle from that starting point.
    static func detectedCycleInDirectedGraph(from startingNode: Node, linkedNodes: (Node) -> [Node]) -> [Node]? {
        // The iterators capture the closure but they go out of scope before this function returns.
        return withoutActuallyEscaping(linkedNodes) { linkedPoints in
            /// This is an implementation of Floyd's cycle-finding algorithm with a slight modification to return the cycle instead of its index and length.
            ///
            /// To understand why and how it works:
            /// Let `𝑋 = 𝑥₀ 𝑥₁ 𝑥₂ 𝑥₃ 𝑥₄ ...` be the sequence of elements visited by traversing the graph (depth first or breadth doesn't matter).
            /// If there is a cycle, then all elements in the cycle can be described as `𝑥ₙ = 𝑥₍ₙ₊ₗₘ₎, 𝑛 ≥ 𝑠` where `𝑙` is the length of the cycle, `𝑚` is the number of loops, and `𝑠` the start of the cycle.
            /// It can be shown that `𝑛 = 𝑚𝑙 ≥ μ` if and only if there exist a element `𝑥ₙ = 𝑥₂ₙ` which implies that `2𝑛 = 𝑛 + 𝑚𝑙` and only if there exist a element `𝑥₂ₙ = 𝑥ₙ = 𝑥₍ₙ₊ₗₘ₎`.
            ///
            /// Thus, the algorithm consists of 3 parts:
            /// First, find an `𝑛 ` where `𝑥ₙ = 𝑥₂ₙ`. This is done by running two iterators over the graph; one which takes one step at a time and one which takes two steps at a time.
            /// If there are cycles, the iterators will end up in a loop which gives the faster iterator a chance to make a lap and catch the slower iterator.
            /// If there are no cycles, the faster iterator will run out of elements.
            let graphIterator = DepthFirstIterator(startingPoint: startingNode, linkedPoints: linkedPoints)
            let slow = IteratorSequence(graphIterator)
            let fast = IteratorSequence(DoubleStepIterator(wrapped: graphIterator))
            
            assert(Array(slow.prefix(1)) == Array(fast.prefix(1)), "If the two iterators aren't aligned then the algorithm will loop infinitely.")
            
            // The iterators start with the same element. Drop it so that we can find the next matching element.
            guard let match = iterateUntilMatch(slow.dropFirst(), fast.dropFirst()) else {
                // Iterated the entire graph without finding a cycle.
                return nil
            }
            
            /// Second, find the start of the cycle `𝑠`. Since `𝑙` divides `𝑛` found above, it follows that `𝑥ₛ = 𝑥₍ₛ₊ₙ₎`.
            /// Because of this,  single steps from the starting point `𝑥₀` and single steps from the `𝑥ₙ` point (found above) will meet at the start of the cycle `𝑥ₛ`.
            let fromStart = IteratorSequence(graphIterator)
            let looping = IteratorSequence(DepthFirstIterator(startingPoint: match, linkedPoints: linkedPoints))
            guard let cycleStart = iterateUntilMatch(fromStart, looping) else {
                // The algorithm encountered a false positive `𝑥ₙ = 𝑥₂ₙ` match that wasn't a cycle.
                return nil
            }
            
            /// Third, iterate through the cycle once more to accumulate all the elements.
            return iterateUntilCycle(IteratorSequence(DepthFirstIterator(startingPoint: cycleStart, linkedPoints: linkedPoints)))
        }
    }
}

/// Pairwise iterates through two sequences until they reach a common element at the same location.
/// - Parameters:
///   - lhs: The first sequence or collection to iterate through.
///   - rhs: The second sequence or collection to iterate through.
/// - Returns: The common element, or `nil` if the sequences don't have a common element at the same location.
private func iterateUntilMatch<Element: Equatable>(_ lhs: some Sequence<Element>, _ rhs: some Sequence<Element>) -> Element? {
    return zip(lhs, rhs)                // iterate in pairs
        .first(where: { $0.0 == $0.1 }) // find the first match
        .map { $0.0 }                   // the elements are the same, so we only need one of them
}

/// Iterates through a sequence until it cycles.
/// - Parameter sequence: The sequence to
/// - Returns: One cycle of the sequence, or `nil` if the sequence doesn't cycle.
private func iterateUntilCycle<Element: Equatable>(_ sequence: some Sequence<Element>) -> [Element]? {
    var cycle = Array(sequence.prefix(1))
    guard let startingPoint = cycle.first else { return nil }
    
    for element in sequence.dropFirst() {
        if element == startingPoint {
            // Reached the cycle point. Return the accumulated elements.
            return cycle
        }
        
        cycle.append(element)
    
    }
    // Reached the end of the sequence. This sequence doesn't cycle.
    return nil
}

/// An iterator that performs depth first traversal of a directed graph.
private struct DepthFirstIterator<Node>: IteratorProtocol {
    private var remainingNodesToVisit: [Node]
    private var linkedPoints: (Node) -> [Node]
    
    init(startingPoint: Node, linkedPoints: @escaping (Node) -> [Node]) {
        self.remainingNodesToVisit = [startingPoint]
        self.linkedPoints = linkedPoints
    }
    
    mutating func next() -> Node? {
        guard !remainingNodesToVisit.isEmpty else { return nil }
        let node = remainingNodesToVisit.removeLast()
        
        remainingNodesToVisit.append(contentsOf: linkedPoints(node))
        return node
    }
}

/// An iterator that skips every other element.
private struct DoubleStepIterator<Wrapped: IteratorProtocol>: IteratorProtocol {
    var wrapped: Wrapped
    
    mutating func next() -> Wrapped.Element? {
        // For Floyd's cycle-finding algorithm it's important that the slow and fast iterators start with the same element.
        // Because of this, we return the first element and skip the next
        //
        //   ╭───────────── 1st element
        //   │     ╭─────── 2nd element
        //   │     │     ╭─ 3rd element
        //   ▼  ◌  ▼  ◌  ▼
        //   A  B  C  D  E  F  G  ...
        defer {
            _ = wrapped.next()
        }
        return wrapped.next()
    }
}
