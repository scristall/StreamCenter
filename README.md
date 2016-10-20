This is a fork of Tim Jarratt's fork of StreamCenter by Olivier Boucher.

Building on Tim's work, this aims to simply maintain StreamCenter for AppleTV for my personal use.

# StreamCenter

StreamCenter is a tvOS project that aims at providing various video feeds to the AppleTV.  
  
**NOTE:** The version in the App Store currently DOES NOT work with Twitch. If you want to use
StreamCenter as of today, you'll need to compile it from source and install it yourself using Xcode.

# Supported platforms
* Twitch

# Running the Project locally (for development)

### Things you need:
* XCode 8+
* carthage v0.16+ 0.39+ ([brew update && brew install carthage](https://github.com/Carthage/Carthage))
* [A Twitch ClientID](https://www.twitch.tv/kraken/oauth2/clients/new)
* [An Apple developer account](https://developer.apple.com)

### Installing Dependencies
* carthage bootstrap --platform tvOS
* carthage update --platform tvOS

### Running tests
* Run xcode
* Select StreamCenter target
* Hit <kbd>cmd</kbd>+u

# Screenshots
![Imgur](http://i.imgur.com/mTZv9Iu.jpg)
![Imgur](http://i.imgur.com/MzOIAyz.jpg)
![Imgur](http://i.imgur.com/IhRWcT2.jpg)

# Contributing
* Many thanks to Olivier Boucher and Brendan Kirchner for creating the project.
* Huge thanks to @waterskier2007 for the support.  
* If anyone wishes to contribute, just email us for info.
* We're looking for contributors to integrate other platforms
