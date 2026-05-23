# Restore (unfreeze) S3 Glacier/Deep Archive objects
# Usage:
#   unfreeze s3://bucket/key [--days N] [--tier Standard|Bulk|Expedited]
#   unfreeze --status s3://bucket/key
#   unfreeze --help

unfreeze() {
  local bucket="" key="" uri="" days="25" tier="Standard" region="" status_only=0 dry_run=0
  local opt

  local _err; _err(){ print -P "%F{red}error:%f $*"; }
  local _info; _info(){ print -P "%F{cyan}info:%f  $*"; }
  local _ok; _ok(){ print -P "%F{green}$*%f"; }

  while [[ $# -gt 0 ]]; do
    opt="$1"
    case "$opt" in
      s3://*) uri="$1"; shift ;;
      --bucket) bucket="$2"; shift 2 ;;
      --key) key="$2"; shift 2 ;;
      --days|-d) days="$2"; shift 2 ;;
      --tier|-t) tier="$2"; shift 2 ;;
      --region|-r) region="$2"; shift 2 ;;
      --status) status_only=1; shift ;;
      --dry-run) dry_run=1; shift ;;
      --help|-h)
        cat <<'EOF'
unfreeze - restore an S3 object from Glacier/Deep Archive.

Examples:
  unfreeze s3://my-bucket/path/file.fastq.gz
  unfreeze --status s3://my-bucket/path/file.fastq.gz

Options:
  --days N        Days restored copy is available (default: 25)
  --tier TIER     Standard | Bulk | Expedited (default: Standard)
  --region R      AWS region (optional)
  --status        Only check restore status
  --dry-run       Show command without executing
EOF
        return 0 ;;
      *) _err "unknown option: $opt"; return 2 ;;
    esac
  done

  if [[ -n "$uri" ]]; then
    bucket="${uri#s3://}"; bucket="${bucket%%/*}"
    key="${uri#s3://$bucket/}"
    if [[ "$key" == "$bucket" ]]; then key=""; fi
  fi

  if [[ -z "$bucket" || -z "$key" ]]; then
    _err "must provide s3://bucket/key or both --bucket and --key"
    return 2
  fi

  case "$tier" in
    Standard|Bulk|Expedited) ;;
    *) _err "--tier must be Standard|Bulk|Expedited (got: $tier)"; return 2 ;;
  esac

  local _head_args=(s3api head-object --bucket "$bucket" --key "$key" --query 'Restore' --output text)
  [[ -n "$region" ]] && _head_args+=(--region "$region")

  if (( status_only )); then
    _info "checking restore status for s3://$bucket/$key"
    aws "${_head_args[@]}"
    return $?
  fi

  local restore_req
  restore_req=$(printf '{"Days":%s,"GlacierJobParameters":{"Tier":"%s"}}' "$days" "$tier")
  local _cmd=(s3api restore-object --bucket "$bucket" --key "$key" --restore-request "$restore_req")
  [[ -n "$region" ]] && _cmd+=(--region "$region")

  _info "requesting restore for s3://$bucket/$key"
  _info "days: $days | tier: $tier${region:+ | region: $region}"

  if (( dry_run )); then
    print -r -- "aws ${_cmd[*]}"
    return 0
  fi

  aws "${_cmd[@]}" || return $?
  _ok "restore requested."
  _info "tip: run 'unfreeze --status s3://$bucket/$key' to check progress."
}
