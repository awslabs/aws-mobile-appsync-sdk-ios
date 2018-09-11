# AWS AppSync SDK for iOS - CHANGELOG

The AWS AppSync SDK for iOS enables you to access your AWS AppSync backend and perform operations like `Queries`, `Mutations` and `Subscriptions`. The SDK also includes support for offline operations.

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


