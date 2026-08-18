#!/bin/sh
# Xcode Cloud runs this after cloning the repo, before the build starts.
#
# The project pins CURRENT_PROJECT_VERSION by hand, so every archive would
# otherwise carry the same CFBundleVersion and App Store Connect rejects a
# duplicate build number -- the build succeeds but never reaches TestFlight.
# Stamp it with Xcode Cloud's own build number, which increases every run.
set -e

if [ -z "$CI_BUILD_NUMBER" ]; then
	echo "CI_BUILD_NUMBER unset; leaving CURRENT_PROJECT_VERSION alone."
	exit 0
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" \
	GardenHarvest.xcodeproj/project.pbxproj

echo "CURRENT_PROJECT_VERSION set to $CI_BUILD_NUMBER"
