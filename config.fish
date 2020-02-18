set -l path \
  ~/.local/bin \
  /usr/local/Cellar/{coreutils,gnu-tar,grep,gawk,gnu-sed,findutils}/**/gnubin
for p in $path[-1..1]
  if not contains $p $PATH
    set PATH $p $PATH
  end
end

# python
set -x VIRTUAL_ENV_DISABLE_PROMPT 1

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
