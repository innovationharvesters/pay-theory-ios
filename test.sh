set -e
xcodebuild test -workspace ./Example/PayTheory.xcworkspace -scheme PayTheory-Example -destination 'platform=iOS Simulator,name=iPhone 8,OS=14.5'
slather coverage --binary-basename PayTheory -x --scheme PayTheory-Example --workspace ./Example/PayTheory.xcworkspace ./Example/PayTheory.xcodeproj
curl -Ls https://coverage.codacy.com/get.sh > get.sh && chmod +x get.sh
bash get.sh report -r cobertura.xml
