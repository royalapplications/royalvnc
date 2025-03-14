#!/usr/bin/env bash

set -e

echo "Installing Skip using homebrew"
brew install skiptools/skip/skip

echo "Installing Skip Android SDK"
skip android sdk install

echo "All Done"