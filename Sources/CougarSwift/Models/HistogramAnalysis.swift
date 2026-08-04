import Foundation

/// Utilities for computing statistics from MetricKit histogram buckets.
enum HistogramAnalysis {
    /// Approximate a percentile from histogram buckets.
    /// Uses the **midpoint** of the bucket that contains the target percentile.
    /// - Parameters:
    ///   - fraction: Target percentile as a fraction (e.g., 0.90 for p90)
    ///   - buckets: Array of `HistogramBucket` in ascending order of `bucketStart`
    /// - Returns: The estimated percentile value in the same unit as the bucket values,
    ///   or `nil` if the input is empty.
    static func percentile(_ fraction: Double, of buckets: [HistogramBucket]) -> Double? {
        let total = buckets.reduce(0) { $0 + $1.bucketCount }
        guard total > 0 else { return nil }
        let target = Int((fraction * Double(total)).rounded(.up))
        var cumulative = 0
        for bucket in buckets {
            cumulative += bucket.bucketCount
            if cumulative >= target {
                return (bucket.bucketStart + bucket.bucketEnd) / 2.0
            }
        }
        return buckets.last.map { ($0.bucketStart + $0.bucketEnd) / 2.0 }
    }

    /// Weighted average using bucket midpoints.
    static func weightedAverage(of buckets: [HistogramBucket]) -> Double? {
        let total = buckets.reduce(0) { $0 + $1.bucketCount }
        guard total > 0 else { return nil }
        let sum = buckets.reduce(0.0) { acc, b in
            acc + ((b.bucketStart + b.bucketEnd) / 2.0) * Double(b.bucketCount)
        }
        return sum / Double(total)
    }
}
