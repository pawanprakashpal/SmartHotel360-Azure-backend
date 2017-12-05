# Deploying backend services on a k8s cluster

## Creating k8s (on Windows)

If you are on Windows, use the script `gen-k8s-env.ps1` to create the k8s cluster. Script has following parameters:

* resourceGroupName: Name of the resource where kubernetes cluster will be deployed 
* createRg: If `$true` means that the resource group must be created. If `$false` resource group must already exists. Default is `$true`.
* location: Location where to create all resources 
* orchestratorName: Name of the ACS resource that contains the Kubernetes cluster
* dnsName: DNS name of the ACS
* registryName: Name of the ACR to use
* createAcr: If the ACR has to be created (`Strue`) or not (`$false`). Default value is `$true`

To deploy a k8s to a resource group called `k8sdev` you can type. The resource group and the ACR (called `sh360acrdev`) will be created

```
.\gen-k8s-env.ps1 --resourceGroupName k8sdev --orchestratorName sh360k8sdev --dnsName sh360k8sdev --registryName sh360acrdev
```

If you don't want to create resource group could use:

```
.\gen-k8s-env.ps1 --resourceGroupName k8sdev --orchestratorName sh360k8sdev --dnsName sh360k8sdev --registryName sh360acrdev --createRg $false
```


