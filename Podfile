platform :ios, "9.0"

use_frameworks!
inhibit_all_warnings!

AWS_SDK_VERSION = "2.12.0"

target "AWSAppSync" do
  pod "AWSCore", "~> #{AWS_SDK_VERSION}"
  pod "SQLite.swift", "~> 0.12.2"
  pod "ReachabilitySwift", "~> 5.0.0"
  pod "Starscream", "~> 3.0.2"
end

target "AWSAppSyncTestCommon" do
  pod "AWSS3", "~> #{AWS_SDK_VERSION}"
  pod "ReachabilitySwift", "~> 5.0.0"
  # We directly access a database connection to verify certain initialization
  # setups
  pod "SQLite.swift", "~> 0.12.2"
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
