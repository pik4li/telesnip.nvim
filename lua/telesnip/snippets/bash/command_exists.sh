# ─< Check if the given command exists silently >─────────────────────────────────────────
command_exists() {
  command -v "$@" >/dev/null 2>&1
}
