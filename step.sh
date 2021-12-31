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
    BCSYMBOLMAP_PATH=$(pwd)/archives/$NAME/$1/$NAME.xcarchive/BCSymbolMaps/$udid.bcsymbolmap
    if [[ -f "$BCYMBOLMAP_PATH" ]]; then
      SYMBOLS="$SYMBOLS -debug-symbols $BCSYMBOLMAP_PATH "
    fi
  done
  echo $SYMBOLS
}

params=()

# macOS

if [ "$macos" = "yes" ]; then
  archive $WORKSPACE $NAME-macos "generic/platform=macOS" "archives/$NAME/macOS/$NAME"

  params+=(-framework "archives/$NAME/macOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/macOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
fi

# macOS Catalyst

if [ "$macoscatalyst" = "yes" ]; then
  archive $WORKSPACE $NAME-ios "generic/platform=macOS,variant=Mac Catalyst" "archives/$NAME/macOS Catalyst/$NAME"

  params+=(-framework "archives/$NAME/macOS Catalyst/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/macOS Catalyst/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
fi

# iOS

if [ "$ios" = "yes" ]; then
  archive $WORKSPACE $NAME-ios "generic/platform=iOS" "archives/$NAME/iOS/$NAME"
  archive $WORKSPACE $NAME-ios "generic/platform=iOS Simulator" "archives/$NAME/iOS Simulator/$NAME"

  params+=(-framework "archives/$NAME/iOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/iOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
  params+=($(bitcodeSymbols "iOS" "$(pwd)/archives/$NAME/iOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM"))
  params+=(-framework "archives/$NAME/iOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/iOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
fi

# watchOS

if [ "$watchos" = "yes" ]; then
  archive $WORKSPACE $NAME-watchos "generic/platform=watchOS" "archives/$NAME/watchOS/$NAME"
  archive $WORKSPACE $NAME-watchos "generic/platform=watchOS Simulator" "archives/$NAME/watchOS Simulator/$NAME"

  params+=(-framework "archives/$NAME/watchOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/watchOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
  params+=($(bitcodeSymbols "watchOS" "$(pwd)/archives/$NAME/watchOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM"))
  params+=(-framework "archives/$NAME/watchOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/watchOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
fi

# tvOS

if [ "$tvos" = "yes" ]; then
  archive $WORKSPACE $NAME-tvos "generic/platform=tvOS" "archives/$NAME/tvOS/$NAME"
  archive $WORKSPACE $NAME-tvos "generic/platform=tvOS Simulator" "archives/$NAME/tvOS Simulator/$NAME"

  params+=(-framework "archives/$NAME/tvOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/tvOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
  params+=($(bitcodeSymbols "tvOS" "$(pwd)/archives/$NAME/tvOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM"))
  params+=(-framework "archives/$NAME/tvOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework")
  params+=(-debug-symbols "$(pwd)/archives/$NAME/tvOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM")
fi

# xcframework

xcodebuild -create-xcframework "${params[@]}" -output "archives/$NAME.xcframework"

# fix xcframework
find "archives/$NAME.xcframework" -name "*.swiftinterface" -exec sed -i -e "s/${NAME}\.//g" {} \;

# zip

cd archives
zip -r ${output_dir}/$NAME.zip $NAME.xcframework
