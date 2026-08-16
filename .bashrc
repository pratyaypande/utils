# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

function clean_orig_and_rej_files() {
    find . -type f \( -name "*.orig" -o -name "*.rej" \) -exec rm -v {} +
}

function replace_all() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: replace_all <old_string> <new_string>"
    return 1
  fi

  local old=$1
  local new=$2

  find . -type f -exec sed -i "s|$old|$new|g" {} +
}


export clean_orig_and_rej_files

export LOCAL_INSTALL_DIR=$HOME/.local

# clang
export PATH="$LOCAL_INSTALL_DIR/llvm/bin:$PATH"
# export PATH="$LOCAL_INSTALL_DIR/llvm/lib/clang/20/bin:$PATH"
export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/llvm/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/llvm/lib/x86_64-unknown-linux-gnu:$LD_LIBRARY_PATH"
# export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/llvm/lib/clang/20/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/llvm/include:$C_INCLUDE_PATH"
# export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/llvm/lib/clang/20/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/llvm/include:$CPLUS_INCLUDE_PATH"
# export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/llvm/lib/clang/20/include:$CPLUS_INCLUDE_PATH"
export CLANG_CMAKE_DIR="$LOCAL_INSTALL_DIR/llvm/lib/cmake/clang"


# gmp
export PATH="$LOCAL_INSTALL_DIR/cmake/bin:$PATH"
export PKG_CONFIG_PATH="$LOCAL_INSTALL_DIR/cmake/lib/pkgconfig:$PKG_CONFIG_PATH"
source "$LOCAL_INSTALL_DIR/cmake/share/bash-completion/completions/cmake"
source "$LOCAL_INSTALL_DIR/cmake/share/bash-completion/completions/cpack"
source "$LOCAL_INSTALL_DIR/cmake/share/bash-completion/completions/ctest"

# SYCL code
# export PATH="$LOCAL_INSTALL_DIR/sycl/bin:$PATH"
# # export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/sycl-install/lib:$LD_LIBRARY_PATH"
# export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/sycl/lib:$LD_LIBRARY_PATH"
# # export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/sycl-install/include:$C_INCLUDE_PATH"
# export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/sycl/include:$C_INCLUDE_PATH"
# # export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/sycl-install/include:$CPLUS_INCLUDE_PATH"
# export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/sycl/include:$CPLUS_INCLUDE_PATH"
# export CLANG_CMAKE_DIR="$LOCAL_INSTALL_DIR/sycl/lib/cmake/clang"

# libtool
export PATH="$LOCAL_INSTALL_DIR/libtool/bin:$PATH"
export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/libtool/lib:$LD_LIBRARY_PATH" #:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/libtool/include:$C_INCLUDE_PATH" #:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/libtool/include:$CPLUS_INCLUDE_PATH" #:$CPLUS_INCLUDE_PATH"
export ACLOCAL_PATH="$LOCAL_INSTALL_DIR/libtool/share/aclocal" #:$ACLOCAL_PATH"

# gmp
export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/gmp/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/gmp/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/gmp/include:$CPLUS_INCLUDE_PATH"
export PKG_CONFIG_PATH="$LOCAL_INSTALL_DIR/gmp/lib/pkgconfig:$PKG_CONFIG_PATH"

# lz4
export PATH="$LOCAL_INSTALL_DIR/lz4/bin:$PATH"
export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/lz4/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/lz4/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/lz4/include:$CPLUS_INCLUDE_PATH"
export PKG_CONFIG_PATH="$LOCAL_INSTALL_DIR/lz4/lib/pkgconfig:$PKG_CONFIG_PATH"
 
# go
export PATH="$LOCAL_INSTALL_DIR/go/bin:$PATH"
export GOPATH="$LOCAL_INSTALL_DIR/.gopath"
export PATH="$GOPATH/bin:$PATH"
 
#boost
export LOCAL_BOOST_ROOT=$LOCAL_INSTALL_DIR/boost
export LD_LIBRARY_PATH=$LOCAL_BOOST_ROOT/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$LOCAL_BOOST_ROOT/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH="$LOCAL_BOOST_ROOT/include:$CPLUS_INCLUDE_PATH"
 
# zstd
export PATH="$LOCAL_INSTALL_DIR/zstd/bin:$PATH"
export LD_LIBRARY_PATH="$LOCAL_INSTALL_DIR/zstd/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$LOCAL_INSTALL_DIR/zstd/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$LOCAL_INSTALL_DIR/zstd/include:$CPLUS_INCLUDE_PATH"
export PKG_CONFIG_PATH="$LOCAL_INSTALL_DIR/zstd/lib/pkgconfig:$PKG_CONFIG_PATH"

# neovim
export PATH=$HOME/.local/neovim/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/neovim/lib:$LD_LIBRARY_PATH

# icu
export PATH=$HOME/.local/icu/bin:$PATH
export PATH=$HOME/.local/icu/sbin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/icu/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$HOME/.local/icu/lib/pkgconfig:$PKG_CONFIG_PATH
export C_INCLUDE_PATH=$HOME/.local/icu/include:$C_INCLUDE_PATH

# postgresql
export PATH=$HOME/.local/postgresql/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/postgresql/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$HOME/.local/postgresql/include:$C_INCLUDE_PATH
export CUSTOM_POSTGRES_DIR=$HOME/.postgresql_files

# cuda
export PATH="${PATH}:/usr/local/cuda-12.3/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/cuda-12.3/lib64"

# spirv-tools
export PATH=$HOME/.local/spirv-tools/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/spirv-tools/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$HOME/.local/spirv-tools/include:$C_INCLUDE_PATH
export PKG_CONFIG_PATH=$HOME/.local/spirv-tools/lib/pkgconfig:$PKG_CONFIG_PATH

# TBB
export PATH=$HOME/.local/tbb/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/tbb/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$HOME/.local/tbb/include:$C_INCLUDE_PATH
export PKG_CONFIG_PATH="$LOCAL_INSTALL_DIR/tbb/lib/pkgconfig:$PKG_CONFIG_PATH"

# LibTorch
export PATH=$HOME/.local/libtorch/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/libtorch/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$HOME/.local/libtorch/include:$C_INCLUDE_PATH
export C_INCLUDE_PATH=$HOME/.local/libtorch/include/torch/csrc/api/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$HOME/.local/libtorch/include:$CPLUS_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$HOME/.local/libtorch/include/torch/csrc/api/include:$CPLUS_INCLUDE_PATH
export PKG_CONFIG_PATH="$LOCAL_INSTALL_DIR/libtorch/lib/pkgconfig:$PKG_CONFIG_PATH"

function octopus_postgresql_db_size() {
	psql -U pratyay -d octopus_main -c "SELECT pg_size_pretty(pg_database_size('octopus_main'));" | sed -n 3,3p
}

if [ -f "$HOME/.llvm-utils.sh" ]; then
	. $HOME/.llvm-utils.sh
else
	echo ---- Couldn\'t find $HOME/.llvm-utils.sh ... LLVM utility functions will not be available
fi

# alias tmux='LC_CTYPE=en_US.UTF-8 tmux -2'
alias tmux='tmux -2 -u'

if [ -f "$HOME/.tmux-utils.sh" ]; then
	. $HOME/.tmux-utils.sh
else
	echo ---- Couldn\'t find $HOME/.tmux-utils.sh ... LLVM utility functions will not be available
fi

# PostgreSQL initdb somehow complains about this
# export LANG="en_US.UTF-8"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export H=$HOME
