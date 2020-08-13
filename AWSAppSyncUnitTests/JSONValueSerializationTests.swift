//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
import StarWarsAPI

class JSONValueSerializationTests: XCTestCase {

    /// Test to confirm that the variables containing Enum type is not valid JSONObject. The variables object should be
    /// valid JSON for downstream serialization done by various consumers (ApolloClient, AppSyncRealTimeClient).
    /// See https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/401 for more details.
    ///
    /// - Given: A code generated file containing the subscription `ReviewAddedSubscription` has variables containing a
    /// single key-value pair. The type of the value is the `Episode` Enum.
    /// - When:
    ///    - Check if `variables` is a valid JSON object.
    /// - Then:
    ///    - `JSONSerialization.isValidJSONObject` returns false
    ///
    func test_subscriptionVariables_invalidJSONObject() {
        let subscription = ReviewAddedSubscription(episode: .jedi)
        guard let variables = subscription.variables else {
            XCTFail("Failed to set up subscription operation containing variables")
            return
        }
        XCTAssertFalse(JSONSerialization.isValidJSONObject(variables))
    }

    /// Test to confirm that variables containing Enum type, converted to JSONValue, can be serialized to Data.
    /// See https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/401 for more details.
    ///
    /// - Given: A code generated file containing the subscription `ReviewAddedSubscription` has variables containing a
    /// single key-value pair. The type of the value is the `Episode` Enum. Retrieve the `JSONValue` representation.
    /// - When:
    ///    - Serialize the JSON object to Data
    /// - Then:
    ///    - Successfully serialized JSON object
    ///
    func test_subscriptionVariablesJSONValue_ValidSerialization() throws {
        let subscription = ReviewAddedSubscription(episode: .jedi)
        guard let variables = subscription.variables else {
            XCTFail("Failed to set up subscription operation containing variables")
            return
        }
        let jsonValue = variables.mapValues { $0?.jsonValue }
        XCTAssertTrue(JSONSerialization.isValidJSONObject(jsonValue))
        let data = try? JSONSerialization.data(withJSONObject: jsonValue)
        XCTAssertNotNil(data)
    }

    func test_variablesEnumAndStruct() throws {
        let reviewInput = ReviewInput(stars: 1, favoriteColor: ColorInput(red: 1, green: 1, blue: 1))
        guard let variables = CreateReviewForEpisodeMutation(episode: .jedi, review: reviewInput).variables else {
            XCTFail("Could not get variables")
            return
        }
        let jsonValue = variables.mapValues { $0?.jsonValue }
        XCTAssertTrue(JSONSerialization.isValidJSONObject(jsonValue))
        let data = try? JSONSerialization.data(withJSONObject: jsonValue)
        XCTAssertNotNil(data)
    }

    func test_variablesMultipleBool() throws {
        guard let variables = HeroNameConditionalBothQuery(skipName: true, includeName: false).variables else {
            XCTFail("Could not get variables")
            return
        }
        let jsonValue = variables.mapValues { $0?.jsonValue }
        XCTAssertTrue(JSONSerialization.isValidJSONObject(jsonValue))
        let data = try? JSONSerialization.data(withJSONObject: jsonValue)
        XCTAssertNotNil(data)
    }

    func test_variablesGraphQLIDAndOptionalGraphQLID() throws {
        guard let variables = HumanFriendsFilteredByIdQuery(id: "123", friendId: "234").variables else {
            XCTFail("Could not get variables")
            return
        }
        let jsonValue = variables.mapValues { $0?.jsonValue }
        XCTAssertTrue(JSONSerialization.isValidJSONObject(jsonValue))
        let data = try? JSONSerialization.data(withJSONObject: jsonValue)
        XCTAssertNotNil(data)
    }
}
