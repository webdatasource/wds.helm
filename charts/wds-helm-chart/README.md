# Web Data Source Helm Chart

A Helm chart for deploying the Web Data Source API Server to Kubernetes clusters. For detailed documentation, visit the Web Data Source [official website](https://webdatasource.com/releases/latest/server/deployments/helm.html)

The chart supports two core deployment modes:

- `SingleService` deploys `solidstack`.
- `MultiService` deploys `dapi`, `datakeeper`, `crawler`, `scraper`, `idealer`, and `jober`. It also deploys `retriever` when search is enabled.

Every Deployment uses `global.resources` by default. Set the component's `resourcesOverride` map to replace the global resource requests and limits for that component.

When search is enabled, `global.coreServices.search.embeddingService.dimentionsCount` configures the embedding vector length in both deployment modes.
