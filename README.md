# WDS Helm Charts

# Deploying the WDS API Server with a Helm Chart

Deploy to Kubernetes using the [WDS Helm Chart](https://github.com/webdatasource/wds.helm)

By default, the chart uses `SingleService` mode: it deploys one [Solidstack](https://webdatasource.com/releases/latest/server/services/solidstack.html) pod, plus the Docs and Playground auxiliary services. Supply MongoDB through either a direct connection string or a Kubernetes Secret reference. Review the server [runtime dependencies](https://webdatasource.com/releases/latest/server/services/overview.html#runtime-dependencies) before deployment.

`MultiService` mode deploys Dapi, Datakeeper, Crawler, Scraper, Idealer, and Jober. Retriever is also deployed when search is enabled. This mode requires a license key and is available with the [Business plan](https://webdatasource.com/pricing.html). [Contact](https://webdatasource.com/contact.html?s=entplan) us for a license key.\
If you find an error in the Helm chart (or in the WDS API Server itself), or if you have specific requirements that need to be added to the Helm chart, kindly use the [Issues](https://github.com/webdatasource/wds.helm/issues)

## Deployment options
There are several ways to deploy the WDS Helm Chart.

### Deploying using Helm CLI

To deploy the WDS API Server using the [Helm CLI](https://helm.sh/docs/intro/install/)

> **_IMPORTANT!_** Ensure you have [access to a Kubernetes cluster](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/)

``` BASH
# Add a repository
helm repo add webdatasource https://webdatasource.github.io/wds.helm

# Update your local repository cache
helm repo update

# Search for the chart to verify it's available
helm search repo webdatasource --version 1.4.0

# Install the chart
helm install wds-server --version 1.4.0 webdatasource/wds-helm-chart \
    --namespace webdatasource --create-namespace \
    --set global.registry="" \
    --set global.coreServices.databases.mongodb.connectionString="mongodb+srv://<user>:<password>@<host>/WebDataSource?appName=<cluster>&readPreference=secondary"
```

### Deploying using Terraform

> **_IMPORTANT!_**  Ensure you have [helm provider](https://github.com/hashicorp/terraform-provider-helm)

#### SingleService

Minimal Terraform configuration to deploy WDS API Server:

```hcl
variable "mongodb_connection_string" {
  description = "MongoDB connection string"
  type        = string
  sensitive   = true
}

variable "registry" {
  description = "Docker registry of WDS API Server service images"
  type        = string
  default     = ""
}

variable "helm_chart_version" {
  description = "Helm chart version for WDS API Server deployment"
  type        = string
  default     = "1.4.0"
}

variable "create_namespace" {
  description = "Namespace and ingress configuration for WDS API Server deployment. Set `create_namespace` to false to deploy in an existing namespace"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace for WDS API Server deployment"
  type        = string
  default     = "webdatasource"
}

variable "enable_ingress" {
  description = "Enable or disable ingress for WDS API Server deployment"
  type        = bool
  default     = true
}

# Kubernetes namespace resource
resource "kubernetes_namespace" "webdatasource" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

# Helm release resource
resource "helm_release" "wds-server" {
  name       = "wds-server"
  repository = "https://webdatasource.github.io/wds.helm"
  chart      = "wds-helm-chart"
  version    = var.helm_chart_version

  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      global = {
        registry = var.registry
        ingress = {
          enabled = var.enable_ingress
        }
      }
    }),
    sensitive(yamlencode({
      global = {
        coreServices = {
          databases = {
            mongodb = {
              connectionString = var.mongodb_connection_string
            }
          }
        }
      }
    }))
  ]

  depends_on = [
    kubernetes_namespace.webdatasource
  ]
}

```

#### MultiService

Terraform configuration to deploy WDS API Server in the MultiService mode with Retrieval:

```hcl
variable "license_key" {
  description = "WebDataSource license key"
  type        = string
  sensitive   = true
}

variable "embedding_service_url" {
  description = "Embedding service URL"
  type        = string
}

variable "embedding_service_api_key" {
  description = "Embedding service API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mongodb_connection_string" {
  description = "MongoDB connection string"
  type        = string
  sensitive   = true
}

variable "registry" {
  description = "Docker registry of WDS API Server service images"
  type        = string
  default     = ""
}

variable "helm_chart_version" {
  description = "Helm chart version for WDS API Server deployment"
  type        = string
  default     = "1.4.0"
}

variable "create_namespace" {
  description = "Namespace and ingress configuration for WDS API Server deployment. Set `create_namespace` to false to deploy in an existing namespace"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace for WDS API Server deployment"
  type        = string
  default     = "webdatasource"
}

variable "enable_ingress" {
  description = "Enable or disable ingress for WDS API Server deployment"
  type        = bool
  default     = true
}

# Kubernetes namespace resource
resource "kubernetes_namespace" "webdatasource" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

# Helm release resource
resource "helm_release" "wds-server" {
  name       = "wds-server"
  repository = "https://webdatasource.github.io/wds.helm"
  chart      = "wds-helm-chart"
  version    = var.helm_chart_version

  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      global = {
        registry = var.registry
        ingress = {
          enabled = var.enable_ingress
        }
        coreServices = {
          mode = "MultiService"
          search = {
            enabled = true
            mode    = "FullTextAndVector"
            embeddingService = {
              url = var.embedding_service_url
            }
          }
        }
      }
    }),
    sensitive(yamlencode({
      global = {
        coreServices = {
          license = {
            key = var.license_key
          }
          databases = {
            mongodb = {
              connectionString = var.mongodb_connection_string
            }
          }
          search = {
            embeddingService = {
              apiKey = var.embedding_service_api_key
            }
          }
        }
      }
    }))
  ]

  depends_on = [
    kubernetes_namespace.webdatasource
  ]
}

```

> _NOTE_ This code can be used to create a dedicated [Terraform Module](https://developer.hashicorp.com/terraform/language/modules)

## Configuration

Set chart configuration in [values.yaml](https://github.com/webdatasource/wds.helm/blob/master/charts/wds-helm-chart/values.yaml)

### Global values

| Path | Default or fallback | Description |
| --- | --- | --- |
| `global.registry` | `docker.io` | Registry prefix for every image. |
| `global.resources.requests.cpu` | `100m` | Default CPU request for each container. |
| `global.resources.requests.memory` | `256Mi` | Default memory request for each container. |
| `global.deploymentExtraLabels` | `{}` | Labels merged into every Deployment; a service override wins on duplicate keys. |
| `global.serviceExtraLabels` | `{}` | Labels merged into every Service; a service override wins on duplicate keys. |
| `global.nodeSelector` | `{}` | Default pod node selector. |
| `global.tolerations` | `[]` | Default pod tolerations. |
| `global.affinity` | `{}` | Default pod affinity rules. |
| `global.coreServices.mode` | `SingleService` | `SingleService` deploys Solidstack. `MultiService` deploys the distributed services and requires a [Business-plan](https://webdatasource.com/pricing.html) license. |
| `global.coreServices.license.key` | Empty | Direct license key used in `MultiService` mode. Use a placeholder or secret integration rather than committing a real key. |
| `global.coreServices.license.keySecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; used when the direct license key is empty. |
| `global.coreServices.cache.connectionString` | Empty; primary MongoDB is used | Optional [Datakeeper cache](https://webdatasource.com/releases/latest/server/services/datakeeper.html#caching) connection string in `MultiService` mode. |
| `global.coreServices.cache.connectionStringSecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; used when the direct cache connection string is empty. |
| `global.coreServices.cache.databaseName` | Empty; connection-string database | Optional cache database name. |
| `global.coreServices.databases.mongodb.connectionString` | Empty; required unless a Secret reference is set | Direct [MongoDB connection string](https://www.mongodb.com/docs/v6.0/reference/connection-string/)
| `global.coreServices.databases.mongodb.connectionStringSecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; used when the direct MongoDB connection string is empty. |
| `global.coreServices.databases.mongodb.databaseName` | `WebDataSource` | Default MongoDB database name; an empty value lets the application use the name from the connection string. |
| `global.coreServices.search.enabled` | `false` | Enables [search and retrieval](https://webdatasource.com/releases/latest/server/services/retriever.html). In `MultiService` mode this also deploys Retriever. |
| `global.coreServices.search.mode` | `FullText` | `FullText`, `Vector`, or `FullTextAndVector`. Vector modes require an embedding service. |
| `global.coreServices.search.database.connectionString` | Empty; Retriever MongoDB connection | Optional MongoDB Atlas or Enterprise search-database connection for Retriever. |
| `global.coreServices.search.database.connectionStringSecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; used when the direct search connection string is empty. |
| `global.coreServices.search.database.databaseName` | `WebDataSource` | Search database name, used when a separate search connection is configured. |
| `global.coreServices.search.embeddingService.url` | Empty | Direct external embedding-service URL. |
| `global.coreServices.search.embeddingService.apiKey` | Empty | Direct external embedding-service API key. |
| `global.coreServices.search.embeddingService.urlSecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; when complete, it overrides the direct URL. |
| `global.coreServices.search.embeddingService.apiKeySecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; when complete, it overrides the direct API key. |
| `global.coreServices.search.embeddingService.dimentionsCount` | `768` | Embedding-vector dimension count. The misspelled `dimentionsCount` is the chart's public value name. |
| `global.coreServices.search.embeddingService.requestTemplate` | Empty; internal fallback `{ 'model': 'embeddinggemma', 'input': null }` | JSON request template for an external embedding service. |
| `global.coreServices.search.embeddingService.contentJsonPath` | Empty; internal fallback `$.input` | JSONPath where the input string array is written in the embedding request. |
| `global.coreServices.search.embeddingService.resultJsonPath` | Empty; internal fallback `$.embeddings` | JSONPath used to read embedding arrays from the response. |
| `global.coreServices.jobTypes` | `[intranet, internet]` | Enabled [job types](https://webdatasource.com/releases/latest/server/services/dapi.html#jobtypes). |
| `global.coreServices.externalIpConfigs` | `[intranet, amazon]` | Enabled [external IP configurations](https://webdatasource.com/releases/latest/server/services/crawler.html#external-ip-getter-services). |
| `global.coreServices.exceptionResponseDelayMs` | Empty; application fallback `1000` ms | Delay before an HTTP error response; applies to the MSSQL API. |
| `global.coreServices.maxInactiveSecToReregistrar` | Empty; application fallback `60` seconds | Maximum Crawler inactivity before re-registration. |
| `global.coreServices.compliance.fips` | false | Run core services on FIPS compliant images (amd64 only). Docs and playground are unaffected. |
| `global.auxiliaryServices.docs.enabled` | `true` | Deploys the Docs auxiliary service. |
| `global.auxiliaryServices.docs.defaultTag` | `v3.0` | Docs image tag used when `auxiliaryServices.docs.image.tag` is empty. |
| `global.auxiliaryServices.playground.enabled` | `true` | Deploys the Playground auxiliary service. |
| `global.minLogLevel` | `Information` | Minimum log level: `Trace`, `Debug`, `Information`, `Warning`, `Error`, or `Critical`. |
| `global.ingress.enabled` | `false` | Creates the chart Ingress. |
| `global.ingress.className` | `nginx` | Ingress class; set an empty value to use the cluster's default class. |
| `global.ingress.annotations` | `{}` | Additional Ingress annotations. |
| `global.ingress.basePath` | `/` | Prefix for all routes. It must be `/` or end with `/`. |
| `global.hpa.enabled` | `true` | Default HorizontalPodAutoscaler state. Core HPAs apply in `MultiService`; enabled auxiliary services also inherit this default. |
| `global.hpa.minReplicas` | `1` | Default HPA minimum replica count. |
| `global.hpa.maxReplicas` | `3` | Default HPA maximum replica count. |
| `global.hpa.targetCPUUtilizationPercentage` | `80` | Default average CPU utilization target. |
| `global.hpa.targetMemoryUtilizationPercentage` | `null` | Optional average memory utilization target; `null` disables the memory metric. |
| `global.pdb.enabled` | `true` | Default PodDisruptionBudget state. Core PDBs apply in `MultiService`; auxiliary services override this to `false` by default. |
| `global.pdb.minAvailable` | `1` | Default minimum available pods. If both availability fields are set, `minAvailable` wins. |
| `global.pdb.maxUnavailable` | `null` | Optional maximum unavailable pods. |

### Core service overrides

In the table below, `<service>` means exactly `solidstack`, `dapi`, `datakeeper`, `crawler`, `scraper`, `idealer`, `jober`, or `retriever`, except where a narrower list is stated.

| Path | Applies to | Default or fallback | Description |
| --- | --- | --- | --- |
| `coreServices.<service>.image.name` | All eight core services | Empty; `webdatasource/<service>` | Overrides the image name. |
| `coreServices.<service>.image.tag` | All eight core services | Empty; `.Chart.AppVersion` | Overrides the image tag. |
| `coreServices.<service>.image.pullPolicy` | All eight core services | Empty; `IfNotPresent` | Overrides the image pull policy. |
| `coreServices.<service>.resourcesOverride` | All eight core services | `{}`; `global.resources` | Replaces the global resource map when non-empty. |
| `coreServices.<service>.deploymentExtraLabelsOverride` | All eight core services | `{}` | Merges with global Deployment labels and wins on duplicate keys. |
| `coreServices.<service>.serviceExtraLabelsOverride` | All eight core services | `{}` | Merges with global Service labels and wins on duplicate keys. |
| `coreServices.<service>.nodeSelectorOverride` | All eight core services | `{}`; `global.nodeSelector` | Replaces the global node selector when non-empty. |
| `coreServices.<service>.tolerationsOverride` | All eight core services | `[]`; `global.tolerations` | Replaces global tolerations when non-empty. |
| `coreServices.<service>.affinityOverride` | All eight core services | `{}`; `global.affinity` | Replaces global affinity when non-empty. |
| `coreServices.<service>.replicaCount` | `dapi`, `datakeeper`, `crawler`, `scraper`, `idealer`, `jober`, `retriever` | `2` | Deployment replica count. Solidstack always uses one replica and has no value at this path. |
| `coreServices.<service>.databases.mongodb.databaseName` | `dapi`, `datakeeper`, `scraper`, `idealer`, `jober`, `retriever` | Empty; global MongoDB database name | Per-service MongoDB database-name override. Crawler and Solidstack do not expose this override. |
| `coreServices.<service>.hpa` | `dapi`, `datakeeper`, `crawler`, `scraper`, `idealer`, `jober`, `retriever` | `{}`; missing keys inherit `global.hpa` | Per-service HPA map. |
| `coreServices.<service>.pdb` | `dapi`, `datakeeper`, `crawler`, `scraper`, `idealer`, `jober`, `retriever` | `{}`; missing keys inherit `global.pdb` | Per-service PDB map. |

### Auxiliary service overrides

Here, `<service>` means exactly `playground` or `docs`.

| Path | Applies to | Default or fallback | Description |
| --- | --- | --- | --- |
| `auxiliaryServices.<service>.replicaCount` | Both services | `1` | Deployment replica count. |
| `auxiliaryServices.<service>.image.name` | Both services | Empty; `webdatasource/<service>` | Overrides the image name. |
| `auxiliaryServices.playground.image.tag` | Playground | Empty; `.Chart.AppVersion` | Overrides the Playground image tag. |
| `auxiliaryServices.docs.image.tag` | Docs | Empty; `global.auxiliaryServices.docs.defaultTag` | Overrides the Docs image tag. |
| `auxiliaryServices.playground.image.pullPolicy` | Playground | Empty; `IfNotPresent` | Overrides the Playground image pull policy. |
| `auxiliaryServices.docs.image.pullPolicy` | Docs | Empty; `Always` | Overrides the Docs image pull policy. |
| `auxiliaryServices.<service>.resourcesOverride` | Both services | `{}`; `global.resources` | Replaces the global resource map when non-empty. |
| `auxiliaryServices.<service>.deploymentExtraLabelsOverride` | Both services | `{}` | Merges with global Deployment labels and wins on duplicate keys. |
| `auxiliaryServices.<service>.serviceExtraLabelsOverride` | Both services | `{}` | Merges with global Service labels and wins on duplicate keys. |
| `auxiliaryServices.<service>.nodeSelectorOverride` | Both services | `{}`; `global.nodeSelector` | Replaces the global node selector when non-empty. |
| `auxiliaryServices.<service>.tolerationsOverride` | Both services | `[]`; `global.tolerations` | Replaces global tolerations when non-empty. |
| `auxiliaryServices.<service>.affinityOverride` | Both services | `{}`; `global.affinity` | Replaces global affinity when non-empty. |
| `auxiliaryServices.<service>.hpa` | Both services | `{}`; missing keys inherit `global.hpa` | Per-service HPA map. |
| `auxiliaryServices.<service>.pdb.enabled` | Both services | `false` | Disables the auxiliary-service PDB by default; enable it when running more than one replica. Other PDB settings inherit the global map. |

## Accessing the WDS API Server instance

When the helm release has been deployed to a Kubernetes cluster, use the following command to get access URLs:

``` BASH
NAMESPACE=webdatasource # Change the namespace if necessary
SCHEME=$(kubectl get ing webdatasource -n $NAMESPACE -o jsonpath='{.spec.tls[0].hosts[0]}')
SCHEME=$([ -n "$SCHEME" ] && echo https || echo http)
HOST=$(kubectl get ing webdatasource -n $NAMESPACE -o jsonpath='{.spec.rules[0].host}')
if [ -z "$HOST" ]; then
  HOST=$(kubectl get ing webdatasource -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  [ -z "$HOST" ] && HOST=$(kubectl get ing webdatasource -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ -z "$HOST" ] && HOST=localhost
fi
echo
kubectl get ing webdatasource -n $NAMESPACE -o jsonpath='{range .spec.rules[*].http.paths[*]}{.path}/{"\n"}{end}' | awk -v s="$SCHEME" -v h="$HOST" '{print s"://"h $0}'
```

The result should look like this:

```
http(s)://[your-host]/playground/
http(s)://[your-host]/docs/
http(s)://[your-host]/api/
http(s)://[your-host]/mcp/
```

* `/playground/` is used to access the [Playground auxiliary container](https://webdatasource.com/releases/latest/server/deployments/dockercompose.html#auxiliary-containers)
* `/docs/` is used to access the [Docs auxiliary container](https://webdatasource.com/releases/latest/server/deployments/dockercompose.html#auxiliary-containers)
* `/mcp/` is used to access the [MCP Server](https://webdatasource.com/releases/latest/mcp/index.html)
* `/api/` is the [API](https://webdatasource.com/releases/latest/server/api/overview.html)
