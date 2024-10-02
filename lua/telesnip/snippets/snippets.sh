# check_root
# Check if the user is root and set sudo variable if necessary
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
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

---
# get_packager
# ─< Distribution detection and installation >────────────────────────────────────────
get_packager() {
  if [ -e /etc/os-release ]; then
    echo_info "Detecting distribution..."
    # Use '.' instead of 'source' for POSIX compatibility
    . /etc/os-release

    # Convert $ID and $ID_LIKE to lowercase
    ID=$(printf "%s" "$ID" | tr '[:upper:]' '[:lower:]')
    ID_LIKE=$(printf "%s" "$ID_LIKE" | tr '[:upper:]' '[:lower:]')

    case "$ID" in
      ubuntu | pop) inst_ubuntu ;;
      debian) inst_debian ;;
      fedora) inst_fedora ;;
      alpine) inst_alpine ;;
      arch | manjaro | garuda | endeavour) inst_arch ;;
      opensuse*) inst_opensuse ;;
      *)
        # Use standard [ ] syntax for string matching
        if [ "${ID_LIKE#*debian}" != "$ID_LIKE" ]; then
          inst_debian
        elif [ "${ID_LIKE#*ubuntu}" != "$ID_LIKE" ]; then
          inst_ubuntu
        elif [ "${ID_LIKE#*arch}" != "$ID_LIKE" ]; then
          inst_arch
        elif [ "${ID_LIKE#*fedora}" != "$ID_LIKE" ]; then
          inst_fedora
        elif [ "${ID_LIKE#*suse}" != "$ID_LIKE" ]; then
          inst_opensuse
        else
          echo_error "Unsupported distribution: $ID"
          exit 1
        fi
      ;;
    esac
  else
    echo_error "Unable to detect distribution. /etc/os-release not found."
    exit 1
  fi
}
