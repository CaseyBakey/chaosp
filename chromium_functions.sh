#!/bin/bash

chromium_build_if_required() {
  log_header "${FUNCNAME[0]}"

  if [ "${CHROMIUM_BUILD_DISABLED}" == "true" ]; then
    log "Chromium build is disabled"
    return
  fi
  
  if [ -e "${REVISION_DIR}/chromium" ]; then
    current=$(cat ${REVISION_DIR}/chromium)
  fi

  log "Chromium current: ${current}"

  log "Chromium requested: ${CHROMIUM_VERSION}"
  if [ "${CHROMIUM_VERSION}" == "${current}" ] && [ "${CHROMIUM_FORCE_BUILD}" != "true" ]; then
    log "Chromium requested (${CHROMIUM_VERSION}) matches current (${current})"
  else
    log "Building chromium ${CHROMIUM_VERSION}"
    build_chromium "${CHROMIUM_VERSION}"
  fi

}

get_bromite() {
  log_header "${FUNCNAME[0]}"
  rm -rf "${BROMITE_DIR}"
  git clone https://github.com/bromite/bromite.git "${BROMITE_DIR}"

  rm -rf "${CHROMIUM_BUILD_DIR}/src/.git/rebase-apply/"

  CHROMIUM_VERSION=$(cat "${BROMITE_DIR}/build/RELEASE")
  BROMITE_ARGS=$(cat "${BROMITE_DIR}/build/bromite.gn_args")

  echo "Will build Chromium/Bromite ${CHROMIUM_VERSION}"
}

# get_vanadium() {
#     #TODO
# }

build_chromium() {
  log_header "${FUNCNAME[0]}"
  CHROMIUM_REVISION="$1"
  CHROMIUM_DEFAULT_VERSION=$(echo "${CHROMIUM_REVISION}" | awk -F"." '{ printf "%s%03d00\n",$3,$4}')

  (
    # depot tools setup
    if [ ! -d "${MISC_DIR}/depot_tools" ]; then
      retry git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${MISC_DIR}/depot_tools"
    fi
    cd "${MISC_DIR}/depot_tools"
    git pull origin main
    export PATH="${PATH}:${MISC_DIR}/depot_tools"

    # fetch chromium
    CHROMIUM_BUILD_DIR="${ROOT_DIR}/chromium"
    mkdir -p "${CHROMIUM_BUILD_DIR}"
    cd "${CHROMIUM_BUILD_DIR}"
    fetch --nohooks android || gclient sync -D --with_branch_heads --with_tags --jobs 32 -RDf --nohooks
    cd src

    # install dependencies
    log "Installing chromium build dependencies"
    sudo ./build/install-build-deps-android.sh

    # download chromium source code and dependencies
    git fetch --tags
    git checkout $VERSION
    gclient sync -D --with_branch_heads --with_tags --jobs 32
    third_party/android_deps/fetch_all.py --ignore-vulnerabilities

    # generate configuration
    KEYSTORE="${KEYS_DIR}/${DEVICE}/chromium.keystore"
    trichrome_certdigest=$(keytool -export-cert -alias chromium -keystore "${KEYSTORE}" -storepass chromium | sha256sum | awk '{print $1}')
    log "trichrome_certdigest=${trichrome_certdigest}"
    mkdir -p out/Default

    #TODO
    git am --whitespace=nowarn ${VANADIUM_DIR}/patches/*.patch
    cp ${VANADIUM_DIR}/args.gn out/Default/args.gn

    gn gen out/Default

    run_hook_if_exists "build_chromium_pre"

    log "Building trichrome"
    autoninja -C out/Default/ trichrome_webview_64_32_apk trichrome_chrome_64_32_apk trichrome_library_64_32_apk

    log "Signing trichrome"
    APKSIGNER="${CHROMIUM_BUILD_DIR}/src/third_party/android_sdk/public/build-tools/31.0.0/apksigner"
    cd out/Default/apks
    rm -rf release
    mkdir release
    cd release
    for app in TrichromeChrome TrichromeLibrary TrichromeWebView; do
      "${APKSIGNER}" sign --ks "${KEYSTORE}" --ks-pass pass:chromium --ks-key-alias chromium --in "../${app}6432.apk" --out "${app}.apk"
    done

    log "Copying trichrome apks"
    #outside of AOSP dir
    cp "TrichromeLibrary.apk" "${BINARIES_DIR}/TrichromeLibrary.apk"
    cp "TrichromeWebView.apk" "${BINARIES_DIR}/TrichromeWebView.apk"
    cp "TrichromeChrome.apk" "${BINARIES_DIR}/TrichromeChrome.apk"

    echo "${CHROMIUM_REVISION}" > "${REVISION_DIR}/chromium"

    run_hook_if_exists "build_chromium_post"
  )
}

chromium_copy_to_build_tree_if_required() {
  log_header "${FUNCNAME[0]}"

  if [ "${CHROMIUM_BUILD_DISABLED}" == "true" ]; then
    log "Chromium build is disabled"
    return
  fi

  # add latest built chromium to external/chromium in AOSP dir, to be included during the build
  mkdir -p "${AOSP_BUILD_DIR}/external/chromium/prebuilt/arm64/"
  cp "${BINARIES_DIR}/TrichromeLibrary.apk" "${AOSP_BUILD_DIR}/external/chromium/prebuilt/arm64/"
  cp "${BINARIES_DIR}/TrichromeWebView.apk" "${AOSP_BUILD_DIR}/external/chromium/prebuilt/arm64/"
  cp "${BINARIES_DIR}/TrichromeChrome.apk" "${AOSP_BUILD_DIR}/external/chromium/prebuilt/arm64/"
}