function tth --wraps ssh --description 'ssh + tmux'
  ssh -t $argv 'tmux new -AD -s default'
  # TODO: if you want to use a different shell inside tmux than your
  # login shell, you can do it like so:
  # ssh -t $argv 'SHELL=/usr/bin/fish tmux new -AD -s default'
end
