#!/bin/sh
version="20191001.01"
tmp_file="/tmp/lalala"
tar_file="/tmp/fsweb.tar.gz"
function check_fs(){
	fs_path="/usr/local/freeswitch"
	if [ -e $fs_path ];then
		echo -ne " \\033[0;31m [错误|ERROR]:已经安装了FreeSwitch,请先卸载!|FreeSwitch Already Installed,Please Uninstall It First!\\033[0;0m \n"
		exit 255
	fi
}
function check_selinux(){
	selinux=$(sestatus | grep 'enforcing'|wc -l)
	if [ $selinux -gt 0 ];then
		echo -ne " \\033[0;31m [错误|ERROR]:需要关闭Selinux!|To disable Selinux!\\033[0;0m \n"
		exit 255
	fi
	
}
function check_port(){
	port_8888=$(lsof -ni:8888|wc -l)
	port_9999=$(lsof -ni:9999|wc -l)
	if [ $port_8888 -gt 0 -o $port_9999 -gt 0 ];then
		echo -ne " \\033[0;31m [错误|ERROR]:8888和9999端口,已被占用!|Need Port 8888 & 9999\\033[0;0m \n"
		exit 255
	fi
}
function check_network(){
	ping www.baidu.com -c 4 2>&1>/dev/null
	if [ $? -ne 0 ];then
		echo -ne " \\033[0;31m [错误|ERROR]:需要联网!|Need an Internet connection!\\033[0;0m \n"
		exit 255
	fi
}
function install_rpms(){
	echo -ne " \\033[0;32m [信息|INFO]:[1/3]正在安装所需的RPMS......!|Install RPMS ......!\\033[0;0m \n"
	sleep 2
	yum install -y epel-release
	yum install -y lsof libtool gcc-c++ yasm libuuid-devel zlib-devel \
			libjpeg-devel ncurses-devel openssl-devel sqlite \
			sqlite-devel libcurl-devel speex-devel ldns-devel \
			libedit libedit-devel lua lua-devel libsndfile-devel \
			sox tcpdump mpg123 lsof net-tools sed gawk httpd httpd-devel\
 			ntp SDL lrzsz screen wget psmisc psutils dmidecode coreutils \
			opus opus-devel iptables iptables-services vim-enhanced mailx sysstat \
			fail2ban-server fail2ban fail2ban-sendmail libpng-devel
}
function install_python(){
    	yum install python3 -y
	pip3 install django==2.0
    	pip3 install django-cors-headers
    	pip3 install django_filter
    	pip3 install djangorestframework
    	pip3 install IPy 
    	pip3 install gunicorn

    	yum install python2-pip -y
	pip2 install phone

}
function install_fsweb(){
	echo -ne " \\033[0;32m [信息|INFO]:[2/3]正在安装FreeSwitch......!|Install Freeswitch......!\\033[0;0m \n"
	sleep 2
	#提取文件
	exit_line=$(($(sed -ne '/exit\ 0/=' $0)+1))
	tail -n +$exit_line $0 > $tmp_file
	echo "$version" > $tar_file
	
	#解压缩
	tar zxvf $tmp_file -C / 2>&1>/dev/null
	rm -rf $tmp_file

}
function start_services(){
	echo -ne " \\033[0;32m [信息|INFO]:[3/3]启动相关服务......!|Start Services......!\\033[0;0m \n"
	sleep 2

	#防火墙
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	iptables -F
	iptables -X
	iptables -Z
	service iptables save  2>&1>/dev/null
	systemctl start iptables.service
	systemctl enable iptables.service

	#启动fsweb
	systemctl restart httpd.service
	systemctl enable httpd.service
	systemctl start fsweb.service
	systemctl enable fsweb.service

	#启动fail2ban
	systemctl start fail2ban.service
	systemctl enable fail2ban.service

	#新建vsftpd用户,用户下载录音.自行建立.
	# useradd -g ftp -d /usr/local/freeswitch/recordings/ -s /sbin/nologin
	# echo "123456" | password monitor --stdin
	# systemctl start vsftpd.service
	# systemctl enable vsftpd.service
	
}

function install_finished(){
	#提示
	ips=$(ifconfig |grep 'inet'|grep -vE 'inet6|127.0.0.1'|awk '{print $2}')
	echo -ne "#####################################\n"
        echo -ne "# \\033[0;32m    [安装完成|Finished]\\033[0;0m           #\n"
        for ip in $ips
        do
        echo -ne "# \\033[0;33m http://$ip:9999/ \\033[0;0m     #\n"
        done
        echo -ne "# \\033[0;33m 默认用户|username:amdin \\033[0;0m         #\n"
        echo -ne "# \\033[0;33m 默认密码|password:admin \\033[0;0m         #\n"
        echo -ne "# \\033[0;33m ---------------------------- \\033[0;0m    #\n"
        echo -ne "# \\033[0;33m 停止运行:systemctl stop fsweb \\033[0;0m   #\n"
        echo -ne "# \\033[0;33m 开始运行:systemctl start fsweb\\033[0;0m   #\n"
        echo -ne "# \\033[0;33m ---------------------------- \\033[0;0m    #\n"
        echo -ne "#####################################\n"
	#加载环境变量
	source /etc/profile
}

function install(){
	check_fs
	check_selinux
	check_network
	install_rpms
	install_python
	check_port
	install_fsweb
	start_services
	install_finished

}
function uninstall(){
	fs_path="/usr/local/freeswitch"
	if [ ! -e $fs_path ];then
		echo -ne " \\033[0;31m [错误|ERROR]:没有安装FreeSwitch!|Can Not Find FreeSwitch!\\033[0;0m \n"
		exit 255
	fi
	systemctl stop fsweb.service
	rm -rf /etc/httpd/conf.d/fsweb.conf
	rm -rf /usr/local/freeswitch
	rm -rf /etc/profile.d/freeswitch.sh
	systemctl restart httpd.service
	source /etc/profile
	echo -ne " \\033[0;32m [信息|INFO]:卸载完毕!|Uninstall Finished!\\033[0;0m \n"
}
function install_select(){
	case "$1" in
		install)
			install
			;;
		uninstall)
			uninstall
			;;
		*)
    		echo "用法|Usage: $0  { install | uninstall }"
    		exit 255
			;;
	esac
}
function ctrlc_clear(){
	echo -ne " \\033[0;31m [错误|ERROR]:意外终止......!|Quit......!\\033[0;0m \n"
	rm -rf /etc/httpd/conf.d/fsweb.conf
	rm -rf /usr/local/freeswitch
	rm -rf /etc/profile.d/freeswitch.sh
	rm -rf $tmp_file
	source /etc/profile
	echo "1111111"
	echo "2222222"
	echo "3333333"
	echo "4444444"
	echo "5555555"
}

trap 'ctrlc_clear' INT QUIT

install_select $1

exit 0
