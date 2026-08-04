import Testing
@testable import CougarSwift

@Suite("HistogramAnalysis")
struct HistogramAnalysisTests {
    private func makeBuckets(_ ranges: [(start: Double, end: Double, count: Int)]) -> [HistogramBucket] {
        ranges.map { r in
            HistogramBucket(bucketStart: r.start, bucketEnd: r.end, bucketCount: r.count)
        }
    }

    @Test("p50 returns midpoint of bucket containing 50th percentile")
    func p50() {
        // 10 samples: [0-100ms: 3, 100-200ms: 4, 200-300ms: 3]
        let buckets = makeBuckets([(0, 100, 3), (100, 200, 4), (200, 300, 3)])
        let p50 = HistogramAnalysis.percentile(0.50, of: buckets)
        // cumulative at bucket 1: 30%, bucket 2: 70% → p50 in bucket 2
        // midpoint = (100+200)/2 = 150
        #expect(p50 == 150.0)
    }

    @Test("p90 returns midpoint of bucket containing 90th percentile")
    func p90() {
        let buckets = makeBuckets([(0, 100, 3), (100, 200, 4), (200, 300, 3)])
        let p90 = HistogramAnalysis.percentile(0.90, of: buckets)
        // cumulative at bucket 3: 100% → p90 in bucket 3
        // midpoint = (200+300)/2 = 250
        #expect(p90 == 250.0)
    }

    @Test("returns nil for empty buckets")
    func emptyBuckets() {
        #expect(HistogramAnalysis.percentile(0.50, of: []) == nil)
    }

    @Test("p100 returns last bucket midpoint")
    func p100() {
        let buckets = makeBuckets([(0, 100, 5), (100, 200, 5)])
        let p100 = HistogramAnalysis.percentile(1.0, of: buckets)
        #expect(p100 == 150.0)
    }

    @Test("weightedAverage computes sum(midpoint*count)/total")
    func weightedAverageTest() {
        let buckets = makeBuckets([(0, 100, 1), (100, 200, 1)])
        // midpoints: 50, 150; average = (50*1 + 150*1)/2 = 100
        #expect(HistogramAnalysis.weightedAverage(of: buckets) == 100.0)
    }

    @Test("weightedAverage returns nil for empty input")
    func weightedAverageEmpty() {
        #expect(HistogramAnalysis.weightedAverage(of: []) == nil)
    }
}
