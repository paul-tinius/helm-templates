{{/*
regex.trimPrefix removes a prefix pattern from a string using regex.

Usage:
  {{- include "regex.trimPrefix" (dict "string" "prefix-value" "pattern" "^prefix-") -}}

Inputs:
  .string: The input string to process
  .pattern: The regex pattern to match at the beginning of the string

Outputs:
  String: The input string with the matching prefix removed
*/}}
{{- define "regex.trimPrefix" -}}
{{- regexReplaceAllLiteral .pattern .string "" -}}
{{- end }}

{{/*
regex.trimSuffix removes a suffix pattern from a string using regex.

Usage:
  {{- include "regex.trimSuffix" (dict "string" "value-suffix" "pattern" "-suffix$") -}}

Inputs:
  .string: The input string to process
  .pattern: The regex pattern to match at the end of the string

Outputs:
  String: The input string with the matching suffix removed
*/}}
{{- define "regex.trimSuffix" -}}
{{- regexReplaceAllLiteral .pattern .string "" -}}
{{- end }}

{{/*
regex.removeAll removes all occurrences of a pattern from a string using regex.

Usage:
  {{- include "regex.removeAll" (dict "string" "a-b-c-d" "pattern" "-") -}}

Inputs:
  .string: The input string to process
  .pattern: The regex pattern to remove all occurrences of

Outputs:
  String: The input string with all matching patterns removed
*/}}
{{- define "regex.removeAll" -}}
{{- regexReplaceAllLiteral .pattern .string "" -}}
{{- end }}
