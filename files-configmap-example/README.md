# Files ConfigMap Example

This example demonstrates how to use the `_files-configmap.tpl` template to create a Kubernetes ConfigMap containing multiple configuration files.

## What it does

This chart creates a single ConfigMap with three YAML files:
- `application-k8s.yaml` - Application configuration
- `agentconfig-k8s.yaml` - Agent/monitoring configuration
- `dbprop-k8s.yaml` - Database properties

## Usage

```bash
# Install the chart
helm install my-release ./files-configmap-example

# Upgrade the chart
helm upgrade my-release ./files-configmap-example

# Uninstall the chart
helm uninstall my-release
```

## Configuration

The `values.yaml` file defines the structure of the ConfigMap using the `filesConfigmap` section:

```yaml
filesConfigmap:
  name: "app-config"
  component: "application"
  files:
    - name: "filename.yaml"
      content:
        key: value
```

## Template Usage

The chart uses the `filesconfigmap.render` template from the parent library:

```yaml
{{- include "filesconfigmap.render" (dict "root" $ "config" .Values.filesConfigmap) -}}
```

This template converts the YAML content in `values.yaml` into properly formatted ConfigMap data entries.
