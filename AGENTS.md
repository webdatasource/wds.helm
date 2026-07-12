# AGENTS.md

## Purpose and scope

This repository packages Web Data Source (WDS) for Kubernetes as a Helm 3 chart. These instructions apply to the entire repository and are intended for coding agents and human contributors working on the chart.

Use a test-driven development (TDD) workflow for every behavior change: describe the expected rendered manifest in a test, observe the test fail for the intended reason, implement the smallest chart change, and then refactor while keeping the suite green.

## Repository map

- `charts/wds-helm-chart/Chart.yaml`: chart metadata. `version` is the chart release version; `appVersion` is the default WDS application/image version.
- `charts/wds-helm-chart/values.yaml`: public configuration contract and defaults.
- `charts/wds-helm-chart/templates/`: rendered Kubernetes resources.
- `charts/wds-helm-chart/templates/_deployment.tpl`, `_service.tpl`, `_hpa.tpl`, and `_pdb.tpl`: the required shared generators for service resources. A change here can affect many resources.
- `charts/wds-helm-chart/templates/_helpers.tpl`: naming, labels, validation, and other non-resource helpers.
- `charts/wds-helm-chart/tests/`: `helm-unittest` suites, generally one suite per template.
- `.github/workflows/release-helm-chart.yml`: publishes chart releases when a `v*` tag is pushed.
- Root-level `wds-helm-chart-*.tgz` files: packaged release artifacts. Do not regenerate or edit them during an ordinary chart change.

The chart supports two core deployment modes:

- `SingleService` renders the `solidstack` core service.
- `MultiService` renders the split core services (`dapi`, `datakeeper`, `crawler`, `scraper`, and `idealer`). `retriever` is additionally gated by search being enabled.

The docs and playground resources have independent enablement flags. Ingress routes to `solidstack` or `dapi` according to the selected core mode. HPA and PDB resources combine global defaults with per-service overrides.

## Before changing anything

1. Read `Chart.yaml`, the relevant section of `values.yaml`, the resource template, any shared helper it calls, and its existing test suite.
2. Check `git status` and preserve all pre-existing work. Never discard, rewrite, or format unrelated changes.
3. Identify every template affected by a shared value or helper. Changes to `_deployment.tpl`, `_service.tpl`, `_hpa.tpl`, `_pdb.tpl`, or `_helpers.tpl` require broader regression coverage than a leaf template change.
4. Keep the public values schema backward compatible unless the task explicitly requires a breaking change.

## TDD workflow for Helm changes

### 1. Red: add a focused failing test

Add the smallest test that expresses the desired rendered Kubernetes behavior. Place it in the existing suite for the affected template, or add `tests/<template-name>-test.yaml` for a new template.

Run only that suite first:

```sh
helm unittest -f 'tests/<suite>-test.yaml' charts/wds-helm-chart
```

Confirm that it fails because the requested behavior is absent or incorrect, not because the test has invalid YAML, the wrong template path, or missing prerequisite values. Record the failure mentally or in the task notes; do not commit deliberately failing tests.

Important: this repository's suites use the `*-test.yaml` naming convention. The plugin's default discovery pattern is usually `*_test.yaml`, so always pass `-f 'tests/*-test.yaml'` when running the full suite.

### 2. Green: implement the minimum change

Make the narrowest values/template change that satisfies the test. Follow the existing global-default/per-service-override pattern and reuse shared helpers when the behavior is genuinely shared.

Re-run the focused suite until it passes:

```sh
helm unittest -f 'tests/<suite>-test.yaml' charts/wds-helm-chart
```

### 3. Refactor and regress

Clean up duplication and naming only after the focused test is green. Then run all tests and lint the chart:

```sh
helm unittest --strict -f 'tests/*-test.yaml' charts/wds-helm-chart
helm lint charts/wds-helm-chart
```

For cross-cutting or conditional changes, also inspect rendered output in every affected mode. Both modes require a MongoDB connection; multi-service rendering additionally requires a license value:

```sh
helm template wds charts/wds-helm-chart \
  --set global.coreServices.databases.mongodb.connectionString=test

helm template wds charts/wds-helm-chart \
  --set global.coreServices.mode=MultiService \
  --set global.coreServices.license.key=test \
  --set global.coreServices.databases.mongodb.connectionString=test
```

Add other flags needed to exercise the change, such as ingress, search, auxiliary-service, HPA, or PDB settings. Use placeholder values only; never place real credentials in commands, fixtures, snapshots, or committed values.

## What to test

Every renderable component file under `charts/wds-helm-chart/templates/*.yaml` must have a corresponding `helm-unittest` suite under `charts/wds-helm-chart/tests/`. This applies to all current and newly added components, including Deployments, Services, HPAs, PDBs, Ingresses, and any future Kubernetes resource type. When a component template is added, renamed, or removed, add, rename, or remove its test suite in the same change. Shared `*.tpl` files are tested through the component templates that consume them.

Each component's test suite must be derived from its source template and cover every variable the template reads. Before changing a component, enumerate its `.Values` inputs, defaults, conditionals, fallbacks, merges, and shared-generator arguments. Tests must exercise every supported value state and every supported combination of those variables that can change rendering, validation, precedence, or Kubernetes behavior. Do not consider a component covered when its suite tests only the default or happy path.

The component test matrix must include, where applicable:

- each value unset, set to its default, and set to a non-default override;
- boolean and enablement values in both enabled and disabled states;
- every mode, enum value, conditional branch, and failure branch;
- global values alone, component overrides alone, and both set together to prove precedence;
- literal values, secret references, neither configured, and both configured when both forms are supported;
- empty and populated maps/lists, plus global and component-level combinations;
- combinations of image registry, repository/name, tag, and pull policy overrides;
- combinations of HPA/PDB global enablement, global defaults, and component overrides;
- feature gates combined with the deployment modes and dependent settings they affect;
- omission of optional fields as well as their fully configured rendered form.

Avoid redundant cases only when two inputs provably follow the same already-tested template path and produce equivalent manifests. Any skipped Cartesian combination must not represent a distinct branch, precedence rule, validation outcome, or rendered result.

Test behavior at the rendered-manifest boundary rather than duplicating the Go-template implementation. For each relevant change, cover the applicable cases:

- resource renders when enabled and has zero documents when disabled;
- `SingleService` and `MultiService` branches;
- default values and explicit overrides;
- global defaults, per-service overrides, and their precedence;
- plain values and Kubernetes `secretKeyRef` alternatives;
- omitted optional fields and invalid combinations that must fail rendering;
- stable names, labels/selectors, ports, probes, images, environment variables, and ingress backends;
- HPA/PDB enablement and override behavior;
- search-enabled and search-disabled behavior for `retriever`.

Prefer semantic assertions such as `isKind`, `equal`, `contains`, `notExists`, `hasDocuments`, and `failedTemplate`. Assert the smallest stable path that proves the behavior. Avoid snapshots or assertions over an entire manifest when a focused assertion will do.

When fixing a defect, first add a regression test that fails on the old behavior. When changing a shared helper, run the full suite even if only one service motivated the change.

## Helm chart conventions

- Treat `values.yaml` as a public API. Document new values next to their defaults and choose safe defaults that preserve existing rendering.
- Maintain the established structure: shared settings under `global`, service settings under `coreServices.<name>` or `auxiliaryServices.<name>`, and service-specific overrides with the existing `Override` naming pattern.
- Do not silently rename or remove values, resources, ports, labels, or selectors. Kubernetes Deployment selectors are immutable after creation.
- Keep mode and feature gates consistent across a component's Deployment, Service, HPA, and PDB templates.
- Preserve precedence rules. A service override should win over a global default; a documented explicit value should win over its fallback.
- Use helpers for repeated resource structure, but keep component-specific configuration in the component template. Pass the root context as `ctx` when a shared helper expects it.
- Use `toYaml` with the correct `nindent`, trim template whitespace deliberately, and quote string values where Kubernetes/YAML type coercion could change their meaning.
- Keep names DNS-compatible and within Kubernetes length limits. Use the existing label helpers and keep pod-template labels aligned with selectors.
- Never render or commit secrets as defaults. Support `valueFrom.secretKeyRef` where the chart already exposes secret references.
- Do not add cluster lookups or environment-dependent template behavior; unit tests and `helm template` must remain deterministic and offline.
- Avoid unrelated formatting or generated-artifact changes.

## Adding or changing a service

Every service must have a complete resource family consisting of a Deployment, Service, HPA, and PDB. This applies when adding a service and when updating an existing service: review and keep all four resources, the service's `values.yaml` section, mode/feature conditions, and tests coherent. A resource may be conditionally disabled through values, but its template and configuration must still exist.

Each resource template must delegate its manifest structure to the corresponding shared generator:

- Deployment templates must use `_deployment.tpl` via `include "wds-helm-chart.deployment"`.
- Service templates must use `_service.tpl` via `include "wds-helm-chart.service"`.
- HPA templates must use `_hpa.tpl` via `include "wds-helm-chart.hpa"`.
- PDB templates must use `_pdb.tpl` via `include "wds-helm-chart.pdb"`.

Do not handcraft these Kubernetes resource bodies in a service-specific YAML file or bypass the shared generators. `_helpers.tpl` is the exception: it contains supporting helpers and is not itself a resource generator. If a shared generator lacks a capability, extend it in a backward-compatible way and add regression coverage for all resource templates it affects.

If the service needs behavior already implemented elsewhere, compare with the closest existing component and reuse the established conventions rather than copying accidental differences.

All four resource templates must have corresponding unit-test suites. At minimum, test render gating, defaults, image overrides, global/per-service scheduling settings, labels, and the resource-specific ports or scaling/disruption settings.

## Releases and documentation

- Do not bump `Chart.yaml` versions, create tags, or rebuild `.tgz` packages unless the task explicitly includes a release.
- When intentionally releasing, keep `Chart.yaml.version`, `Chart.yaml.appVersion`, image-tag defaults, documentation, and packaged artifacts consistent with the requested release scope.
- Update `charts/wds-helm-chart/README.md` when a user-facing value or behavior changes. Keep `values.yaml` comments accurate as part of the same change.
- A pushed `v*` tag invokes the chart-releaser workflow; creating or pushing a tag is a release action and requires explicit authorization.

## Definition of done

A chart change is complete only when:

- a focused test demonstrated the missing or incorrect behavior before implementation;
- the focused suite passes after implementation;
- `helm unittest --strict -f 'tests/*-test.yaml' charts/wds-helm-chart` passes;
- `helm lint charts/wds-helm-chart` passes;
- affected modes and feature gates render successfully with `helm template`;
- every `templates/*.yaml` component has a corresponding suite in `tests/`;
- every component suite covers all variables and all behaviorally distinct supported combinations referenced by its template;
- each added or updated service has Deployment, Service, HPA, and PDB templates backed by their corresponding shared generators and tests;
- public values and user-facing behavior are documented;
- no unrelated files, packaged charts, secrets, or existing user changes were modified.

In the final handoff, summarize the rendered behavior changed, list the validation commands run and their results, and call out any checks that could not be run.
