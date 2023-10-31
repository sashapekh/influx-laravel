#!/usr/bin/env bash

set -e

USER=$1
NEW_UID=$2
NEW_GID=$3

MY_UID=$(id -u $USER)
MY_GID=$(id -g $USER)

function change_uid ()
{
    OLD=$1; NEW=$2; usermod -u $NEW $(id -un $OLD)
    find / -xdev -user $OLD -exec chown -h $NEW {} \;
}

function change_gid ()
{
    OLD=$1; NEW=$2; groupmod -g $NEW $(getent group $OLD | cut -d: -f1)
    find / -xdev -group $OLD -exec chgrp -h $NEW {} \;
}

function nextent ()
{
    TYPE=$1; EXCEPT=$2; START=1000; RESULT=$3

    while true; do
        if [ $START -eq $EXCEPT ]; then
            START=$((START + 1)); continue
        fi

        if getent $TYPE $START > /dev/null; then
            START=$((START + 1)); continue
        fi

        break
    done

    eval $RESULT=$START
}

if [ "$MY_UID" -ne "$NEW_UID" ]; then
    if getent passwd $NEW_UID > /dev/null; then
        nextent 'passwd' $NEW_UID FREE_UID
        change_uid $NEW_UID $FREE_UID
    fi
    echo "Changing UID $MY_UID to $NEW_UID"
    change_uid $MY_UID $NEW_UID
fi

if [ "$MY_GID" -ne "$NEW_GID" ]; then
    if getent group $NEW_GID > /dev/null; then
        nextent 'group' $NEW_GID FREE_GID
        change_gid $NEW_GID $FREE_GID
    fi
    echo "Changing GID $MY_GID to $NEW_GID"
    change_gid $MY_GID $NEW_GID
fi
