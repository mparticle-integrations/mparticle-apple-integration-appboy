VERSION="$1"
PREFIXED_VERSION="v$1"
NOTES="$2"

# Update version number
#

# Update Carthage release json file
jq --indent 3 '. += {'"\"$VERSION\""': "'"https://github.com/mparticle-integrations/mparticle-apple-integration-appboy/releases/download/$PREFIXED_VERSION/mParticle_Appboy.framework.zip?alt=https://github.com/mparticle-integrations/mparticle-apple-integration-appboy/releases/download/$PREFIXED_VERSION/mParticle_Appboy.xcframework.zip"'"}'
mParticle_Appboy.json > tmp.json
mv tmp.json mParticle_Appboy.json

# Update CocoaPods podspec file
sed -i '' 's/\(^    s.version[^=]*= \).*/\1"'"$VERSION"'"/' mParticle-Appboy.podspec

# Make the release commit in git
#

git add mParticle-Appboy.podspec
git add mParticle_Appboy.json
git add CHANGELOG.md
git commit -m "chore(release): $VERSION [skip ci]

$NOTES"
