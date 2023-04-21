#!/bin/bash

#Присвоение переменным
HOST="192.168.8.16"
PASS_MASTER="mysqlSlave2023#"
PORT_MASTER="3306"
USER="repl"
PORT="3306"
PASS_SLAVE="Testpass1$"

#Проверка статуса SLAVE , должно быть 2 если нет то дольше условие if
COL=$(/usr/bin/mysql -h 127.0.0.1 -P $PORT -e 'show slave status\G' | grep Running | grep Yes | wc -l)


if [ $COL -ne 2 ] ; then
# остановка слейва
/usr/bin/mysql -h 127.0.0.1 -P $PORT -p$PASS_SLAVE -e 'stop slave'
# сброс слейва
/usr/bin/mysql -h 127.0.0.1 -P $PORT -p$PASS_SLAVE -e 'reset slave'
# смотрим имя файла и позицию на мастере
FILE=$(mysql -h $HOST -P $PORT_MASTER -u repl -p$PASS_MASTER -e 'show master status' | grep -v File | awk ' {print $1}')
POS=$(mysql -h $HOST -P $PORT_MASTER -u repl -p$PASS_MASTER -e 'show master status' | grep -v File | awk ' {print $2}')
# настройка слейва
/usr/bin/mysql -h 127.0.0.1 -P $PORT -p$PASS_SLAVE -e "CHANGE MASTER TO MASTER_HOST = '$HOST', MASTER_USER = '$USER', MASTER_PASSWORD = '$PASS_MASTER', MASTER_LOG_FILE = '$FILE', MASTER_LOG_POS = $POS"
# старт слейва
/usr/bin/mysql -h 127.0.0.1 -P $PORT -p$PASS_SLAVE -e 'start slave'
fi