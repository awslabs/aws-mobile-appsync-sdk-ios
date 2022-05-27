public final class InMemoryNormalizedCache: NormalizedCache {
    private var records: RecordSet
    
    public init(records: RecordSet = RecordSet()) {
        if records.isEmpty {
            self.records = InMemoryNormalizedCache.emptyQueryRootRecords()
        } else {
            self.records = records
        }
    }
    
    public func loadRecords(forKeys keys: [CacheKey]) -> Promise<[Record?]> {
        let records = keys.map { self.records[$0] }
        return Promise(fulfilled: records)
    }
    
    public func merge(records: RecordSet) -> Promise<Set<CacheKey>> {
        return Promise(fulfilled: self.records.merge(records: records))
    }
    
    public func clear() -> Promise<Void> {
        records.clear()
        self.records = InMemoryNormalizedCache.emptyQueryRootRecords()
        return Promise(fulfilled: ())
    }
    
    private static func emptyQueryRootRecords() -> RecordSet {
        // Prepopulate the InMemoryNormalizedCache record set with an empty QUERY_ROOT, to allow optimistic
        // updates against empty caches to succeed. Otherwise, such an operation will fail with a "missingValue"
        // error (#92)
        let emptyQueryRootRecord = Record(key: AWSAppSyncClient.EmptyQuery.rootCacheKey, [:])
        return RecordSet(records: [emptyQueryRootRecord])
    }
}
