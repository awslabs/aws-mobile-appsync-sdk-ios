# AWS AppSync SDK for iOS - CHANGELOG

The AWS AppSync SDK for iOS enables you to access your AWS AppSync backend and perform operations like `Queries`, `Mutations` and `Subscriptions`. The SDK also includes support for offline operations.

## 2.8.0

### Misc. Updates

* Use Swift 4.2's `Float.random(in:)` instead of `arc4random()` to generate request retry jitter. [See PR #108](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/108). Thanks @larryonoff! 🎉
* Added SwiftLint to project. [See PR #121](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/121) and [issue #107](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/107). Thanks @larryonoff! 🎉
* Increase stability of the integration tests; removed subscription integration test since its functionality is now covered by sync operation test.
* Upgraded SQLite.swift to 0.11.5, which fixes compiler warnings when compiling AWSAppSync in Xcode. Thanks @larryonoff! 🎉
* **Breaking API Changes**
  * `SyncConfiguration`:
    - The type changed from a `class` to a `struct`
    - The initializer parameter is now optional, and the previous `defaultSyncConfiguration` method has been removed. Create a default configuration by invoking the initializer with no arguments, `SyncConfiguration()`

## 2.7.0

### New Features

* Added support for Delta Sync Feature
    Delta Sync allows you to perform automatic synchronization with an AWS AppSync GraphQL server. The client will perform reconnection, exponential backoff, and retries when network errors take place for simplified data replication to devices. For more details, please refer [documentation.](https://aws-amplify.github.io/docs/ios/api)

### Bug Fixes

* Fixed issue where if a timeout error occurred due to lack of network availability, the callback would not be given back to the developer. [See issue #91](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/91)

### Misc. Updates

* Officially convert project to Swift 4.2. Previously, the project used some Swift 4.2 idioms even though the `SWIFT_VERSION` was officially set to 3. This change makes the support explicit in the project files and README.
* Updated SwiftReachability dependency to 4.3.0. (See PR #84)[https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/84] Thanks @larryonoff! 🎉
* Replaced generic struct based AWSAppSyncClientError by a typed enum. (See PR #35)[https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/35] Thanks @MarioBajr! 🎉

## 2.6.24

### Misc. Updates

* `AWSAppSync` now depends on `AWSCore` version `2.7.x` instead of `2.6.x`.

## 2.6.23

### Bug Fixes

* Resolved retain cycles in AWSAppSyncClient which allow the instance to be deallocated. [See PR#88](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/88) Thanks @ifabijanovic 🎉
* Resolved retain cycle in underlying MQTT client. [Source](https://github.com/aws/aws-sdk-ios/pull/1037)

## 2.6.22

### Enhancements

* Allow multiple active subscriptions while using `API_KEY` auth.
* Add retry logic for the HTTP service calls.
* Allow responses to have missing fields if they are optional.
* Fix issue with optimistic writes which would incorrectly throw `JSONDecodingError.missingValue` error. See issues [#51](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/51) [#8](https://github.com/aws-samples/aws-mobile-appsync-events-starter-ios/issues/8)
* Fix warnings imposed by iOS 12. [See PR#71](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/71)

## 2.6.21

### Enhancements

* Improve subscriptions logic to use a single shared queue and avoid delay between multiple subscriptions. [See PR#28](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/28) Thanks @MarioBajr! 🎉

## 2.6.20

### Enhancements

* Allow asynchronous fetching of User Pools / OIDC auth token. [See PR#62](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/62) Thanks @JohnRbk 🎉
* Integrate logging with `AWSDDLog`. To print logs from the SDK, follow instructions mentioned [here](https://github.com/aws/aws-sdk-ios#logging).

### Bug Fixes

* Fixed a bug in loading configuration from `awsconfiguration.json`
* Fixed a bug where receiving a non String or JSON object would cause SDK to crash. The SDK would now instead log an error message.

## 2.6.19

### New Features
* Add support for AWS AppSync configuration through `awsconfiguration.json` in `AWSAppSyncClient`.

## 2.6.18

### Enhancements

* Improve connection handling of underlying MQTTClient.

## 2.6.17

### Enhancements

* Improve performance of AWSAppSyncMQTTClient. [See PR#34](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/34)
* AWSNetworkTransport modifications to enable the ability to mock server. [See PR#40](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/40)
* Fixed typo in AWSGraphQLSubscriptionResponse initializer and variable. [See PR#29](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/29)

### Bug Fixes

* Preventing IAM signature requests from blocking the main thread. [See PR#32](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/32)
* Call the AWSAppSyncClientConfiguration connectionStateChangeHandler which was previously un-used. [See PR#30](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/30)

## 2.6.16

### New Feature
* Add OpenID Connect (OIDC) support as an authorization option.

### Bug Fixes
* Fix SQLite lock issue. [See PR#20](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/20)
* Renamed private AWSSRWebSocket classes in order to avoid duplicated symbols. [See PR#21](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/21)
* Respect the requested callback queue when invoking subscription callbacks. [See PR#22](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/22)


## 2.6.15

### Bug Fix
* Fixed a crash  in `cancel` method of `SubscriptionWatcher` by adding a safer workflow. [See PR #11](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/11)

## 2.6.14

### New Features
* Expose whether a result was served from service or cache. [Source](https://github.com/apollographql/apollo-ios/commit/d93b763226c97eaf9128f643fb56c756e2ba7560)
* Watchers are now triggered while writing to cache from a transaction. [Source](https://github.com/apollographql/apollo-ios/commit/a5a3e1d273ebe376ff021eca45239a1197417307)

### Bug Fixes
* Fixed a bug in `cancel` method of `SubscriptionWatcher` where calling `cancel` and then restarting a subscription in the same view controller would cause a crash.


