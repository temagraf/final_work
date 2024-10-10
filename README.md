# Дипломная работа по профессии "DEV-OPS" FOPS-22 Яковлев А.Г.
## "Создание инфраструктуры в облаке"


## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности.



### 1. Для выполнения задания был написан файл Terraform [main.tf](https://github.com/temagraf/final_work/blob/main/main.tf) для создания следующих ресурсов:
 
### 1.1. Виртуальные машины 
  - nginx1 
  - nginx2 
  - zabix 
  - elasticsearc
  - kibana
  - bastion


<details>
<summary> Скриншот(-ы) </summary>

![список вм](https://github.com/temagraf/final_work/blob/main/img/VM_list.png)

</details>


### 1.2. Балансировщик нагрузки для вебсерверов

<details>
<summary> Скриншот(-ы) </summary>

![балансировщик](https://github.com/temagraf/final_work/blob/main/img/alb.png)

</details>


### 1.3. Группы безопасности для ограничения доступности хостов по определенным портам
  - nginx-sg (nginx1-2 разрешен доступ через балансировщик на порты 22, 80, 10050)
  - zabbix-sg  (разрешен доступ на порты 22, 8080, 10051)
  - elastic-sg (разрешен доступ на порты 22, 10050, 9200)
  - kibana-sg (разрешен доступ на порты 22, 10050, 5601)
  - bastion-sg (разрешен доступ на 22 порт)

<details>
<summary> Скриншот(-ы) </summary>

![группы безопасности](https://github.com/temagraf/final_work/blob/main/img/security_groups.png)

</details>

### 1.4. Расписание создания снапшотов дисков со всех виртуальных машин
  - создано расписание на ежедневное создание снапшотов в 20:00 по московскому времени
  - хранение снапшотов 7 дней


<details>
<summary> Скриншот(-ы) </summary>

![снимки дисков](https://github.com/temagraf/final_work/blob/main/img/schedule.png)

</details>


### 1.5. Сеть и 4 подсети в разных зонах доступности для обеспечения отказоустойчивости.
#### Pаспределение ВМ в сети:
  - nginx1 (зона а, приватная сеть, имеет внутренний IP 192.168.1.11)
  - nginx2 (зона b, приватная сеть, имеет внутренний IP 192.168.2.22)
  - zabix (зона c, публичная сеть, имеет внутренний IP 192.168.3.33 и внешний IP <назначается автоматически> )
  - elasticsearc (зона d, приватная сеть, имеет внутренний IP 192.168.4.44)
  - kibana (зона c, публичная сеть, имеет внутренний IP 192.168.3.34 и внешний IP <назначается автоматически> )
  - bastion (зона c, публичная сеть, имеет внутренний IP 192.168.33.33 и внешний IP <назначается автоматически> )

<details>
<summary> Скриншот(-ы) </summary>

![Карта сети](https://github.com/temagraf/final_work/blob/main/img/network1.png)

</details>


### 1.6. Шлюз (для доступа в интернет ВМ расположенных в приватных сетях)

<details>
<summary> Скриншот(-ы) </summary>

![Карта сети](https://github.com/temagraf/final_work/blob/main/img/network_map.png)

</details>




## 2. Установка необходимых программ для подготовленной инфраструктуры осуществлялась с помощью плэйбуков через Ansible:

*Ansible настроен на Bastion host и вся установка происходит с него.

### 2.1. [inventory.ini](https://github.com/temagraf/final_work/blob/main/ansible/inventory.ini)
  - содержит список удаленных хостов для подключения к ним и установки необходимых программ

### 2.2. [ping_pb.yml](https://github.com/temagraf/final_work/blob/main/ansible/ping_pb.yml) (был добавлен для удобства)
  - проверяет доступность хостов

<details>
<summary> Скриншот(-ы) </summary>

![пинг](https://github.com/temagraf/final_work/blob/main/img/ping.png)

</details>

### 2.3. [nginx_pb.yml](https://github.com/temagraf/final_work/blob/main/ansible/nginx_pb.yml) 
  - устанавливает nginx на две виртуальные машины состоящие в группе web_servers
  - копирует c локального хоста страницу для отображения при обращении на ip адрес балансировщика. 
*Проверка работоспособности [тут](http://158.160.144.65:80)

<details>
<summary> Скриншот(-ы) </summary>

![установка nginx](https://github.com/temagraf/final_work/blob/main/img/install_nginx.png)
![веб страница](https://github.com/temagraf/final_work/blob/main/img/web_page.png)

</details>


### 2.4. [zabbix_pb.yml](https://github.com/temagraf/final_work/blob/main/ansible/zabbix_pb.yml)
  - добавляет репозиторий zabbix
  - устанавливает на хост zabbix -  zabbix server, zabbix agent, mysql, nginx и прочие зависимости
  - создает базу данных, пользователя, задает пароль

<details>
<summary> Скриншот(-ы) </summary>

![установка zabbix](https://github.com/temagraf/final_work/blob/main/img/install_zabbix_server.png)
![установка zabbix](https://github.com/temagraf/final_work/blob/main/img/finish_install_zabbix.png)

</details>


### 2.5. [zabbix_agent_pb.yml](https://github.com/temagraf/final_work/blob/main/ansible/zabbix_agent_pb.yml)
  - добавляет репозиторий zabbix
  - устанавливает zabbix agent на все хосты
  - вносит корректировку в файл конфигурации  
*Ссылка на админку [zabbix](http://51.250.33.162:8080)

<details>
<summary> Скриншот(-ы) </summary>

![установка zabbix-agent](https://github.com/temagraf/final_work/blob/main/img/install_zabbix_agent.png)
![установка zabbix-agent](https://github.com/temagraf/final_work/blob/main/img/enable_zabagent.png)
![установка zabbix-agent](https://github.com/temagraf/final_work/blob/main/img/dashboard_zabbix.png)

</details>


### 2.6. [elasticsearch_pb.yml](https://github.com/temagraf/final_work/blob/main/ansible/elasticsearch_pb.yml)
  - скачивает и добавляет ключ gpg elasticsearch
  - добавляет репозиторий elasticsearch 8.x
  - устанавливает elasticsearch и зависимости
  - корректирует конфигурационный файл
  - выводит на экран пароль пользователя и токен для подключения kibana

<details>
<summary> Скриншот(-ы) </summary>

![установка elastic](https://github.com/temagraf/final_work/blob/main/img/install_elastic.png)
![установка elastic](https://github.com/temagraf/final_work/blob/main/img/elastic_status.png)
![установка elastic](https://github.com/temagraf/final_work/blob/main/img/password_token.png)

</details>

### 2.7. [kibana_pb.yml](https://github.com/temagraf/final_work/blob/main/ansible/kibana_pb.yml)
  - скачивает и добавляет ключ gpg elasticsearch
  - добавляет репозиторий elasticsearch 8.x
  - устанавливает kibana и зависимости
  - корректирует конфигурационный файл
  - выводит на экран 6-ти значный код для подтверждения подключения к elastic  
*Ссылка на админку [kibana](http://51.250.36.99:5601)

<details>
<summary> Скриншот(-ы) </summary>

![установка kibana](https://github.com/temagraf/final_work/blob/main/img/install_kibana.png)
![статус kibana](https://github.com/temagraf/final_work/blob/main/img/kibana_status.png)
![подключение kibana](https://github.com/temagraf/final_work/blob/main/img/check_code.png)
![веб kibana](https://github.com/temagraf/final_work/blob/main/img/kibana_web.png)

</details>

### 2.8. [filebeat_pb.yml](https://github.com/temagraf/final_work/blob/main/ansible/filebeat_pb.yml)
  - скачивает и добавляет ключ gpg elasticsearch
  - добавляет репозиторий elasticsearch 8.x
  - устанавливает filebeat и зависимости
  - копирует с локального хоста конфигурационный файл  
*Для подключения filebeat к elasticsearh перед запуском плейбука необходимо указать пароль для авторизации в файле ./filebeat_conf/filebeat.yml 

<details>
<summary> Скриншот(-ы) </summary>

![установка filebeat](https://github.com/temagraf/final_work/blob/main/img/install_filebeat.png)
![установка filebeat](https://github.com/temagraf/final_work/blob/main/img/filebeat_status.png)
![установка filebeat](https://github.com/temagraf/final_work/blob/main/img/filebeat_web.png)

</details>



### Инфраструктура готова к эксплуатации.
