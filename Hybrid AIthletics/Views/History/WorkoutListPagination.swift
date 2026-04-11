//
//  WorkoutListPagination.swift
//  Hybrid AIthletics
//
//  Pure-Swift pagination math used by `WorkoutListView`. Extracted so the
//  index/page calculations can be unit-tested without spinning up SwiftUI.
//

import Foundation

/// Stateless pagination helpers for `WorkoutListView`.
enum WorkoutListPagination {

    /// Returns the zero-based page index that contains the item at the given
    /// flat index, for the given page size.
    /// - Parameters:
    ///   - index: Zero-based position of the item in the full list.
    ///   - pageSize: Number of items shown per page. Must be positive.
    /// - Returns: The zero-based page index the item lives on, or `0` for a
    ///   non-positive `pageSize` (defensive — callers should not pass 0).
    static func pageIndex(forItemAt index: Int, pageSize: Int) -> Int {
        guard pageSize > 0 else { return 0 }
        return max(0, index) / pageSize
    }

    /// Returns the total number of pages required to display `count` items at
    /// `pageSize` items per page. Always returns at least `1` so the UI can
    /// render an "empty state" page.
    /// - Parameters:
    ///   - count: Total number of items.
    ///   - pageSize: Number of items shown per page. Must be positive.
    static func totalPages(count: Int, pageSize: Int) -> Int {
        guard pageSize > 0 else { return 1 }
        guard count > 0 else { return 1 }
        return (count + pageSize - 1) / pageSize
    }
}
