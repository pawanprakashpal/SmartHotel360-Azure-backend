Param(
    [parameter(Mandatory=$true)][string]$configFile,    
    [parameter(Mandatory=$false)][string]$registry,
    [parameter(Mandatory=$false)][string]$dockerUser,
    [parameter(Mandatory=$false)][string]$dockerPassword,
    [parameter(Mandatory=$false)][string]$execPath,
    [parameter(Mandatory=$false)][string]$kubeconfigPath,
    [parameter(Mandatory=$false)][string]$imageTag,
    [parameter(Mandatory=$false)][string]$loadBalancerIp,
    [parameter(Mandatory=$false)][bool]$deployCI=$false,
    [parameter(Mandatory=$false)][bool]$useSSL=$false,
    [parameter(Mandatory=$false)][bool]$deployFrontend=$false,
    [parameter(Mandatory=$false)][bool]$buildImages=$true,
    [parameter(Mandatory=$false)][bool]$pushImages=$true,
    [parameter(Mandatory=$false)][string]$sslCertificate="",
    [parameter(Mandatory=$false)][string]$dockerOrg="smarthotels"
)

$scriptPath = Split-Path $script:MyInvocation.MyCommand.Path

function ExecKube($cmd) {    
    if($deployCI) {
        $kubeconfig = $kubeconfigPath + 'config';
        $exp = $execPath + 'kubectl ' + $cmd + ' --kubeconfig=' + $kubeconfig
        Invoke-Expression $exp
    }
    else{
        $exp = $execPath + 'kubectl ' + $cmd
        Invoke-Expression $exp
    }
}

function ReplaceFrontendIp($newipline) {
    $inPath = "$scriptPath\frontend.template.yaml"
    if ($useSSL) {
        $inPath = "$scriptPath\frontend.template-ssl.yaml"
    }
    $outPath = "$scriptPath\.frontend.yaml"
    (Get-Content $inPath | out-string).Replace("[[LoadBalancerIP]]",$newipline) | Set-Content $outPath
}

# Initialization
$debugMode = $PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent
$useDockerHub = [string]::IsNullOrEmpty($registry)

if ($useSSL -eq $true -and [String]::IsNullOrEmpty($sslCertificate)) {
    Write-Host "If useSSL is true then sslCertificate MUST be the name of certificate file (no extension)" -ForegroundColor Red
    exit
}

# Check required commands (only if not in CI environment)
if(-not $deployCI) {
        $requiredCommands = ("docker", "docker-compose", "kubectl")
        foreach ($command in $requiredCommands) {
        if ((Get-Command $command -ErrorAction SilentlyContinue) -eq $null) {
            Write-Host "$command must be on path" -ForegroundColor Red
            exit
        }
    }
}
else {
    $pushImages = false;
    $buildImages = false;       # Never build images through CI, as they previously built
}

# Get tag to use from current branch if no tag is passed
if ([string]::IsNullOrEmpty($imageTag)) {
    $imageTag = $(git rev-parse --abbrev-ref HEAD)
}

Write-Host "Docker image Tag: $imageTag" -ForegroundColor Yellow

# if we have login/pwd add the secret to k8s
if (-not [string]::IsNullOrEmpty($dockerUser)) {
    $registryFDQN =  if (-not $useDockerHub) {$registry} else {"index.docker.io/v1/"}

    Write-Host "Logging in to $registryFDQN as user $dockerUser" -ForegroundColor Yellow
    if ($useDockerHub) {
        docker login -u $dockerUser -p $dockerPassword
    }
    else {
        docker login -u $dockerUser -p $dockerPassword $registryFDQN
    }
    
    if (-not $LastExitCode -eq 0) {
        Write-Host "Login failed" -ForegroundColor Red
        exit
    }

    # create registry key secret
    ExecKube -cmd 'create secret docker-registry registry-key `
    --docker-server=$registryFDQN `
    --docker-username=$dockerUser `
    --docker-password=$dockerPassword `
    --docker-email=not@used.com'
}

if ($buildImages) {
    Write-Host "Building Docker images tagged with '$imageTag'" -ForegroundColor Yellow
    $env:TAG=$imageTag
    docker-compose -p .. -f ../../src/docker-compose.yml -f ../../src/docker-compose-tagged.yml  build    
}

if ($pushImages) {
    Write-Host "Pushing images to $registry/$dockerOrg..." -ForegroundColor Yellow
    $services = ("bookings", "hotels", "suggestions", "tasks", "configuration", "notifications", "reviews", "discounts", "profiles")

    foreach ($service in $services) {
        $imageFqdn = if ($useDockerHub)  {"$dockerOrg/${service}"} else {"$registry/$dockerOrg/${service}"}
        docker tag smarthotels/${service}:$imageTag ${imageFqdn}:$imageTag
        docker push ${imageFqdn}:$imageTag            
    }
}


# Removing previous services & deployments
Write-Host "Removing existing services & deployments.." -ForegroundColor Yellow
ExecKube -cmd 'delete -f deployments.yaml'
ExecKube -cmd 'delete  -f services.yaml'

if ($deployFrontend) {
    Write-Host "Removing deployment... " -ForegroundColor Yellow
    ExecKube -cmd 'delete services frontend'
    ExecKube -cmd 'delete deployment frontend'
}


ExecKube -cmd 'delete configmap config-files'
ExecKube -cmd 'delete configmap externalcfg'
ExecKube -cmd 'delete configmap ssl-files'

if ($useSSL) {
    ExecKube -cmd 'create configmap config-files --from-file=nginx-conf=nginx-ssl.conf --from-file=self-signed.conf=certs-nginx/self-signed.conf --from-file=ssl-params.conf=certs-nginx/ssl-params.conf'
}
else {
    ExecKube -cmd 'create configmap config-files --from-file=nginx-conf=nginx.conf'
}

ExecKube -cmd 'label configmap config-files app=smarthotels'

if ($useSSL) {
    Write-Host "Mounting certificate files for SSL... " -ForegroundColor Yellow
    ExecKube -cmd "create configmap ssl-files --from-file=dev.crt=certs-nginx/$sslCertificate.crt --from-file=dhparam.pem=certs-nginx/dhparam.pem --from-file=dev.key=certs-nginx/$sslCertificate.key"
    ExecKube -cmd 'label configmap ssl-files app=smarthotels'
}


Write-Host 'Deploying WebAPIs' -ForegroundColor Yellow
ExecKube -cmd 'create -f services.yaml'

if ($deployFrontend) {
    Write-Host "Deploying frontend..." -ForegroundColor Yellow
    if ([string]::IsNullOrEmpty($loadBalancerIp)) {
            ReplaceFrontendIp("");
            ExecKube -cmd 'create -f .frontend.yaml'
            Write-Host "Waiting for frontend's external ip..." -ForegroundColor Yellow
            while ($true) {
                $frontendUrl = & ExecKube -cmd 'get svc frontend -o=jsonpath="{.status.loadBalancer.ingress[0].ip}"'
                if ([bool]($frontendUrl -as [ipaddress])) {
                    break
                }
                Start-Sleep -s 15
            }
            $loadBalancerIp = $frontendUrl
    }
    else {
        ReplaceFrontendIp("loadBalancerIP: ${loadBalancerIp}");
        ExecKube -cmd 'create -f .frontend.yaml'
    }
}

Write-Host "Using $loadBalancerIp as the external DNS/IP of the k8s cluster"

Write-Host "Deploying configuration from $configFile" -ForegroundColor Yellow

ExecKube -cmd "create -f $configFile"

Write-Host "Creating desployments on k8s..." -ForegroundColor Yellow
ExecKube -cmd 'create -f deployments.yaml'

# update deployments with the correct image (with tag and/or registry)
$registryPath = ""
if (-not [string]::IsNullOrEmpty($registry)) {
    $registryPath = "$registry/"
}

if ($imageTag -eq "latest" -and $dockerOrg -eq "smarthotels" -and [String]::IsNullOrEmpty($registryPath)) {
    Write-Host "No need to update image containers (default values used)"-ForegroundColor Yellow
}
else {
    Write-Host "Update Image containers to use prefix '$registry/$dockerOrg' and tag '$imageTag'" -ForegroundColor Yellow
    ExecKube -cmd 'set image deployments/hotels hotels=${registryPath}${dockerOrg}/hotels:$imageTag'
    ExecKube -cmd 'set image deployments/bookings bookings=${registryPath}${dockerOrg}/bookings:$imageTag'
    ExecKube -cmd 'set image deployments/suggestions suggestions=${registryPath}${dockerOrg}/suggestions:$imageTag'
    ExecKube -cmd 'set image deployments/tasks tasks=${registryPath}${dockerOrg}/tasks:$imageTag'
    ExecKube -cmd 'set image deployments/config config=${registryPath}${dockerOrg}/configuration:$imageTag'
    ExecKube -cmd 'set image deployments/notifications notifications=${registryPath}${dockerOrg}/notifications:$imageTag'
    ExecKube -cmd 'set image deployments/reviews reviews=${registryPath}${dockerOrg}/reviews:$imageTag'
    ExecKube -cmd 'set image deployments/discounts discounts=${registryPath}${dockerOrg}/discounts:$imageTag'
    ExecKube -cmd 'set image deployments/profiles profiles=${registryPath}${dockerOrg}/profiles:$imageTag'
}

Write-Host "Execute rollout..." -ForegroundColor Yellow
ExecKube -cmd 'rollout resume deployments/hotels'
ExecKube -cmd 'rollout resume deployments/bookings'
ExecKube -cmd 'rollout resume deployments/suggestions'
ExecKube -cmd 'rollout resume deployments/config'
ExecKube -cmd 'rollout resume deployments/tasks'
ExecKube -cmd 'rollout resume deployments/notifications'
ExecKube -cmd 'rollout resume deployments/reviews'
ExecKube -cmd 'rollout resume deployments/discounts'
ExecKube -cmd 'rollout resume deployments/profiles'

ExecKube -cmd 'rollout resume deployments/frontend'

Write-Host "$loadBalancerIp is the root IP/DNS of thhe cluster" -ForegroundColor Yellow