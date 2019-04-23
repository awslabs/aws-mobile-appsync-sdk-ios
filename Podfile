platform :ios, '9.0'

# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

target 'AWSAppSync' do
  pod 'AWSCore', '~> 2.9.0'
  pod 'SQLite.swift', '0.11.6'

  # We are pinning to this version as 4.3.1 updates XCode requirements to Xcode
  # 10.2 and Swift 5. We currently intend to keep Xcode 10+ and Swift 4+ as
  # minimum requirement for development.
  pod 'ReachabilitySwift', '4.3.0'
end

target 'AWSAppSyncTestCommon' do
  pod 'AWSCore', '~> 2.9.0'
  pod 'AWSS3', '~> 2.9.0'
  pod 'ReachabilitySwift', '4.3.0'
  # We directly access a database connection to verify certain initialization
  # setups
  pod 'SQLite.swift', '0.11.6'
end

target 'AWSAppSyncTestApp' do
  pod 'AWSS3', '~> 2.9.0'
  pod 'AWSMobileClient', '~> 2.9.0'
end

target 'AWSAppSyncTestHostApp' do
end

target 'AWSAppSyncUnitTests' do
end

target 'AWSAppSyncIntegrationTests' do
end

target 'ApolloTests' do
  pod 'AWSCore', '~> 2.9.0'
end
