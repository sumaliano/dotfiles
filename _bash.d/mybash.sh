#!/usr/bin/env bash

# for DOTFILE in ~/.bash.d/{env,options,alias,functions,prompt,completion,z.sh}; do
for DOTFILE in ~/.bash.d/{env,options,alias,functions,prompt,completion}; do
	[ -f "$DOTFILE" ] && . "$DOTFILE"
done

if [ ! -d ~/tmp ]; then
    mkdir ~/tmp
    chmod 700 ~/tmp
    echo ~/tmp was missing. I created it for you.
fi

if [ ! -d ~/.Trash ]; then
    if [ -d ~/.local/share/Trash ]; then
        ln -s ~/.local/share/Trash ~/.Trash
        echo ~/.Trash is now linked to ~/.local/share/Trash.
    else
        mkdir ~/.Trash
        chmod 700 ${home}/.Trash
        echo ~/.Trash was missing. I created it for you.
    fi
fi
