# Web Data Source Helm Chart

A Helm chart for deploying the Web Data Source API Server to Kubernetes clusters. For detailed documentation, visit the Web Data Source [official website](https://webdatasource.com/releases/latest/server/deployments/helm.html)

The chart supports two core deployment modes:

- `SingleService` deploys `solidstack`.
- `MultiService` deploys `dapi`, `datakeeper`, `crawler`, `scraper`, `idealer`, and `jober`. It also deploys `retriever` when search is enabled.

Set `global.coreServices.compliance.fips: true` to append `-fips` to core service image names in either deployment mode. For example, `docker.io/webdatasource/dapi:v3.0.0` becomes `docker.io/webdatasource/dapi-fips:v3.0.0`. This also applies to custom core service image names; configure them without the suffix. Docs and playground images are unaffected. Image tags, registries, and pull policies are unchanged. The default is `false`, which adds no suffix.

Every Deployment uses `global.resources` by default. Set the component's `resourcesOverride` map to replace the global resource requests and limits for that component.

When search is enabled, `global.coreServices.search.embeddingService.dimentionsCount` configures the embedding vector length in both deployment modes.
