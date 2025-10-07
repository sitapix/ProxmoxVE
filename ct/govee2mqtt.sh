#!/usr/bin/env bash

source <(curl -fsSL https://raw.githubusercontent.com/sitapix/ProxmoxVE/refs/heads/govee2mqtt-feat/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: sitapix (sitapix)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wez/govee2mqtt

APP="Govee2MQTT"
var_tags="${var_tags:-iot;mqtt;bridge;smart-home}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/govee2mqtt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  msg_info "Stopping ${APP}"
  systemctl stop govee2mqtt
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP}"
  
  if ! check_for_gh_release "govee2mqtt" "wez/govee2mqtt"; then
    msg_ok "${APP} is already up to date"
    exit
  fi
  
  msg_info "New version available: $CHECK_UPDATE_RELEASE"
  
  if ! command -v git >/dev/null 2>&1; then
    $STD apt-get update
    $STD apt-get install -y git
  fi
  
  if ! command -v cargo >/dev/null 2>&1; then
    msg_info "Installing Rust toolchain"
    RUST_TOOLCHAIN="stable" setup_rust
  fi
  
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR" || exit 1
  
  msg_info "Downloading ${APP} source code (${CHECK_UPDATE_RELEASE})"
  fetch_and_deploy_gh_release "govee2mqtt" "wez/govee2mqtt" "source" "$CHECK_UPDATE_RELEASE" "$TEMP_DIR"
  
  msg_info "Building ${APP} (optimized build, this may take a few minutes)"
  
  export CARGO_NET_RETRY=10
  export CARGO_HTTP_TIMEOUT=30
  export CARGO_BUILD_JOBS=1
  
  if ! $STD cargo build --release --bin govee --locked; then
    msg_error "Build failed"
    cd / || exit 1
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  cp target/release/govee /opt/govee2mqtt/target/release/govee
  
  echo "${CHECK_UPDATE_RELEASE#v}" > "$HOME/.govee2mqtt"
  
  chmod +x /opt/govee2mqtt/target/release/govee
  chown govee2mqtt:govee2mqtt /opt/govee2mqtt/target/release/govee
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  systemctl start govee2mqtt
  msg_ok "Started ${APP}"
  
  cd / || exit 1
  rm -rf "$TEMP_DIR"
  
  msg_info "Cleaning up build cache"
  rm -rf ~/.cargo/registry ~/.cargo/git ~/.cargo/.package-cache ~/.rustup
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "Access it using the following URL:"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7474${CL}"
echo -e "\n${INFO}Configuration Required:${CL}"
echo -e "${TAB}Edit ${BGN}/opt/govee2mqtt/config.yml${CL} to configure:"
echo -e "${TAB}• MQTT broker settings (host, username, password)"
echo -e "${TAB}• Govee credentials (email, password, API key)"
echo -e "${TAB}• Enable LAN control in Govee Home app for supported devices"
echo -e "${TAB}Restart service: ${BGN}systemctl restart govee2mqtt${CL}"
