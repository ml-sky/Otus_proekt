#!/bin/bash

source /etc/selinux/config #Для чтения параметра SELINUX из конфига

status=$(getenforce) #Проверка статуса Selinux и присвоение результата команды переменной

#Manual
if [ "$1" == "man" ] 
then echo "********************************************************"
	  echo "Скрипт рекомендуется запускать только из sudo пользователя."
	  echo "Данный скрипт позволяет включать/выключать систему Selinux в текущем сеансе через команду setenforce 0/1,до перезагрузки системы (требуются sudo права)"
	  echo "Также скрипт позволяет активировать/деактивировать систему Selinux через редактирования конфига(требуются sudo права)."
	  echo "В данном случае для применения изменений потребуется перезагрузка системы!!!"
	  echo "Скрипт проверяет значение SELINUX в конфиге и взависимости от этого предлагает пользователю его поменять"
	  echo "E-enforcing, P-permissive, D-disabled"
	  echo "'enforcing' - Selinux активирован в конфиге."
	  echo "'permissive' - Selinux работает в режиме предупреждений."
	  echo "'disabled' - Selinux деактивирован в конфиге."
	  echo "********************************************************"
     exit 1
fi

#Проверка запуска скрипта от sudo пользователя или root
if [ "$UID" != "0" ]
then echo "Скрипт необходимо запускать из под sudo или root, запустите скрипт с sudo или под root"
	 echo "Для справки используйте аргумент 'man'(Например ./script man)"
     exit 1
else echo "Вы можете использовать данный скрипт, продолжаем..."
	 echo "Для справки используйте аргумент 'man'(Например ./script man)"
	 echo
fi

#Первый if если Selinux включен
if [ "$status" = "Enforcing" ]
then echo "Selinux включен." && echo "Отключить Selinux? (y/n)" #Если selinux включен ,далее диалог с пользователем
	 read item
	 case "$item" in
		y|Y) echo "Вы ввели 'y', Selinux выключен" && setenforce 0
			;;
		n|N) echo "Вы ввели 'n', Selinux остался запущенным"
		    ;;
		*)   echo "Вы не ввели 'y' или 'n'"
			;;
	 esac
fi
 
#Второй if если Selinux деактивирован в конфиге
if [ "$status" = "Disabled" ]
then echo "Selinux деактивирован полностью." && echo "Активировать Selinux в конфиге? (y/n),Потребуется перезагрузка системы" #Активация selinux в конфиге
     read item
	 case "$item" in
		y|Y) sed -i 's/SELINUX=disabled/SELINUX=enforcing/gi' /etc/selinux/config && echo "Ввели 'y', Selinux активирован" #Меняем значение disabled на enforcing
			;;
		n|N) echo "Ввели 'n', Selinux остался деактивированным"
			;;
		*)   echo "Вы не ввели 'y' или 'n'"
			;;
	 esac
	 echo "Перезапусить систему (y/n)?" #Предложение перезапустить ОС
	 read item2
	 case "$item2" in
		y|Y) echo "Ввели 'y', Перезагрузка системы" && shutdown -r now
			;;
		n|N) echo "Ввели 'n'. Для активации Selinux необходимо перезагрузить ОС"
		   	;;
		*)   echo "Вы не ввели 'y' или 'n'"
			;;
	 esac
fi

#Третий if ,если Selinux выключен, но работает в режиме Permissive
if [ "$status" = "Permissive" ]
then echo "Selinux деактивирован (работает в режиме Permissive)" && echo -n "Включить Selinux? (y/n)" #Если selinux выключен, далее диалог с пользователем
	 read item
	 case "$item" in
		y|Y) setenforce 1 && echo "Ввели "y", Selinux включен"
			;;
		n|N) echo "Ввели 'n', Selinux остался деактивированным"
			;;
		*)   echo "Вы не ввели 'y' или 'n'"
			;;
	 esac
fi


echo

echo  "Статус SELINUX в конфиге $SELINUX" #Вывод статуса SELINUX из конфига

#Проверяем значение параметра Selinux в конфиге через if
if [ "${SELINUX,,}" = "enforcing" ] || [ "${SELINUX,,}" = "permissive" ] || [ "${SELINUX,,}" = "disabled" ] 
   then
    echo "Вы хотите поменять значение SELINUX в конфиге? (y/n)? Изменения вступят в силу после перезагрузки системы" #Диалог с пользователем
		read item
	 case "$item" in
		y|Y) echo "Продолжаем..."
			;;
		n|N) echo "Значение осталось не изменным"
		     exit 1
			;;
		*)   echo "Вы не ввели 'y' или 'n'"
			 exit 1
			;;
	 esac
	 echo "На какой значение Вы хотите изменить E-enforcing,P-permissive,D-disabled ?" # Изменение значения в конфиге
		read item2
	 case "$item2" in
		e|E) sed -i '/#/b;s/SELINUX=.*/SELINUX=enforcing/gi' /etc/selinux/config && echo "Вы ввели 'E', меняем значение на 'enforcing'"
		;;
		p|P) sed -i '/#/b;s/SELINUX=.*/SELINUX=permissive/gi' /etc/selinux/config && echo "Вы ввели 'P', меняем значение на 'permissive'" 
		;;
		d|D) sed -i '/#/b;s/SELINUX=.*/SELINUX=disabled/gi' /etc/selinux/config && echo "Вы ввели 'D', меняем значение на 'disabled'"
		;;
		*)   echo "Вы не ввели 'E' или 'P' или 'D'"
		         exit 1
		;;
	 esac
	 echo "Перезапусить систему (y/n)?" #Предложение перезапустить ОС
	 read item2
	 case "$item2" in
		y|Y) echo "Ввели 'y', Перезагрузка системы" && shutdown -r now
			;;
		n|N) echo "Ввели 'n'. Для применения изменений необходимо перезагрузить ОС"
		   	;;
		*)   echo "Вы не ввели 'y' или 'n'"
			 exit 1
			;;
	 esac
 fi
 
