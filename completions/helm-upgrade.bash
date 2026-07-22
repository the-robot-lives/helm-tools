# bash completion for helm-upgrade.
#
# Install (either works):
#   1. Copy to ${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions/helm-upgrade
#      (done by `make install-completions`; auto-loaded by bash-completion v2).
#   2. Source this file from .bashrc.

_helm_upgrade_config() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.infra-config.yaml" ]]; then
      echo "$dir/.infra-config.yaml"
      return
    fi
    dir="$(dirname "$dir")"
  done
}

_helm_upgrade_charts() {
  local f
  f="$(_helm_upgrade_config)"
  [[ -z "$f" ]] && return
  command -v yq >/dev/null 2>&1 || return
  yq '.tiers[].charts[]' "$f" 2>/dev/null
}

_helm_upgrade_namespaces() {
  local f
  f="$(_helm_upgrade_config)"
  [[ -z "$f" ]] && return
  command -v yq >/dev/null 2>&1 || return
  yq '.namespace_overrides[]' "$f" 2>/dev/null | sort -u
}

_helm_upgrade_tiers() {
  local f
  f="$(_helm_upgrade_config)"
  [[ -z "$f" ]] && return
  command -v yq >/dev/null 2>&1 || return
  yq '.tiers[].tier' "$f" 2>/dev/null
}

_helm-upgrade() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()

    # Flags whose value is the next word.
    case "$prev" in
        -n|--namespace)
            COMPREPLY=($(compgen -W "$(_helm_upgrade_namespaces)" -- "$cur"))
            return ;;
        --env)
            COMPREPLY=($(compgen -W "dev stage prod" -- "$cur"))
            return ;;
        --preview-tool)
            COMPREPLY=($(compgen -W "code kdiff3 opendiff meld terminal" -- "$cur"))
            return ;;
        --include|--exclude)
            COMPREPLY=($(compgen -W "$(_helm_upgrade_charts)" -- "$cur"))
            return ;;
        --tiers)
            COMPREPLY=($(compgen -W "$(_helm_upgrade_tiers)" -- "$cur"))
            return ;;
        --config)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
    esac

    # All flags for helm-upgrade.
    local opts="-n --namespace --env --stage --prod --dev --include --exclude --tiers -i --interactive --preview --preview-tool --config --force --force-conflicts --dry-run --headless -h --help"

    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    else
        # Positional = chart/release name.
        COMPREPLY=($(compgen -W "$(_helm_upgrade_charts)" -- "$cur"))
    fi
}

complete -F _helm-upgrade helm-upgrade
