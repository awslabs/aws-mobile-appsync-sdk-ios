import XCTest
@testable import AWSAppSync

extension XCTestCase {
  public func awaitWith<T>(_ promise: Promise<T>) throws -> T {
    let expectation = self.expectation(description: "Expected promise to be resolved")
    
    promise.finally {
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 5)
    
    return try promise.result!.valueOrError()
  }
}
