#!/bin/bash
# 一键部署github-pages，包括更新bundle依赖、运行jekyll服务、git提交与push。
# 保存当前目录
currentDir=$PWD
echo "Start to publish..."
# 切换到FLHonker.github.io目录
cd /home/frank/Study/FLHonker.github.io/
if [ -z "$1" ]
then
    echo "Usage: $0 message [-u]"
fi
# bundle更新与生成
if [ "$2" == "-u" ]; then
    bundle update
fi
bundle exec jekyll build
# 执行git命令
git add .
git commit -m ""$1""
git push origin master
# 切换回原来目录
cd $currentDir
echo ""
# echo -e "\033[42;37m Frank Blog update online! \033[0m"
echo "Frank Blog update online!"
