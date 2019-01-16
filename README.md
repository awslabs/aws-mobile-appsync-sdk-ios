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

> Note: AWS AppSync uses Swift 4.2.1. Use Xcode 10.1 or greater to build.

### Installing the SDK

#### Via CocoaPods

1. Add the following line to your Podfile:

    ```ruby
    pod 'AWSAppSync', '~> 2.9.0'
    ```

    Example:

    ```ruby
    # Uncomment the next line to define a global platform for your project
    # platform :ios, '9.0'

    target 'EventsApp' do
      # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
      use_frameworks!

      # Pods for EventsApp
      pod 'AWSAppSync', '~> 2.9.0'
    end
    ```

1. Run `pod install` to install the AppSync SDK, then open the **`.xcworkspace`** file (not the `.xcodeproj` file) in Xcode.

1. Now **Build** your project to start using the SDK. Whenever a new version of the SDK is released you can update by running `pod update` and rebuilding your project to use the new features.

1. In your source file, import the SDK using `import AWSAppSync`.

#### Via Carthage

1. Add the following to your Cartfile:

    ```
    github "awslabs/aws-mobile-appsync-sdk-ios"
    ```

1. Once complete, run `carthage update` and open the `*.xcworkspace` with Xcode and chose your `Target`. In the `General` tab, find `Embedded Binaries`, then choose the `+` button.

1. Choose the `Add Other` button, navigate to the `AWS<#ServiceName#>.framework` files under `Carthage > Build > iOS` and select `AWSAppSync.framework` and its required dependencies:

    * AWSAppSync.framework
    * AWSCore.framework
    * Reachability.framework
    * SQLite.framework

    Do not select the `Destination: Copy items` if needed check box when prompted.

1. Under the `Build Phases` tab in your `Target`, choose the `+` button on the top left and then select `New Run Script Phase`. Setup the build phase as follows. Make sure this phase is below the Embed Frameworks phase.

    ```bash
    bash "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/AWSCore.framework/strip-frameworks.sh"
    ```

    Options:
    * **Shell**: /bin/sh
    * **Show environment variables in build log**: Checked
    * **Run script only when installing**: Not checked
    * **Input Files**: Empty
    * **Output Files**: Empty

1. Now **Build** your project to start using the SDK. Whenever a new version of the SDK is released you can update by running `carthage update` and rebuilding your project to use the new features.

    > Note: Currently, the AWSAppSync SDK for iOS builds the Carthage binaries using Xcode 10.1. To consume the pre-built binaries your Xcode version needs to be the same. Otherwise you will have to build the frameworks on your machine by passing `--no-use-binaries` flag to `carthage update` command.

1. In your source file, import the SDK using `import AWSAppSync`.

### Codegen

    To use the AppSync SDK, you will need to use `amplify codegen` from the [AWS Amplify CLI](https://aws-amplify.github.io/docs/cli/codegen?sdk=ios) which helps generate a strongly typed API for your schema. You can find the instructions to use the codegen here: https://aws-amplify.github.io/docs/ios/api

## Sample

You can find a sample app which uses the AppSync SDK here: https://github.com/aws-samples/aws-mobile-appsync-events-starter-ios

## Documentation

You can find a step by step walk through of setting up codegen backend and accessing it via the iOS client here: https://aws-amplify.github.io/docs/ios/api

## Contributing

Contributing guidelines are noted [here](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/blob/master/CONTRIBUTING.md).

## Testing Contributions

If you are contributing to the SDK, it is recommended to add some unit and/or integration tests and evaluate against existing tests.

### Invoking tests

The `AWSAppSync` target is configured to run both Unit and Integration tests in its `Test` configuration. After completing integration test setup following the instructions below, you can run both suites by invoking "Product > Test" (⌘-U) in Xcode.

To run only one suite of tests (Unit or Integration), select the appropriate target from the Scheme selector and invoke "Product > Test" (⌘-U). While Unit tests run much faster than Integration tests, we recommend running both before submitting a PR.

### Setting up unit tests

Unit Tests do not require any specific setup and can be run directly from your Xcode IDE.
  - NOTE: Currently, any test that requires network activity is placed in Integration tests, even if the test hits localhost and not a valid service.

### Setting up integration tests

To run integration tests, you will need the following:
- Two AppSync API instances with an `Posts` schema.
  - The first AppSync instance should be configured to use a Cognito Identity Pool with unauthenticated identities supported.
    - The Cognito Identity Pool's unauth role should have the `AppSync Invoke Full Access` permission.
  - The second instance should be configured to use API Key authentication.

You can get the backend setup by following the steps below:

1. Create a stack with an AppSync API using API Key authentication
    1. Go to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation/home).
    1. Click on __Create stack__ and then select __Upload a template file__. Click __Choose File__, and navigate to the Cloud Formation Template in this project: `AWSAppSyncIntegrationTests/ConsoleResources/appsync-integrationtests-cloudformation.yaml`
    1. Click __Next__
    1. Type a "Stack name" and a "ResourceNamePrefix"
        - We recommend using a "ResourceNamePrefix" that makes it easy to tell that the stack is used for AppSync tests, such as `AppSyncTest<YYYYMMDDHHMM>`.
        - Because you will create two stacks for these tests, one using API Key authentication and one using IAM (Cognito Identity) authentication, we recommend selecting a stack name that makes it easy to differentiate between the two, such as `AppSyncTest<YYYYMMDDHHMM>-APIKey` and `AppSyncTest<YYYYMMDDHHMM>-IAM`.
    1. Select the `ApiKey` Auth Type
    1. Once the stack is complete, click on the __Output__ tab.
    1. Copy the appropriate values to the test configuration file `AppSyncIntegrationTests/appsync_test_credentials.json`:
        - `AppSyncApiKey`
        - `AppSyncEndpointAPIKey`
        - `AppSyncEndpointAPIKeyRegion`
1. Create another CloudFormation Stack following steps 1-6 above, but select the "IAM" Auth Type in step 5.
    1. Copy the appropriate values to the test configuration file `AppSyncIntegrationTests/appsync_test_credentials.json`:
        - `AppSyncEndpoint`
        - `AppSyncRegion`
        - `CognitoIdentityPoolId`
        - `CognitoIdentityPoolRegion`

> Note: You must either provide all values in the `AppSyncIntegrationTests/appsync_test_credentials.json` or in code. There is no mechanism to handle partial overrides of one source with the other. All values must be specified before running the integration tests.

__Option 1: Use a test configuration file__

Add a file `appsync_test_credentials.json` (see sample below) in the `AWSAppSyncIntegrationTests` folder and replace the values for `AppSyncEndpoint`,  `CognitoIdentityPoolId`, `AppSyncEndpointAPIKey`, `AppSyncAPIKey` and regions if required:

```json
{
  "AppSyncEndpoint": "https://iambasedendpoint.appsync-api.us-east-1.amazonaws.com/graphql",
  "AppSyncRegion": "us-east-1",
  "CognitoIdentityPoolId": "us-east-1:abcd1234-1234-12324-b4b7-aaa0c0831234",
  "CognitoIdentityPoolRegion": "us-east-1",
  "AppSyncEndpointAPIKey": "https://apikeybasedendpoint.appsync-api.us-east-1.amazonaws.com/graphql",
  "AppSyncEndpointAPIKeyRegion": "us-east-1",
  "AppSyncAPIKey": "da2-sad3lkh23422"
}
```

> Note: The `AppSyncEndpointAPIKey` endpoint uses `API_KEY` based auth, while `AppSyncEndpoint` uses the `AWS_IAM` based auth.

__Option 2: Edit defaults in source code__

Edit the file `AWSAppSyncTestCommon/AppSyncClientTestConfigurationDefaults` with appropriate values.

Now you should be able to run the integration tests by invoking "Product > Test" (⌘-U) in Xcode.

## License

This library is licensed under the [Amazon Software License](https://aws.amazon.com/asl/).
