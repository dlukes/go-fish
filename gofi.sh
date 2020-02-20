#!/bin/sh

#=======================================================================
# PRELIMINARIES
#=======================================================================

#-----------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------

# exit immediately if an error is encountered
set -e

export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

# where to put programs not installed from .deb packages
prefix=/usr/local
mandir="$prefix/share/man/man1"
bindir="$prefix/bin"

fish_conf_dir="$HOME/.config/fish"
fonts_confd=/etc/fonts/conf.d
fontconfig_overrides="$fonts_confd/00-overrides.conf"

#-----------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------

width="$( seq 1 72 )"
log() {
  local msg="$1"
  local color="$2"
  local sep="$3"
  if [ -n "$color" ]; then
    reset='\e[0m'
  fi
  if [ -n "$sep" ]; then
    sep=$( printf "$sep%.s" $width )
    before="$sep\n\n"
    after="\n\n$sep"
  fi
  >&2 printf "$color$before$msg$after$reset\n"
}

info() {
  local msg="$1"
  local sep="$2"
  log "$msg" '\e[32m' "$sep"
}

warning() {
  local msg="$1"
  local sep="$2"
  log "$msg" '\e[33m' "$sep"
}

error() {
  local msg="$1"
  local sep="$2"
  log "$msg" '\e[31m' "$sep"
}

# Fetch installation archive if cmd is not available, else exit 2.
maybe_fetch_archive() {
  local cmd="$1"
  local repo="$2"
  local archive_regex="$3"
  if ! command -v "$cmd" >/dev/null || [ -n "$GOFISH_FORCE" ]; then
    release_link=https://github.com$(
      curl -sL "https://github.com/$repo/releases" |
        grep -oPm1 '/[^"]+/'"$archive_regex"
    )
    curl -sLO "$release_link"
    basename "$release_link"
  else
    exit 2
  fi
}

maybe_install_deb() {
  local deb=$( maybe_fetch_archive "$@" ) &&
    sudo dpkg --force-overwrite -i "$deb"
}

#-----------------------------------------------------------------------
# Check that we're not running as root
#-----------------------------------------------------------------------

if [ $( id -u ) -eq 0 ]; then
  error "\
This script should be run as a regular user, it will request sudo
privileges where appropriate.\
"
  exit 1
fi

#-----------------------------------------------------------------------
# Check for required commands which might not be present
#-----------------------------------------------------------------------

cmds='curl git dpkg apt-add-repository apt-get mandb unzip'
for cmd in $cmds; do
  if ! command -v $cmd >/dev/null; then
    error "This script needs the command '$cmd' to run but it wasn't found."
    abort=1
  fi
done
if [ -n "$abort" ]; then
  error 'Some required commands are missing, please install them first.'
  exit 1
fi

#=======================================================================
# INSTALLATION
#=======================================================================

# trace the execution of the script to pinpoint problem in case of
# failure
set -x

sudo mkdir -p "$mandir" "$bindir"

#-----------------------------------------------------------------------
# Clone fish config
#-----------------------------------------------------------------------

if [ -d "$fish_conf_dir" ]; then
  disabled="$fish_conf_dir:disabled:$(date +%s)"
  set +x
  warning "\
Moving existing fish configuration directory:

$fish_conf_dir

to:

$disabled\
" =
  set -x
  mv "$fish_conf_dir" "$disabled"
fi
mkdir -p "$fish_conf_dir"
cd "$fish_conf_dir"
git clone https://github.com/dlukes/go-fish .

#-----------------------------------------------------------------------
# Add fish PPA and install it:
#-----------------------------------------------------------------------

if ! command -v fish >/dev/null || [ -n "$GOFISH_FORCE" ]; then
  sudo apt-add-repository -y ppa:fish-shell/release-3
  sudo apt-get update
  sudo apt-get install -o Dpkg::Options::=--force-overwrite -y fish
fi

#-----------------------------------------------------------------------
# Perform all custom downloads in a temporary working directory
#-----------------------------------------------------------------------

workdir=$( mktemp -d )
cd "$workdir"

set +x
info "\
Temporary working directory is:

$workdir

All downloaded and extracted files will be placed there, so that's where
you should check if anything goes wrong.\
" =
set -x

#-----------------------------------------------------------------------
# Install fzf (for fuzzy-searching all the things™):
#-----------------------------------------------------------------------

# additional resources are only in the source release, so it has to be
# fetched separately and *first*, because once the fzf binary is
# available, the command -v check in maybe_fetch_archive will succeed
# and the conditional block will be skipped
fzf_source_archive=$( maybe_fetch_archive fzf junegunn/fzf '.*?\.tar\.gz' ) && {
  tar xzf "$fzf_source_archive"
  sudo mv fzf-*/man/man1/fzf.1 "$mandir"
  fzf_share="$prefix/share/fzf"
  sudo rm -rf "$fzf_share"
  sudo mkdir -p "$fzf_share"
  sudo mv fzf-*/shell "$fzf_share"
  update_man_db=1
}

fzf_binary_archive=$( maybe_fetch_archive fzf junegunn/fzf-bin 'fzf-.*?-linux_amd64.tgz' ) && {
  tar xzf "$fzf_binary_archive"
  sudo mv fzf "$bindir"
}

#-----------------------------------------------------------------------
# Install fasd (for quick cd based on frecency of history entries)
#-----------------------------------------------------------------------

fasd_archive=$( maybe_fetch_archive fasd clvv/fasd '.*?\.tar\.gz' ) && {
  tar xzf "$fasd_archive"
  sudo mv fasd-*/fasd.1 "$mandir"
  sudo mv fasd-*/fasd "$bindir"
  update_man_db=1
}

#-----------------------------------------------------------------------
# Install exa (a modern replacement for ls, with git support & more):
#-----------------------------------------------------------------------

repo=ogham/exa

# additional resources are only in the source release, so it has to be
# fetched separately and *first*, because once the exa binary is
# available, the command -v check in maybe_fetch_archive will succeed
# and the conditional block will be skipped
exa_source_archive=$( maybe_fetch_archive exa "$repo" '.*?\.tar\.gz' ) && {
  tar xzf "$exa_source_archive"
  sudo mv exa-*/contrib/man/exa.1 "$mandir"
  sudo mv exa-*/contrib/completions.fish /usr/share/fish/completions/exa.fish
  update_man_db=1
}

exa_binary_archive=$( maybe_fetch_archive exa "$repo" 'exa-linux-x86_64-.*?\.zip' ) && {
  unzip "$exa_binary_archive"
  sudo mv exa-linux-x86_64 "$bindir/exa"
}

#-----------------------------------------------------------------------
# Install bat (a cat(1) clone with wings):
#-----------------------------------------------------------------------

maybe_install_deb bat sharkdp/bat 'bat_.*?amd64.deb'

#-----------------------------------------------------------------------
# Install rg (a faster grep clone with better defaults):
#-----------------------------------------------------------------------

maybe_install_deb rg BurntSushi/ripgrep 'ripgrep_.*?_amd64.deb'

#-----------------------------------------------------------------------
# Install fd (a faster & simpler find clone with better defaults):
#-----------------------------------------------------------------------

maybe_install_deb fd sharkdp/fd 'fd_.*?_amd64.deb'

#-----------------------------------------------------------------------
# Fix Ubuntu Mono fontconfig substitution rules (prompt uses Unicode)
#-----------------------------------------------------------------------

if [ ! -d "$fonts_confd" ]; then
  set +x
  warning "\
The directory

$fonts_confd

does not exist, will not attempt to fix Ubuntu Mono font substitution
rules.\
" =
  set -x
elif [ -e "$fontconfig_overrides" ]; then
  set +x
  warning "\
A file named

$fontconfig_overrides

already exists; refusing to overwrite it to fix Ubuntu Mono font
substitution rules.\
" =
  set -x
else
  set +x
  info "\
Installing fontconfig substitution overrides for Ubuntu Mono. This is
because the default prompt uses Unicode characters which don't exist in
Ubuntu Mono and get substituted by a sans-serif font by default because
of improper configuration.

If you're using a different font, you may have to tweak this override
file:

$fontconfig_overrides

If you're installing this on a server which you'll be connecting to via
ssh, you may have to configure these overrides on your local machine
instead. Cf.:

https://github.com/dlukes/go-fish#troubleshooting-unicode-glyphs-in-prompt

NOTE: You may need to run 'fc-cache -fv' to update your fontconfig cache
and/or open a new terminal window for these changes to take effect.\
" =
  set -x
  cat <<'END' | sudo tee "$fontconfig_overrides"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<!--

Added by https://github.com/dlukes/go-fish because the default prompt
uses Unicode characters which don't exist in Ubuntu Mono and get
substituted by a sans-serif font by default because of improper
configuration.

-->
<fontconfig>
  <alias>
    <family>Ubuntu Mono</family>
    <default>
      <family>monospace</family>
    </default>
  </alias>
</fontconfig>
END
fi

#-----------------------------------------------------------------------
# Update man db for good measure if some man pages were manually added
#-----------------------------------------------------------------------

if [ -n "$update_man_db" ]; then
  sudo mandb >/dev/null
fi

set +x
info "\
All done. Invoke the 'fish' command to try the fish shell out and see if
you like it. Check out the README for tips on what's available and
configured:

https://github.com/dlukes/go-fish

And the fish shell website for a tutorial and extensive documentation:

https://fishshell.com/

Have fun using the Friendly Interactive SHell!\
" =
