#!/usr/bin/env bash
# Build & Push: <namespace>/qwen3-tts:gpu-<version>
set -euo pipefail

log_i(){ printf '[INFO] %s\n' "$1" >&2; }
log_w(){ printf '[WARN] %s\n' "$1" >&2; }
log_e(){ printf '[ERROR] %s\n' "$1" >&2; }

export DOCKER_BUILDKIT="${DOCKER_BUILDKIT:-1}"

DEFAULT_ANSWER=""
IMG_VERSION="${IMG_VERSION:-0.0.1}"
GIT_REPO="https://github.com/groxaxo/Qwen3-TTS-Openai-Fastapi.git"

usage(){
  cat >&2 <<EOF
Usage: $(basename "$0") [--default-answer y|n] [--version X.X.X] [--help]

Options:
  -d, --default-answer [y|n]   Überschreiben ohne Rückfrage.
  -v, --version X.X.X          Image Version (default: $IMG_VERSION)
  -h, --help                   Diese Hilfe.
EOF
}

parse_args(){
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--default-answer)
        [[ $# -ge 2 ]] || { log_e "Option $1 erfordert [y|n]"; exit 2; }
        DEFAULT_ANSWER="$2"; shift 2;;
      --default-answer=*)
        DEFAULT_ANSWER="${1#*=}"; shift;;
      -v|--version)
        [[ $# -ge 2 ]] || { log_e "Option $1 erfordert Version"; exit 2; }
        IMG_VERSION="$2"; shift 2;;
      --version=*)
        IMG_VERSION="${1#*=}"; shift;;
      -h|--help) usage; exit 0;;
      *) log_w "Ignoriere unbekannte Option: $1"; shift;;
    esac
  done
  if [[ -n "$DEFAULT_ANSWER" ]]; then
    case "$DEFAULT_ANSWER" in
      y|Y) DEFAULT_ANSWER="y";;
      n|N) DEFAULT_ANSWER="n";;
      *) log_e "--default-answer erwartet 'y' oder 'n'"; exit 2;;
    esac
  fi
}

need_env(){
  local n="$1"
  eval "val=\${$n:-}"
  [[ -n "$val" ]] || { log_e "$n ist nicht gesetzt!"; exit 1; }
}

ns(){
  if [[ -n "${DOCKERHUB_ORG:-}" ]]; then echo "$DOCKERHUB_ORG"; else echo "$DOCKERHUB_USERNAME"; fi
}

dockerhub_login(){
  log_i "Login bei Docker Hub…"
  echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin >/dev/null
  log_i "Login ok."
}

confirm_overwrite_if_exists(){
  local ref="$1"
  log_i "Prüfe, ob ${ref} bereits existiert…"
  if docker manifest inspect "$ref" >/dev/null 2>&1; then
    log_w "Tag existiert bereits: $ref"
    if [[ -n "$DEFAULT_ANSWER" ]]; then
      [[ "$DEFAULT_ANSWER" == "y" ]] && { log_i "Überschreibe ohne Rückfrage."; return; }
      log_i "Kein Überschreiben (--default-answer n). Abbruch."; exit 0
    fi
    read -r -p "Vorhandenes Image überschreiben? (y/N): " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { log_i "Abgebrochen."; exit 0; }
  else
    log_i "Tag nicht vorhanden. Baue neu."
  fi
}

main(){
  parse_args "$@"

  need_env DOCKERHUB_USERNAME
  need_env DOCKERHUB_TOKEN

  local REPO="qwen3-tts"
  local TAG="gpu-${IMG_VERSION}"
  local TAG_LATEST="gpu-latest"

  local NS; NS="$(ns)"
  local REF="${NS}/${REPO}:${TAG}"
  local REF_LATEST="${NS}/${REPO}:${TAG_LATEST}"

  log_i "Repository:   ${NS}/${REPO}"
  log_i "Tag:          ${TAG}"
  log_i "Git Repo:     ${GIT_REPO}"

  dockerhub_login
  confirm_overwrite_if_exists "$REF"

  local TMPDIR
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT

  log_i "Clone ${GIT_REPO} nach ${TMPDIR}…"
  git clone --depth 1 "$GIT_REPO" "$TMPDIR"

  log_i "Baue Image $REF … (das kann dauern)"
  docker build \
    -f "$TMPDIR/Dockerfile" \
    -t "$REF" \
    "$TMPDIR"

  log_i "Push $REF …"
  docker push "$REF"

  log_i "Tag und push $REF_LATEST …"
  docker tag "$REF" "$REF_LATEST"
  docker push "$REF_LATEST"

  log_i "Fertig: $REF + $REF_LATEST"
}

main "$@"