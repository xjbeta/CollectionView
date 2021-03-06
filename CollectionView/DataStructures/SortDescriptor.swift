//
//  SortDescriptor.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/16/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation

/// Sort Descriptor Result
///
/// - same: The two objects are equally compared
/// - ascending: The first object is before the second (ordered)
/// - descending: The second object precedes the first (reversed)
public enum SortDescriptorResult: ExpressibleByBooleanLiteral {
    case same
    case ascending
    case descending
    
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) {
        self = value ? .ascending : .descending
    }
}

/// a comparator used to compare two objects
public struct SortDescriptor<T> {
    
    public let ascending: Bool
    private let comparator: (T, T) -> SortDescriptorResult
    
    /// Initialize a sort descriptor with a custom comparator
    ///
    /// - Parameter keyPath: A keypath for the type being sorted
    /// - Parameter ascending: If the comparison should order ascending
    public init<V: Comparable>(_ keyPath: KeyPath<T, V>, ascending: Bool = true) {
        self.comparator = {
            let v1 = $0[keyPath: keyPath]
            let v2 = $1[keyPath: keyPath]
            if v1 < v2 { return ascending ? .ascending : .descending }
            if v1 > v2 { return ascending ? .descending : .ascending }
            return .same
        }
        self.ascending = ascending
    }
    
    /// Initialize a sort descriptor with a custom comparator
    ///
    /// - Parameter comparator: A comparator returning a comparison result
    public init(_ comparator: @escaping ((T, T) -> SortDescriptorResult)) {
        self.comparator = comparator
        self.ascending = true
    }
    
    /// Compare two objects
    ///
    /// - Parameters:
    ///   - a: The first object
    ///   - b: The second object
    /// - Returns: A SortDescriptorResult for the two objects.
    public func compare(_ a: T, to b: T) -> SortDescriptorResult {
        return comparator(a, b)
    }
}

extension SortDescriptor where T: Comparable {
    public static var ascending: SortDescriptor<T> {
        return SortDescriptor({ (a, b) -> SortDescriptorResult in
            if a == b { return .same }
            if a > b { return .descending }
            return .ascending
        })
    }
    public static var descending: SortDescriptor<T> {
        return SortDescriptor({ (a, b) -> SortDescriptorResult in
            if a == b { return .same }
            if a > b { return .descending }
            return .ascending
        })
    }
}

protocol Comparer {
    associatedtype Compared
    func compare(_ a: Compared, to b: Compared) -> SortDescriptorResult
}
extension SortDescriptor: Comparer { }

extension Sequence where Element: Comparer {
    func compare(_ element: Element.Compared, _ other: Element.Compared) -> SortDescriptorResult {
        for comparer in self {
            switch comparer.compare(element, to: other) {
            case .same: break
            case .descending: return .descending
            case .ascending: return .ascending
            }
        }
        return .same
    }
    
    func element(_ element: Element.Compared, isBefore other: Element.Compared) -> Bool {
        return self.compare(element, other) == .ascending
    }
}

public extension Array {
    public mutating func sort(using sortDescriptor: SortDescriptor<Element>) {
        self.sort { (a, b) -> Bool in
            return sortDescriptor.compare(a, to: b) == .ascending
        }
    }
    
    public mutating func sort(using sortDescriptors: [SortDescriptor<Element>]) {
        guard !sortDescriptors.isEmpty else { return }
        if sortDescriptors.count == 1 {
            return self.sort(using: sortDescriptors[0])
        }
        self.sort { (a, b) -> Bool in
            for desc in sortDescriptors {
                switch desc.compare(a, to: b) {
                case .same: break
                case .descending: return false
                case .ascending: return true
                }
            }
            return false
        }
    }
    
    public mutating func insert(_ element: Element, using sortDescriptors: [SortDescriptor<Element>]) -> Int {

        if !sortDescriptors.isEmpty, let idx = (self.index { return sortDescriptors.compare(element, $0) != .ascending }) {
            self.insert(element, at: idx)
            return idx
        }
        self.append(element)
        return self.count - 1
    }
    
//    public mutating func insert(_ element: Element, using sortDescriptors: [SortDescriptor<Element>]) -> Int {
//        if sortDescriptors.count > 0 {
//            for (idx, existing) in self.enumerated() {
//                if sortDescriptors.compare(element, existing) != .ascending {
//                    self.insert(element, at: idx)
//                    return idx
//                }
//            }
//        }
//        self.append(element)
//        return self.count - 1
//    }
}
    
extension Sequence {
    public func sorted(using sortDescriptor: SortDescriptor<Element>) -> [Element] {
        return self.sorted(by: { (a, b) -> Bool in
            return sortDescriptor.compare(a, to: b) == .ascending
        })
    }
    
    public func sorted(using sortDescriptors: [SortDescriptor<Element>]) -> [Element] {
        guard !sortDescriptors.isEmpty else { return Array(self) }
        if sortDescriptors.count == 1 {
            return self.sorted(using: sortDescriptors[0])
        }
        return self.sorted { (a, b) -> Bool in
            return sortDescriptors.element(a, isBefore: b)
        }
    }
}
