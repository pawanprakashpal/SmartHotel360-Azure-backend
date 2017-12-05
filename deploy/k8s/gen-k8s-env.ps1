Param(
    [parameter(Mandatory=$true)][string]$resourceGroupName,
    [parameter(Mandatory=$true)][string]$location,
    [parameter(Mandatory=$false)][string]$registryName,
    [parameter(Mandatory=$true)][string]$orchestratorName,
    [parameter(Mandatory=$true)][string]$dnsName,
    [parameter(Mandatory=$true)][bool]$createAcr=$true,
    [parameter(Mandatory=$true)][bool]$createRg=$true,
    [parameter(Mandatory=$false)][string]$publicIpName="",
    [parameter(Mandatory=$false)][string]$agentvmsize="Standard_D2_v2",
    [parameter(Mandatory=$false)][Int]$agentcount=1
)


$createIp = -Not [string]::IsNullOrEmpty($publicIpName);

if ([string]::IsNullOrEmpty($orchestratorName)) {
    Write-Host "Must use --orchestratorName to set the ACS name" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($dnsName)) {
    Write-Host "Must use --dnsName to set the dns" -ForegroundColor Red
    exit 1
}


# Create resource group
if ($createRg) {
    Write-Host "Creating resource group..." -ForegroundColor Yellow
    az group create --name=$resourceGroupName --location=$location
}

if ($createIp) {
    Write-Host "Creating public IP for use with k8s LoadBalancer service..." -ForegroundColor Yellow
    $ipAddress = $(az network public-ip create -g $resourceGroupName -n $publicIpName  --allocation-method static -o json | sls "ipAddress")
    Write-Host "Public IP created is $ipAddress" -ForegroundColor Yellow
}

if ($createAcr -eq $true) {
    # Create Azure Container Registry
    Write-Host "Creating Azure Container Registry..." -ForegroundColor Yellow
    az acr create -n $registryName -g $resourceGroupName -l $location  --admin-enabled true --sku Basic
}

# Create kubernetes orchestrator
Write-Host "Creating kubernetes orchestrator..." -ForegroundColor Yellow
az acs create --orchestrator-type=kubernetes --resource-group=$resourceGroupName --name=$orchestratorName --dns-prefix=$dnsName --agent-vm-size=$agentvmsize --agent-count=$agentcount --generate-ssh-keys

# Retrieve kubernetes cluster configuration and save it under ~/.kube/config 
az acs kubernetes get-credentials --resource-group=$resourceGroupName --name=$orchestratorName

if ($createAcr -eq $true) {
    # Show ACR credentials
    az acr credential show -n $registryName
}