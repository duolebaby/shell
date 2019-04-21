#!/bin/bash
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
## This is shell script for ops.
## Writen by mufengs 2019-04-21
## concat me by mufeng5619@gmail.com
dir="/data/ops/menu/"
menu=`ls -t /data/ops/menu/ | cat | sed -n "1,8p"`

select option in ${menu} "Exit menu"
do
    case $option in
    "Exit menu")
        break ;;
    "urlcheck.sh")
        bash $dir/$option $1 ;;
    *)
        bash $dir/$option ;;
    esac
done
