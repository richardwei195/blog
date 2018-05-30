---
title: nodejs与nginx的完美搭配
date: 2017-03-26 18:14:26
tags: 
  - nginx
  - nodejs
---

# 引言
---
node自己本身可以作为服务器进行驱动，但是node本身对文件的处理能力并不是很好，所以当我们的生产环境中应尽量使用nginx来处理静态的资源以及反向代理，同时也解决了node分布式以及负载均衡的相关问题。


# nginx的安装以及配置
---
这里以cenos环境为基础进行配置

1、基础编译环境的配置C/C++等编译工具以及工具库：

	yum -y install make zlib zlib-devel gcc-c++ libtool  openssl openssl-devel

2、PRCE安装
（1）下载：
    ```shell
        wget http://downloads.sourceforge.net/project/pcre/pcre/8.35/pcre-8.35.tar.gz
    ```
（2）解压

	tar -zxvf pcre-8.35.tar.gz
（3）安装

	cd pcre-8.35
	./configure
	make && make install
3、安装Nginx
（1）下载
	
	 wget http://nginx.org/download/nginx-1.10.3.tar.gz
（2）解压、安装

	tar -zxvf nginx-1.10.3.tar.gz
	cd /nginx-1.10.3
	./configure --prefix=/usr/local/webserver/nginx --with-http_stub_status_module --with-http_ssl_module --with-pcre=/usr/local/src/pcre-8.35
	make && make install
（3）是否安装成功

	/usr/local/webserver/nginx/sbin/nginx -v
能够查看版本号说明安装成功

（4）配置

	/usr/sbin/groupadd www 
	/usr/sbin/useradd -g www www
	
（5）实现node反向代理

		node默认端口号为3000
编辑 nginx.conf 文件

		#user  nobody;
	worker_processes  1; ##默认的CPU核心数
	
	#error_log  logs/error.log;
	#error_log  logs/error.log  notice;
	#error_log  logs/error.log  info;
	
	#pid        logs/nginx.pid;
	#Specifies the value for maximum file descriptors that can be opened by this process.
	worker_rlimit_nofile 65535;
	
	events {
		#进行如下配置
	    use epoll;
	    worker_connections  65535;
	}
	
	
	http {
	    include       mime.types;
	    default_type  application/octet-stream;
	
		 #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;
	#主机配置
    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;
		#修改反向代理地址
        location / {
	        proxy_set_header X-Real-IP $remote_addr;
	        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	        proxy_set_header Host  $http_host;
	        proxy_set_header X-Nginx-Proxy true;
	        proxy_set_header Connection "";
		   proxy_pass http://127.0.0.1:3000;
		   proxy_redirect default;
           # root   html;
           #index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}


查看是否配置成功：
	
	/usr/local/webserver/nginx/sbin/nginx -t
打印如下信息代表成功：
	
	nginx: the configuration file /usr/local/webserver/nginx/conf/nginx.conf syntax is ok
	nginx: configuration file /usr/local/webserver/nginx/conf/nginx.conf test is successful

（6）启动

	/usr/local/webserver/nginx/sbin/nginx

3、实现负载均衡：
这里推荐这篇文章：http://blog.csdn.net/chszs/article/details/43203127