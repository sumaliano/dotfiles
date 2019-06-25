#!/bin/bash

TMPFILE="/tmp/updateslist"
FONT="-adobe-helvetica-medium-*-normal-*-12-*-75-*-*-*-*-*"

while :;
do
    po=$(yaourt -Qu --aur 2> "/dev/null" | tee "/tmp/updateslist" | wc -l)

    if [ "$po" -gt 1 ]; then # found some
        echo -e "^fg(#FF0000)$po updates^fg()\n$(cat $TMPFILE)" | dzen2 -p -h 22 -ta l -l $po -fn $FONT -bg black &
    elif [ "$po" -eq 1 ]; then # found something
        echo -e "^fg(#FF0000)1 update^fg()\n$(cat $TMPFILE)" | dzen2 -p -h 22 -ta l -l $po -fn $FONT -bg black &
    else
        echo -e "no updates" | dzen2 -p -h 22 -ta l -fn $FONT -bg black &
    fi
    inotifywait "/var/lib/pacman/local/"
done
