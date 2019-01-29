#!/bin/bash
# time-wait检测脚本
warnNum=60
while true
do
 a=`netstat -n  | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}' | grep CLOSE_WAIT | cut -d ' ' -f 2`
 if [ $a -ge $warnNum ] 
   then 
   echo `date +%m%d:%H:%M:%S`"连接未释放的超过$warnNum个,已达$a个，请查看5.51"
   echo "发送微信告警"   
   curl -d "连接未释放的超过'$warnNum'个,已达'$a'个！请检查服务器aa.b.c.d" http://xxx/xxx/xxx
 fi
 echo $a 
 sleep 10
done
