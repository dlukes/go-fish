#!/bin/sh

# check that we're not running as root
if [ $( id -u ) -eq 0 ]; then
  >&2 echo 'This script should be run as a regular user, it will request sudo privileges where appropriate.'
  exit 1
fi

# check for commands which might not be present
cmds='curl git dpkg apt-add-repository apt-get mandb unzip'
for cmd in $cmds; do
  if ! command -v $cmd >/dev/null; then
    >&2 echo "This script needs the command '$cmd' to run but it wasn't found."
    abort=1
  fi
done
if [ -n "$abort" ]; then
  >&2 echo 'Some required commands are missing, please install them first.'
  exit 1
fi

# exit immediately if an error is encountered
set -e
# trace the execution of the script to pinpoint problem in case of
# failure
set -x

export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
prefix='/usr/local'
mandir="$prefix/share/man/man1"
bindir="$prefix/bin"
fish_conf_dir="$HOME/.config/fish"
sudo mkdir -p "$mandir" "$bindir"

fetch_and_install_deb() {
  cmdname="$1"
  repo="$2"
  archive_regex="$3"
  if ! command -v "$cmdname" >/dev/null || [ -n "$GOFISH_FORCE" ]; then
    release_link=https://github.com$(
      curl -sL "https://github.com/$repo/releases" |
        grep -oPm1 '/[^"]+/'"$archive_regex"
    )
    curl -sLO "$release_link"
    sudo dpkg --force-overwrite -i $( basename "$release_link" )
  fi
}

#-----------------------------------------------------------------------
# Clone fish config
#-----------------------------------------------------------------------

if [ -d "$fish_conf_dir" ]; then
  disabled="$fish_conf_dir:disabled:$(date +%s)"
  set +x
  >&2 echo -n "
========================================================================

Moving existing fish configuration directory $fish_conf_dir to $disabled

========================================================================
"
  set -x
  mv "$fish_conf_dir" "$disabled"
fi
mkdir -p "$fish_conf_dir"
cd "$fish_conf_dir"
git clone https://github.com/dlukes/go-fish .

workdir=$( mktemp -d )
cd "$workdir"

#-----------------------------------------------------------------------
# Add fish PPA and install it:
#-----------------------------------------------------------------------

if ! command -v fish >/dev/null || [ -n "$GOFISH_FORCE" ]; then
  sudo apt-add-repository -y ppa:fish-shell/release-3
  sudo apt-get update
  sudo apt-get install -o Dpkg::Options::=--force-overwrite -y fish
fi

#-----------------------------------------------------------------------
# Install fzf (for fuzzy-searching all the things™):
#-----------------------------------------------------------------------

if ! command -v fzf >/dev/null || [ -n "$GOFISH_FORCE" ]; then
  fzf_release_link=https://github.com$(
    curl -sL https://github.com/junegunn/fzf-bin/releases |
      grep -oPm1 '/[^"]+/fzf-.*?-linux_amd64.tgz'
  )
  curl -sLO "$fzf_release_link"
  tar xzf $( basename "$fzf_release_link" )
  sudo mv fzf "$bindir"

  # additional resources are only in the source release, so it has to be
  # fetched separately
  fzf_source_release_link=https://github.com$(
    curl -sL https://github.com/junegunn/fzf/releases |
      grep -oPm1 '/[^"]+\.tar\.gz'
  )
  curl -sLO "$fzf_source_release_link"
  tar xzf $( basename "$fzf_source_release_link" )
  sudo mv fzf-*/man/man1/fzf.1 "$mandir"
  fzf_share="$prefix/share/fzf"
  sudo rm -rf "$fzf_share"
  sudo mkdir -p "$fzf_share"
  sudo mv fzf-*/shell "$fzf_share"

  sudo mandb
fi

#-----------------------------------------------------------------------
# Install fasd (for quick cd based on frecency of history entries)
#-----------------------------------------------------------------------

if ! command -v fasd >/dev/null || [ -n "$GOFISH_FORCE" ]; then
  fasd_release_link=https://github.com$(
    curl -sL https://github.com/clvv/fasd/releases |
      grep -oPm1 '/[^"]+\.tar\.gz'
  )
  curl -sLO "$fasd_release_link"
  tar xzf $( basename "$fasd_release_link" )
  sudo mv fasd-*/fasd.1 "$mandir"
  sudo mv fasd-*/fasd "$bindir"

  sudo mandb
fi

#-----------------------------------------------------------------------
# Install exa (a modern replacement for ls, with git support & more):
#-----------------------------------------------------------------------

if ! command -v exa >/dev/null || [ -n "$GOFISH_FORCE" ]; then
  exa_release_link=https://github.com$(
    curl -sL https://github.com/ogham/exa/releases |
      grep -oPm1 '/[^"]+/exa-linux-x86_64-.*?\.zip'
  )
  curl -sLO "$exa_release_link"
  unzip $( basename "$exa_release_link" )
  sudo mv exa-linux-x86_64 "$bindir/exa"

  # additional resources are only in the source release, so it has to be
  # fetched separately
  exa_source_release_link=https://github.com$(
    curl -sL https://github.com/ogham/exa/releases |
      grep -oPm1 '/[^"]+\.tar\.gz'
  )
  curl -sLO "$exa_source_release_link"
  tar xzf $( basename "$exa_source_release_link" )
  sudo mv exa-*/contrib/man/exa.1 "$mandir"
  mv exa-*/contrib/completions.fish "$fish_conf_dir/completions/exa.fish"
fi

#-----------------------------------------------------------------------
# Install bat (a cat(1) clone with wings):
#-----------------------------------------------------------------------

fetch_and_install_deb bat sharkdp/bat 'bat_.*?amd64.deb'

#-----------------------------------------------------------------------
# Install rg (a faster grep clone with better defaults):
#-----------------------------------------------------------------------

fetch_and_install_deb rg BurntSushi/ripgrep 'ripgrep_.*?_amd64.deb'

#-----------------------------------------------------------------------
# Install fd (a faster & simpler find clone with better defaults):
#-----------------------------------------------------------------------

fetch_and_install_deb fd sharkdp/fd 'fd_.*?_amd64.deb'

set +x
>&2 echo -n "
========================================================================

All done. Temporary working directory was:

$workdir

All downloaded and extracted files are there, if you'd like to check
something.

Invoke the fish command to try the fish shell out and see if you like
it. Check out the README for tips on what's available and configured:

https://github.com/dlukes/go-fish

And the fish shell website for a tutorial and extensive documentation:

https://fishshell.com/

Have fun with the Friendly Interactive SHell!
"
