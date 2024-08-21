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
