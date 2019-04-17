//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

@testable import AWSAppSync

struct UnitTestHelpers {

    static func makeAppSyncClient(using httpTransport: AWSNetworkTransport,
                                  cacheConfiguration: AWSAppSyncCacheConfiguration?) throws -> DeinitNotifiableAppSyncClient {
        let helper = try AppSyncClientTestHelper(
            with: .apiKey,
            testConfiguration: AppSyncClientTestConfiguration.forUnitTests,
            cacheConfiguration: cacheConfiguration,
            httpTransport: httpTransport,
            reachabilityFactory: MockReachabilityProvidingFactory.self
        )

        if let cacheConfiguration = cacheConfiguration {
            print("AppSyncClient created with cacheConfiguration: \(cacheConfiguration)")
        } else {
            print("AppSyncClient created with in-memory caches")
        }
        return helper.appSyncClient
    }

    static func makeAddPostResponseBody(withId id: GraphQLID,
                                        for mutation: CreatePostWithoutFileUsingParametersMutation) -> JSONObject {
        let createdDateMilliseconds = Date().timeIntervalSince1970 * 1000

        let response = CreatePostWithoutFileUsingParametersMutation.Data.CreatePostWithoutFileUsingParameter(
            id: id,
            author: mutation.author,
            title: mutation.title,
            content: mutation.content,
            url: mutation.url,
            ups: mutation.ups ?? 0,
            downs: mutation.downs ?? 0,
            file: nil,
            createdDate: String(describing: Int(createdDateMilliseconds)),
            awsDs: nil)
        return ["data": ["createPostWithoutFileUsingParameters": response.jsonObject]]
    }

    static func makeGetPostResponseBody(with id: GraphQLID) -> JSONObject {
        let createdDateMilliseconds = Date().timeIntervalSince1970 * 1000
        let post = GetPostQuery.Data.GetPost(id: id,
                                             author: DefaultTestPostData.author,
                                             title: DefaultTestPostData.title,
                                             content: DefaultTestPostData.content,
                                             url: DefaultTestPostData.url,
                                             ups: DefaultTestPostData.ups,
                                             downs: DefaultTestPostData.downs,
                                             file: nil,
                                             createdDate: String(describing: Int(createdDateMilliseconds)),
                                             awsDs: nil)

        let response = GetPostQuery.Data(getPost: post)
        return [
            "data": response.jsonObject
        ]
    }

    static func makeListPostsResponseBody(withId id: GraphQLID) -> JSONObject {
        let createdDateMilliseconds = Date().timeIntervalSince1970 * 1000
        let post = ListPostsQuery.Data.ListPost(id: id,
                                                author: "Test author",
                                                title: "Test Post",
                                                content: "Test Content",
                                                url: "http://test.com",
                                                ups: 0,
                                                downs: 0,
                                                file: nil,
                                                createdDate: String(describing: Int(createdDateMilliseconds)),
                                                awsDs: nil)
        let response = ListPostsQuery.Data(listPosts: [post])
        return [
            "data": response.jsonObject
        ]
    }

}
