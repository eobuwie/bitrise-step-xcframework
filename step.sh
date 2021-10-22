#!/bin/bash
set -ex

WORKSPACE=${workspace}
NAME=${framework_name}

function archive {
  xcodebuild archive \
  -workspace $1.xcworkspace \
  -scheme $2 \
  -destination "$3" \
  -archivePath "$4" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  BITCODE_GENERATION_MODE=bitcode \
  clean
}

function bitcodeSymbols {
  UDIDs=$(dwarfdump --uuid $2 | cut -d ' ' -f2)
  SYMBOLS=""
  for udid in $UDIDs; do
    PATH=$(pwd)/archives/$NAME/$1/$NAME.xcarchive/BCSymbolMaps/$udid.bcsymbolmap
    SYMBOLS="$SYMBOLS -debug-symbols $PATH "
  done
  echo $SYMBOLS
}

# macOS

archive $WORKSPACE $NAME-macos "generic/platform=macOS" "archives/$NAME/macOS/$NAME"
archive $WORKSPACE $NAME-ios "generic/platform=macOS,variant=Mac Catalyst" "archives/$NAME/macOS Catalyst/$NAME"

# iOS

archive $WORKSPACE $NAME-ios "generic/platform=iOS" "archives/$NAME/iOS/$NAME"
archive $WORKSPACE $NAME-ios "generic/platform=iOS Simulator" "archives/$NAME/iOS Simulator/$NAME"

# watchOS

archive $WORKSPACE $NAME-watchos "generic/platform=watchOS" "archives/$NAME/watchOS/$NAME"
archive $WORKSPACE $NAME-watchos "generic/platform=watchOS Simulator" "archives/$NAME/watchOS Simulator/$NAME"

# tvOS

archive $WORKSPACE $NAME-tvos "generic/platform=tvOS" "archives/$NAME/tvOS/$NAME"
archive $WORKSPACE $NAME-tvos "generic/platform=tvOS Simulator" "archives/$NAME/tvOS Simulator/$NAME"

# xcframework

xcodebuild -create-xcframework \
-framework "archives/$NAME/macOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/macOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/macOS Catalyst/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/macOS Catalyst/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/iOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/iOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
$(bitcodeSymbols "iOS" "$(pwd)/archives/$NAME/iOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM") \
-framework "archives/$NAME/iOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/iOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/watchOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/watchOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
$(bitcodeSymbols "watchOS" "$(pwd)/archives/$NAME/watchOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM") \
-framework "archives/$NAME/watchOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/watchOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/tvOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/tvOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
$(bitcodeSymbols "tvOS" "$(pwd)/archives/$NAME/tvOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM") \
-framework "archives/$NAME/tvOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/tvOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-output "archives/$NAME.xcframework"

# fix xcframework
find "archives/$NAME.xcframework" -name "*.swiftinterface" -exec sed -i -e "s/${NAME}\.//g" {} \;

# zip

cd archives
zip -r ${output_dir}/$NAME.zip $NAME.xcframework
