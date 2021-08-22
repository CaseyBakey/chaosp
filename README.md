# Customized Hybrid AOSP (CHAOSP)  

## Introduction  

This project aims to help you build [RattlesnakeOS](https://github.com/RattlesnakeOS), locally, with some optional features than you can add.  

Depending of the used options, the resulting build can range from 'simple' [RattlesnakeOS](https://github.com/RattlesnakeOS) build to a fully featured ROM with [BiTGapps](https://github.com/BiTGApps/BiTGApps) as Google Apps provider, [Bromite](https://github.com/bromite/bromite) as the default browser/webview, and [Magisk](https://github.com/topjohnwu/Magisk) as a root solution, all with your bootloader relocked.  

Regarding this project name, and since we all like having a fully working smartphone with push notifications and so, it's also possible to bake in some patches before building the ROM.  
At the end, you'll get a flashable ROM customized to your need.  


## Features  

* pure AOSP  
* locally built (no proprietary cloud used)  
* signed with your keys (only you can push ROM updates to your phone)  
* bootloader is relocked after first install: no rogue 'fastboot boot/fastboot flash' commands can be issued to your device  
* secure boot aka Android Verified Boot  
* [F-Droid](https://github.com/f-droid) and F-Droid Privileged Extension to allow easy installation of FOSS apps  
* Optional: add [BiTGapps](https://github.com/BiTGApps/BiTGApps) (while still retaining locked bootloader)  
* Optional: add [Magisk](https://github.com/topjohnwu/Magisk) (while still retaining locked bootloader)  
* Optional: add [Bromite](https://github.com/bromite/bromite) as default browser and webview  
* Optional: misc. patches (custom bootanimation, add/delete entries in recovery menu, add new permission toggles and so)  


## Initial setup  

The ROM will be built on your computer/server so, the prerequisites of AOSP has to be met: [Establishing a Build Environment](https://source.android.com/setup/build/initializing)  
Keep in mind that AOSP and Chromium will be built in the process, so the whole build will take many hours.  
I'm personally building this on a (quite powerful) computer (4c/8t Core i7, 32GB RAM, 1 TB SSD NVMe) with Ubuntu 18.04 and the whole thing is compiled under 5 hours (maybe less, can't remember)  


## Building  

There are mandatory and optional options that you can provide to the build.sh script to customize your ROM.  

Note: I wanted long options with clear names. It's a PIA to setup/parse so, for now, even the options that should just have been a toggle without an argument, actually need an argument. You can put whatever you want, but I'm using "true" as a placeholder. 

Here are the mandatory ones:  
* --release <em>release</em>  
  For this one, you have to give "release" as value (I need to check where it's really used, since it's inherited from RattlesnakeOS)  
* --aosp-build <em>RQ3A.210805.001.A1</em>  
  Here, give the desired AOSP build number; You should take a look at [Source code tags and builds](https://source.android.com/setup/start/build-numbers#source-code-tags-and-builds) to know what is the latest release for your device.  
* --aosp-branch <em>android-11.0.0_r40</em>  
  Here, give the related AOSP branch that you find on the above link.  
* --device <em>blueline</em>  
  Here, give the device for which you're building CHAOSP (it has to be an AOSP supported device). The supported devices on August 2021 are: blueline, crosshatch, sargo, bonito, flame, coral, sunfish, bramble and redfin.  
* --chromium-version <em>92.0.4515.134</em>  
  Here, give the desired Chromium version. You can ommit this option, if you opt for the --bromite option that will build the latest stable Chromium version supported by the Bromite project.  

Here are the optional ones:  
* --bromite <em>true</em>  
  This one will build the latest [Bromite](https://github.com/bromite/bromite) patches on top of the Chromium source code. Take a look on the project page to know what features Bromite add.  
* --add-bitgapps <em>true</em>  
  This one adds the [BiTGapps](https://github.com/BiTGApps/BiTGApps) thanks to the [aosp-build project](https://github.com/BiTGApps/aosp-build). You'll be able to use Google Play Services and the related services (Store, GCM, location, etc.).  
* --mimick-google <em>true</em>  
  This one will extract some values from the official release Google images and reuse them during our build, to be able to pass the Play Protect certification check when using the Google Play Services.  
* --bypass-safetynet <em>true</em>  
  This one adds the [Universal SafetyNet Fix](https://github.com/kdrag0n/safetynet-fix) patch. It should allow you to bypass SafetyNET check once your bootloader is relocked.  
* --use-custom-bootanimation <em>true</em>  
  This one changes the AOSP default bootanimation to a cooler one. Give it a try!  
* --add-magisk <em>true</em>  
  This one adds [Magisk](https://github.com/topjohnwu/Magisk) to your build image. Once the build flashed on your device, you'll need to adb install the Magisk Manager.  

For example:  
./build.sh --release release --aosp-build RQ3A.210805.001.A1 --aosp-branch android-11.0.0_r40 --device blueline --chromium-version 92.0.4515.134  

will build AOSP version 11, with the latest security fixes (on August 2021), with Chromium 92.0.4515.134 for the Pixel 3 (blueline) device.  


## Flashing  

Once the build is done you'll find yourself with flashable zip files within $CHAOSP_DIR/out/release-$DEVICE-$BUILD_NUMBER/  
You can now follow the same guide than RattlesnakeOS: [Flashing guide](https://github.com/dan-v/rattlesnakeos-stack/blob/9.0/FLASHING.md)  


## Credits  
* @thestinger for his work on the now deceased CopperheadOS, and newly started [GrapheneOS](https://github.com/GrapheneOS)  
* @dan-v for his work on [RattlesnakeOS](https://github.com/dan-v/rattlesnakeos-stack) from which near the integrity of the build Go template is re-used here  
* @topjohnwu for the only FOSS Android rooting solution: [Magisk](https://github.com/topjohnwu/Magisk)  
* @anestisb for his handy script allowing us to retrieve important missing and non-git commited binary blobs for our devices : [android-prepare-vendor](https://github.com/anestisb/android-prepare-vendor)  
* @PabloCastellano for his handy DTB extracter script: [extract-dtb](https://github.com/PabloCastellano/extract-dtb)  
* [OpenGapps](https://github.com/opengapps) for their [aosp_build](https://github.com/opengapps/aosp_build) project  
* many different people for the useful FOSS marketplace: [F-Droid](https://github.com/f-droid)  
* @TheHitMan7 for his work on [BiTGapps](https://github.com/BiTGApps/BiTGApps)  
* @kdrag0n for his work on [Universal SafetyNet Fix](https://github.com/kdrag0n/safetynet-fix)


