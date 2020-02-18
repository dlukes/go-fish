function fish_user_key_bindings
  set fzf /usr/local/share/fzf/shell/key-bindings.fish
  test -r $fzf
    and source $fzf
    and fzf_key_bindings
end
