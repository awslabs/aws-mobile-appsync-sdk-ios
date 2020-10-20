#!/bin/bash

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo "Usage: $0 <current_sdk_version> <new_sdk_version>" >&2
  exit 1
fi

echo "Bumping version from $1 to $2"
find . -name 'AWSAppSync.podspec' -print0 | xargs -0 sed -i '' -e "s/$1/$2/g"
find . -name 'Podfile' -print0 | xargs -0 sed -i '' -e "s/$1/$2/g"
find . -name 'Cartfile' -print0 | xargs -0 sed -i '' -e "s/$1/$2/g"
sed -i '' -e "s/$1/$2/g" README.md

echo "SDK dependency updated in podspec, Podfile, and Cartfile."
echo "Review the diff. If it looks correct, run 'pod update', build and test."
echo "Then commit, and create a PR."

