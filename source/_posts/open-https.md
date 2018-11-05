---
title: 为你的网站启用 Https
date: 2018-09-08 15:35:18
category: 技术
tags:
  - Nginx
  - HTTPS
---

> 阅读本篇文章以前，你需要具备基本的服务器运维知识，包括不限于: 基本 Shell 命令，服务器选择及配置，Nginx 基本操作...

### 序言
都已经 `8102` 年了，为什么要使用 **HTTPS** 我就不记录了，相关资料网上一搜一大堆，总之，用 **HTTPS** 准没错对吧？

为什么要写一篇文章专门讨论启用 HTTPS 这个问题呢，原因有几点:

- Chrome 69 以后，默认 HTTPS 的网站才不会出现安全风险提示，否则在地址栏永远会有一个感叹号，心里难受
- 了解一下准没错吧？
- 了解了，实践一下更没错吧？
...

<!-- more -->

### 正文

废话不多说了，我的域名由于是在万网买的，阿里云提供了免费一年的 `SLL` 证书，我就直接拿来用了，至于以后，以后再说吧(继续用阿里是不可能的，太贵 -.-!)，[Let's Encryp](https://letsencrypt.org/) 是一个通用以及不错的选择。

购买好域名之后，在阿里云盾为你自己的域名(包括子域名)下载免费一年的证书:

![ssl证书](aliyunssl.png)

解压之后会得到 **xxxx.key**, **xxxxx.pem**(基于 `BASE64` 编码的证书) 两个文件，上传至服务器的 `/cert` 文件夹中。

#### 配置你的 Nginx

如果你是 CentOS 发行版本，使用

```
yum -y install nginx
```

安装 Nginx，安装好之后的配置文件处于 `/etc/nginx/` 文件夹中。 

编辑 Nginx 配置文件:

```
<!-- 找到你的虚拟主机 -->
http {
    .....
    以上关于开启 gzip 等基本设置就忽略了

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  你的域名; 
        # (我的是 server_name:blog.richardweitech.cn;)
        root         /usr/share/nginx/html;
        # 将默认80端口的 http 请求通过 rewrite 重写到 https 上
        rewrite ^(.*)$  https://$host$1 permanent;
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

    server {
        # 监听 443 端口，默认开启 http2
        listen       443 ssl http2 default_server;
        server_name  你的域名，同上;

        # 开启 SSL 协议
        ssl on;
        # 上传到服务器上的证书存放位置
        ssl_certificate   /cert/xxxxx.pem;
        ssl_certificate_key  /cert/xxxxx.key;
        ssl_session_timeout 5m;
        # 一些加密算法的指定了
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;



        location / {
    	  }

        location /dev {
            root /source/dev/public;
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
```

当然，如果 HTTP/HTTPS 功能单一或者只需要 HTTPS，我们也可以直接将 HTTP/HTTPS 默认虚拟主机合并, 删除之前的 443 端口虚拟主机的 `ssl on` 参数:

```
server {
    listen              80;
    listen              443 ssl;
    server_name         www.example.com;
    ssl_certificate     www.example.com.crt;
    ssl_certificate_key www.example.com.key;
    ...
}
```

在服务器中启动 Nginx CentOS 7 以上

```shell
> systemctl start nginx
```

再次确认 Nginx 配置是否正确
```shell
> nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

访问所配置的域名，可以看见默认已经是 HTTPS 方法了。

#### Nginx 指令优化

```
http {
  # 缓存 SLL 会话，设置 10M 缓存
  ssl_session_cache    shared:SSL:10m;
  # 缓存超时时间
  ssl_session_timeout  10m;
  # 开启 gzip 压缩
  gzip  on;
  gzip_min_length  1k;
  gzip_comp_level  2;
  gzip_types   text/plain application/x-javascript text/css application/xml text/javascript application/javascript application/json;
  gzip_buffers 16 8k;
  gzip_proxied any;
  gzip_vary  on;
}
```