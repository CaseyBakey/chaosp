#!/usr/bin/env bash

########################################
######## BUILD ARGS ####################
########################################
#RELEASE=$1
#echo "RELEASE=${RELEASE}"
#AOSP_BUILD_ID=$2
#echo "AOSP_BUILD_ID=${AOSP_BUILD_ID}"
#AOSP_TAG=$3
#echo "AOSP_TAG=${AOSP_TAG}"
#CHROMIUM_VERSION=$4
#echo "CHROMIUM_VERSION=${CHROMIUM_VERSION}"
#CHROMIUM_FORCE_BUILD=$5
#echo "CHROMIUM_FORCE_BUILD=${CHROMIUM_FORCE_BUILD}"
#LOCAL_MANIFEST_REVISIONS=$6
#echo "LOCAL_MANIFEST_REVISIONS=${LOCAL_MANIFEST_REVISIONS}"

#### <generated_vars_and_funcs.sh> ####

ARGUMENT_LIST=(
    "device"
    "release"
    "aosp-build"
    "aosp-branch"
    "chromium-version"
    "bromite"
    "mimick-google"
    "add-magisk"
    "add-bitgapps"
    "bypass-safetynet"
    "use-custom-bootanimation"
)


# read arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
    case "$1" in
        --device)
          DEVICE=$2
          shift 2
          ;;
        --release)
            RELEASE=$2
            shift 2
            ;;
        --aosp-build)
            AOSP_BUILD_ID=$2
            shift 2
            ;;
        --aosp-branch)
            AOSP_TAG=$2
            shift 2
            ;;
        --chromium-version)
            CHROMIUM_VERSION=$2
            shift 2
            ;;
        --bromite)
            APPLY_BROMITE_PATCHES="true"
            shift 2
            ;;
        --mimick-google)
            MIMICK_GOOGLE_BUILDS="true"
            shift 2
            ;;
        --add-magisk)
            ADD_MAGISK="true"
            shift 2
            ;;
        --add-bitgapps)
            ADD_BITGAPPS="true"
            shift 2
            ;;
        --bypass-safetynet)
            SAFETYNET_BYPASS="true"
            shift 2
            ;;
        --use-custom-bootanimation)
            USE_CUSTOM_BOOTANIMATION="true"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

if [[ -z "${RELEASE}" || -z "${AOSP_BUILD_ID}" || -z "${AOSP_TAG}" || -z "${DEVICE}" || ( -z "${APPLY_BROMITE_PATCHES}" && -z "${CHROMIUM_VERSION}" ) ]]; then
  echo "--release, --aosp-build, --aosp-branch, --device and (--bromite or --chromium-version) are mandatory options!"
  exit 1
fi

if [[ "${ADD_BITGAPPS}" == "true" && "${MIMICK_GOOGLE_BUILDS}" != "true" ]]; then
  echo "If you want to add gapps, you also need to mimick google builds (--mimick-google true) to avoid Play Protect errors at runtime!"
  exit 1
fi

case "${DEVICE}" in
  blueline)
    DEVICE_FRIENDLY="Pixel 3"
    DEVICE_FAMILY="crosshatch"
    DEVICE_AVB_MODE="vbmeta_chained"
    DEVICE_EXTRA_OTA="--retrofit_dynamic_partitions"
    ;;
  crosshatch)
    DEVICE_FRIENDLY="Pixel 3 XL"
    DEVICE_FAMILY="crosshatch"
    DEVICE_AVB_MODE="vbmeta_chained"
    DEVICE_EXTRA_OTA="--retrofit_dynamic_partitions"
    ;;
  sargo)
    DEVICE_FRIENDLY="Pixel 3a"
    DEVICE_FAMILY="bonito"
    DEVICE_AVB_MODE="vbmeta_chained"
    DEVICE_EXTRA_OTA="--retrofit_dynamic_partitions"
    ;;
  bonito)
    DEVICE_FRIENDLY="Pixel 3a XL"
    DEVICE_FAMILY="bonito"
    DEVICE_AVB_MODE="vbmeta_chained"
    DEVICE_EXTRA_OTA="--retrofit_dynamic_partitions"
    ;;
  flame)
    DEVICE_FRIENDLY="Pixel 4"
    DEVICE_FAMILY="coral"
    DEVICE_AVB_MODE="vbmeta_chained_v2"
    DEVICE_EXTRA_OTA=""
    ;;
  coral)
    DEVICE_FRIENDLY="Pixel 4 XL"
    DEVICE_FAMILY="coral"
    DEVICE_AVB_MODE="vbmeta_chained_v2"
    DEVICE_EXTRA_OTA=""
    ;;
  sunfish)
    DEVICE_FRIENDLY="Pixel 4a"
    DEVICE_FAMILY="sunfish"
    DEVICE_AVB_MODE="vbmeta_chained_v2"
    DEVICE_EXTRA_OTA=""
    ;;
  bramble)
    DEVICE_FRIENDLY="Pixel 4a 5G"
    DEVICE_FAMILY="bramble"
    DEVICE_AVB_MODE="vbmeta_chained_v2"
    DEVICE_EXTRA_OTA=""
    ;;
  redfin)
    DEVICE_FRIENDLY="Pixel 5"
    DEVICE_FAMILY="redfin"
    DEVICE_AVB_MODE="vbmeta_chained_v2"
    DEVICE_EXTRA_OTA=""
    ;;
  *)
    echo "Device not supported!"
    exit 1
    ;;
esac

echo "RELEASE=${RELEASE}"
echo "AOSP_BUILD_ID=${AOSP_BUILD_ID}"
echo "AOSP_TAG=${AOSP_TAG}"
echo "CHROMIUM_VERSION=${CHROMIUM_VERSION}"
echo "CHROMIUM_FORCE_BUILD=${CHROMIUM_FORCE_BUILD}"
echo "DEVICE_FRIENDLY=${DEVICE_FRIENDLY}"
echo "DEVICE_FAMILY=${DEVICE_FAMILY}"
echo "DEVICE_AVB_MODE=${DEVICE_AVB_MODE}"
echo "DEVICE_EXTRA_OTA=${DEVICE_EXTRA_OTA}"

########################################
######## OTHER VARS ####################
########################################
SECONDS=0
ROOT_DIR=$(dirname $(realpath $0))
REVISION_DIR="${ROOT_DIR}/revision"
BINARIES_DIR="${ROOT_DIR}/binaries"
AOSP_BUILD_DIR="${ROOT_DIR}/aosp"
CORE_DIR="${ROOT_DIR}/core"
CUSTOM_DIR="${ROOT_DIR}/custom"
KEYS_DIR="${ROOT_DIR}/keys"
MISC_DIR="${ROOT_DIR}/misc"
RELEASE_TOOLS_DIR="${MISC_DIR}/releasetools"
PRODUCT_MAKEFILE="${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/aosp_${DEVICE}.mk"
CORE_VENDOR_BASEDIR="${AOSP_BUILD_DIR}/vendor/core"
CORE_VENDOR_MAKEFILE="${CORE_VENDOR_BASEDIR}/vendor/config/main.mk"
CUSTOM_VENDOR_BASEDIR="${AOSP_BUILD_DIR}/vendor/custom"
CUSTOM_VENDOR_MAKEFILE="${CUSTOM_VENDOR_BASEDIR}/vendor/config/main.mk"
BROMITE_DIR="${ROOT_DIR}/bromite"

CORE_CONFIG_REPO="https://github.com/RattlesnakeOS/core-config-repo.git"
CUSTOM_CONFIG_REPO="https://github.com/CaseyBakey/example-custom-config-repo.git"
CUSTOM_CONFIG_REPO_BRANCH=chaosp_12

APV_REMOTE=https://github.com/GrapheneOS/
APV_BRANCH=12
APV_REVISION=bde54dfa66e1092893e2c1bfa78385a35588387a

full_run() {
  log_header "${FUNCNAME[0]}"

  echo "CHAOSP Build STARTED"
  
  revert_patches_from_previous_run
  
  setup_env

  if [ "$(ls "${KEYS_DIR}/${DEVICE}" | wc -l)" == '0' ]; then
  	gen_keys
  fi
  
  aosp_repo_init
  aosp_local_repo_additions
  aosp_repo_sync
  if [ "${APPLY_BROMITE_PATCHES}" == "true" ]; then
    get_bromite
  fi
  chromium_build_if_required
  chromium_copy_to_build_tree_if_required
  setup_vendor
  # Mimick Google builds
  if [ "${MIMICK_GOOGLE_BUILDS}" == "true" ]; then
    mimick_google_builds
  fi
  aosp_build
  release
  echo "CHAOSP Build SUCCESS"
}

revert_patches_from_previous_run() {
  log_header "${FUNCNAME[0]}"

  if [ -d "${AOSP_BUILD_DIR}" ]; then
    cd "${AOSP_BUILD_DIR}"
    repo forall -vc "git clean -f ; git reset --hard" >/dev/null 2>&1 || true
  fi
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

  # Already done in core repo config
  #sed -i "s/PRODUCT_MODEL := AOSP on ${DEVICE}/PRODUCT_MODEL := ${DEVICE_FRIENDLY}/" "${PRODUCT_MAKEFILE}"
}

setup_env() {
  log_header "${FUNCNAME[0]}"

  if [ ! -f "${ROOT_DIR}/.aosp_build_deps_done" ]; then
  # install required packages
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y install apt-transport-https ca-certificates python python2.7 python3 gperf jq default-jdk git-core gnupg \
        flex bison build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev \
        x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip liblz4-tool \
        libncurses5 wget parallel rsync python-protobuf python3-protobuf python3-pip libarchive-tools git-lfs bsdtar

    git lfs install
    pip3 install -U protobuf
    retry curl --fail -s https://storage.googleapis.com/git-repo-downloads/repo > /tmp/repo
    chmod +x /tmp/repo
    sudo mv /tmp/repo /usr/local/bin/
    touch "${ROOT_DIR}/.aosp_build_deps_done"
  fi

  # setup git
  git config --get --global user.name || git config --global user.name 'aosp'
  git config --get --global user.email || git config --global user.email 'aosp@localhost'
  git config --global color.ui true

  # # mount /tmp filesystem as tmpfs
  # sudo mount -t tmpfs tmpfs /tmp || true

  # setup base directories
  mkdir -p "${AOSP_BUILD_DIR}"
  mkdir -p "${KEYS_DIR}"
  mkdir -p "${MISC_DIR}"
  mkdir -p "${RELEASE_TOOLS_DIR}"
  mkdir -p "${REVISION_DIR}"
  mkdir -p "${BINARIES_DIR}"

  # get core repo
  rm -rf "${CORE_DIR}"
  retry git clone "${CORE_CONFIG_REPO}" "${CORE_DIR}"
  if [ -n "${CORE_CONFIG_REPO_BRANCH}" ]; then
    pushd "${CORE_DIR}"
    git checkout "${CORE_CONFIG_REPO_BRANCH}"
    popd
  fi

  # get custom repo if specified
  if [ -n "${CUSTOM_CONFIG_REPO}" ]; then
    rm -rf "${CUSTOM_DIR}"
    retry git clone "${CUSTOM_CONFIG_REPO}" "${CUSTOM_DIR}"
    if [ -n "${CUSTOM_CONFIG_REPO_BRANCH}" ]; then
      pushd "${CUSTOM_DIR}"
      git checkout "${CUSTOM_CONFIG_REPO_BRANCH}"
      popd
    fi
  fi

  # mount keys directory as tmpfs
  if [ -z "$(ls -A ${KEYS_DIR})" ]; then
    sudo mount -t tmpfs -o size=20m tmpfs "${KEYS_DIR}" || true
  fi
}

aosp_repo_init() {
  log_header "${FUNCNAME[0]}"
  cd "${AOSP_BUILD_DIR}"

  run_hook_if_exists "aosp_repo_init_pre"

  MANIFEST_URL="https://android.googlesource.com/platform/manifest"
  retry repo init --manifest-url "${MANIFEST_URL}" --manifest-branch "${AOSP_TAG}" --depth 1

  run_hook_if_exists "aosp_repo_init_post"
}

aosp_local_repo_additions() {
  log_header "${FUNCNAME[0]}"
  cd "${AOSP_BUILD_DIR}"

  run_hook_if_exists "aosp_local_repo_additions_pre"

  rm -rf "${AOSP_BUILD_DIR}/.repo/local_manifests"
  mkdir -p "${AOSP_BUILD_DIR}/.repo/local_manifests"
  cp -f "${CORE_DIR}"/local_manifests/*.xml "${AOSP_BUILD_DIR}/.repo/local_manifests"

  if [ "${CHROMIUM_BUILD_DISABLED}" == "true" ]; then
    local_chromium_manifest="${AOSP_BUILD_DIR}/.repo/local_manifests/001-chromium.xml"
    if [ -f "${local_chromium_manifest}" ]; then
      log "Removing ${local_chromium_manifest} as chromium build is disabled"
      rm -f "${local_chromium_manifest}" || true
    fi
  fi

  if [ -n "${CUSTOM_CONFIG_REPO}" ]; then
    cp -f "${CUSTOM_DIR}"/local_manifests/*.xml "${AOSP_BUILD_DIR}/.repo/local_manifests" || true
  fi

  run_hook_if_exists "aosp_local_repo_additions_post"
}

aosp_repo_sync() {
  log_header "${FUNCNAME[0]}"
  cd "${AOSP_BUILD_DIR}"

  run_hook_if_exists "aosp_repo_sync_pre"

  # if [ "$(ls -l "${AOSP_BUILD_DIR}" | wc -l)" -gt 0 ]; then
  #   log "Running git reset and clean as environment appears to already have been synced previously"
  #   repo forall -c 'git reset --hard ; git clean --force -dx'
  # fi

  for i in {1..10}; do
    log "Running aosp repo sync attempt ${i}/10"
    repo sync -c --no-tags --no-clone-bundle --jobs 32 && break
  done

  run_hook_if_exists "aosp_repo_sync_post"
}

setup_vendor() {
  log_header "${FUNCNAME[0]}"
  run_hook_if_exists "setup_vendor_pre"

  # skip if already downloaded
  current_vendor_build_id=""
  vendor_build_id_file="${AOSP_BUILD_DIR}/vendor/google_devices/${DEVICE}/build_id.txt"
  if [ -f "${vendor_build_id_file}" ]; then
    current_vendor_build_id=$(cat "${vendor_build_id_file}")
  fi
  if [ "${current_vendor_build_id}" == "${AOSP_BUILD_ID}" ]; then
    log "Skipping vendor download as ${AOSP_BUILD_ID} already exists at ${vendor_build_id_file}"
    return
  fi

  # get vendor files (with timeout)
  timeout 30m "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/execute-all.sh" --yes --keep --device "${DEVICE}" \
      --buildID "${AOSP_BUILD_ID}" --output "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor"

  # copy vendor files to build tree
  mkdir --parents "${AOSP_BUILD_DIR}/vendor/google_devices" || true
  rm -rf "${AOSP_BUILD_DIR}/vendor/google_devices/${DEVICE}" || true
  cp -rf "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/$(tr '[:upper:]' '[:lower:]' <<< "${AOSP_BUILD_ID}")/vendor/google_devices/${DEVICE}" "${AOSP_BUILD_DIR}/vendor/google_devices"

  # smaller devices need big brother vendor files
  if [ "${DEVICE}" != "${DEVICE_FAMILY}" ]; then
    rm -rf "${AOSP_BUILD_DIR}/vendor/google_devices/${DEVICE_FAMILY}" || true
    cp -rf "${AOSP_BUILD_DIR}/vendor/android-prepare-vendor/${DEVICE}/$(tr '[:upper:]' '[:lower:]' <<< "${AOSP_BUILD_ID}")/vendor/google_devices/${DEVICE_FAMILY}" "${AOSP_BUILD_DIR}/vendor/google_devices"
  fi

  run_hook_if_exists "setup_vendor_post"
}

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

env_setup_script() {
  log_header "${FUNCNAME[0]}"
  cd "${AOSP_BUILD_DIR}"

  source build/envsetup.sh
  export LANG=en_US.UTF-8
  export _JAVA_OPTIONS=-XX:-UsePerfData
  # shellcheck disable=SC2155
  if [[ ! "${MIMICK_GOOGLE_BUILDS}" ]]; then
    export BUILD_DATETIME=$(cat out/build_date.txt 2>/dev/null || date -u +%s)
    echo "BUILD_DATETIME=$BUILD_DATETIME"
  # shellcheck disable=SC2155
    export BUILD_NUMBER=$(cat out/soong/build_number.txt 2>/dev/null || date -u -d @$BUILD_DATETIME +%Y%m%d%H)
    echo "BUILD_NUMBER=$BUILD_NUMBER"
    export DISPLAY_BUILD_NUMBER=true
    export BUILD_USERNAME=aosp
    export BUILD_HOSTNAME=aosp
  fi
  export OVERRIDE_TARGET_FLATTEN_APEX=true
  chrt -b -p 0 $$
}

aosp_build() {
  log_header "${FUNCNAME[0]}"
  run_hook_if_exists "aosp_build_pre"
  cd "${AOSP_BUILD_DIR}"

  insert_vendor_includes

  if [ "${CHROMIUM_BUILD_DISABLED}" == "true" ]; then
    log "Removing TrichromeChrome and TrichromeWebView as chromium build is disabled"
    sed -i '/PRODUCT_PACKAGES += TrichromeChrome/d' "${CORE_VENDOR_MAKEFILE}" || true
    sed -i '/PRODUCT_PACKAGES += TrichromeWebView/d' "${CORE_VENDOR_MAKEFILE}" || true
  fi

  (
    env_setup_script
    if [ "${MIMICK_GOOGLE_BUILDS}" == "true" ]; then
      build_target="release ${DEVICE} user"
    else
      build_target="release aosp_${DEVICE} user"
    fi
    
    log "Running choosecombo ${build_target}"

    ccache -M 100G

    choosecombo ${build_target}

    log "Running target-files-package"
    retry m target-files-package

    # Wasn't retrieving our mkbootfs patches since the file already existed!
    #if [ ! -f "${RELEASE_TOOLS_DIR}/releasetools/sign_target_files_apks" ]; then
      log "Running m otatools-package"
      m otatools-package
      rm -rf "${RELEASE_TOOLS_DIR}"
      unzip "${AOSP_BUILD_DIR}/out/target/product/${DEVICE}/otatools.zip" -d "${RELEASE_TOOLS_DIR}"
    #fi
  )

  run_hook_if_exists "aosp_build_post"
}

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
    # shellcheck disable=SC2034
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

gen_keys() {
  log_header "${FUNCNAME[0]}"

  # download make_key and avbtool as aosp tree isn't downloaded yet
  make_key="${MISC_DIR}/make_key"
  retry curl --fail -s "https://android.googlesource.com/platform/development/+/refs/tags/${AOSP_TAG}/tools/make_key?format=TEXT" | base64 --decode > "${make_key}"
  chmod +x "${make_key}"
  avb_tool="${MISC_DIR}/avbtool"
  retry curl --fail -s "https://android.googlesource.com/platform/external/avb/+/refs/tags/${AOSP_TAG}/avbtool.py?format=TEXT" | base64 --decode > "${avb_tool}"
  chmod +x "${avb_tool}"

  # generate releasekey,platform,shared,media,networkstack keys
  mkdir -p "${KEYS_DIR}/${DEVICE}"
  cd "${KEYS_DIR}/${DEVICE}"
  for key in {releasekey,platform,shared,media,networkstack} ; do
    # make_key exits with unsuccessful code 1 instead of 0, need ! to negate
    ! "${make_key}" "${key}" "/CN=CHAOSP"
  done

  # generate avb key
  openssl genrsa -out "${KEYS_DIR}/${DEVICE}/avb.pem" 4096
  "${avb_tool}" extract_public_key --key "${KEYS_DIR}/${DEVICE}/avb.pem" --output "${KEYS_DIR}/${DEVICE}/avb_pkmd.bin"

  # generate chromium.keystore
  cd "${KEYS_DIR}/${DEVICE}"
  keytool -genkey -v -keystore chromium.keystore -storetype pkcs12 -alias chromium -keyalg RSA -keysize 4096 \
        -sigalg SHA512withRSA -validity 10000 -dname "cn=CHAOSP" -storepass chromium
}

run_hook_if_exists() {
  local hook_name="${1}"
  local core_hook_file="${CORE_DIR}/hooks/${hook_name}.sh"
  local custom_hook_file="${CUSTOM_DIR}/hooks/${hook_name}.sh"

  if [ -n "${core_hook_file}" ]; then
    if [ -f "${core_hook_file}" ]; then
      log "Running ${core_hook_file}"
      # shellcheck disable=SC1090
      (source "${core_hook_file}")
    fi
  fi

  if [ -n "${custom_hook_file}" ]; then
    if [ -f "${custom_hook_file}" ]; then
      log "Running ${custom_hook_file}"
      # shellcheck disable=SC1090
      (source "${custom_hook_file}")
    fi
  fi
}

log_header() {
  echo "=================================="
  echo "$(date "+%Y-%m-%d %H:%M:%S"): Running $1"
  echo "=================================="
}

log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S"): $1"
}

retry() {
  set +e
  local max_attempts=${ATTEMPTS-3}
  local timeout=${TIMEOUT-1}
  local attempt=0
  local exitCode=0

  while [[ $attempt < $max_attempts ]]
  do
    "$@"
    exitCode=$?

    if [[ $exitCode == 0 ]]
    then
      break
    fi

    log "Failure! Retrying ($*) in $timeout.."
    sleep "${timeout}"
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout * 2 ))
  done

  if [[ $exitCode != 0 ]]
  then
    log "Failed too many times! ($*)"
  fi

  set -e

  return $exitCode
}

########################################
######## CHROMIUM ######################
########################################

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

build_chromium() {
  log_header "${FUNCNAME[0]}"
  CHROMIUM_REVISION="$1"
  CHROMIUM_DEFAULT_VERSION=$(echo "${CHROMIUM_REVISION}" | awk -F"." '{ printf "%s%03d52\n",$3,$4}')

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
    fetch --nohooks android || gclient sync -D --with_branch_heads --with_tags --jobs 32 -RDf --nohooks && cd src && git fetch && cd -
    cd src

    # checkout specific revision
    git checkout "${CHROMIUM_REVISION}" -f

    # install dependencies
    log "Installing chromium build dependencies"

    if [ ! -f "${ROOT_DIR}/.chromium_build_deps_done" ]; then
      echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
      sudo ./build/install-build-deps-android.sh
      touch "${ROOT_DIR}/.chromium_build_deps_done"
    fi

    # run gclient sync (runhooks will run as part of this)
    log "Running gclient sync (this takes a while)"
    for i in {1..5}; do
      yes | gclient sync --with_branch_heads --jobs 32 -RDf && break
    done

    # cleanup any files in tree not part of this revision
    git clean -dff

    # reset any modifications
    git checkout -- .

    # apply required patches
    if [ -n "$(ls -A ${AOSP_BUILD_DIR}/external/chromium/patches)" ]; then
      git am --whitespace=nowarn ${AOSP_BUILD_DIR}/external/chromium/patches/*.patch
    fi

    # generate configuration
    KEYSTORE="${KEYS_DIR}/${DEVICE}/chromium.keystore"
    trichrome_certdigest=$(keytool -export-cert -alias chromium -keystore "${KEYSTORE}" -storepass chromium | sha256sum | awk '{print $1}')
    log "trichrome_certdigest=${trichrome_certdigest}"
    mkdir -p out/Default
    cp -f "${AOSP_BUILD_DIR}/external/chromium/args.gn" out/Default/args.gn
    cat <<EOF >> out/Default/args.gn

android_default_version_name = "${CHROMIUM_REVISION}"
android_default_version_code = "${CHROMIUM_DEFAULT_VERSION}"
trichrome_certdigest = "${trichrome_certdigest}"
chrome_public_manifest_package = "org.chromium.chrome"
system_webview_package_name = "org.chromium.webview"
trichrome_library_package = "org.chromium.trichromelibrary"
${BROMITE_ARGS}
EOF
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

set -e

full_run
