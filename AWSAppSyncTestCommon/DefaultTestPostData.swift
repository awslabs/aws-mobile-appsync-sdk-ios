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

@testable import AWSAppSync

struct DefaultTestPostData {
    static let author = "Test author"
    static let title = "Test title"
    static let content = "Test content"
    static let url: String? = nil
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
