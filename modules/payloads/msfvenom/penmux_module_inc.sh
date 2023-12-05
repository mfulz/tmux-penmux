#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

_PENMUX_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# source "$_PENMUX_INC_CURRENT_DIR/shared.sh"

_load() {
  return
}

_unload() {
  return
}

_run() {
  local pane_id="$1"
  local no_confirm="$(penmux_module_get_option "$_MODULE_FILE" "NoConfirm" "$pane_id")"
  local payload="$(penmux_module_get_option "$_MODULE_FILE" "Payload" "$pane_id")"
  local arch="$(penmux_module_get_option "$_MODULE_FILE" "Arch" "$pane_id")"
  local platform="$(penmux_module_get_option "$_MODULE_FILE" "Platform" "$pane_id")"
  local format="$(penmux_module_get_option "$_MODULE_FILE" "Format" "$pane_id")"
  local encoder="$(penmux_module_get_option "$_MODULE_FILE" "Encoder" "$pane_id")"
  local sub_path="$(penmux_module_get_option "$_MODULE_FILE" "SubPath" "$pane_id")"
  local out_file="$(tmux command-prompt -p "Output filename: " -I "shell.$format" "display-message -p '%%'")"
  local base_dir
  local cmd="msfvenom LHOST=###LocalHost### LPORT=###LocalPort###"
  cmd="$(penmux_module_expand_options_string "$_MODULE_FILE" "$cmd" "$pane_id")"

  base_dir="$(penmux_module_expand_options_string "$_MODULE_FILE" "###HttpRootDir###" "$pane_id")"
  if [[ -z "$base_dir" ]]; then
    base_dir="$(penmux_module_expand_options_string "$_MODULE_FILE" "###SessionDir###" "$pane_id")"
  fi
  base_dir="$(penmux_module_expand_options_string "$_MODULE_FILE" "$base_dir/$sub_path" "$pane_id")"

  if [[ -n "$base_dir" ]]; then
    base_dir="$(penmux_expand_tmux_format_path "$pane_id" "$base_dir")"
  fi

  if [[ -n "$base_dir" ]]; then
    if [[ ! -d "$base_dir" ]]; then
      mkdir -p "$base_dir" || return
    fi
  fi

  out_file="$base_dir/$out_file"

  [[ -n "$payload" ]] && cmd="$cmd -p '$payload'"
  [[ -n "$arch" ]] && cmd="$cmd -a '$arch'"
  [[ -n "$platform" ]] && cmd="$cmd --platform '$platform'"
  [[ -n "$format" ]] && cmd="$cmd -f '$format'"
  [[ -n "$encoder" ]] && cmd="$cmd -d '$encoder'"
  [[ -n "$out_file" ]] && cmd="$cmd -o '$out_file'"

  if [[ "$no_confirm" == "true" ]]; then
    tmux send-keys "$cmd" Enter
  else
    tmux send-keys "$cmd"
  fi
}

_cmd() {
  return
}

_optionsnotify() {
  return
}

_optionvalues() {
  local pane_id="$1"
  local opt="$2"
  local cache_dir="$(penmux_module_get_option "$_MODULE_FILE" "CacheDir" "$pane_id")"
  cache_dir="$(penmux_module_expand_options_string "$_MODULE_FILE" "$cache_dir" "$pane_id")"
  cache_dir="$(penmux_expand_tmux_format_path "$pane_id" "$cache_dir")"
  local cache_file
  local vals_plain
  local start
  local get_vals_cmd="msfvenom -l $(echo "$opt" | tr '[:upper:]' '[:lower:]')s"

  [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir" >/dev/null 2>&1

  [[ -d "$cache_dir" ]] && cache_file="$cache_dir/$opt"

  if [[ -n "$cache_file" && -e "$cache_file" ]]; then
    cat "$cache_file"
    return
  fi

  [[ -n "$cache_file" ]] && touch "$cache_file"

  vals_plain="$($get_vals_cmd)"

  while IFS= read -r l; do
    tl="$(echo "$l" | awk '{$1=$1;print}')"
    [[ -z "$tl" ]] && continue

    if [[ -z "$start" ]]; then
      if [[ "$tl" == "----"* ]]; then
        start="1"
      fi
      continue
    fi

    local val="$(echo "$tl" | cut -d' ' -f1 | awk '{$1=$1;print}')"
    if [[ "$opt" == "Encoder" ]]; then
      local desc="$(echo "$tl" | cut -d' ' -f3- | awk '{$1=$1;print}')"
    else
      local desc="$(echo "$tl" | cut -d' ' -f2- | awk '{$1=$1;print}')"
    fi

    echo "$val###$desc"
    [[ -e "$cache_file" ]] && echo "$val###$desc" >> "$cache_file"
  done<<<"$vals_plain"

  return
}

_consumes() {
  return
}

_hook() {
  local pane_id="$1"
  local hook="$2"
  local hook_option="$3"

  case "$hook" in
    "PreModuleLoad")
      ;;
    "PostModuleLoad")
      ;;
    "PreModuleUnload")
      ;;
    "PostModuleUnload")
      ;;
    *)
      echo >&2 "Unknown hook name: '$hook'"
      ;;
  esac

  return
}

_apiver() {
  # do not change this without implementing the
  # required changes
  echo "1.0.0"
}
