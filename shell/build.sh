set -e
rm -r out
rm -r build
mkdir out
mkdir out/Payload
xcodebuild -workspace Example/PayTheory.xcworkspace -scheme PayTheoryExample -destination generic/platform=iOS build-for-testing -derivedDataPath build
cp -r build/Build/Products/Debug-iphoneos/PayTheory\ Example.app out/Payload
cp -r out/Payload/PayTheory\ Example.app/PlugIns/PayTheory_Tests.xctest out/
cd out
zip -r Payload Payload
mv Payload.zip PayTheoryExample.ipa
zip -r PayTheory_Tests.xctest.zip PayTheory_Tests.xctest
rm -r Payload PayTheory_Tests.xctest
cd ..