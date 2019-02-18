import XCTest

@testable import AWSAppSync
import StarWarsAPI

class CachePersistenceTests: XCTestCase {
    @available(iOS 10.0, *)
    func testHumanQueryWithDotInFieldArgumentFromCache() {
        let directoryURL = FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try! FileManager.default.createDirectory(at: directoryURL,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)

        let fileURL = directoryURL.appendingPathComponent("queries.db")

        print("Testing with cache DB at:\n\(fileURL.path)")

        SQLiteTestCacheProvider.withCache(fileURL: fileURL) { cache in
            let networkTransport = MockNetworkTransport(body: [
                "data": [
                    "human": [
                        "__typename": "Human",
                        "name": "Test person 1",
                        "mass": 90,
                        "friendsFilteredById": [
                            [
                                "__typename": "Human",
                                "id": "100.2",
                                "name": "Test person 2",
                            ]
                        ]
                    ]
                ]
                ])

            let store = ApolloStore(cache: cache)
            let client = ApolloClient(networkTransport: networkTransport, store: store)

            let query = HumanFriendsFilteredByIdQuery(id: "100.1", friendId: "100.2")
            // populate cache by fetching from server
            let fetchFromServer = self.expectation(description: "Fetching query from server")
            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
                defer { fetchFromServer.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.human?.name, "Test person 1")
                XCTAssertEqual(result.data?.human?.friendsFilteredById?[0]?.id, "100.2")
                XCTAssertEqual(result.data?.human?.friendsFilteredById?[0]?.name, "Test person 2")
            }

            self.wait(for: [fetchFromServer], timeout: 5.0)

            // read from cache
            let fetchFromCache = self.expectation(description: "Fetching query from cache")
            client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
                defer { fetchFromCache.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.human?.name, "Test person 1")
                XCTAssertEqual(result.data?.human?.friendsFilteredById?[0]?.id, "100.2")
                XCTAssertEqual(result.data?.human?.friendsFilteredById?[0]?.name, "Test person 2")
            }

            self.wait(for: [fetchFromCache], timeout: 5.0)
        }
    }

    @available(iOS 10.0, *)
    func testHumanQueryWithDotInIdFromCache() {
        let directoryURL = FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try! FileManager.default.createDirectory(at: directoryURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)

        let fileURL = directoryURL.appendingPathComponent("queries.db")

        print("Testing with cache DB at:\n\(fileURL.path)")

        SQLiteTestCacheProvider.withCache(fileURL: fileURL) { cache in
            let networkTransport = MockNetworkTransport(body: [
                "data": [
                    "human": [
                        "name": "Test person",
                        "__typename": "Human",
                        "mass": 90
                    ]
                ]
                ])

            let store = ApolloStore(cache: cache)
            let client = ApolloClient(networkTransport: networkTransport, store: store)

            let query = HumanQuery(id: "100.1")

            // populate cache by fetching from server
            let fetchFromServer = self.expectation(description: "Fetching query from server")
            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
                defer { fetchFromServer.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.human?.name, "Test person")
            }

            self.wait(for: [fetchFromServer], timeout: 5.0)

            // read from cache
            let fetchFromCache = self.expectation(description: "Fetching query from cache")
            client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
                defer { fetchFromCache.fulfill() }

                guard let result = result else { XCTFail("No query result");  return }

                XCTAssertEqual(result.data?.human?.name, "Test person")
            }

            self.wait(for: [fetchFromCache], timeout: 5.0)
        }
    }

    func testFetchAndPersist() {
        let query = HeroNameQuery()
        let sqliteFileURL = SQLiteTestCacheProvider.temporarySQLiteFileURL()

        SQLiteTestCacheProvider.withCache(fileURL: sqliteFileURL) { (cache) in
            let store = ApolloStore(cache: cache)
            let networkTransport = MockNetworkTransport(body: [
                "data": [
                    "hero": [
                        "name": "Luke Skywalker",
                        "__typename": "Human"
                    ]
                ]
                ])
            let client = ApolloClient(networkTransport: networkTransport, store: store)

            let networkExpectation = self.expectation(description: "Fetching query from network")
            let newCacheExpectation = self.expectation(description: "Fetch query from new cache")

            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
                defer { networkExpectation.fulfill() }
                guard let result = result else { XCTFail("No query result");  return }
                XCTAssertEqual(result.data?.hero?.name, "Luke Skywalker")

                // Do another fetch from cache to ensure that data is cached before creating new cache
                client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
                    SQLiteTestCacheProvider.withCache(fileURL: sqliteFileURL) { (cache) in
                        let newStore = ApolloStore(cache: cache)
                        let newClient = ApolloClient(networkTransport: networkTransport, store: newStore)
                        newClient.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
                            defer { newCacheExpectation.fulfill() }
                            guard let result = result else { XCTFail("No query result");  return }
                            XCTAssertEqual(result.data?.hero?.name, "Luke Skywalker")
                            _ = newClient // Workaround for a bug - ensure that newClient is retained until this block is run
                        }
                    }
                }
            }
            self.waitForExpectations(timeout: 2, handler: nil)
        }
    }
}
