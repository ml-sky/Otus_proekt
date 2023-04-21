#!/bin/bash

#Логин и пароль сохранены в my.cnf
echo "*************************************************************"
echo "Для работы данного скрипта логин и пароль для доступа в MYSQL должны быть сохранены в my.cnf"
echo "*************************************************************"
DIR_BACKUP="/var/backup_mysql" #Путь куда будут сохранятся бекапы
DATE=`date +"%Y-%m-%d_%H:%M"` #Для создания каталогов с текущей датой и временем

mysql -e "STOP SLAVE;" #Остановка SLAVE

#Присвоение переменной mysql_backup выполнение команды в баше с выводом названий всех баз
mysql_backup=$(mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|sys)")

#Присвоение переменной mysql_table выполнение команды для доступа к сервису MYSQL
mysql_table="mysql --skip-column-names";

#Цикл для db для поиска в выводе команды mysql_backup
for db in $mysql_backup; 
	do
        echo "BACKUP_database: $db" #вывод сообщения на экран с названием БД
		mkdir -p $DIR_BACKUP/$DATE; #Создание каталога с текущей датой и временем
		mkdir -p $DIR_BACKUP/$DATE/$db; #Создание отдельного каталога с названием БД в каталоге с текущей датой и временем
		
#Цикл для t , потабличный бекап с сохранением позиции бинлога.
	for t in $($mysql_table -e "SHOW TABLES FROM $db"); 
		do 
        mysqldump --force --opt $db $t --events --routines  --single-transaction --master-data=2  > $DIR_BACKUP/$DATE/$db/$t.sql #Команда mysqldump с сохранением в DIR_BACKUP
	done
	
done

mysql -e "START SLAVE;" #Запуск SLAVE
