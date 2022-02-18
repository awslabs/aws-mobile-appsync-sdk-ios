pwd=$(pwd)
ios_device_archive_path="$(pwd)/xcframeworks/output/iOS/AWSAppSync"
ios_simulator_archive_path="$(pwd)/xcframeworks/output/Simulator/AWSAppSync"
xcframework_path="$(pwd)/xcframeworks/output/XCF"

# archive for device
#xcodebuild archive -workspace AWSAppSyncClient.xcworkspace -scheme AWSAppSync -destination "generic/platform=iOS" -archivePath $ios_device_archive_path SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# archive for simulator
#xcodebuild archive -workspace AWSAppSyncClient.xcworkspace -scheme AWSAppSync -destination "generic/platform=iOS Simulator" -archivePath $ios_simulator_archive_path SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# create xcframework

xcodebuild -create-xcframework \
	   -framework "$ios_device_archive_path.xcarchive/Products/Library/Frameworks/AWSAppSync.framework" \
	   -debug-symbols "$ios_device_archive_path.xcarchive/dSYMs/AWSAppSync.framework.dSYM" \
	   -framework "$ios_simulator_archive_path.xcarchive/Products/Library/Frameworks/AWSAppSync.framework" \
	   -debug-symbols "$ios_simulator_archive_path.xcarchive/dSYMs/AWSAppSync.framework.dSYM" \
       -output "$xcframework_path/AWSAppSync.xcframework"

