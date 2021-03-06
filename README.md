# Overview

Set up the [`fish` shell] + some additional goodies on Ubuntu. Take a
look at the asciicast below for some highlights!

[![asciicast](https://asciinema.org/a/303279.svg)](https://asciinema.org/a/303279)

# Installation

If you're on a reasonably recent Ubuntu system and just want to install
and set up everything automatically, run:

```sh
curl --proto '=https' --tlsv1.2 -sSf \
  https://raw.githubusercontent.com/dlukes/go-fish/master/gofi.sh |
  sh
```

Of course, feel free to take a look at the script first to see what it
does.

Force re-installing all packages by setting the `GOFISH_FORCE`
environment variable:

```sh
curl --proto '=https' --tlsv1.2 -sSf \
  https://raw.githubusercontent.com/dlukes/go-fish/master/gofi.sh |
  GOFISH_FORCE=1 sh
```

By default, configuration files are installed only for the current user
under `~/.config/fish`, but they can be set up system-wide by setting
the environment variable `GOFISH_CONF_DIR=/etc/fish`.

Alternatively, you can clone this repo as `~/.config/fish`, which will
give you just the configuration files, and install all or some of the
software by hand (or maybe it has already been installed by your system
administrator). Here's a list of what's included, with links:

- the [`fish` shell] itself
- [`fasd`], a frecency sorter for your command line history
- [`fzf`], a command-line fuzzy-finder
- [`exa`], a modern replacement for `ls` with `git` integration, tree
  views and more
- [`rg`] and [`fd`] as modern replacements for `grep` and `find` which
  are faster and have better defaults (e.g. they're VCS-aware)
- [`bat`] as a modern replacement for `cat`/`less` with pretty colors,
  `git` integration and wings

# Features and usage

These are just highlights of what this particular config adds on top of
`fish`; to see the great features `fish` provides by default, check out
<https://fishshell.com/>.

- [`exa`] replaces `ls` and the following shortcuts are predefined: `ll`
  (long listing), `la` (same but including hidden files), `lt` (long
  listing with tree view), `lat` (same but including hidden files)
- a `j` function (as in *jump*) is provided to quickly navigate
  "frecently" visited directories using [`fasd`]: just type `j <Tab>` or
  `j foo<Tab>` and completions should pop up based on your history
- the [`fzf`] fuzzy-finder is installed and its default [keyboard
  shortcuts](https://github.com/junegunn/fzf#key-bindings-for-command-line)
  are loaded:
  - `<Ctrl+R>` uses `fzf` to search your command line history
  - `<Alt+C>` allows to quickly find directories in the subtree under
    `$PWD` or a path you've started typing on the command line and `cd`
    into them
  - `<Ctrl+T>` interactively selects one or more files in the subtree
    under `$PWD` whose paths should be added to the command line -- try
    e.g. `vim <Ctrl+T>` or `nano <Ctrl+T>` to select files to edit with
    `vim`/`nano`
  - entries in the selection list are navigated with `<Ctrl+N/P>`
  - where it makes sense, multiple ones can be de/selected with
    `<Shift+Tab>`/`<Tab>`
  - the preview window can be scrolled either using the mouse wheel or
    the appropriate gesture on the touchpad
  - the basic search syntax is intuitive but it has some advanced
    features which are documented
    [here](https://github.com/junegunn/fzf#search-syntax)
- `<Ctrl+X>` interactively expands globs in the word under cursor
- informative prompts showing Python virtualenv if active, exit status
  of last command if abnormal (if it was a pipeline, then a status for
  each command), timing info for long-running commands, and git repo
  state
- SSH keys configured in `conf.d/go.fish` are pre-loaded upon first
  login using `ssh-agent`, so that you don't have to repeatedly enter
  passphrases when they are used
- ... and some more stuff, see `conf.d/go.fish` and `functions/*`

# Troubleshooting Unicode glyphs in prompt

The default prompt uses Unicode characters which don't exist in Ubuntu
Mono and get substituted by a sans-serif font by default because of
improper configuration. This looks ugly, so the installation script
tries to add fontconfig overrides for Ubuntu Mono which address this.

However, maybe you're not using Ubuntu Mono, or maybe you're installing
this on a server which you'll be accessing from your local machine. In
these cases, you'll probably want to tweak this manually, i.e.
modify/add a file under `/etc/fonts/conf.d/00-overrides.conf` with
contents along the following lines:

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>Ubuntu Mono</family>
    <default>
      <family>monospace</family>
    </default>
  </alias>
</fontconfig>
```

Edit "Ubuntu Mono" to match the font you're using as needed.

You may need to run `fc-cache -fv` to update your fontconfig cache
and/or open a new terminal window for these changes to take effect.

NOTE: If your local machine runs macOS or Windows, you don't need this.

Alternatively, you can of course always just get rid of these characters
by customizing `functions/fish_prompt.fish`, especially if you don't
like them :)

[`fish` shell]: https://fishshell.com/
[`fasd`]: https://github.com/clvv/fasd/
[`fzf`]: https://github.com/junegunn/fzf/
[`exa`]: https://the.exa.website/
[`rg`]: https://github.com/BurntSushi/ripgrep/
[`fd`]: https://github.com/sharkdp/fd/
[`bat`]: https://github.com/sharkdp/bat
