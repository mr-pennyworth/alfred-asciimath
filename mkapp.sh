#!/usr/bin/env bash


if [ -e "/Applications/Xcode_11.7.app" ]; then
    sudo xcode-select -switch /Applications/Xcode_11.7.app
fi

xcodebuild \
  -project 'AsciiMath Renderer.xcodeproj' \
  -configuration Release \
  -scheme 'AsciiMath Renderer' \
  -derivedDataPath DerivedData \
  build

cp -r 'DerivedData/Build/Products/Release/AsciiMath Renderer.app' ./
