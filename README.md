# terraform-yelb

## О проекте
Этот репозиторий содержит код для развертывания облачной инфраструктуры, необходимой для деплоя [pet_pipeline](https://github.com/Truth711/k8s-deploy-yelb). Инфраструктура включает в себя **Yandex Managed Service for Kubernetes**, сеть для кластера, **Yandex Container Registry** для хранения образов, сервисный аккаунт для взаимодействия с облаком и ресурсы внутри кластера (узнать что где описано можно [здесь](#-перечень-ресурсов)).

---
## Оглавление
- [Установка](#-установка)
- [Перечень ресурсов](#-перечень-ресурсов)
- [Дополнительные команды](#-дополнительные-команды)
- [Полезные ссылки](#-полезные-ссылки)

---
## Установка

### Предварительные требования
Перед началом работы необходимо установить:
- **[YC CLI](https://cloud.yandex.ru/docs/cli/quickstart)** – утилита для работы с Yandex Cloud
- **[Helm](https://helm.sh/docs/intro/install/)** – пакетный менеджер Kubernetes
- **[Terraform](https://hashicorp-releases.yandexcloud.net/terraform/)** – инструмент управления инфраструктурой (IaC) (добавьте путь до файла в PATH)
- **[kubectl](https://kubernetes.io/docs/tasks/tools/)** – утилита для управления кластером Kubernetes

### Шаги установки
1. **Настройка источника провайдеров**
   
   Создайте файл `terraform.rc` в директории `%APPDATA%` (Windows) или `~/.terraformrc` (Linux/macOS) со следующим содержимым:
   ```hcl
   provider_installation {
     network_mirror {
       url = "https://terraform-mirror.yandexcloud.net/"
       include = ["registry.terraform.io/*/*"]
     }
     direct {
       exclude = ["registry.terraform.io/*/*"]
     }
   }
   ```

2. **Скопируйте `var.tfvars.example` в `var.tfvars` и заполните значениями**
   
   ```sh
   cp var.tfvars.example var.tfvars
   ```
   Укажите необходимые значения переменных (токен, идентификаторы облака, каталогов, останое опционально).

3. **Инициализация Terraform**
   
   В каталоге с конфигурационными файлами Terraform выполните команду:
   ```sh
   terraform init
   ```
   Это скачает необходимые провайдеры и подготовит окружение.

4. **Применение конфигурации**
   
   Запустите команду:
   ```sh
   terraform apply -var-file="var.tfvars"
   ```
   Просмотрите список создаваемых ресурсов и подтвердите их создание. По завершении в папке появится файл `ca.pem`, который потребуется на следующем шаге.

5. **Настройка доступа к кластеру**
   
   Для обеспечения доступа к кластеру без использования YC CLI (например, из CI/CD) выполните скрипт:
   ```sh
   ./setup-kubeconfig.ps1
   ```
   В результате создастся статический конфигурационный файл для использования в пайплайнах.

6. **Удаление инфраструктуры:**

  Удалите инфраструктуру, когда она будет не нужна:
  ```sh
  terraform destroy -var-file="var.tfvars"
  ```


---
## Перечень ресурсов

- **`cluster.tf`** – описание мастера, узлов и групп безопасности
- **`helm.tf`** – установка **nginx-ingress** и **cert-manager** через Helm
- **`kube.tf`** – настройка доступа к кластеру и создание **service account**, ролей и **imagePullSecret**
- **`network.tf`** – описание сети, подсетей и DNS-зоны
- **`provider.tf`** – конфигурация провайдеров Terraform
- **`registry.tf`** – создание **Yandex Container Registry** и группы безопасности для него
- **`service_account.tf`** – сервисный аккаунт и права доступа к облаку
- **`variables.tf`** – описание переменных
- **`var.tfvars`** – значения переменных (требуется заполнение)

---
## Дополнительные команды

- **Обновление конфигурации:**
  ```sh
  terraform apply -var-file="var.tfvars"
  ```

- **Проверка состояния:**
  ```sh
  terraform state list
  ```

---
## Полезные ссылки
- [Документация Terraform](https://developer.hashicorp.com/terraform/docs)
- [Документация Yandex Cloud](https://cloud.yandex.ru/docs)
- [Kubernetes](https://kubernetes.io/docs/)
- [Helm Charts](https://artifacthub.io/)
