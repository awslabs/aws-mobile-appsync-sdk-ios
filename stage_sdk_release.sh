if [ -z $1 ] || [ -z $2 ]; then
    echo "Usage: ./$0 [current_sdk_version] [new_sdk_version]"
    exit 1
fi

export LC_CTYPE=C LANG=C
echo "Bumping version from $1 to $2"
find . -name 'AWSAppSync.podspec' -print0 | xargs -0 sed -i '' -e "s/$1/$2/g"
find . -path '*AWSAppSyncClient/*.plist' -print0 | xargs -0 sed -i '' -e "s/$1/$2/g"
find . -path '*AWSAppSyncClient/AWSAppSyncHTTPNetworkTransport.swift' -print0 | xargs -0 sed -i '' -e "s/$1/$2/g"

echo "SDK version replaced in podspec, info.plist, network transport.\n\n"

echo "Adding git commit and tag..."
git add -u && git commit -m "Release SDK version $2"
git tag -a "$2" -m "$2"
