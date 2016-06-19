#!/usr/bin/env bash

if test -f /usr/local/vagrant.nginx.lock
then
    exit
fi

# --------------------------   安装NGINX  -----------------------------
cd ~
wget http://www.openssl.org/source/openssl-1.0.1j.tar.gz
tar -zxvf openssl-1.0.1j.tar.gz

wget http://nginx.org/download/nginx-1.6.2.tar.gz
tar -zxvf nginx-1.6.2.tar.gz
cd nginx-1.6.2

./configure --prefix=/usr/local/nginx --with-openssl=/root/openssl-1.0.1j --with-http_ssl_module
make
sudo make install

# Nginx 环境变量
cd ~
echo 'if [ -d "/usr/local/nginx/sbin" ] ; then
    PATH=$PATH:/usr/local/nginx/sbin
    export PATH
fi' > env_nginx.sh
sudo cp env_nginx.sh /etc/profile.d/env_nginx.sh

# 配置文件链接，方便编辑
sudo ln -s /usr/local/nginx/conf/nginx.conf /etc/nginx.conf

# Nginx配置
cd ~
echo 'user  vagrant;
worker_processes  auto;

error_log  logs/error.log;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;
        root         /www;

        location / {
            index  index.html index.htm index.php;
			try_files $uri $uri/ /index.php;
        }

        location ~ \.php$ {
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
			fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
			fastcgi_param  PATH_INFO $fastcgi_script_name;
		}
		
    }
}' > nginx.conf
sudo mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.default
sudo mv nginx.conf /usr/local/nginx/conf/nginx.conf
#创建启动脚本
echo '#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /etc/nginx/nginx.conf
# config:      /etc/sysconfig/nginx
# pidfile:     /var/run/nginx.pid


# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

nginx="/usr/local/nginx/sbin/nginx"
prog=$(basename $nginx)

sysconfig="/etc/sysconfig/$prog"
lockfile="/var/lock/subsys/nginx"
pidfile="/usr/local/nginx/logs/nginx.pid"

NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"

[ -f $sysconfig ] && . $sysconfig


start() {
	if [ -f ${pidfile} ];  then
		exit 0
    fi
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    $nginx
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    if [ -f ${pidfile} ];  then
	    echo -n $"Stopping $prog: "
		$nginx -s stop
		retval=$?
		echo
		[ $retval -eq 0 ] && rm -f $lockfile
		return $retval
    fi

}

restart() {
    stop
    start
}

reload() {
	if [ -f ${pidfile} ];  then
		echo -n $"Reloading $prog: "
		$nginx -s reload
		echo
    fi

}

case "$1" in
    start)
        $1
        ;;
    stop)
        $1
        ;;
    reload)
        $1
        ;;
    restart)
        $1
        ;;
    *)
        echo $"Usage: $0 {start|stop|reload|restart}"
        exit 2
esac' > nginxd
## 创建启动脚本
sudo mv nginxd /etc/init.d/nginxd
sudo chmod 755 /etc/init.d/nginxd
sudo chkconfig nginxd on
sudo service nginxd start
touch /usr/local/vagrant.nginx.lock
