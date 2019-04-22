#!/bin/bash
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
## This is shell script for ops.
## Writen by mufengs 2019-04-21
## concat me by mufeng5619@gmail.com

docker_log_clean(){
echo "==================== start clean docker containers logs ==========================" 
logs=$(find /var/lib/docker/containers/ -name *-json.log) 
for log in $logs
    do 
        echo "clean logs : $log" 
        cat /dev/null > $log 
    done 
echo "==================== end clean docker containers logs   ==========================" 
}
nginx_log_cut(){
    date=$(date +%F -d -1day)
    cd /var/log/nginx/
    if [ ! -d cut ]; then
        mkdir cut
    fi
    mv access.log cut/access_$(date +%F -d -1day).log
    mv error.log cut/error_$(date +%F -d -1day).log
    nginx -s reload
    tar -zcvf cut/$date.tar.gz cut/*
    rm -rf cut/access* && rm -rf cut/error*
cat >> /var/spool/cron/root <<EOF
00 00 * * * /bin/sh /root/cut_nginx_log.sh >/dev/null 2>&1
EOF
    find -type f -mtime +5 | xargs rm -rf
}
system_log_clean(){
    if [ $USER != "root" ];then
	echo "你必须使用 root 用户才能执行这个脚本"
	exit 10
    fi
    #判断日志文件在不在
    if [ ! -f /var/log/messages ];then
        echo "文件不存在"
        exit 11
    fi
    #保留最近 100 行的日志内容
    tail -100 /var/log/messages > /var/log/mesg.tmp
    #日志清理
    >/var/log/messages
    cat /var/log/mesg.tmp >> /var/log/messages
    mv /var/log/mesg.tmp /var/log/messages
    echo "Logs clean up"
}
urlcheck(){
    . /etc/rc.d/init.d/functions
    echo -n "need check url is:"
    read urls
  
    RETVAL=0
    CheckUrl(){
        RETURN=`curl -o /dev/null -iL -s -w "%{http_code}" "$i"`
        if [ $RETURN == '200' ];then
            action "$i url" /bin/true
        else
            action "$i url" /bin/false
        fi
        return $RETVAL
    }
    main(){
        for i in $urls
            do
                CheckUrl
            done
    }
    main $*
}



select option in docker_log_clean nginx_log_cut system_log_clean urlcheck "Exit menu" "help"
do
    case $option in
    "Exit menu")
        break ;;
    "help")
        echo "please input the number of option!" ;;
    *)
        $option ;;
    esac
done
