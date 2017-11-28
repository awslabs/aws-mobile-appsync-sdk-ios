AWS AppSync SDK for iOS

The AWS AppSync SDK for iOS enables you to access your AWS AppSync backend and perform operations like `Queries`, `Mutations` and `Subscriptions`. The SDK also includes support for offline operations.

## Setup

- Consuming through cocoapods:

1. Add the following line to your Podfile:

```
  pod 'AWSAppSync', '~> 2.6.7'
```

Example:

```
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'EventsApp' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for EventsApp
  pod 'AWSAppSync', '~> 2.6.7'
end
```

2. Run `pod install` to install the AppSync SDK

3. Now, open the `.xcworkspace` file and import the SDK using `import AWSAppSync`.

- Codegen

To use the AppSync SDK, you will need to use `aws-appsync-codegen` which helps generated a strongly typed API for your schema. You can find the instructions to use the codegen here: https://github.com/awslabs/aws-appsync-codegen 

## Sample

You can find a sample app which uses the AppSync SDK here: https://github.com/aws-samples/aws-mobile-appsync-events-starter-ios 

## License

This library is licensed under the Amazon Software License.
