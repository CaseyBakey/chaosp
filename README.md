# Customized Hybrid AOSP (CHAOSP)  

## Introduction  

This project aims to help you build an AOSP ROM for one of the (Google) devices actually supported by AOSP, targeting Android 9 Pie onwards.  
It's a mainly privacy/security focused ROM (no Google Play Services neither root by default).  
Regarding this project name, and since we all like having a fully working smartphone with push notifications and so, it's also possible to bake in some patches before building the ROM.  
At the end, you'll get a flashable ROM customized to your need.  

## Features  

* pure AOSP  
* locally built (no proprietary cloud is used)  
* signed with your keys (only you can push ROM updates to your phone)  
* bootloader is relocked after first install: no rogue 'fastboot boot/fastboot flash' commands can be issued to your device  
* secure boot aka Android Verified Boot
* Optional: OpenGapps (while still retaining locked bootloader)  
* Optional: Magisk (while still retaining locked bootloader)  
* Optional: misc. patches (custom bootanimation, add/delete entries in recovery menu, and so...)


## Setup

The ROM will be built on your computer/server so, the prerequisites of AOSP has to be met: [Establishing a Build Environment](https://source.android.com/setup/build/initializing)  


## TODO  
* add an option in recovery menu to delete all Magisk-related settings/modules to avoid a lock-out situation (when bootloop occured, etc.)  
* replace Chromium with Bromite as a Browser/WebView  
* add an option to use microG Project instead of proprietary Google Play Services (when using OpenGapps)  

## Credits  
* @thestinger for his work on the now deceased CopperheadOS, and newly started [GrapheneOS](https://github.com/GrapheneOS)  
* @dan-v for his work on [RattlesnakeOS](https://github.com/dan-v/rattlesnakeos-stack) from which the majority of this project is inspired  
* @topjohnwu for the only FOSS Android rooting solution: [Magisk](https://github.com/topjohnwu/Magisk)  
* @anestisb for his handy script allowing us to retrieve important missing and non-git commited binary blobs for our devices : [android-prepare-vendor](https://github.com/anestisb/android-prepare-vendor)  


