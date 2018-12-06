AWS AppSync SDK for iOS
=======================

[![Release](https://img.shields.io/github/release/awslabs/aws-mobile-appsync-sdk-ios.svg)](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/releases)
[![CocoaPods](https://img.shields.io/cocoapods/v/AWSAppSync.svg)](https://github.com/CocoaPods/CocoaPods)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/awslabs/aws-mobile-appsync-sdk-ios.svg?branch=master)](https://travis-ci.org/awslabs/aws-mobile-appsync-sdk-ios)
[![Documentation Status](https://readthedocs.org/projects/ansicolortags/badge/?version=latest)](https://aws-amplify.github.io/docs/ios/api/)
[![Swift](https://img.shields.io/badge/swift-4.2-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Twitter Follow](https://img.shields.io/twitter/follow/AWSforMobile.svg?style=social&label=Follow)](https://twitter.com/AWSforMobile)


The AWS AppSync SDK for iOS enables you to access your AWS AppSync backend and perform operations like `Queries`, `Mutations`, and `Subscriptions`. The SDK also includes support for offline operations. This SDK is based off of the Apollo project found [here](https://github.com/apollographql/apollo-ios). Please log questions for this client SDK in this repo and questions for the AppSync service in the [official AWS AppSync forum](https://forums.aws.amazon.com/forum.jspa?forumID=280&start=0).

## Setup

> Note: AWS AppSync uses Swift 4.2. Use Xcode 10.0 or greater to build.

- Consuming through cocoapods:

1. Add the following line to your Podfile:

    ```
    pod 'AWSAppSync', '~> 2.6.24'
    ```

    Example:

    ```
    # Uncomment the next line to define a global platform for your project
    # platform :ios, '9.0'

    target 'EventsApp' do
      # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
      use_frameworks!

      # Pods for EventsApp
      pod 'AWSAppSync', '~> 2.6.24'
    end
    ```

2. Run `pod install` to install the AppSync SDK

3. Now, open the `.xcworkspace` file and import the SDK using `import AWSAppSync`.

- Codegen

    To use the AppSync SDK, you will need to use `amplify codegen` from the [AWS Amplify CLI](https://aws-amplify.github.io/docs/cli/codegen?sdk=ios) which helps generate a strongly typed API for your schema. You can find the instructions to use the codegen here: https://aws-amplify.github.io/docs/ios/api


## Sample

You can find a sample app which uses the AppSync SDK here: https://github.com/aws-samples/aws-mobile-appsync-events-starter-ios 

## Documentation

You can find a step by step walk through of setting up codegen backend and accessing it via the iOS client here: https://aws-amplify.github.io/docs/ios/api

## Contributing

Contributing guidelines are noted [here](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/blob/master/CONTRIBUTING.md).

## Testing Contributions

If you are contributing to the SDK, it is recommended to add some unit/ functional tests and evaluate against existing tests.

### Unit Tests

Unit Tests do not require any specific setup and can be run directly from your Xcode IDE.

### Functional Tests

For running functional tests, we will need the following:
- An AppSync API with an `Events App` schema
- A Cognito Identity Pool with unauthenticated identities supported
- The Cognito Identity Pool's unauth role should have the `AppSync Invoke Full Access` permission

You can get the backend setup by following the steps below:

- Go to [AWS AppSync console](https://console.aws.amazon.com/appsync/home).
- Click on `Create New API` and then select `Event App` and hit `Create`, take a note of the `API URL` of the created API.
- Once the creation completes, select `Settings` from left side of the console and then select `AWS Identity and Access Management (IAM)` as the authorization type.
- Next, create a new Cognito Identity Pool and attach `AppSync Invoke Full Access` permission to the unauth role of the Identity Pool. Keep a note of the Identity Pool ID of newly created pool.
- Create another AppSync API using the same steps above, but use API Key Auth mode instead which is available by default.

Finally, you will need to setup a config file locally to access the server, either by using a local configuration file, or by editing defaults in the source code.

> Note: You must either provide all values in the `AppSyncTests/appsync_test_credentials.json` or in code. There is no mechanism to handle partial overrides of one source with the other. All values must be specified before running the functional tests.

__Option 1: Use a test configuration file__

Add a file `appsync_test_credentials.json` (see sample below) in the `AWSAppSyncTests` folder and replace the values for `AppSyncEndpoint`,  `CognitoIdentityPoolId`, `AppSyncEndpointAPIKey`, `AppSyncAPIKey` and regions if required:

```json
{
  "AppSyncEndpoint": "https://asd32hl34523454532.appsync-api.us-east-1.amazonaws.com/graphql",
  "AppSyncRegion": "us-east-1",
  "CognitoIdentityPoolId": "us-east-1:abcas234-1234-12324-b4b7-aaa0c0831234",
  "CognitoIdentityPoolRegion": "us-east-1",
  "AppSyncEndpointAPIKey": "https://apikeybasedendpoint.appsync-api.us-east-1.amazonaws.com/graphql",
  "AppSyncEndpointAPIKeyRegion": "us-east-1",
  "AppSyncAPIKey": "da2-sad3lkh23422"
}
```

> Note: The `AppSyncEndpointAPIKey` endpoint uses `API_KEY` based auth, while `AppSyncEndpoint` uses the `AWS_IAM` based auth.

__Option 2: Edit defaults in source code__

Edit the file `AWSAppSyncTests/AppSyncClientTestConfigurationDefaults` with appropriate values.

Now you should be able to run the functional tests by invoking "Product > Test" (⌘-U) in Xcode.

## License

This library is licensed under the [Amazon Software License](https://aws.amazon.com/asl/).
