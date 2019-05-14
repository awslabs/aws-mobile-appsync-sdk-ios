//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

@testable import AWSAppSync

struct DefaultTestPostData {
    static let author = "Test author"
    static let title = "Test title"
    static let content = "Test content"
    static let url: String? = "https://aws.amazon.com/"
    static let ups = 0
    static let downs = 0

    static var defaultCreatePostWithoutFileUsingParametersMutation: CreatePostWithoutFileUsingParametersMutation {
        let mutation = CreatePostWithoutFileUsingParametersMutation(
            author: author,
            title: title,
            content: content,
            url: url,
            ups: ups,
            downs: downs
        )
        return mutation
    }
}
