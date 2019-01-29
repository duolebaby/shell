#!/bin/bash
#*/30 * * * *  bash /root/port_mon.sh
# author:mufeng
# time:20190115
warnNum=400
num=`lsof -i tcp |grep WAIT|wc -l`
Now=`date +"%Y-%m-%d %H:%M:%S"`

if [ $num -ge $warnNum ] 
then
ps -ef |grep java |grep -v 'grep'|awk '{print $2}' | xargs kill -9
echo "$Now恢复"
else
echo "--------$Now----------" >> PortContectInfo
lsof -i :10080 | wc -l   >> PortContectInfo
fi


