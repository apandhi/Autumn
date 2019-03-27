#!/bin/bash
DEST=~/Applications/Autumn.app
set -ex
osascript -e 'quit app "Autumn"'
xcodebuild clean build
trash $DEST || true
mv build/Release/Autumn.app ~/Applications
open $DEST
