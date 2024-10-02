# check_root
# Check if the user is root and set sudo variable if necessary
check_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    if command_exists sudo; then
      echo_binfo "User is not root. Using sudo for privileged operations."
      _sudo="sudo"
    else
      echo_error "No sudo found and you're not root! Can't install packages."
      return 1
    fi
  else
    echo_binfo "Root access confirmed."
    _sudo=""
  fi
}

---
# command_exists
# ─< Check if the given command exists silently >─────────────────────────────────────────
command_exists() {
  command -v "$@" >/dev/null 2>&1
}

---
# get_ip
# ─< get the current ip as a 1 line >─────────────────────────────────────────────────────
get_ip() {
  command ip a | command grep 'inet ' | command grep -v '127.0.0.1' | command awk '{print $2}' | command cut -d/ -f1 | head -n 1
}

---
# echo_essentials
# ─< Helper functions >─────────────────────────────────────────────────────────────────
echo_error() { printf "\033[0;1;31mError: \033[0;31m\t%s\033[0m\n" "$*"; }
echo_binfo() { printf "\033[0;1;34mINFO: \033[0;34m\t%s\033[0m\n" "$*"; }
echo_info() { printf "\033[0;1;35mInfo: \033[0;35m%s\033[0m\n" "$*"; }

---
# silentexec
# ─< Silent execution >─────────────────────────────────────────────────────────────────
silentexec() {
  "$@" >/dev/null 2>&1
}
