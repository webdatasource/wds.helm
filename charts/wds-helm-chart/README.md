# Web Data Source Helm Chart

Deploy the Web Data Source (WDS) API Server and its auxiliary services to Kubernetes.

| Chart version | Default WDS image tag |
| --- | --- | --- |
| `1.6.0` | `v3.1.0` |

## Deployment modes

| Mode | Core deployments | Requirements |
| --- | --- | --- |
| `SingleService` (default) | One Solidstack replica | MongoDB connection |
| `MultiService` | Dapi, Datakeeper, Crawler, Scraper, Idealer, and Jober; Retriever when search is enabled | MongoDB connection and license key |

Docs and Playground are enabled by default in either mode and can be disabled independently. MongoDB, an optional external cache, and an embedding service are provided separately; the chart does not deploy them.

## Prerequisites

- Helm 3 and access to a Kubernetes cluster.
- Support for the Kubernetes APIs used by enabled resources: `apps/v1`, `networking.k8s.io/v1`, `autoscaling/v2`, and `policy/v1`.
- A MongoDB connection string, supplied directly or through an existing Kubernetes Secret.
- A license key for `MultiService` mode, supplied directly or through an existing Kubernetes Secret.
- An Ingress controller when ingress is enabled, and a resource metrics API when resource-based autoscaling is enabled.
- Search database capabilities appropriate for the configured search mode; vector search also requires an embedding service.
- amd64 nodes when FIPS images are enabled.

Secret references must name Secrets in the release namespace. The chart references existing Secrets; it does not create them.

## Installation

Save the following as `wds-values.yaml`. The example assumes that a Secret named `wds-mongodb` already exists and contains the connection string under the key `connection-string`.

```yaml
# wds-values.yaml
global:
  coreServices:
    databases:
      mongodb:
        connectionStringSecretRef:
          name: wds-mongodb
          key: connection-string
```

After chart `1.6.0` is published, install it from the Helm repository:

```bash
helm repo add webdatasource https://webdatasource.github.io/wds.helm
helm repo update
helm install wds-server webdatasource/wds-helm-chart \
  --version 1.6.0 \
  --namespace webdatasource --create-namespace \
  -f wds-values.yaml
```

To install the current source chart instead, run from the repository root:

```bash
helm install wds-server ./charts/wds-helm-chart \
  --namespace webdatasource --create-namespace \
  -f wds-values.yaml
```

To inspect the rendered resources before installing:

```bash
helm template wds-server ./charts/wds-helm-chart \
  --namespace webdatasource \
  -f wds-values.yaml
```

## Configuration

The complete configuration and inline comments are in [values.yaml](values.yaml). Supply overrides with `-f` or `--set`; values files are merged in order, with later files taking precedence.

Empty image names and tags use the fallbacks listed below. Non-empty per-service scheduling and resource overrides replace the corresponding global maps or lists. Extra labels merge with global labels, with service values winning on duplicate keys. HPA and PDB maps inherit missing keys from the global defaults.

### Global values

| Path | Default or fallback | Description |
| --- | --- | --- |
| `global.imageRegistry` | `docker.io` | Registry prefix for every core and auxiliary image. Set an empty string to omit the prefix. |
| `global.resources` | Requests shown below; no limits by default | Default resource map for every container. Non-empty service `resourcesOverride` maps replace it. |
| `global.resources.requests.cpu` | `100m` | Default CPU request for each container. |
| `global.resources.requests.memory` | `256Mi` | Default memory request for each container. |
| `global.deploymentExtraLabels` | `{}` | Labels merged into every Deployment; a service override wins on duplicate keys. |
| `global.serviceExtraLabels` | `{}` | Labels merged into every Service; a service override wins on duplicate keys. |
| `global.nodeSelector` | `{}` | Default pod node selector. |
| `global.tolerations` | `[]` | Default pod tolerations. |
| `global.affinity` | `{}` | Default pod affinity rules. |
| `global.coreServices.mode` | `SingleService` | `SingleService` deploys Solidstack. `MultiService` deploys the distributed services and requires a license key. |
| `global.coreServices.license.key` | Empty | Direct license key used in `MultiService` mode. Use a placeholder or secret integration rather than committing a real key. |
| `global.coreServices.license.keySecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; used when the direct license key is empty. |
| `global.coreServices.cache.connectionString` | Empty; primary MongoDB is used | Optional [Datakeeper cache](https://webdatasource.com/releases/latest/server/services/datakeeper.html#caching) connection string in `MultiService` mode. |
| `global.coreServices.cache.connectionStringSecretRef` | `{}` | Kubernetes Secret reference with `name` and `key`; used when the direct cache connection string is empty. |
| `global.coreServices.cache.databaseName` | Empty; connection-string database | Optional cache database name. |
| `global.coreServices.databases.mongodb.connectionString` | Empty; required unless a Secret reference is set | Direct MongoDB connection string. |
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
| `global.coreServices.compliance.fips` | `false` | Appends `-fips` to core service image names in both modes, including custom names (amd64 only). Docs and Playground image names are unaffected. |
| `global.coreServices.idSourceHashMode` | `FullLength` | ID source hash mode for Solidstack and Idealer: `FullLength`, `Sha512`, or `Raw`. |
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

## Configuration examples

### MultiService mode and license Secret

Save this as `multiservice-values.yaml` and install with both `-f wds-values.yaml -f multiservice-values.yaml`. The `wds-license` Secret must contain the license under the key `license-key`.

```yaml
# multiservice-values.yaml
global:
  coreServices:
    mode: MultiService
    license:
      keySecretRef:
        name: wds-license
        key: license-key
```

For MongoDB, license, cache, and search database settings, a non-empty literal value takes precedence over its Secret reference. Complete embedding-service URL and API-key Secret references take precedence over their corresponding literal values.

### Search and retrieval

Save this as `search-values.yaml` and add `-f search-values.yaml` to the install command, together with your mode and database settings:

```yaml
# search-values.yaml
global:
  coreServices:
    search:
      enabled: true
      mode: FullText
```

In `SingleService` mode, search runs within Solidstack. In `MultiService` mode, enabling search adds Retriever and connects Dapi to it. The separate `global.coreServices.search.database` settings apply to Retriever; otherwise it uses its primary MongoDB connection. Use MongoDB search capabilities appropriate to your deployment.

For `Vector` or `FullTextAndVector`, also configure `global.coreServices.search.embeddingService.url` or `urlSecretRef`, and any required API key, request template, and response paths. Set `dimentionsCount` to the model's vector length; the value name retains this spelling for compatibility.

### Image registry and FIPS

Save this as `image-values.yaml` and add `-f image-values.yaml` to the install command:

```yaml
# image-values.yaml
global:
  imageRegistry: mirror.example:5000
  nodeSelector:
    kubernetes.io/arch: amd64
  coreServices:
    compliance:
      fips: true
```

`global.imageRegistry` applies to every container, including Docs and both Playground containers. An empty string omits the registry prefix. The registry must contain the configured image repositories and tags.

FIPS appends `-fips` to core image names, including custom names. For example, the default Solidstack image becomes `mirror.example:5000/webdatasource/solidstack-fips:v3.1.0`; Dapi becomes `mirror.example:5000/webdatasource/dapi-fips:v3.1.0`. Configure custom core image names without the suffix. FIPS preserves tags and pull policies, and Docs and Playground keep their regular image names.

### Resources, autoscaling, and disruption budgets

Save this as `scaling-values.yaml` and combine it with the MongoDB and MultiService values files:

```yaml
# scaling-values.yaml
global:
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      memory: 1Gi
coreServices:
  dapi:
    resourcesOverride:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        memory: 1Gi
    hpa:
      minReplicas: 2
      maxReplicas: 5
      targetCPUUtilizationPercentage: 70
    pdb:
      minAvailable: 1
```

Core HPAs and PDBs apply to the split services in `MultiService` mode. Solidstack always has one replica and has no HPA or PDB. Enabled auxiliary services inherit the global HPA configuration; their PDBs are disabled by default.

Per-service HPA maps support `enabled`, `minReplicas`, `maxReplicas`, `targetCPUUtilizationPercentage`, and `targetMemoryUtilizationPercentage`. PDB maps support `enabled`, `minAvailable`, and `maxUnavailable`; set one availability field, since a configured `minAvailable` takes precedence. Set a service's `hpa.enabled` or `pdb.enabled` to `false` to disable that resource.

## Accessing the application

Ingress is disabled by default. Save this as `ingress-values.yaml` and add it to your values files to enable the `webdatasource` Ingress:

```yaml
# ingress-values.yaml
global:
  ingress:
    enabled: true
    className: nginx
    basePath: /wds/
```

The configured base path must be `/` or end in `/`. The example exposes `/wds/api`, `/wds/mcp`, and, when enabled, `/wds/docs` and `/wds/playground`. API and MCP routes target Solidstack in `SingleService` mode and Dapi in `MultiService` mode. Use the address assigned by your Ingress controller.

For local access without ingress, forward the Playground Service:

```bash
kubectl port-forward --namespace webdatasource service/playground 8080:80
```

Then open `http://localhost:8080/`. This requires Playground to be enabled.

## Upgrading

Chart `1.6.0` replaces `global.registry` with `global.imageRegistry`. Rename the key in existing values files and command-line overrides when upgrading from `1.5.0` or earlier. The old key is no longer read.

Review the new defaults and update your values files, then upgrade after the release is available:

```bash
helm upgrade wds-server webdatasource/wds-helm-chart \
  --version 1.6.0 \
  --namespace webdatasource \
  -f wds-values.yaml
```

Include every values file used by your deployment, such as `multiservice-values.yaml` or `search-values.yaml`. Chart version `1.6.0` defaults to WDS `v3.1.0`; Docs uses its independent `v3.0` tag. Per-service image tag overrides continue to take precedence.

## Uninstalling

```bash
helm uninstall wds-server --namespace webdatasource
```

Externally managed databases and Secrets remain under your management.

## Documentation and support

- [WDS deployment documentation](https://webdatasource.com/releases/latest/server/deployments/helm.html)
- [WDS runtime dependencies](https://webdatasource.com/releases/latest/server/services/overview.html#runtime-dependencies)
- [Source repository](https://github.com/webdatasource/wds.helm)
- [Report an issue](https://github.com/webdatasource/wds.helm/issues)
