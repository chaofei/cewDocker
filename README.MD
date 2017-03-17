#初始化项目目录 根据实际的路径修改docker-compose.yaml文件
mkdir -p /usr/local/cew/
cp -r conf /usr/local/cew/
cp -r srv /usr/local/cew/

##创建镜像前，最好提前把200M大小的centos:6.6镜像文件上传到服务器上

#创建镜像
docker build -t cew:1.0 .

#创建容器
docker-compose up -d 

#进入容器
docker exec -it cew_web_1 bash

#进入mysql 命令交互模式
/usr/local/webserver/mysql/bin/mysql

#创建数据库
create database cew;

#添加mysql用户
CREATE USER 'ceweb'@'localhost' IDENTIFIED BY '123456';
#授权mysql用户
GRANT ALL ON *.* TO 'ceweb'@'localhost';
#刷权限
flush privileges;

