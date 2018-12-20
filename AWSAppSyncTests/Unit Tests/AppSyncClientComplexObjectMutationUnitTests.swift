//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import XCTest
@testable import AWSAppSync

class AppSyncClientComplexObjectMutationUnitTests: XCTestCase {
    // TODO: Test in progress
    func TODO_IN_PROGRESS_test_clientQueuesMutationOfCorrectType_WhenS3ObjectIsPartOfInput() throws {
        // Create a client
        let httpTransport = MockNetworkTransport()

        let helper = try AppSyncClientTestHelper(
            with: .apiKey,
            testConfiguration: AppSyncClientTestConfiguration.UnitTestingConfiguration,
            httpTransport: httpTransport
        )

        let appSyncClient = helper.appSyncClient

        let fileInput = S3ObjectInput(
            bucket: "the-bucket",
            key: "the-key.jpg",
            region: "us-east-1",
            localUri: "/path/to/file.jpg",
            mimeType: "image/jpeg"
        )

        // Create an object with a complex object field
        let mutation = AddEventWithFileMutation(
            name: "Test Event",
            when: "Today",
            where: "Location",
            description: "Description",
            file: fileInput
        )

        // Add the object to a mutation
        appSyncClient.perform(mutation: mutation)

        // Ensure the mutation is queued with .graphQLMutationWithS3Object
    }

    // TODO: Test in progress
    func TODO_test_clientQueuesMutationOfCorrectType_WhenS3ObjectIsSeparateMutationParameter() {
        // Create a client
        // Create an object with a complex object field
        // Add the object to a mutation
        // Ensure the mutation is queued with .graphQLMutationWithS3Object
    }

}
