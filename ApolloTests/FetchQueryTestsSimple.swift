import XCTest
@testable import AWSAppSync
import StarWarsAPI

// Expands Apollo's "FetchQueryTests" with more cache miss coverage, including a test for AppSync's pre-population of
// the cache with an empty QUERY_ROOT. Note that there is some overlap between this and FetchQueryTests, but we're
// allowing it to localize the changes without significantly modifying the Apollo-provided test code. These tests have
// been run against the unmodified Apollo codebase to ensure that AppSync maintains the same caching hit/miss behavior.
class FetchQueryTestsSimple: XCTestCase {

    struct InitialCacheRecords {
        static let cacheHit: RecordSet = [
            "QUERY_ROOT": ["hero": Reference(key: "hero")],
            "hero": [ "name": "R2-D2", "__typename": "Droid", "optionalString": NSNull()]
        ]

        static let emptyCache: RecordSet = [:]

        static let queryRoot: RecordSet = ["QUERY_ROOT": [:]]

        static let missingData: RecordSet = [
            "QUERY_ROOT": ["hero": Reference(key: "hero")],
            "hero": [ "name": "R2-D2", "optionalString": NSNull()]
        ]

        private init() {}
    }

    let mockNetworkTransport = MockNetworkTransport(body: [
        "data": [
            "hero": [ "name": "Luke Skywalker", "__typename": "Human", "optionalString": NSNull()]
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
        let query = HeroNameQuery()

        withCache(initialRecords: initialRecords) { cache in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.hero?.name, "Luke Skywalker")
                XCTAssertNil(result.data?.hero?.optionalString)
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    // MARK: - returnCacheDataAndFetch

    func testReturnCacheDataAndFetchCacheHit() throws {
        let query = HeroNameQuery()

        withCache(initialRecords: InitialCacheRecords.cacheHit) { cache in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let cacheResultExpectation = self.expectation(description: "Query result from cache")
            let serverResultExpectation = self.expectation(description: "Query result from server")

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { (result, error) in
                if result?.data?.hero?.name == "R2-D2" {
                    cacheResultExpectation.fulfill()
                } else if result?.data?.hero?.name == "Luke Skywalker" {
                    serverResultExpectation.fulfill()
                } else {
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
        let query = HeroNameQuery()

        withCache(initialRecords: initialRecords) { cache in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let serverResultExpectation = self.expectation(description: "Query result from server")

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { (result, error) in
                if result?.data?.hero?.name == "Luke Skywalker" {
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
        let query = HeroNameQuery()

        withCache(initialRecords: InitialCacheRecords.cacheHit) { (cache) in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .returnCacheDataElseFetch) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.hero?.name, "R2-D2")
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
        let query = HeroNameQuery()

        withCache(initialRecords: initialRecords) { (cache) in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .returnCacheDataElseFetch) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.hero?.name, "Luke Skywalker")
            }

            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    // MARK: - returnCacheDataDontFetch

    func testReturnCacheDataDontFetchCacheHit() throws {
        let query = HeroNameQuery()

        withCache(initialRecords: InitialCacheRecords.cacheHit) { (cache) in
            let store = ApolloStore(cache: cache)

            let client = ApolloClient(networkTransport: mockNetworkTransport, store: store)

            let expectation = self.expectation(description: "Fetching query")

            client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
                defer { expectation.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.hero?.name, "R2-D2")
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
        let query = HeroNameQuery()

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
