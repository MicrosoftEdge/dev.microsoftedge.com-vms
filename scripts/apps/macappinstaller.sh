#!/bin/bash

Echo Installing homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap caskroom/cask
brew tap homebrew/core

Echo Installing programs
# Packer for Mac
brew install packer
# Parallels Desktop 11 for Mac
brew cask install parallels-desktop