set -euo pipefail

framework=$@
pwd=$(pwd)
ios_device_archive_path="$pwd/build/iOS/AWSAppSync"
ios_simulator_archive_path="$pwd/build/Simulator/AWSAppSync"
xcframework_path="$pwd/build/$framework.xcframework"

if [ -d "$xcframework_path" ]
then
  echo "XCFramework exists already, skipping."
  exit 0
fi

# archive for device
xcodebuild archive -workspace AWSAppSyncClient.xcworkspace \
					-scheme $framework \
					-destination "generic/platform=iOS" \
					-archivePath $ios_device_archive_path \
					-quiet \
					SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
					

# archive for simulator
xcodebuild archive -workspace AWSAppSyncClient.xcworkspace \
					-scheme $framework \
					-destination "generic/platform=iOS Simulator" \
					-archivePath $ios_simulator_archive_path \
					-quiet \
					SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# create xcframework
xcodebuild -create-xcframework \
	   -framework "$ios_device_archive_path.xcarchive/Products/Library/Frameworks/$framework.framework" \
	   -debug-symbols "$ios_device_archive_path.xcarchive/dSYMs/$framework.framework.dSYM" \
	   -framework "$ios_simulator_archive_path.xcarchive/Products/Library/Frameworks/$framework.framework" \
	   -debug-symbols "$ios_simulator_archive_path.xcarchive/dSYMs/$framework.framework.dSYM" \
           -output "$xcframework_path"

cd build && zip -q -r AWSAppSync.xcframework.zip  AWSAppSync.xcframework

