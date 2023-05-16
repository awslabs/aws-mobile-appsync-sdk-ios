platform :ios, "9.0"

use_frameworks!
inhibit_all_warnings!

AWS_SDK_VERSION = "2.32.0"

target "AWSAppSync" do
  pod "AWSCore", "~> #{AWS_SDK_VERSION}"
  pod "SQLite.swift", "~> 0.12.2"
  pod "AppSyncRealTimeClient", "~> 3.0.0"

  pod "SwiftLint"
end

target "AWSAppSyncTestCommon" do
  pod "AWSS3", "~> #{AWS_SDK_VERSION}"
  # We directly access a database connection to verify certain initialization
  # setups
  pod "SQLite.swift", "~> 0.12.2"
  pod "AppSyncRealTimeClient", "~> 3.0.0"
end

target "AWSAppSyncTestApp" do
  pod "AWSS3", "~> #{AWS_SDK_VERSION}"
  pod "AWSMobileClient", "~> #{AWS_SDK_VERSION}"
end

target "AWSAppSyncTestHostApp" do
end

target "AWSAppSyncUnitTests" do
end

target "AWSAppSyncIntegrationTests" do
end

target "ApolloTests" do
  pod "AWSCore", "~> #{AWS_SDK_VERSION}"
end
