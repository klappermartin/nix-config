[[ "${BASH_SOURCE[0]}" == "${0}" ]] || return 0

case "${1:-}" in
  add) shift; cmd_add "$@" ;;
  sync|check) mode=$1; shift; cmd_manifest "$mode" "$@" ;;
  prune) shift; cmd_prune "$@" ;;
  list) shift; cmd_list "$@" ;;
  help|--help|-h) cmd_help; exit 0 ;;
  '') cmd_help; exit 0 ;;
  *) log_err "usage: oss-ref <add|sync|check|prune|list|help>"; exit 2 ;;
esac
