import XCTest
@testable import AWSAppSync
import StarWarsAPI

// Test cache behavior for complex queries. These tests have been run against the unmodified Apollo codebase to ensure
// that AppSync maintains the same caching hit/miss behavior.
class ComplexQueryFetchTests: XCTestCase {

    struct InitialCacheRecords {
        static let cacheHit: RecordSet = [
            "QUERY_ROOT": [
                "hero": Reference(key: "hero"),
                "hero(episode:EMPIRE)": Reference(key: "hero(episode:EMPIRE)")
            ],
            "hero": ["__typename": "Droid", "name": "R2-D2 Cache"],
            "hero(episode:EMPIRE)": ["__typename": "Human", "name": "Luke Skywalker Cache"]
        ]

        static let emptyCache: RecordSet = [:]

        static let queryRoot: RecordSet = ["QUERY_ROOT": [:]]

        static let missingData: RecordSet = [
            "QUERY_ROOT": [
                "hero": Reference(key: "hero"),
            ],
            "hero": ["__typename": "Droid", "name": "R2-D2 Cache"]
        ]

        private init() {}
    }

    let mockNetworkTransport = MockNetworkTransport(body: [
        "data": [
            "r2": ["__typename": "Droid", "name": "R2-D2 Server"],
            "luke": ["__typename": "Human", "name": "Luke Skywalker Server"]
        ]
        ])

    // MARK: - fetchIgnoringCacheData

    func testFetchIgnoringCacheData_cacheHit() throws {
        try doTestFetchIgnoringCacheData(with: InitialCacheRecords.cacheHit)
    }

    func testFetchIgnoringCacheData_cacheMissEmptyCache() throws {
        try doTestFetchIgnoringCacheData(with: InitialCacheRecords.emptyCache)
    }

    func testFetchIgnoringCacheData_cacheMissQueryRootOnly() throws {
        try doTestFetchIgnoringCacheData(with: InitialCacheRecords.queryRoot)
    }

    func testFetchIgnoringCacheData_cacheMissMissingData() throws {
        try doTestFetchIgnoringCacheData(with: InitialCacheRecords.missingData)
    }

    func doTestFetchIgnoringCacheData(with initialRecords: RecordSet) throws {
        let query = TwoHeroesQuery()

        withCache(initialRecords: initialRecords) { cache in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.luke?.name, "Luke Skywalker Server")
                XCTAssertEqual(result.data?.r2?.name, "R2-D2 Server")
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    // MARK: - returnCacheDataAndFetch

    func testReturnCacheDataAndFetchCacheHit() throws {
        let query = TwoHeroesQuery()

        withCache(initialRecords: InitialCacheRecords.cacheHit) { cache in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let cacheResultExpectation = self.expectation(description: "Query result from cache")
            let serverResultExpectation = self.expectation(description: "Query result from server")

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { (result, error) in
                switch (result?.data?.r2?.name, result?.data?.luke?.name) {
                case ("R2-D2 Cache", "Luke Skywalker Cache"):
                    cacheResultExpectation.fulfill()
                case ("R2-D2 Server", "Luke Skywalker Server"):
                    serverResultExpectation.fulfill()
                default:
                    XCTFail("Unexpected or nil result: \(String(describing: result))")
                }
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    func testReturnCacheDataAndFetch_emptyCache() throws {
        try doTestReturnCacheDataAndFetchCacheMiss(with: InitialCacheRecords.emptyCache)
    }

    func testReturnCacheDataAndFetch_missingData() throws {
        try doTestReturnCacheDataAndFetchCacheMiss(with: InitialCacheRecords.missingData)
    }

    func testReturnCacheDataAndFetch_queryRoot() throws {
        try doTestReturnCacheDataAndFetchCacheMiss(with: InitialCacheRecords.queryRoot)
    }

    func doTestReturnCacheDataAndFetchCacheMiss(with initialRecords: RecordSet) throws {
        let query = TwoHeroesQuery()

        withCache(initialRecords: initialRecords) { cache in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let serverResultExpectation = self.expectation(description: "Query result from server")

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { (result, error) in
                let isLukeResultFromCache = result?.data?.luke?.name.hasSuffix("Cache") ?? false
                let isR2ResultFromCache = result?.data?.r2?.name.hasSuffix("Cache") ?? false

                if isLukeResultFromCache || isR2ResultFromCache {
                    XCTFail("Unexpectedly got cached result for a cache miss test")
                    return
                }

                if result?.data?.luke?.name == "Luke Skywalker Server" && result?.data?.r2?.name == "R2-D2 Server" {
                    serverResultExpectation.fulfill()
                } else {
                    XCTFail("Unexpected or nil result: \(String(describing: result))")
                }
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    // MARK: - returnCacheDataElseFetch

    func testReturnCacheDataElseFetchCacheHit() throws {
        let query = TwoHeroesQuery()

        withCache(initialRecords: InitialCacheRecords.cacheHit) { (cache) in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .returnCacheDataElseFetch) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.r2?.name, "R2-D2 Cache")
                XCTAssertEqual(result.data?.luke?.name, "Luke Skywalker Cache")
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    func testReturnCacheDataElseFetch_emptyCache() throws {
        try doTestReturnCacheDataElseFetchCacheMiss(with: InitialCacheRecords.emptyCache)
    }

    func testReturnCacheDataElseFetch_missingData() throws {
        try doTestReturnCacheDataElseFetchCacheMiss(with: InitialCacheRecords.missingData)
    }

    func testReturnCacheDataElseFetch_queryRoot() throws {
        try doTestReturnCacheDataElseFetchCacheMiss(with: InitialCacheRecords.queryRoot)
    }

    func doTestReturnCacheDataElseFetchCacheMiss(with initialRecords: RecordSet) throws {
        let query = TwoHeroesQuery()

        withCache(initialRecords: initialRecords) { (cache) in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .returnCacheDataElseFetch) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.luke?.name, "Luke Skywalker Server")
                XCTAssertEqual(result.data?.r2?.name, "R2-D2 Server")
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    // MARK: - returnCacheDataDontFetch

    func testReturnCacheDataDontFetchCacheHit() throws {
        let query = TwoHeroesQuery()

        withCache(initialRecords: InitialCacheRecords.cacheHit) { (cache) in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.r2?.name, "R2-D2 Cache")
                XCTAssertEqual(result.data?.luke?.name, "Luke Skywalker Cache")
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    func testReturnCacheDataDontFetch_emptyCache() throws {
        try doTestReturnCacheDataDontFetchCacheMiss(with: InitialCacheRecords.emptyCache)
    }

    func testReturnCacheDataDontFetch_missingData() throws {
        try doTestReturnCacheDataDontFetchCacheMiss(with: InitialCacheRecords.missingData)
    }

    func testReturnCacheDataDontFetch_queryRoot() throws {
        try doTestReturnCacheDataDontFetchCacheMiss(with: InitialCacheRecords.queryRoot)
    }

    func doTestReturnCacheDataDontFetchCacheMiss(with initialRecords: RecordSet) throws {
        let query = TwoHeroesQuery()

        withCache(initialRecords: initialRecords) { (cache) in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
                defer { expectation.fulfill() }

                XCTAssertNil(error)
                XCTAssertNil(result)
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

}
