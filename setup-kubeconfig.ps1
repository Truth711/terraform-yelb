# Получаем ID кластера (по имени)
$CLUSTER_LIST = yc managed-kubernetes cluster list --format json | ConvertFrom-Json
$CLUSTER_ID = ($CLUSTER_LIST | Where-Object { $_.name -eq "k8s-cluster" }).id

if (-not $CLUSTER_ID) {
    Write-Error "❌ Kubernetes cluster not found!"
    exit 1
}

Write-Host "Found Kubernetes cluster: $CLUSTER_ID"

# Получаем kubeconfig
yc managed-kubernetes cluster get-credentials `
    $CLUSTER_ID --external --force --kubeconfig cicd.kubeconfig

# Получаем информацию о кластере
$CLUSTER = yc managed-kubernetes cluster get --id $CLUSTER_ID --format json | ConvertFrom-Json
$CLUSTER.master.master_auth.cluster_ca_certificate | Set-Content ca.pem

Write-Host $CLUSTER

# Получаем секрет сервисного аккаунта
$SECRET = kubectl get secret -n default -o json | `
    ConvertFrom-Json | `
    Select-Object -ExpandProperty items | `
    Where-Object { $_.metadata.annotations."kubernetes.io/service-account.name" -eq "cicd" }

if (-not $SECRET) {
    Write-Error "❌ Service account secret not found!"
    exit 1
}

# Декодируем токен
$SA_TOKEN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($SECRET.data.token))

# Получаем API-эндпоинт кластера
$MASTER_ENDPOINT = $CLUSTER.master.endpoints.external_v4_endpoint

# Создаем kubeconfig для сервисного аккаунта
kubectl config set-cluster k8s-cluster `
    --certificate-authority=ca.pem `
    --embed-certs `
    --server=$MASTER_ENDPOINT `
    --kubeconfig=cicd.kubeconfig

kubectl config set-credentials cicd-sa `
    --token=$SA_TOKEN `
    --kubeconfig=cicd.kubeconfig

kubectl config set-context cicd-context `
    --cluster=k8s-cluster `
    --user=cicd-sa `
    --namespace=default `
    --kubeconfig=cicd.kubeconfig

# Устанавливаем контекст по умолчанию
kubectl config use-context cicd-context --kubeconfig=cicd.kubeconfig

Write-Host "✅ Kubeconfig for CICD service account has been created: cicd.kubeconfig"
