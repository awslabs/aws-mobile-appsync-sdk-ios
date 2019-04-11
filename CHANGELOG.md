# AWS AppSync SDK for iOS - CHANGELOG

The AWS AppSync SDK for iOS enables you to access your AWS AppSync backend and perform operations like `Queries`, `Mutations` and `Subscriptions`. The SDK also includes support for offline operations.

## 2.10.4

### New Features

- The AppSyncClient now supports specifying retry strategy using the `retryStrategy` parameter in `AWSAppSyncClientConfiguration`. You can choose between `aggressive` and `exponential`(default selection).

### Bug Fixes

- Mark `uniqueIdentifier` field in `AWSSubscriptionWatcher` as public which was incorrectly marked private in previous version.

## 2.10.3

### New Features

- The AppSyncClient's `subscribe` method now accepts an optional `statusChangeHandler`. If provided, then the `AWSAppSyncSubscriptionWatcher`
  returned by the `subscribe` method will invoke that method when it is notified of changes to the state of the underlying MQTT client.
  `AWSAppSyncSubscriptionWatcherStatus` for a description of the statuses and their progression. Thanks @fans3210, @shannon-hager-skookum, and @achager for
  contributing your thoughts to the original request ([Issue #42](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/42)) and to
  @MarioBajr for contributing the original implementation on [PR #75](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/75).
- Added a `queuedMutationCount` property to AppSyncClient ([Issue #192](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/192))

### Bug fixes

- Fixed incorrect AWSCore dependency version in podspec ([Issue #190](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/190))
- Fixed data races in AppSyncMQTTClient that were causing crashes ([Issue #184](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/184))

### Misc. Updates

- Added `AWSAppSyncClientLogFormatter` utility class. Developers who want to use it can add it to the appropriate logger. For example, a configuration like:
    ```swift
    AWSDDLog.sharedInstance.logLevel = .verbose
    AWSDDTTYLogger.sharedInstance.logFormatter = AWSAppSyncClientLogFormatter()
    AWSDDLog.sharedInstance.add(AWSDDTTYLogger.sharedInstance)
    ```
  would output log messages like:
    ```
    2019-03-04 07:21:32.131-0800 [I AWSAppSyncClient.init(appSyncConfig:reachabilityFactory:), L75] Initializing AppSyncClient
    2019-03-04 07:21:32.135-0800 [V AWSPerformMutationQueue.init(appSyncClient:networkClient:reachabiltyChangeNotifier:cacheFileURL:), L24] Initializing AWSPerformMutationQueue
    2019-03-04 07:21:32.135-0800 [V AWSPerformMutationQueue.resume(), L95] Resuming OperationQueue
    ```
  Please note that `verbose` logging is quite verbose, and there is a significant difference between `verbose` and `debug`. We will be making
  `debug` more useful as we go. (See [Issue #145](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/145))
  
  As always, we recommend turning off logging when deploying to production.
- Added some verbose logging around mutation queue handling and subscription connections; minor log additions elsewhere
- Minor dead code removal & miscellaneous cleanup

## 2.10.2

### Bug fixes

- Fixed a bug where queries with dots (`"."`) in the arguments were not being properly cached ([Issue #110](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/110), [#165](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/165))
- `AWSAppSyncClient.perform(mutation:queue:optimisticUpdate:conflictResolutionBlock:resultHandler:)` now properly invokes its result handler callbacks on the supplied `queue` instead of always using `DispatchQueue.main`

## 2.10.1

### Bug fixes

- Prepopulate the queries cache with an empty `QUERY_ROOT` record, to allow optimistic updates of the cache where no queries have been previously performed. ([Issue #92](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/92), [#101](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/101))
- Fix how "cache hits" are determined in queries, to match Apollo behavior.
  A "cache hit" is defined as all members of the selection set having a non-nil value. For a simple query, (e.g., the `HeroNameQuery` of the StarWars API), that is an easy mental map:

  **Cache hit**

    ```javascript
    {
      "QUERY_ROOT": { "hero": "#hero" },
      "#hero": { "hero": {"name": "R2-D2", "__typename": "Droid"} }
    }
    ```

  **Cache misses**
    ```javascript
    {}

    { "QUERY_ROOT": null }


    { "QUERY_ROOT": {} }

    {
      "QUERY_ROOT": { "hero": "#hero" },
      "#hero": { "hero": null }
    }

    // Misses because type data is incomplete
    {
      "QUERY_ROOT": { "hero": "#hero" },
      "#hero": { "hero": {"name": "R2-D2"} }
    }
    ```

  For more complex queries (like the `TwoHeroesQuery`), only all values being non-nil will result in a cache hit:
  **Cache Hit**
    ```javascript
    {
      "QUERY_ROOT": {
        "hero": "#hero",
        "hero(episode:EMPIRE)": "#hero(episode:EMPIRE)"
      },
      "#hero": {"name": "R2-D2", "__typename": "Droid"},
      "#hero(episode:EMPIRE)": {"name": "Luke Skywalker", "__typename": "Human"}
    }
    ```

  **Cache Misses**
    ```javascript
    {}

    { "QUERY_ROOT": null }


    { "QUERY_ROOT": {} }

    {
      "QUERY_ROOT": { "hero": "#hero" },
      "#hero": { "hero": null }
    }

    {
      "QUERY_ROOT": {
        "hero": "#hero"
      },
      "#hero": {"name": "R2-D2", "__typename": "Droid"}
    }
    ```

  These definitions match the existing Apollo behavior, as verified in additional tests against the
  unmodified Apollo codebase.


### Misc. Updates

- Updated CloudFormation template to include S3 buckets and associated configuration to support complex object integration tests, and added integration tests for S3 uploads and downloads.

## 2.10.0

### Bug fixes

* Merged Apollo iOS [PR #427](https://github.com/apollographql/apollo-ios/pull/427) to fix incompatibility with EnumeratedIterator in latest Xcode 10.2 beta.
* Fixed an issue where performing a mutation with no parameters would crash clients using a backing database. [Issue #33](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/33)
* Reduced database contention to fix crash resuming from background (See [Issue #160](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/160)). Thanks @larryonoff for contributing to this fix! 🎉

### Misc. Updates

**AWSAppSyncCacheConfiguration**

AppSync persistent caches for queries (used by the Apollo store), mutations,
and subscription metadata are now stored in separate files. A new
`AWSAppSyncCacheConfiguration` API has been added that allows clients to
specify persistent caches for all, some, or none of these caches:

```swift
// Specify persistent caches that live in the app's Cache directory
let cacheConfiguration = try AWSAppSyncCacheConfiguration()

// ... or specify persistent caches that live in `rootDirectory`
let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)

// ... or specify a database path for the query cache and the subscriptionMetadata cache, but an in-memory cache for mutation queue
let cacheConfiguration = AWSAppSyncCacheConfiguration(offlineMutations: nil,
                                                      queries: queriesDatabasePath,
                                                      subscriptionMetadataCache: subscriptionMetadataDatabasePath)

// ... or specify all caches to be in-memory
let cacheConfiguration = AWSAppSyncCacheConfiguration.inMemory

// ... then use the cache config in the AWSAppSyncClientConfiguration constructor
let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig, cacheConfiguration: cacheConfiguration)
let appSyncClient = AWSAppSyncClient(appSyncConfig: appSyncConfig)

// Alternately, specify all in-memory caches by passing no `cacheConfiguration`
let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig)
let appSyncClient = AWSAppSyncClient(appSyncConfig: appSyncConfig)
```

**Migration**

Clients can migrate to the new AWSAppSyncCacheConfiguration with a utility
method that performs a one-time move of data from the previous databaseURL to
the new cache configuration directory:

```swift
// Specify persistent caches that live in the app's Cache directory
let cacheConfiguration = try AWSAppSyncCacheConfiguration()

let databaseURL = // whatever your old databaseURL was

// Upon successful completion, this method sets a flag in UserDefaults, making it safe
// to call at startup for as long as this method exists.
AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, to: cacheConfiguration)
```

* **Breaking API Changes**
  - `AWSSQLLiteNormalizedCacheError` has been renamed to
    `AWSAppSyncQueriesCacheError`. Error conditions during manipulations of the
    Apollo store will now throw this type.

* **Deprecations**
  - `AWSSQLLiteNormalizedCache` is deprecated and will be removed in an
    upcoming minor version of AWSAppSync, as that implementation is an internal
    detail. Clients that wish to do cleanup of database files can use
    `AWSAppSyncCacheConfiguration` to get the path of the appropriate database
    file.
  - The `databaseURL` option to `AWSAppSyncClientConfiguration` is deprecated.
    Please use the `cacheConfiguration` option (See above)
  - The `MutationCache` protocol is deprecated because it is unused.

## 2.9.2

### New Features

* Added an `AWSAppSyncClient.clearCache()` method to clear the local Apollo cache. See [Issue #36](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/36), [PR #141](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/141) Thanks @larryonoff! 🎉

### Bug fixes

* AppSyncClient.sync() now properly invokes its subscription callbacks on the supplied `handlerQueue` instead of always using `DispatchQueue.main`

### Misc. Updates

* AWSAppSync now uses Xcode 10.1 to build its Carthage binaries. This will make the binaries compatible with **Swift 4.2.1**. Projects that have not yet upgraded to use Swift 4.2.1 will fall back to building from source.
* The AWSAppSync target no longer specifies values for `VALID_ARCH` in its build settings but instead uses defaults. [See PR#156](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/156) Thanks @larryonoff! 🎉

## 2.9.1

### Bug Fixes

* Updated the Cartfile to depend on the correct version of the AWS iOS SDK. (Note, this is advisory only; we do not retrieve dependencies via Carthage.)
* Added Pods to source control so Carthage users (or anyone else who builds from source) will no longer need to issue a `pod update` before building (#150)

## 2.9.0

### Bug Fixes

* Mutation queue handling is rewritten to use `OperationQueue`, to fix cases where mutations would either deadlock (#81), or not execute (#106). Thanks @larryonoff! 🎉
* S3Objects now correctly upload whether they are included as part of a mutation's parameters or an input type (#122)

### Misc. Updates

* **Breaking API Changes**
  * `AWSPerformMutationOperation` was `public`, now it's `internal`
  * `AWSAppSyncClient.perform` now returns `Cancellable` instead of `AWSPerformMutationOperation`

* Refactored internal network change notifications (#139)

* Refactored structure & tests to make future maintenance easier. As part of this, we deprecated the `AWSAppSyncClientInfo` class in favor of the `AWSAppSyncServiceConfigProvider` protocol. We provide a default implementation `AWSAppSyncServiceConfig`. `AWSAppSyncClientInfo` will be removed in a future minor version.
  - Thanks to @larryonoff for contributing code and PR feedback to this refactor! 🎉

* Refactored tests into Unit and Integration tests. Currently, any test that requires network activity is placed in Integration tests, even if the test hits localhost and not a valid service.
  - Updated the README to include new instructions for setting up your integration test environment.
  - The project now includes an AWS CloudFormation template to bootstrap your test setups. This will be updated in the future to include S3 buckets and associated configuration to support complex object integration tests.

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
