FROM centos:6.6
MAINTAINER chenchaofei "c_chaofei@geotmt.com"

# c c++编译器
RUN yum install -y gcc gcc-c++ 

# 常用的工具包
RUN yum -y install vim wget curl sudo tar


RUN mkdir /usr/local/webserver

##############################################################
ADD ./src/setuptools-0.6c11-py2.6.egg /usr/local/src/
ADD ./src/supervisor-3.0b1.tar.gz /usr/local/src/

WORKDIR /usr/local/src/
RUN sh setuptools-0.6c11-py2.6.egg

WORKDIR /usr/local/src/supervisor-3.0b1
RUN python setup.py install
RUN echo_supervisord_conf  >/etc/supervisord.conf
##############################################################
WORKDIR /usr/local/src/
RUN mkdir -p /usr/local/webserver/java
RUN mv jre1.7.0_80 /usr/local/webserver/java/

WORKDIR /usr/local/webserver/java/
RUN chown root.root -R jre1.7.0_80

RUN echo 'export JAVA_HOME=/usr/local/webserver/java' >> /etc/profile
RUN echo 'export JRE_HOME=/usr/local/webserver/java/jre1.7.0_80' >> /etc/profile
RUN echo 'export CLASSPATH=$JRE_HOME/lib/rt.jar:$JRE_HOME/lib/ext' >> /etc/profile
RUN echo 'export PATH=$PATH:$JRE_HOME/bin' >> /etc/profile' >> /etc/profile
RUN source /etc/profile

##############################################################
ADD ./src/nginx-1.8.0.tar.gz /usr/local/src

# nginx扩展依赖
RUN yum install -y pcre pcre-devel openssl-devel 

#安装nginx
WORKDIR /usr/local/src/nginx-1.8.0
RUN ./configure --prefix=/usr/local/webserver/nginx --user=www --group=www --with-http_stub_status_module --with-http_ssl_module
RUN make && make install

RUN groupadd www
RUN useradd -g www www

###############################################################
ADD ./src/tcl8.6.3-src.tar.gz /usr/local/src/
ADD ./src/redis-2.8.19.tar.gz /usr/local/src/

WORKDIR /usr/local/src/tcl8.6.3/unix/
RUN ./configure
RUN make
RUN make install

WORKDIR /usr/local/src/redis-2.8.19
RUN make
RUN make PREFIX=/usr/local/webserver/redis install

##############################################################
ADD ./src/mysql-5.6.27.tar.gz /usr/local/src/

# 必要软件包
RUN yum -y install gcc gcc-c++ autoconf automake zlib* libxml* ncurses-devel libtool-ltdl-devel* make bison ncurses ncurses-* cmake

WORKDIR /usr/local/src/mysql-5.6.27

# 先配置下MySQL的编译参数
RUN cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/webserver/mysql -DMYSQL_DATADIR=/usr/local/webserver/mysql/data -DWITH_INNOBASE_STORAGE_ENGINE=1 -DMYSQL_UNIX_ADDR=/usr/local/webserver/mysql/mysql.sock -DMYSQL_USER=mysql -DDEFAULT_CHARSET=utf8 -DEXTRA_CHARSETS=all -DDEFAULT_COLLATION=utf8_general_ci

#这里你大可以泡杯茶 编译需要较长的时间
RUN make
RUN make install

#添加mysql用户
RUN groupadd mysql
RUN useradd -g mysql mysql

#创建安装目录
RUN mkdir -p /usr/local/webserver/mysql
RUN mkdir -p /usr/local/webserver/mysql/data

#复制mysql管理脚本
RUN cp support-files/mysql.server /etc/init.d/mysqld
RUN chmod a+x /etc/init.d/mysqld

#复制mysql配置文件
RUN cp /usr/local/webserver/mysql/support-files/my-default.cnf /etc/my.cnf
RUN chown mysql:mysql /etc/my.cnf

RUN echo "export PATH=$PATH:/usr/local/webserver/mysql/bin" >> /etc/profile
RUN source /etc/profile

#修改目录权限
RUN chown -R mysql.mysql /usr/local/webserver/mysql

#初始化mysql
RUN su - mysql
WORKDIR /usr/local/webserver/mysql/scripts
RUN ./mysql_install_db --user=mysql --basedir=/usr/local/webserver/mysql --datadir=/usr/local/webserver/mysql/data

###################################################################

ADD ./src/bin/supervisord /etc/init.d/
ADD ./src/bin/redis /etc/init.d/
ADD ./src/bin/nginx /etc/init.d/

VOLUME ["/conf", "/srv"]

RUN mv /usr/local/webserver/nginx/conf/nginx.conf /usr/local/webserver/nginx/conf/nginx.conf-bak
RUN mv /etc/supervisord.conf /etc/supervisord.conf-default
RUN mv /etc/my.cnf /etc/my.cnf-default

RUN ln -s /conf/nginx.conf /usr/local/webserver/nginx/conf/
RUN ln -s /conf/supervisord.conf /etc/supervisord.conf
RUN ln -s /conf/redis.conf /usr/local/webserver/redis/
RUN ln -s /conf/my.cnf /etc/my.cnf

CMD ["/usr/bin/supervisord"]

EXPOSE 80
