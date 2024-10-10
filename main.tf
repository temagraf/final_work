terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.key_id
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}


//____________________VM-1_(NGINX-1)____________________________________
resource "yandex_compute_instance" "vm-1" {
  name = "nginx1"
  platform_id = "standard-v3"
  zone = "ru-central1-a"
  hostname = "nginx1"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = false
    ip_address = "192.168.1.11"
    security_group_ids = [yandex_vpc_security_group.nginx-sg.id]
  }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

//_____________________VM-2__(NGINX-2)__________________________________
resource "yandex_compute_instance" "vm-2" {
  name = "nginx2"
  platform_id = "standard-v3"
  zone = "ru-central1-b"
  hostname = "nginx2"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    nat       = false
    ip_address = "192.168.2.22"
    security_group_ids = [yandex_vpc_security_group.nginx-sg.id]
  }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

//______________________VM-3_(ZABBIX)__________________________________
resource "yandex_compute_instance" "vm-3" {
  name = "zabbix"
  platform_id = "standard-v3"
  zone = "ru-central1-c"
  hostname = "zabbix"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-3.id
    nat       = true
    ip_address = "192.168.3.33"
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
  }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

//______________________VM-4_(ELASTICSEARCH)______________________________
resource "yandex_compute_instance" "vm-4" {
  name = "elastic"
  platform_id = "standard-v3"
  zone = "ru-central1-d"
  hostname = "elastic"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-4.id
    nat       = false
    ip_address = "192.168.4.44"
    security_group_ids = [yandex_vpc_security_group.elastic-sg.id]
  }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

//_________________________VM-5_(KIBANA)_____________________________________
resource "yandex_compute_instance" "vm-5" {
  name = "kibana"
  platform_id = "standard-v3"
  zone = "ru-central1-c"
  hostname = "kibana"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-3.id
    nat       = true
    ip_address = "192.168.3.34"
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

//______________________VM-6_(BASTION)________________________________________
resource "yandex_compute_instance" "vm-6" {
  name = "bastion"
  platform_id = "standard-v3"
  zone = "ru-central1-c"
  hostname = "bastion"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd855o9p0a32dtp1uf17"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-3.id
    nat       = true
    ip_address = "192.168.33.33"
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
  }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}



//_________________________TARGET_GROUP___________________________________________
resource "yandex_alb_target_group" "ngx-target-group" {
  name      = "ngx-target-group"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    ip_address   = "${yandex_compute_instance.vm-2.network_interface.0.ip_address}"
  }
}

//______________________BACKEND_GROUP__________________________________________________
resource "yandex_alb_backend_group" "nginx-backend-group" {
  name      = "nginx-backend-group"

  http_backend {
    name = "backend-1"
    weight = 1
    port = 80
    target_group_ids = [yandex_alb_target_group.ngx-target-group.id]
    
    load_balancing_config {
      panic_threshold = 0
    }    
    healthcheck {
      timeout = "1s"
      interval = "3s"
      healthy_threshold    = 2
      unhealthy_threshold  = 2 
      healthcheck_port     = 80
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

//_______________________HTTP-ROUTER_________________________________________
resource "yandex_alb_http_router" "nginx-router" {
  name      = "nginx-router"
}

//______________________ВИРТУАЛЬНЫЙ__ХОСТ____________________________________
resource "yandex_alb_virtual_host" "ngx-virtual-host" {
  name                    = "ngx-virtual-host"
  http_router_id          = yandex_alb_http_router.nginx-router.id
  route {
    name                  = "ngx-route"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.nginx-backend-group.id
      }
    }
  }
}    

//________________________Балансер_____________________________________________
resource "yandex_alb_load_balancer" "nginx-balancer" {
name        = "nginx-balancer"
  network_id  = yandex_vpc_network.network-1.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id 
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id 
    }
    location {
      zone_id   = "ru-central1-c"
      subnet_id = yandex_vpc_subnet.subnet-3.id 
    }
    location {
      zone_id   = "ru-central1-d"
      subnet_id = yandex_vpc_subnet.subnet-4.id 
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.nginx-router.id
      }
    }
  }
}  




//_______________ ГРУППЫ БЕЗОПАСНОСТИ________________
//_________________БАСТИОН________________________
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "access via ssh"
  network_id  = "${yandex_vpc_network.network-1.id}"  
  ingress {
      protocol          = "TCP"
      description       = "ssh-in"
      port              = 22
      v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      protocol          = "ANY"
      description       = "any for basion to out"
      from_port         = 0
      to_port           = 65535
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
}



//________________nginx_____________________
resource "yandex_vpc_security_group" "nginx-sg" {
  name        = "nginx-sg"
  description = "rules for nginx"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.33.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["192.168.3.0/24"] 
  }

  ingress {
    description = "Health checks from NLB"
    protocol = "TCP"
    predefined_target = "loadbalancer_healthchecks" 
  }


  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

//__________________ZABBIX_server_____________________
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  description = "rules for zabbix"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "8080"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.33.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10051"
    v4_cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24", "192.168.4.0/24"] 
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

//____________ELASTIC__________________
resource "yandex_vpc_security_group" "elastic-sg" {
  name        = "elastic-sg"
  description = "rules for elastic"
  network_id  = "${yandex_vpc_network.network-1.id}"  


  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.33.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["192.168.3.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "elastic agent in"
    port           = "9200"
    v4_cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"] 
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

# //___________________KIBANA______________________
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  description = "rules for kibana"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "kibana interface"
    port           = "5601"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.33.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["192.168.3.0/24"] 
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}



//_____________РАСПИСАНИЕ СНИМКОВ ДИСКОВ ВМ__________________________________________
resource "yandex_compute_snapshot_schedule" "daily" {
  name = "daily"

  schedule_policy {
    expression = "00 17 ? * *"
  }

  retention_period = "168h"

  disk_ids = [yandex_compute_instance.vm-1.boot_disk.0.disk_id, yandex_compute_instance.vm-2.boot_disk.0.disk_id, yandex_compute_instance.vm-3.boot_disk.0.disk_id, yandex_compute_instance.vm-4.boot_disk.0.disk_id, yandex_compute_instance.vm-5.boot_disk.0.disk_id, yandex_compute_instance.vm-6.boot_disk.0.disk_id]
}




//_______________ШЛЮЗ И ТАБЛИЦА МАРШРУТИЗАЦИИ__________________________
resource "yandex_vpc_gateway" "nginx1-2_elastic_gateway" {
  name = "nginx-elastic-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nginx1-2_elastic" {
  name       = "nginx-elastic-route-table"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nginx1-2_elastic_gateway.id
  }
}



//__________________________СЕТЬ_______________________________________
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

//_________________________ПОДСЕТЬ-1____________________________________
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}

//_________________________ПОДСЕТЬ-2____________________________________
resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.2.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}

//_________________________ПОДСЕТЬ-3____________________________________
resource "yandex_vpc_subnet" "subnet-3" {
  name           = "subnet3"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.3.0/24", "192.168.33.0/24"]
}

//_________________________ПОДСЕТЬ-4____________________________________
resource "yandex_vpc_subnet" "subnet-4" {
  name           = "subnet4"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.4.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}





//_____вывод IP адреса бастиона_____________________________
output "external_ip_address_vm_6_BASTION" {
  value = yandex_compute_instance.vm-6.network_interface.0.nat_ip_address
}
