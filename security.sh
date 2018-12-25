
#!/bin/sh

# desc: setup linux system security
# author:mufengs
# powered by blog.mufengs.com
# version 0.1.2 written by 2018.11.24
#account setup

#锁定以下用户
passwd -l xfs
passwd -l news
passwd -l nscd
passwd -l dbus
passwd -l vcsa
passwd -l games
passwd -l nobody
passwd -l avahi
passwd -l haldaemon
passwd -l gopher
passwd -l ftp
passwd -l mailnull
passwd -l pcap
passwd -l mail
passwd -l shutdown
passwd -l halt
passwd -l uucp
passwd -l operator
passwd -l sync
passwd -l adm
passwd -l lp

#将帐号相关文件设为只读属性
# chattr /etc/passwd /etc/shadow
chattr +i /etc/passwd
chattr +i /etc/shadow
chattr +i /etc/group
chattr +i /etc/gshadow

#系统登陆失败3次锁定5分钟
# add continue input failure 3 ,passwd unlock time 5 minite
sed -i 's#auth        required      pam_env.so#auth        required      pam_env.so \n auth       required       pam_tally.so  onerr=fail deny=3 unlock_time=300 \n auth           required     /lib/security/$ISA/pam_tally.so onerr=fail deny=3 unlock_time=300#' /etc/pam.d/system-auth

#5分钟超时登出
# system timeout 5 minite auto logout
echo "TMOUT=300" >>/etc/profile

#设置历史命令为10条
# will system save history command list to 10
sed -i "s/HISTSIZE=1000/HISTSIZE=10/" /etc/profile

#让以上配置生效
# enable /etc/profile go!
source /etc/profile

#防范SYN Flood攻击
# add syncookie enable /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
sysctl -p # exec sysctl.conf enable


# optimizer sshd_config

sed -i "s/#MaxAuthTries 6/MaxAuthTries 6/" /etc/ssh/sshd_config
sed -i  "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config

#限制重要命令的权限
# limit chmod important commands
chmod 700 /bin/ping
chmod 700 /usr/bin/finger
chmod 700 /usr/bin/who
chmod 700 /usr/bin/w
chmod 700 /usr/bin/locate
chmod 700 /usr/bin/whereis
chmod 700 /sbin/ifconfig
chmod 700 /usr/bin/pico
chmod 700 /bin/vi
chmod 700 /usr/bin/which
chmod 700 /usr/bin/gcc
chmod 700 /usr/bin/make
chmod 700 /bin/rpm

# history security

chattr +a /root/.bash_history
chattr +i /root/.bash_history

# write important command md5
cat > list << "EOF" &&
/bin/ping
/bin/finger
/usr/bin/who
/usr/bin/w
/usr/bin/locate
/usr/bin/whereis
/sbin/ifconfig
/bin/pico
/bin/vi
/usr/bin/vim
/usr/bin/which
/usr/bin/gcc
/usr/bin/make
/bin/rpm
/bin/ls
/bin/top
/bin/ps
EOF

for i in `cat list`
do
   if [ ! -x $i ];then
   echo "$i not found,no md5sum!"
  else
   md5sum $i >> /var/log/`hostname`.log
  fi
done
rm -f list

# 修改默认umask
perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/bashrc
perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/csh.cshrc


#cron加固
echo "Locking down Cron"

touch /etc/cron.allow

chmod 600 /etc/cron.allow

awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny

echo "Locking down AT"

touch /etc/at.allow

chmod 600 /etc/at.allow

awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/at.deny


#内核加固
cat << EOF >> /etc/sysctl.conf
net.ipv4.ip_forward = 0

net.ipv4.conf.all.send_redirects = 0

net.ipv4.conf.default.send_redirects = 0

net.ipv4.tcp_max_syn_backlog = 1280

net.ipv4.icmp_echo_ignore_broadcasts = 1

net.ipv4.conf.all.accept_source_route = 0

net.ipv4.conf.all.accept_redirects = 0

net.ipv4.conf.all.secure_redirects = 0

net.ipv4.conf.all.log_martians = 1

net.ipv4.conf.default.accept_source_route = 0

net.ipv4.conf.default.accept_redirects = 0

net.ipv4.conf.default.secure_redirects = 0

net.ipv4.icmp_echo_ignore_broadcasts = 1

net.ipv4.icmp_ignore_bogus_error_responses = 1

net.ipv4.tcp_syncookies = 1

net.ipv4.conf.all.rp_filter = 1

net.ipv4.conf.default.rp_filter = 1

net.ipv4.tcp_timestamps = 0
EOF

# 禁止所有TCP Wrappers
echo "ALL:ALL" >> /etc/hosts.deny
echo "sshd:ALL" >> /etc/hosts.allow


#防止缓冲区溢出
sysctl -w kernel.exec-shield=1
sysctl -q -n -w kernel.randomize_va_space=2
echo "kernel.exec-shield = 1">>/etc/sysctl.conf
echo "kernel.randomize_va_space = 2">>/etc/sysctl.conf

#禁止空密码登陆
sed -i 's/\<nullok\>//g' /etc/pam.d/system-auth

#定时更新
yum -y install yum-cron
chkconfig yum-cron on

#以下为防ssh爆破,8次之后永久封禁
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
 
test -d /usr/local/cron || mkdir -p /usr/local/cron
cat > /usr/local/cron/sshdeny.sh << "EOF"
#!/bin/bash
DEFINE="8"
cat /var/log/secure|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print $2"="$1;}' > /tmp/sshDenyTemp.txt
for i in `cat /tmp/sshDenyTemp.txt`
do
    IP=`echo $i |awk -F= '{print $1}'`
    NUM=`echo $i|awk -F= '{print $2}'`
    if [ $NUM -gt $DEFINE ];
    then
        grep $IP /etc/hosts.deny > /dev/null
        if [ $? -gt 0 ];
        then
            echo "sshd:$IP" >> /etc/hosts.deny
        fi
    fi
done
echo > /var/log/secure
rm -rf /tmp/sshDenyTemp.txt
#echo sshd>> /root/ssh.log
EOF
function Install_cron()
{
    if [ "$PM" = "yum" ]; then
        yum -y install  vixie-cron crontabs
        log=/var/log/secure
        test -d /var/spool/cron || mkdir -p /var/spool/cron
        echo '*/10 * * * * /usr/local/cron/sshdeny.sh > /dev/null 2>&1' >> /var/spool/cron/root
        crontab /var/spool/cron/root
        chmod 600 /var/spool/cron/root
    elif [ "$PM" = "apt" ]; then
        apt -y update
        apt install -y cron
        log=/var/log/auth.log
        sed -i 's/secure/auth.log/g' /usr/local/cron/sshdeny.sh
        test -d /var/spool/cron/crontabs || mkdir -p /var/spool/cron/crontabs
        echo '*/10 * * * * /usr/local/cron/sshdeny.sh > /dev/null 2>&1' >> /var/spool/cron/crontabs/root
        crontab /var/spool/cron/crontabs/root
        chmod 600 /var/spool/cron/crontabs/root
    fi
}
 
if [ ! -f "/usr/bin/yum" ]; then
    PM=apt
else
    PM=yum
fi
 
Install_cron;
chmod +x /usr/local/cron/sshdeny.sh
 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Deny for SSH Cront have added success!"
echo "The task work by 10/min"
echo "If you want to allow one, please delete it from /etc/hosts.deny"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 
