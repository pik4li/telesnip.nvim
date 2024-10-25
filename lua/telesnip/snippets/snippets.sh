# posix - check_root
# ─< Check if the user is root and set sudo variable if necessary >───────────────────────
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
# bash - echo_essentials
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
# posix - echo_essentials
# ─< ANSI color codes >───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
LIGHT_GREEN='\033[0;92m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo_error() {
  printf "${BOLD}${RED}ERROR: ${NC}${RED}%s${NC}\n" "$1" >&2
}

echo_info() {
  printf "${BOLD}${CYAN}INFO: ${NC}${CYAN}%s${NC}\n" "$1"
}

echo_warning() {
  printf "${BOLD}${YELLOW}WARNING: ${NC}${YELLOW}%s${NC}\n" "$1"
}

echo_note() {
  printf "${BOLD}${LIGHT_GREEN}NOTE: ${NC}${LIGHT_GREEN}%s${NC}\n" "$1"
}

---
# posix - get_packager
# ─< Distribution detection and installation >────────────────────────────────────────
get_packager() {
  if [ -e /etc/os-release ]; then
    echo_info "Detecting distribution..."
    . /etc/os-release

    # ─< Convert $ID and $ID_LIKE to lowercase >──────────────────────────────────────────────
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

---
# posix - logging essentials
# ─< ANSI color codes >───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
LIGHT_GREEN='\033[0;92m'
BOLD='\033[1m'
NC='\033[0m'

# ─< Initialize storage variables >───────────────────────────────────────────────────────
_STORED_ERRORS=""
_STORED_WARNINGS=""
_STORED_INFOS=""
_STORED_NOTES=""

# ─< echo functions that store and display messages >────────────────────────────
echo_error() {
  local message="${RED}$1${NC}\n"
  printf "$message" >&2
  _STORED_ERRORS="${_STORED_ERRORS}${message}"
}

echo_warning() {
  local message="${YELLOW}$1${NC}\n"
  printf "$message"
  _STORED_WARNINGS="${_STORED_WARNINGS}${message}"
}

echo_info() {
  local message="${CYAN}$1${NC}\n"
  printf "$message"
  _STORED_INFOS="${_STORED_INFOS}${message}"
}

echo_note() {
  local message="${LIGHT_GREEN}$1${NC}\n"
  printf "$message"
  _STORED_NOTES="${_STORED_NOTES}${message}"
}

# ─< Improved display function that only shows categories with content >──────────────────
display_stored_messages() {
  local has_messages=0

  # ─< First check if we have any messages at all >─────────────────────────────────────────
  if [ -z "$_STORED_ERRORS" ] && [ -z "$_STORED_WARNINGS" ] && [ -z "$_STORED_INFOS" ] && [ -z "$_STORED_NOTES" ]; then
    return 0
  fi

  # ─< Now display each non-empty category with proper spacing >────────────────────────────
  if [ -n "$_STORED_ERRORS" ]; then
    printf "\n${BOLD}${RED}=== Errors ===${NC}\n"
    printf "$_STORED_ERRORS"
    has_messages=1
  fi

  if [ -n "$_STORED_WARNINGS" ]; then
    [ "$has_messages" -eq 1 ] && printf "\n"
    printf "${BOLD}${YELLOW}=== Warnings ===${NC}\n"
    printf "$_STORED_WARNINGS"
    has_messages=1
  fi

  if [ -n "$_STORED_INFOS" ]; then
    [ "$has_messages" -eq 1 ] && printf "\n"
    printf "${BOLD}${CYAN}=== Info ===${NC}\n"
    printf "$_STORED_INFOS"
    has_messages=1
  fi

  if [ -n "$_STORED_NOTES" ]; then
    [ "$has_messages" -eq 1 ] && printf "\n"
    printf "${BOLD}${LIGHT_GREEN}=== Notes ===${NC}\n"
    printf "$_STORED_NOTES"
  fi
}
