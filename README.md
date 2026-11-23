# Unpackerr Helm Chart

![Downloads](https://img.shields.io/github/downloads/tonylea/helm-chart-unpackerr/total)

Deploys [Unpackerr](https://github.com/Unpackerr/unpackerr), which extracts the archives in the *arr apps' completed downloads so they can import them, from [`golift/unpackerr`](https://hub.docker.com/r/golift/unpackerr), the project's own image.

It runs one replica with the `Recreate` strategy, so the old pod stops before the new one starts.
Unpackerr has no `/config` volume: it writes nothing while none is mounted, history is lost on restart, and the *arr apps hold the real queue.
All configuration is `UN_*` environment, which locks those fields in the web UI, so the UI shows status and history only.
The pod runs as the `user` and `group` values, non-root, with all capabilities dropped and no privilege escalation.

## Values

| Value | Default |
| --- | --- |
| `image.tag` | empty, which uses the chart's `appVersion` |
| `user` | `1000` |
| `group` | `1000` |
| `timezone` | `UTC` |
| `sonarr` | `[]`; a list of watched apps, each with `url` and `apiKey.secretKeyRef` (`name` and `key`) |
| `radarr` | `[]`; as `sonarr` |
| `lidarr` | `[]`; as `sonarr` |
| `readarr` | `[]`; as `sonarr`; Readarr forks such as Bookshelf go here |
| `uiPassword.secretKeyRef.name` | none; required |
| `uiPassword.secretKeyRef.key` | `ui-password` |
| `metricsApiKey.secretKeyRef.name` | none; required |
| `metricsApiKey.secretKeyRef.key` | `api-key` |
| `media` | `[]`; at least one entry is required, each with `name`, `existingClaim` and `mountPath` |
| `resources` | `{}` |
| `affinity` | `{}` |
| `serviceMonitor.enabled` | `true` |
| `serviceMonitor.interval` | `30s` |
| `dashboard.enabled` | `true` |
| `httpRoute.enabled` | `false` |
| `httpRoute.parentRefs` | `[]`; required when `httpRoute.enabled` is set |
| `httpRoute.hostnames` | `[]` |

## Fixed settings

- `UN_WEBSERVER_METRICS` is `true`, and an API key named `prometheus` has a role with only `system:metrics:read`, because `/metrics` needs a key.
  The ServiceMonitor sends it as `Authorization: Bearer`.
- Each watched app becomes `UN_<KIND>_<n>_URL` and `UN_<KIND>_<n>_API_KEY`, numbered from 0 in list order.
- `protocols` is left at its default, torrents only, because SABnzbd unpacks its own jobs.
- The web UI login is never set empty, because an empty value wipes the stored password hash.

## Requirements

- A Secret holding the web UI login as `<user>:<password>`, which Unpackerr hashes at start.
- A Secret holding the metrics API key, 60 to 150 ASCII characters.
- A Secret key holding each watched app's API key.
- A claim for each `media` entry, mounted at the same path the *arr apps see, because Unpackerr acts on the paths they report.
- The Prometheus Operator's CRDs when `serviceMonitor.enabled` is set, and a Grafana dashboard sidecar that reads ConfigMaps labelled `grafana_dashboard: "1"` when `dashboard.enabled` is set.
- The Gateway API's `HTTPRoute` CRD when `httpRoute.enabled` is set.

## Usage

```sh
helm repo add unpackerr https://tonylea.github.io/helm-chart-unpackerr
helm install unpackerr unpackerr/unpackerr --values my-values.yaml
```

An example `my-values.yaml`:

```yaml
uiPassword:
  secretKeyRef:
    name: unpackerr
metricsApiKey:
  secretKeyRef:
    name: unpackerr
sonarr:
  - url: http://sonarr:8989
    apiKey:
      secretKeyRef:
        name: sonarr-api-key
        key: api-key
media:
  - name: library
    existingClaim: library
    mountPath: /data
```

## Development

Pull requests run:

- `helm lint --strict`, and the rendered chart checked by kubeconform against Kubernetes 1.37.
- helm-unittest's tests in `tests/`.
- An install with chart-testing in a kind cluster, against the Secrets and claim that `ci/kind` creates, with the ServiceMonitor off because kind has no Prometheus Operator CRDs.

Commits follow Conventional Commits.
Releases are versioned and tagged automatically from `main`, and published to the Helm repository on this repo's GitHub Pages.
