#!/bin/bash

# Append to the default bashrc
append_to_profile() {
    if ! grep -q "This sources my bash stuff" ~/.profile; then
        echo "Appending to bash."
        echo " " >> ~/.profile
        echo "# This sources my bash stuff!!" >> ~/.profile
        echo "if [ -d ~/.bash.d ]; then" >> ~/.profile
        echo "  source ~/.bash.d/mybash.sh" >> ~/.profile
        echo "fi" >> ~/.profile
        echo " " >> ~/.profile
    fi
}

# Neovim to vim symlinks
nvim_to_vim() {
    echo "Symlinking nvim to vim."
    mkdir -p ${XDG_CONFIG_HOME:=$HOME/.config}
    ln -snf ~/.vim $XDG_CONFIG_HOME/nvim
    ln -sf ~/.vimrc $XDG_CONFIG_HOME/nvim/init.vim
}

install_timew() {
    if ! hash ~/.bin/timew 2>/dev/null; then
        echo "Installing Time Warrior."
        mkdir -p ~/tmp && cd ~/tmp
        curl -O https://taskwarrior.org/download/timew-1.0.0.tar.gz
        tar xzf timew-1.0.0.tar.gz
        cd timew-1.0.0
        cmake -DCMAKE_BUILD_TYPE=release .
        make
        mv src/timew ~/.bin/
        /bin/rm -r ~/tmp/timew*
    fi
}

install_getidle() {
    if [ ! -z ~/.bin/getidle ]; then
        echo "Installing gettime from source."
        gcc ~/dotfiles/getidle/getidle.c -o ~/.bin/getidle -lXss -lX11
    fi
}

install_teensy() {
    if [ ! -f /etc/udev/rules.d/49-teensy.rules ]; then
        echo "Intalling teensy"
        sudo cp ~/.teensy-linux64/49-teensy.rules /etc/udev/rules.d/49-teensy.rules
    fi
}

# Main method, backup existing dotfiles and symlink the ones started with _*.
main() {
    echo "Symlinking  dotfiles"

    cd ${PWD}

    srcfiles=( _* )

    mkdir -p ~/.dotfiles_bkp

    for src in ${srcfiles[@]}; do

        dot="$(echo $src | sed -r 's/\%/\//g')";
        dot="${dot/\_/\.}";

        [ -L ~/$dot ] && rm ~/$dot || mv ~/$dot ~/dotfiles_bkp/ ;

        ln -sf ${PWD}/$src ~/$dot
    done
}

nvim_to_vim
append_to_profile
# install_teensy
# install_getidle
install_timew
main


