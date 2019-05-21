Pod::Spec.new do |s|
  s.name         = 'AWSAppSync'
  s.version      = '2.13.1'
  s.author       = 'AWS'
  s.homepage     = 'http://aws.amazon.com/mobile/sdk'
  s.license      = { :type => 'Amazon Software License', :file => 'LICENSE' }
  s.summary      = "iOS client to access AWSAppSync backend."
  s.source       = { :git => 'https://github.com/awslabs/aws-mobile-appsync-sdk-ios.git',
                     :tag => s.version }
  s.requires_arc = true
  s.ios.deployment_target = '9.0'
  s.swift_version = '4.2'

  s.dependency 'AWSCore', '~> 2.9.0'
  s.dependency 'SQLite.swift', '0.11.6'

  # We are pinning to this version as 4.3.1 updates XCode requirements to Xcode
  # 10.2 and Swift 5. We currently intend to keep Xcode 10+ and Swift 4+ as
  # minimum requirement for development.
  s.dependency 'ReachabilitySwift', '4.3.0'

  s.source_files = 'AWSAppSyncClient/AWSAppSync.h', 'AWSAppSyncClient/*.swift', 'AWSAppSyncClient/Internal/*.swift', 'AWSAppSyncClient/Apollo/Sources/Apollo/*.swift', 'AWSAppSyncClient/MQTTSDK/*.{h,m}', 'AWSAppSyncClient/MQTTSDK/MQTTSDK/*.{h,m}', 'AWSAppSyncClient/MQTTSDK/SocketRocket/*.{h,m}', 'AWSAppSyncClient/Internal/*.{h,m}'
  s.public_header_files = ['AWSAppSyncClient/AWSAppSync.h', 'AWSAppSyncClient/AWSAppSync-Swift.h', 'AWSAppSyncClient/MQTTSDK/AWSIoTMQTTClient.h','AWSAppSyncClient/MQTTSDK/AWSIoTMQTTTypes.h','AWSAppSyncClient/Internal/AppSyncLogHelper.h']
  s.private_header_files = 'AWSAppSyncClient/MQTTSDK/AWSIoTWebSocketOutputStream.h', 'AWSAppSyncClient/MQTTSDK/MQTTSDK/*.h', 'AWSAppSyncClient/MQTTSDK/SocketRocket/*.h'
end
