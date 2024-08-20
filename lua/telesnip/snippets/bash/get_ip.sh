# ─< get the current ip as a 1 line >─────────────────────────────────────────────────────
get_ip() {
  command ip a | command grep 'inet ' | command grep -v '127.0.0.1' | command awk '{print $2}' | command cut -d/ -f1 | head -n 1
}
