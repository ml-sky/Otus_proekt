ReadME Для проектной работы Otus_admBasic

На подготовленную систему (предварительно настроены сеть,firewall,пользователи) необходимо установить следующие компоненты:
	- Система контроля версий Git;
	- СУБД MySQL;
	- СУБД MySQL на slave сервер для репликации;
	- Web server Nginx, Apache;
	- Система логирования ELK stack (Elasticsearch, Logstash и Kibana);
	- Система мониторинга Prometeus+Grafana на docker_compose;
Установка статического ip:
Основной сервер 192.168.8.25 CentOs
SLAVE сервер для репликации 192.168.8.26 CentOs
ELK сервер 192.168.8.27 Ubuntu


Инструкция:

	#Для CentOS/RHat
	sudo yum update
	#Установка Git
	sudo yum install git -y
	#Подключение удаленного репо с GITHUB (подразумевается что ключ ssh уже настроен)
	git clone git@github.com:ml-sky/Otus_proekt.git
	
	
	1.  #Установка MySQL
		# Установка репозитория Oracle MySQL 8.0 (Для CentOs 7)
		sudo rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-7.noarch.rpm
		# Включаем репозиторий
		sudo sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
		# Устанавливаем MySQL
		yum --enablerepo=mysql80-community install mysql-community-server
		# Запускаем MySQL
		sudo systemctl start mysqld
		# Ставим в автозагрузку
		sudo systemctl enable mysqld
		#Узнаем временный пароль 
		grep "A temporary password" /var/log/mysqld.log
		#Запускаем скрипт безопасности для MySQL и устанавливаем постоянный пароль для пользователя root
		mysql_secure_installation
		
		
	1.1 #Для репликации используем второй сервер с установленным MySQL, для установки читаем пункт 1
	
	
	1.2 #Настройка репликации MASTER-SLAVE
		1.2.1 #На обоих серверах необходимо прописать в конец файла /etc/my.cnf логин и пароль от root пользователя в виде
			  [client]
			  user=root
			  password=password
			  #Если на серверах MASTER-SLAVE не настроен файрволл то его необходимо выключить, либо настроить.
		1.2.2 #Настройка master сервера(Заходим в mysql)
			  #Создаём пользователя для реплики
			  CREATE USER repl@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'mysqlSlave2023#'; 
			  #Даём ему права
			  GRANT ALL PRIVILEGES ON *.* TO repl@'%';
			  #Закрываем и блокируем все таблицы
			  FLUSH TABLES WITH READ LOCK;
			 
		1.2.3 #Настройка SLAVE сервера
			  #Для slave сервера меняем имя хоста
			   sudo hostnamectl set-hostname proekt_slave
			  #Переходим на slave сервер и добавляем server_id
			   sudo nano /etc/my.cnf
				  server_id = 2
			   systemctl restart mysqld
			  #Если клонировали машину с мастера, обновляем auto.cnf
			   rm /var/lib/mysql/auto.cnf
			   systemctl restart mysqld
			 
		
		1.2.4 #На настроенном SLAVE сервере запустить скрипт с GITHUB repl.sh
			  #Проверить статус репликации (в mysql) 
			  show slave status\G
		
	1.3 #Настройка потабличного бекапа с указанием позиции binlog
		1.3.1 #Запустить скрипт на slave сервере backup_mysql-complete.sh c GITHUB и проверить бекапы в /var/backup_mysql
	
	
	2.  #Установка Nginx и Apache
		 #Для тестирования выключаем SELinux испольуем скрипт bash_hw.sh с GITHUB
		 #Установка репозитория EPEL
		 sudo yum install epel-release
		 #Установка Nginx
		 sudo yum install nginx
		 #Установка Apache
		 sudo yum install httpd
		 #Запуск Nginx
		 sudo systemctl start nginx
		 #Автозапуск Nginx
		 sudo systemctl enable nginx
		 #Проверка статуса
		 sudo systemctl status nginx
		 #Меняем порт Listen 8080 в конфиге /etc/httpd/conf/httpd.conf
		 #Запуск Apache
		 sudo systemctl start httpd
		 #Автозапуск Apache
		 sudo systemctl enable httpd
		 #Проверка статуса
		 sudo systemctl status httpd
	2.1 #Настройка балансировки на примере Joomla
		
		2.1.1 #Установка необходимых компонентов для CMS Joomla
			  #Установка PHP
			  sudo yum install php
			  sudo yum install php-mysql
			  sudo yum install php-gd php-mcrypt php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-soap curl curl-devel
			  #MySQL и связка nginx+apache должны быть уже установлены (Пункты 1 и 2)
		
		2.1.2 #Настройка MySQL под Joomla (Если необходим сторонний пользователь)
			  #Создание БД под Joomla
			  CREATE DATABASE joomladb;
			  #Создание пользователя для работы с БД joomladb
			  CREATE USER 'joomlauser'@'localhost' IDENTIFIED BY 'сюда придумываем пароль';
			  #Выдаем права на БД joomladb
			  GRANT ALL PRIVILEGES ON joomladb.* TO 'joomlauser'@'localhost';
			  Сохраняем права:
			  FLUSH PRIVILEGES;
			  #Если будут проблемы с подлючением joomla к БД то необходимо отредактировать пользователя
			  ALTER USER 'joomlauser'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'пароль joomlauser';
			  ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'пароль от root';
		
		2.1.3 #Установка Joomla (этап 1)
			  #Установка (если не установлены) unzip, wget, nano
			  sudo yum install wget unzip nano -y
			  #Скачиваем Joomla_3.7.2-Stable-Full_Package.zip и переходим в каталог( тут в /tmp)
			  cd /tmp
			  #Создаем каталог для сайта
			  mkdir -p /var/www/html/joomla
			  #Распаковываем архим joomla в каталог для сайта
			  sudo unzip -q Joomla_3.7.2-Stable-Full_Package.zip -d /var/www/html/joomla
			  #Выдаем права на каталог для редактирование под текущим пользователем:
			  sudo chown -R $USER:$USER /var/www/html/joomla
			  sudo chmod -R 755 /var/www/html/joomla
		
		2.1.4 #Настройка конфигов и балансировки web сервера nginx+apache
			  #Настройка конфигурации nginx
			  #Копируем конфиг nginx.conf с GITHUB в каталог /etc/nginx с заменой, из папки conf.d удаляем все дефолтные конфиги (если есть)
			  cd ~
			  sudo cp Otus_proekt/configs/nginx.conf /etc/nginx/
			  #Проверяем конфигурацию nginx
			  sudo nginx -t
			  #Копируем конфиг virt.conf с GITHUB в каталог /etc/httpd/conf.d
			  sudo cp Otus_proekt/configs/virt.conf /etc/httpd/conf.d
			  #Копируем конфиг httpd.conf с GITHUB в каталог /etc/httpd/conf/ с заменой
			  sudo cp Otus_proekt/configs/httpd.conf /etc/httpd/conf/
			  #Перезапускаем nginx+apache (SELinux должен быть отключен!)
			  sudo systemctl restart httpd
			  sudo systemctl restart nginx
		
		2.1.5 #Установка Joomla (этап 2)
			  #Заходим по ссылке 192.168.8.25:8080
			  #Вводим все необходимые данные и задаем логин/пароль администратора Joomla
			  #Тип базы данных MySQL
			  #Имя сервера БД localhost
			  #Имя пользователя joomlauser либо root если не создавали
			  #Пароль от joomlauser либо пароль от root
			  #Префикс таблиц быз изменений
			  #Далее все по умолчанию
			  #При завершении установки удаляем папку installation
			  sudo rm -rf /var/www/html/joomla/installation
			  #Создаем файл configuration.php в корне сайта содержимое копируем из файла с Git (либо копируем с GITHUB) 
			  sudo nano /var/www/html/joomla/configuration.php
			  cp Otus_proekt/joomla/configuration.php /var/www/html/joomla/ #Проверяем логин и пароль к БД!
			  #Также с GitHUB копируем с заменой файл phpversioncheck.php в каталог /var/www/html/joomla/plugins/quickicon/phpversioncheck
			  cp Otus_proekt/joomla/phpversioncheck.php /var/www/html/joomla/plugins/quickicon/phpversioncheck/
			  #Проверяем работу, панель администратора по ссылке http://192.168.8.25:8080/administrator/
	
	
	3. #Настройка мониторинга сервера (Prometheus+grafana в docker compose)
		
		3.1.1 #Установка docker
			  yum install -y yum-utils
			  yum-config-manager \
              --add-repo \
              https://download.docker.com/linux/centos/docker-ce.repo
			  yum install docker-ce docker-ce-cli containerd.io
			  #Запуск docker
			  systemctl start docker
			  systemctl enable docker
			  #Проверим статус
			  systemctl status docker
		
		3.1.2 #Установка docker compose
			  Переходим на страницу github.com/docker/compose/releases/latest и смотрим последнюю версию docker-compose на момент написания инструкции 2.17.2
			  COMVER=2.17.2
			  curl -L "https://github.com/docker/compose/releases/download/v$COMVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
			  #Даем права файлу на исполнение
			  chmod +x /usr/bin/docker-compose
			  #Проверяем
			  docker-compose --version
		
		3.1.3 #Подготовка и настройка Prometheus + Node Exporter + Grafana
			  #Создаем каталоги, где будем создавать наши файлы:
			  mkdir -p /opt/prometheus_stack/{prometheus,grafana}
			  #Переходим в каталог prometheus_stack и копируем туда с GITHUB файл docker-compose.yml
			  cd /opt/prometheus_stack 
			  cp /root/Otus_proekt/configs/docker-compose.yml /opt/prometheus_stack/
			  #Переходим в каталог prometheus и копируем туда с GITHUB файл prometheus.yml
			  cp /root/Otus_proekt/configs/prometheus.yml /opt/prometheus_stack/prometheus/
			  #Запускаем контейнеры находясь в cd /opt/prometheus_stack 
			  docker-compose up -d
			  #Проверяем Prometheus 192.168.8.25:9090 + Node Exporter 192.168.8.25:9100 + Grafana 192.168.8.25:3000
			  #В Grafana настраиваем Data source http://prometheus:9090
			  #Import Dashboard 1860
			  #Перезапуск всех сервисов
			  docker-compose up -d --no-deps --build
	
	4. #Настройка ELK на Ubuntu server 22.04
		
		4.1.1 #Обновляем apt
			  sudo apt update
			  sudo apt upgrade
			  #Скачиваем с yandexDiSK https://disk.yandex.ru/d/Hn-w4MGbxok_OA в предварительно созданную папку /root/DEB ELK
		
		4.1.2 #Установка ELK
			  cd /root/DEB/
			  dpkg -i *.deb
			  #Установка Java
			  apt install default-jdk
			  #Разрешаем автозапуск elasticsearch
			  systemctl enable elasticsearch --now
			  #Смена пароля Elasticsearch
			  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
			  #Разрешаем автозапуск и перезапускаем logstash
			  systemctl enable logstash
			  #Разрешаем автозапуск и перезапускаем kibana
			  systemctl enable kibana
			  #Берем конфиг с GITHUB kibana.yml и меняем в /etc/kibana/kibana.yml
			  systemctl restart kibana
			  #Открываем 192.168.8.27:5601
			  #Переходим на сервер и получаем токен
			  /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
			  #Получаем код
			  /usr/share/kibana/bin/kibana-verification-code
			  #Настройка logstash
			  #Берем конфиги input, output, filter с GITHUB и копируем в /etc/logstash/conf.d/
			  cp Otus_proekt/configs/input.conf /etc/logstash/conf.d/
			  cp Otus_proekt/configs/output.conf /etc/logstash/conf.d/
			  cp Otus_proekt/configs/filter.conf /etc/logstash/conf.d/
			  #В конфиге output меняем пароль к Elasticsearch (который был после установки Elasticsearh)
			  systemctl restart logstash
			  #Проверка конфигурации Logstash
			  /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
		
		4.1.3 #Настройка filebeat на основной сервер
			  #Скачиваем с GITHUB filebeat-8.7.0-x86_64.rpm
			  rpm -ivh filebeat-8.7.0-x86_64.rpm
			  #Получаем с GITHUB filebeat.yml и заменяем в /etc/filebeat
			  cp Otus_proekt/configs/filebeat.yml /etc/filebeat/
			  #Разрешаем автозапуск filebeat и перезапускаем сервис
			  systemctl enable filebeat
			  systemctl restart filebeat
		
		4.2 #Проверяем работу ELK и получение логов с основного сервера 
		логин elastic 
		пароль указанный после установки либо командой меняем 
		/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
			#Добавляем index (разделе Analytics переходим в Discover)
	
