---
name: actualize-wds-helm-chart
description: Reconcile, test, and locally package the wds-helm-chart service inventory, mode gates, ports, images, and runtime environment against the live WDS .NET solution and Docker Compose configurations while treating values.yaml as a user-maintained, read-only configuration contract. Use when Codex must actualize or audit the Helm chart after WDS services or their appsettings change, add a missing chart service for a WDS.Kesa.Dotnet .Web project, remove a stale core service, synchronize MultiService and SingleService wiring with wds.build, or produce a deployable local chart package after reconciliation.
---

# Actualize WDS Helm Chart

Reconcile the chart from the current source repositories. Do not use a remembered service list or copy configuration from old packaged charts.

## Establish the workspace

1. Read the Helm repository `AGENTS.md` and every more-specific instruction file that applies to files being changed.
2. Run `git status --short` in the Helm repository. Preserve all pre-existing edits and restrict the diff to the reconciliation.
3. Locate these inputs, preferring the sibling repositories shown when the user does not provide paths:

   - Helm repository: current repository
   - application repository: `../wds.kesa.dotnet`
   - solution: `../wds.kesa.dotnet/WDS.Kesa.Dotnet.sln`
   - MultiService topology: `../wds.build/dc-box.yml`
   - SingleService topology: `../wds.build/dc-solidstack.yml`

4. Stop before editing if the solution, either Compose file, the chart, or an applicable instruction file is unavailable. Never substitute `_retired` projects, packaged `*.tgz` charts, cached inventories, or assumptions.
5. Treat the application and build repositories as read-only unless the user explicitly puts them in scope.
6. Treat `charts/wds-helm-chart/values.yaml` as user-maintained and read-only. Capture its initial contents or checksum and verify it remains byte-for-byte unchanged, including when it already contains uncommitted user edits.
7. Use the bundled scripts from the Helm repository root. Do not retype their full commands when the scripts are available:

   - `scripts/run-unit-tests.sh` runs the complete strict `helm-unittest` suite.
   - `scripts/build-local-chart.sh` packages the chart to the repository root by default, replacing the same-version local package only after validation succeeds.

## Apply source authority

Use each source only for the facts it owns:

- `WDS.Kesa.Dotnet.sln` owns the core application service inventory. Select project entries whose path ends in `.Web.csproj`; do not infer the set from existing chart templates, directory names alone, or CI workflows.
- Each selected project's adjacent `appsettings.json` owns that service's configuration placeholders and Kestrel endpoints. Extract every exact `${ENVIRONMENT_VARIABLE}` reference and every listening port. Read the whole JSON hierarchy so the consuming feature and dependency remain clear.
- `dc-box.yml` owns the working MultiService composition: participating services, image repositories, DNS hostnames, service-to-service origins, enabled feature flags, database/cache/search wiring, and externally published entry points.
- `dc-solidstack.yml` owns the working SingleService composition for `solidstack` and its configuration.
- `charts/wds-helm-chart/values.yaml` is the sole source of truth for every user-configurable option available to a component, including defaults, global settings, service overrides, feature gates, and literal/secret-reference choices. Read it; never add, remove, rename, reorder, reformat, comment, or otherwise modify it.
- The rest of the current chart and its `AGENTS.md` own the Kubernetes conventions, shared generators, and compatibility constraints, but they do not override the configuration contract declared by `values.yaml`.

Do not invent a configuration option from an appsettings placeholder, Compose value, existing template, test, README, or neighboring component. A template may use fixed operational wiring derived from appsettings or Compose, such as a required internal service DNS name or container port, without making it user-configurable. Every behavior intended to be configurable by the user must map to an option already declared in `values.yaml`.

Do not treat Compose infrastructure containers such as MongoDB or MinIO as WDS chart services unless the user explicitly requests bundling them. Preserve docs and playground as auxiliary services; their absence from the .NET `.Web` inventory is not evidence that they are stale.

If the authorities conflict, do not guess. In particular, stop and report the exact mismatch when a solution `.Web` project lacks `appsettings.json`, a non-Solidstack `.Web` service has no usable `dc-box.yml` definition, `solidstack` has no usable `dc-solidstack.yml` definition, or the required user-configurable behavior has no matching `values.yaml` option. Ask the user to maintain `values.yaml`; do not patch it on the user's behalf.

## Build a reconciliation inventory

Before editing, derive and record a table with one row per solution `.Web` project:

- project path and normalized service name;
- target mode and any feature gate;
- Compose service key, hostname, and image;
- Kestrel container ports and required Kubernetes Service ports;
- all `appsettings.json` environment placeholders;
- Compose-provided values and service DNS dependencies;
- every matching global and component option declared in `values.yaml`, including defaults and override precedence;
- Deployment, Service, HPA, and PDB template and test-suite presence;
- status: add, update, keep, remove, or blocked.

Derive the service name from `WDS.<Name>.Web.csproj` and normalize it to the chart's lowercase DNS-compatible convention. Gate `solidstack` with `SingleService`. Gate services in `dc-box.yml` with `MultiService`, retaining any documented feature gate such as retrieval/search only when the sources and current public contract support it.

Also inventory existing `templates/core-*.yaml`, their `tests/*-test.yaml` suites, the read-only `values.yaml` contract, ingress backends, and README entries. For each component, enumerate all of its configuration options from `values.yaml` before reading how templates consume them. Classify a current core chart service as stale only if it has no corresponding solution `.Web` project and is not an auxiliary service.

Treat every `${...}` placeholder as a runtime input that must be consciously accounted for, but do not assume every placeholder must render unconditionally. Use the Compose configurations and existing values semantics to determine whether it is always set, feature-gated, optional, literal, or secret-backed. Search shared application configuration before deleting an existing chart environment variable merely because it is absent from one project's local `appsettings.json`.

## Reconcile with TDD

Follow the repository's red-green-refactor workflow for every behavior change.

1. Read `Chart.yaml`, all relevant read-only `values.yaml` sections, the affected component template, its shared generator, and the complete existing suite.
2. Add the smallest rendered-manifest assertion first. Run only the focused suite and confirm it fails because the desired chart behavior is missing.
3. Implement the narrowest chart change that makes the focused suite pass.
4. Refactor only after the focused suite is green.

For every solution `.Web` project, ensure the chart has a coherent core-service contract:

- an existing user-maintained `coreServices.<service>` section in `values.yaml` that completely defines the component's configurable options; stop and request the missing contract if it is absent or insufficient;
- a Deployment using `include "wds-helm-chart.deployment"`;
- a Service using `include "wds-helm-chart.service"`;
- an HPA using `include "wds-helm-chart.hpa"`;
- a PDB using `include "wds-helm-chart.pdb"`;
- one `*-test.yaml` suite for each resource template.

Use the Compose image repository, appsettings Kestrel ports, and Compose DNS topology rather than copying a neighboring service blindly. Make cluster-local origin variables point to Kubernetes Service DNS names and the required target port. Expose only ports required by callers, probes, or public routing. Keep selectors and pod labels stable for existing resources.

Represent credentials and sensitive connection strings only through alternatives already declared in `values.yaml`, without rendering secret defaults. Preserve the precedence encoded by that user-maintained contract. Do not add a secret reference, override, fallback, or feature switch that `values.yaml` does not expose.

When adding a service, require its user-maintained values contract first, then add its full Deployment/Service/HPA/PDB family, documentation, mode/feature conditions, and tests in the same change without modifying `values.yaml`. When removing a stale service, remove the same complete resource family and repair internal origins, ingress, docs, and tests only after verifying no surviving service depends on it; leave its values section for the user to maintain or remove.

Do not bump `Chart.yaml`, create tags, or make release changes unless explicitly requested. Do not package during red/green iteration. Build the local `*.tgz` only as the final validation step by using the bundled packaging script.

## Test the complete behavior matrix

Derive the test matrix from every global and component option declared for the component in `values.yaml`, then cover every branch read by each added or changed component, including as applicable:

- enabled and disabled rendering;
- `SingleService` and `MultiService` gating;
- dependent feature gates;
- default and overridden image registry, name, tag, and pull policy;
- replicas, resources, labels, node selectors, tolerations, and affinity;
- global values, service overrides, and precedence when both are set;
- every configurable environment variable's present and omitted states;
- literal values, secret references, neither configured, and defined precedence;
- ports, service DNS origins, probes, selectors, HPA, and PDB behavior;
- invalid configurations that must fail rendering.

Test at the rendered-manifest boundary with focused semantic assertions. Any shared-generator or helper change requires regression coverage across every consumer and a full suite run.

## Validate and hand off

Run focused suites directly during red/green development. After the focused suites pass, run the complete unit-test suite through the bundled script from the Helm repository root:

```sh
.ai/skills/actualize-wds-helm-chart/scripts/run-unit-tests.sh
```

Then run the remaining checks:

```sh
helm lint charts/wds-helm-chart

helm template wds charts/wds-helm-chart \
  --set global.coreServices.databases.mongodb.connectionString=test

helm template wds charts/wds-helm-chart \
  --set global.coreServices.mode=MultiService \
  --set global.coreServices.license.key=test \
  --set global.coreServices.databases.mongodb.connectionString=test
```

Add flags needed to render every affected feature gate, using only configuration paths declared in `values.yaml`. Use placeholders only. Verify that every component `templates/*.yaml` has a corresponding `tests/*-test.yaml` suite, inspect the final diff, and confirm `values.yaml` is byte-for-byte identical to its preflight state and that application/build repositories, secrets, and unrelated user changes are untouched.

After every test, lint, render, coverage, checksum, and diff check succeeds, build the deployable local package as the last step:

```sh
.ai/skills/actualize-wds-helm-chart/scripts/build-local-chart.sh
```

The script writes `<chart-name>-<version>.tgz` to the Helm repository root, such as `wds-helm-chart-<chart.version>.tgz`, and intentionally replaces an existing same-version local package. Pass the repository root as the first argument and another output directory as the second argument only when the defaults do not apply. Verify the reported path and checksum. Never use the generated package as a reconciliation source.

In the final response, summarize additions, updates, removals, and any blocked source or missing-values-contract mismatches; explicitly confirm that `values.yaml` was not modified; list every validation command and result; report the local package path and checksum; and identify checks that could not run.
