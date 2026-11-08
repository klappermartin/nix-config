cmd_list() {
  find "$ROOT" -mindepth 1 -maxdepth 1 -type d -name '*@*' -exec basename {} \; 2>/dev/null | sort
}
