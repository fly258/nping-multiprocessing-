#!/bin/sh
#20190826
#write for test tcping
# Version:     3.0
#fly
bash=$(cd "$(dirname "$0")"; pwd)
cd `echo ${bash}`
source /etc/profile

cur_time=`date +%Y%m%d%H%M`             ##定义log时间
touch ./log/icmpping_end_"$cur_time".txt  ##创建log文件
logfile=./log/icmpping_end_"$cur_time".txt


tmp_fifofile="/tmp/$$.fifo"               ##其中$$为该进程的pid
mkfifo $tmp_fifofile                      ##创建命名管道
exec 6<>$tmp_fifofile                     ##把文件描述符6和FIFO进行绑定
rm -f $tmp_fifofile                       ##绑定后，该文件就可以删除了
thread=20                                 ## 进程并发数为30，用这个数字来控制一次提交的请求数
awk '{print FNR" "$0}' ip_ning > ip_ning_new  ## 测试ip文本前面添加序号

    for ((i=0;i<$thread;i++));
    do
        echo >&6                              ##写一个空行到管道里，因为管道文件的读取以行为单位
    done


    while read   NUM DESTIP DESTPORT
    do
          ##读取管道中的一行,每次读取后，管道都会少一行
        read -u6
        {        a_sub || {echo "a_sub is failed"}
        ##进程并发的nping测试
        echo  "$DESTIP" "$DESTPORT" >> aa_$NUM
        nping  --tcp -c10 -p $DESTPORT  $DESTIP  > bb_$NUM
        cat bb_$NUM |gawk -F "|" '/Max/{print $3}' |gawk -F " " '{print $3}' >>      aa_$NUM
        cat bb_$NUM |sed 's#(#/#g'|sed 's#)#/#g'|gawk -F "/" '/packets/ {print $6}' >> aa_$NUM
        echo "" >> aa_$NUM
        awk '{if($0 !~ /^$/)printf "%s ",$0;else print}' aa_$NUM >> $logfile
        rm -rf aa_$NUM bb_$NUM

                   echo >&6              ##每次执行完a_sub函数后，再增加一个空行，这样下面的进程才可以继续执行
        } &
    done < ip_ning_new

wait                                     ##这里的wait意思是，需要等待以上所有操作（包括后台的进程）都结束后，再往下执行。

exec 6>&-                                ##关闭文件描述符6的写

##统计logfile的信息
sleep  5
rm -rf aa_* bb_*
echo HBdx-s130_$cur_time >> a.txt
cc=`cat $logfile | awk '{print $4}'|grep -v ^100.00 | wc -l`
cat $logfile | awk '{print $3}' | grep ms | awk '{sum += $1;} END { print "time delay average = "sum/NR}' >> a.txt
cat $logfile | awk '{print $4}' | grep -v ^0.00 |grep -v ^100.00 |awk '{sum += $1;} END { print "Packet loss average = "sum/'$cc'}' >> a.txt
cat $logfile | grep "N/A" | wc -l >> a.txt
rm -rf ./tmp
