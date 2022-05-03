#!/bin/bash

source ./variables.sh
source ./common_functions.sh
source ./chromium_functions.sh
source ./aosp_functions.sh

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
  #TODO
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

get_device_config
print_build_info
full_run