# Simple ConfigMap Example

This example demonstrates how to use the `_configmap.tpl` template to create a Kubernetes ConfigMap with simple key-value pair data.

## What it does

This chart creates a ConfigMap with configuration data as key-value pairs, suitable for environment variables or simple configuration settings.

## Usage

```bash
# Install the chart
helm install my-release ./simple-configmap-example

# Upgrade the chart
helm upgrade my-release ./simple-configmap-example

# Uninstall the chart
helm uninstall my-release
```

## Configuration

The `values.yaml` file defines the ConfigMap structure using the `configmap` section:

```yaml
configmap:
  name: "app-settings"
  data:
    app.name: "my-application"
    app.version: "1.0.0"
    server.port: "8080"
```

## Template Usage

The chart uses the `configmap.render` template from the parent library:

```yaml
{{- include "configmap.render" (dict "root" $ "configmap" .Values.configmap) -}}
```

This template renders the key-value pairs from `values.yaml` into a ConfigMap data section.

## Alternative: File-based Data

The `_configmap.tpl` template also supports loading data from files using the `dataFrom` field instead of `data`:

```yaml
configmap:
  name: "app-settings"
  dataFrom:
    - file: "/path/to/config/file"
      key: "config-key"
```
