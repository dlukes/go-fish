# color theme: sorin, originally a zsh prompt theme from
# https://github.com/sorin-ionescu/prezto
set fish_color_autosuggestion 969896
set fish_color_cancel -r
set fish_color_command b294bb
set fish_color_comment f0c674
set fish_color_cwd green
set fish_color_cwd_root red
set fish_color_end b294bb
set fish_color_error cc6666
set fish_color_escape 00a6b2
set fish_color_history_current --bold
set fish_color_host normal
set fish_color_host_remote yellow
set fish_color_match --background=brblue
set fish_color_normal normal
set fish_color_operator 00a6b2
set fish_color_param 81a2be
set fish_color_quote b5bd68
set fish_color_redirection 8abeb7
set fish_color_search_match 'bryellow --background=brblack'
set fish_color_selection 'white --bold --background=brblack'
set fish_color_status red
set fish_color_user brgreen
set fish_color_valid_path --underline
set fish_pager_color_completion normal
set fish_pager_color_description 'B3A06D yellow'
set fish_pager_color_prefix 'white --bold --underline'
set fish_pager_color_progress 'brwhite --background=cyan'

# path
set -l path \
  ~/.local/bin \
  /usr/local/Cellar/{coreutils,gnu-tar,grep,gawk,gnu-sed,findutils}/**/gnubin
for p in $path[-1..1]
  if not contains $p $PATH
    set PATH $p $PATH
  end
end

# pager
set --export PAGER less

# python
set --export VIRTUAL_ENV_DISABLE_PROMPT 1

# preexec hook to update database of frecently visited directories/files
if type -q fasd
  function update_fasd_db --on-event fish_preexec
    fasd --proc (fasd --sanitize $argv) &>/dev/null
  end
end

# fzf
source /usr/local/share/fzf/shell/key-bindings.fish
fzf_key_bindings
if type -q fd
  set -gx FZF_CTRL_T_COMMAND 'fd --type f --hidden --follow --exclude .git'
end
if type -q bat
  set -gx FZF_CTRL_T_OPTS '--multi --preview "bat --style numbers,changes --color=always --decorations=always {} | head -500"'
end

# git
set -g __fish_git_prompt_showcolorhints
set -g __fish_git_prompt_use_informative_chars
# indicate we're in sync with upstream by just being silent
set -g __fish_git_prompt_char_upstream_equal ''

# the following provides full git info but can be quite slow:
# set -g __fish_git_prompt_show_informative_status
# this is a subset which is faster:
set -g __fish_git_prompt_showdirtystate
set -g __fish_git_prompt_showuntrackedfiles
set -g __fish_git_prompt_showupstream
set -g __fish_git_prompt_showstashstate

# TODO: set paths to ssh keys to pre-load on first login
set -l ssh_keys ~/.ssh/id_rsa
if type -q ssh-agent
  set -l ssh_agent_env /tmp/ssh-agent.env.(id -u)

  if not set -q SSH_AUTH_SOCK
    test -r $ssh_agent_env && source $ssh_agent_env

    if not ps -U $LOGNAME -o pid,ucomm | grep -q -- "$SSH_AGENT_PID ssh-agent"
      # use the -t switch (e.g. -t 10m) to add a timeout on the auth
      eval (ssh-agent -c | sed '/^echo /d' | tee $ssh_agent_env)
    end
  end

  if ssh-add -l 2>&1 | grep -q 'The agent has no identities'
    for ssh_key in $ssh_keys
      if test -r $ssh_key
        ssh-add $ssh_key 2>/dev/null
      end
    end
  end
end

# press <Ctrl+X> to expand glob in word under cursor
bind \cx expand_glob
