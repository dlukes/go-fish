function fish_prompt --description 'Write out the prompt'
  test $SSH_TTY
    and printf (set_color red)$USER(set_color brwhite)'@'(set_color yellow)(prompt_hostname)' '
  test $USER = 'root'
    and echo -n (set_color red)'# '

  if set -q VIRTUAL_ENV
    set venv (basename $VIRTUAL_ENV)
    set venv (set_color yellow)':'(string replace -r -- '-.*?-py' '…' $venv)
  else
    set venv ''
  end

  echo -n (set_color cyan)(prompt_pwd)$venv \
    (set_color red)'❯'(set_color yellow)'❯'(set_color green)'❯ '(set_color normal)
end
