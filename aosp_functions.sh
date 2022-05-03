#!/bin/bash

revert_patches_from_previous_run() {
  log_header "${FUNCNAME[0]}"

  if [ -d "${AOSP_BUILD_DIR}" ]; then
    cd "${AOSP_BUILD_DIR}"
    repo forall -vc "git clean -f ; git reset --hard" >/dev/null 2>&1 || true
  fi
}

aosp_tuning() {
    export OVERRIDE_TARGET_FLATTEN_APEX=true
    #TODO
}

env_setup_script() {
  log_header "${FUNCNAME[0]}"
  cd "${AOSP_BUILD_DIR}"

  source build/envsetup.sh
  export LANG=en_US.UTF-8
  export _JAVA_OPTIONS=-XX:-UsePerfData

  if [[ "${MIMICK_GOOGLE_BUILDS}" == "false" ]]; then
    export BUILD_DATETIME=$(cat out/build_date.txt 2>/dev/null || date -u +%s)
    echo "BUILD_DATETIME=$BUILD_DATETIME"
    export BUILD_NUMBER=$(cat out/soong/build_number.txt 2>/dev/null || date -u -d @$BUILD_DATETIME +%Y%m%d%H)
    echo "BUILD_NUMBER=$BUILD_NUMBER"
    export DISPLAY_BUILD_NUMBER=true
    export BUILD_USERNAME=aosp
    export BUILD_HOSTNAME=aosp
  fi

  # use SCHED_BATCH
  chrt -b -p 0 $$
}

aosp_repo_init() {
  log_header "${FUNCNAME[0]}"
  cd "${AOSP_BUILD_DIR}"

  run_hook_if_exists "aosp_repo_init_pre"

  MANIFEST_URL="https://android.googlesource.com/platform/manifest"
  retry repo init --manifest-url "${MANIFEST_URL}" --manifest-branch "${AOSP_TAG}" --depth 1

  run_hook_if_exists "aosp_repo_init_post"
}

aosp_repo_sync() {
  log_header "${FUNCNAME[0]}"
  cd "${AOSP_BUILD_DIR}"

  run_hook_if_exists "aosp_repo_sync_pre"

  for i in {1..10}; do
    log "Running aosp repo sync attempt ${i}/10"
    repo sync -c --no-tags --no-clone-bundle --jobs 32 && break
  done

  run_hook_if_exists "aosp_repo_sync_post"
}

aosp_build() {
  log_header "${FUNCNAME[0]}"
  run_hook_if_exists "aosp_build_pre"
  cd "${AOSP_BUILD_DIR}"

  #TOKEEP?
  insert_vendor_includes

  if [ "${CHROMIUM_BUILD_DISABLED}" == "true" ]; then
    log "Removing TrichromeChrome and TrichromeWebView as chromium build is disabled"
    sed -i '/PRODUCT_PACKAGES += TrichromeChrome/d' "${CORE_VENDOR_MAKEFILE}" || true
    sed -i '/PRODUCT_PACKAGES += TrichromeWebView/d' "${CORE_VENDOR_MAKEFILE}" || true
  fi

  (
    env_setup_script
    if [ "${MIMICK_GOOGLE_BUILDS}" == "true" ]; then
      build_target="release ${DEVICE} eng"
    else
      build_target="release aosp_${DEVICE} eng"
    fi
    
    log "Running choosecombo ${build_target}"

    ccache -M 100G

    choosecombo ${build_target}

    log "Running target-files-package"
    retry m target-files-package

    # Wasn't retrieving our mkbootfs patches since the file already existed!
    if [ ! -f "${RELEASE_TOOLS_DIR}/releasetools/sign_target_files_apks" ]; then
     log "Running m otatools-package"
     m otatools-package
     rm -rf "${RELEASE_TOOLS_DIR}"
     unzip "${AOSP_BUILD_DIR}/out/target/product/${DEVICE}/otatools.zip" -d "${RELEASE_TOOLS_DIR}"
    fi
  )

  run_hook_if_exists "aosp_build_post"
}

# Dirty function to mimick Google builds fingerprint and be able to use Google Apps without having to register our GSF ID online
mimick_google_builds(){
  log_header "${FUNCNAME[0]}"
  BUILD_LOWER=$(echo ${AOSP_BUILD_ID} | tr '[:upper:]' '[:lower:]')

  cd "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/"

  rm -rf "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/${DEVICE}-${BUILD_LOWER}/"
  rm -rf "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/boot.img"
  rm -rf "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/magisk-latest"
  rm -rf "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/magisk-latest.zip"
  rm -rf "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/BOOT_EXTRACT"

  unzip "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/${DEVICE}-${BUILD_LOWER}-factory-*.zip" >/dev/null 2>&1
  unzip "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/${BUILD_LOWER}/${DEVICE}-${BUILD_LOWER}/image-${DEVICE}-${BUILD_LOWER}.zip" boot.img >/dev/null 2>&1

  # Download latest Magisk release
  curl -s https://api.github.com/repos/topjohnwu/Magisk/releases | grep "Magisk-v.*.apk" |grep https|head -n 1| cut -d : -f 2,3|tr -d \" | wget -O magisk-latest.zip -qi -
  # Extract the downloaded APK/zip
  unzip -d magisk-latest magisk-latest.zip >/dev/null 2>&1
  # Make the fakely-librarized magiskboot executable
  chmod +x ./magisk-latest/lib/x86/libmagiskboot.so

  mkdir -p BOOT_EXTRACT
  cd BOOT_EXTRACT

  ../magisk-latest/lib/x86/libmagiskboot.so unpack ../boot.img >/dev/null 2>&1
  mkdir ramdisk
  cd ramdisk
  ../../magisk-latest/lib/x86/libmagiskboot.so cpio ../ramdisk.cpio extract >/dev/null 2>&1

  BUILD_DATETIME=$(cat default.prop | grep -i ro.build.date.utc | cut -d "=" -f 2)
  BUILD_USERNAME=$(cat default.prop | grep -i ro.build.user | cut -d "=" -f 2)
  BUILD_NUMBER=$(cat default.prop | grep -i ro.build.version.incremental | cut -d "=" -f 2)
  BUILD_HOSTNAME=$(cat default.prop | grep -i ro.build.host | cut -d "=" -f 2)

  printf "Values exported:\n BUILD_DATETIME=$BUILD_DATETIME\n BUILD_USERNAME=$BUILD_USERNAME\n BUILD_NUMBER=$BUILD_NUMBER\n BUILD_HOSTNAME=$BUILD_HOSTNAME\n"

  export BUILD_DATETIME
  export BUILD_USERNAME
  export BUILD_NUMBER
  export BUILD_HOSTNAME
  export PRODUCT_MAKEFILE="${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/${DEVICE}.mk"

  cd "${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/"
  cp "aosp_${DEVICE}.mk" "${PRODUCT_MAKEFILE}"

  sed -i "s@PRODUCT_NAME := aosp_${DEVICE}@PRODUCT_NAME := ${DEVICE}@" "${PRODUCT_MAKEFILE}" || true
  sed -i "s@PRODUCT_BRAND := Android@PRODUCT_BRAND := google@" "${PRODUCT_MAKEFILE}" || true
  sed -i "s@aosp_${DEVICE}.mk@${DEVICE}.mk@g" "${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/AndroidProducts.mk" || true
  sed -i "s@aosp_${DEVICE}-userdebug@${DEVICE}-userdebug@g" "${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/AndroidProducts.mk" || true

  sed -i "s/PRODUCT_MODEL := AOSP on ${DEVICE}/PRODUCT_MODEL := ${DEVICE_FRIENDLY}/" "${PRODUCT_MAKEFILE}"
}

#TOKEEP?
insert_vendor_includes() {
  log_header "${FUNCNAME[0]}"

  if ! grep -q "${CORE_VENDOR_MAKEFILE}" "${PRODUCT_MAKEFILE}"; then
    sed -i "\@vendor/google_devices/${DEVICE_FAMILY}/proprietary/device-vendor.mk)@a \$(call inherit-product, ${CORE_VENDOR_MAKEFILE})" "${PRODUCT_MAKEFILE}"
  fi

  if [ -n "${CUSTOM_CONFIG_REPO}" ]; then
    if ! grep -q "${CUSTOM_VENDOR_MAKEFILE}" "${PRODUCT_MAKEFILE}"; then
      sed -i "\@vendor/google_devices/${DEVICE_FAMILY}/proprietary/device-vendor.mk)@a \$(call inherit-product, ${CUSTOM_VENDOR_MAKEFILE})" "${PRODUCT_MAKEFILE}"
    fi
  fi
}

#TODO
release() {
  log_header "${FUNCNAME[0]}"
  run_hook_if_exists "release_pre"
  cd "${AOSP_BUILD_DIR}"

  (
    env_setup_script

    KEY_DIR="${KEYS_DIR}/${DEVICE}"
    OUT="out/release-${DEVICE}-${BUILD_NUMBER}"
    device="${DEVICE}"

    log "Running clear-factory-images-variables.sh"
    source "device/common/clear-factory-images-variables.sh"
    DEVICE="${device}"
    if [ ${MIMICK_GOOGLE_BUILDS} != "true" ]; then
      PREFIX="aosp_"
    fi
    BUILD="${BUILD_NUMBER}"
    PRODUCT="${DEVICE}"
    TARGET_FILES="${DEVICE}-target_files-${BUILD}.zip"
    BOOTLOADER=$(grep -Po "require version-bootloader=\K.+" "vendor/google_devices/${DEVICE}/vendor-board-info.txt" | tr '[:upper:]' '[:lower:]')
    RADIO=$(grep -Po "require version-baseband=\K.+" "vendor/google_devices/${DEVICE}/vendor-board-info.txt" | tr '[:upper:]' '[:lower:]')
    VERSION=$(grep -Po "BUILD_ID=\K.+" "build/core/build_id.mk" | tr '[:upper:]' '[:lower:]')
    log "BOOTLOADER=${BOOTLOADER} RADIO=${RADIO} VERSION=${VERSION} TARGET_FILES=${TARGET_FILES}"

    # make sure output directory exists
    mkdir -p "${OUT}"

    # pick avb mode depending on device and determine key size
    avb_key_size=$(openssl rsa -in "${KEY_DIR}/avb.pem" -text -noout | grep 'Private-Key' | awk -F'[()]' '{print $2}' | awk '{print $1}')
    log "avb_key_size=${avb_key_size}"
    avb_algorithm="SHA256_RSA${avb_key_size}"
    log "avb_algorithm=${avb_algorithm}"
    case "${DEVICE_AVB_MODE}" in
      vbmeta_chained)
        AVB_SWITCHES=(--avb_vbmeta_key "${KEY_DIR}/avb.pem"
                      --avb_vbmeta_algorithm "${avb_algorithm}"
                      --avb_system_key "${KEY_DIR}/avb.pem"
                      --avb_system_algorithm "${avb_algorithm}")
        ;;
      vbmeta_chained_v2)
        AVB_SWITCHES=(--avb_vbmeta_key "${KEY_DIR}/avb.pem"
                      --avb_vbmeta_algorithm "${avb_algorithm}"
                      --avb_system_key "${KEY_DIR}/avb.pem"
                      --avb_system_algorithm "${avb_algorithm}"
                      --avb_vbmeta_system_key "${KEY_DIR}/avb.pem"
                      --avb_vbmeta_system_algorithm "${avb_algorithm}")
        ;;
    esac

    export PATH="${RELEASE_TOOLS_DIR}/bin:${PATH}"
    export PATH="${AOSP_BUILD_DIR}/prebuilts/jdk/jdk9/linux-x86/bin:${PATH}"

    log "Running sign_target_files_apks"
    "${RELEASE_TOOLS_DIR}/bin/sign_target_files_apks" \
      -o -d "${KEY_DIR}" \
      --extra_apks OsuLogin.apk,ServiceConnectivityResources.apk,ServiceWifiResources.apk="$KEY_DIR/releasekey" "${AVB_SWITCHES[@]}" \
      "${AOSP_BUILD_DIR}/out/target/product/${DEVICE}/obj/PACKAGING/target_files_intermediates/${PREFIX}${DEVICE}-target_files-${BUILD_NUMBER}.zip" \
      "${OUT}/${TARGET_FILES}"

    log "Running ota_from_target_files"
    # shellcheck disable=SC2068
    "${RELEASE_TOOLS_DIR}/bin/ota_from_target_files" --block -k "${KEY_DIR}/releasekey" ${DEVICE_EXTRA_OTA[@]} "${OUT}/${TARGET_FILES}" \
      "${OUT}/${DEVICE}-ota_update-${BUILD}.zip"

    log "Running img_from_target_files"
    "${RELEASE_TOOLS_DIR}/bin/img_from_target_files" "${OUT}/${TARGET_FILES}" "${OUT}/${DEVICE}-img-${BUILD}.zip"

    log "Running generate-factory-images"
    cd "${OUT}"
    source "../../device/common/generate-factory-images-common.sh"
    mv "${DEVICE}"-*-factory-*.zip "${DEVICE}-factory-${BUILD_NUMBER}.zip"
  )

  run_hook_if_exists "release_post"
}