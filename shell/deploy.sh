pod lib lint
git add -A && git commit -m "Release $1"
git tag $1
git push --tags
pod trunk push PayTheory.podspec