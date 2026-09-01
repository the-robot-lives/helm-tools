# bash completion for helm-publish.
#
# Install (either works):
#   1. Copy to ${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions/helm-publish
#      (done by `make install-completions`; auto-loaded by bash-completion v2).
#   2. Source this file from .bashrc.

_helm_publish_config() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.infra-config.yaml" ]]; then
      echo "$dir/.infra-config.yaml"
      return
    fi
    dir="$(dirname "$dir")"
  done
}

_helm_publish_charts() {
  local f
  f="$(_helm_publish_config)"
  [[ -z "$f" ]] && return
  command -v yq >/dev/null 2>&1 || return
  yq '.tiers[].charts[]' "$f" 2>/dev/null
}

_helm-publish() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()

    # Flags whose value is the next word.
    case "$prev" in
        --bump)
            COMPREPLY=($(compgen -W "patch minor major" -- "$cur"))
            return ;;
        --config)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
    esac

    # All flags for helm-publish.
    local opts="--list --pick --all --dry-run --bump --force -y --yes -v --verbose --config -h --help"

    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    else
        # Positional = chart name.
        COMPREPLY=($(compgen -W "$(_helm_publish_charts)" -- "$cur"))
    fi
}

complete -F _helm-publish helm-publish
