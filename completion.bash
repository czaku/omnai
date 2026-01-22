# ai-runner bash completion
# Source this file: source ~/dev/ai-runner/completion.bash

_ai-runner() {
  local cur prev words cword
  _init_completion || return

  local options="--help --version --verbose --engine --model --timeout --file --interactive --list --list-engines --test --info"
  local engines="claude opencode ollama aider"
  local models_claude="haiku sonnet opus"
  local models_ollama="llama3.2 llama3.1 mistral codellama deepseek-coder"

  case "$prev" in
    --engine|-e)
      COMPREPLY=($(compgen -W "$engines" -- "$cur"))
      return
      ;;
    --model|-m)
      case "${words[cword-2]}" in
        --engine|-e|claude)
          COMPREPLY=($(compgen -W "$models_claude" -- "$cur"))
          ;;
        ollama)
          COMPREPLY=($(compgen -W "$models_ollama" -- "$cur"))
          ;;
      esac
      return
      ;;
    --timeout|-t)
      return
      ;;
    --file)
      _filedir
      return
      ;;
  esac

  if [[ "$cur" == -* ]]; then
    COMPREPLY=($(compgen -W "$options" -- "$cur"))
  fi
}

complete -F _ai-runner ./ai-runner.sh
complete -F _ai-runner ai-runner
