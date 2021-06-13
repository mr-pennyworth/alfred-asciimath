#!/bin/bash

xattr -d com.apple.quarantine 'AsciiMath Renderer.app'
sed -i '' 's/firstrun.sh/asciimath.sh/g' ./info.plist
./asciimath.sh
