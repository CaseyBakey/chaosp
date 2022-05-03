#!/bin/bash
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

get_device_config() {
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
    barbet)
        DEVICE_FRIENDLY="Pixel 5a"
        DEVICE_FAMILY="barbet"
        DEVICE_AVB_MODE="vbmeta_chained_v2"
        DEVICE_EXTRA_OTA=""
        ;;
    *)
        echo "Device not supported!"
        exit 1
        ;;
    esac
}

print_build_info() {
    echo "RELEASE=${RELEASE}"
    echo "AOSP_BUILD_ID=${AOSP_BUILD_ID}"
    echo "AOSP_TAG=${AOSP_TAG}"
    echo "CHROMIUM_VERSION=${CHROMIUM_VERSION}"
    echo "CHROMIUM_FORCE_BUILD=${CHROMIUM_FORCE_BUILD}"
    echo "DEVICE_FRIENDLY=${DEVICE_FRIENDLY}"
    echo "DEVICE_FAMILY=${DEVICE_FAMILY}"
    echo "DEVICE_AVB_MODE=${DEVICE_AVB_MODE}"
    echo "DEVICE_EXTRA_OTA=${DEVICE_EXTRA_OTA}"
}

# read arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)

eval set --"${opts}"

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
        --use-hardened-malloc)
            USE_HARDENED_MALLOC="true"
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