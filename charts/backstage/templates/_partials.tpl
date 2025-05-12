{{- define "orchestrator.plugins" }}
{{- $config := include "orchestrator.plugins.config" . | fromYaml  }}
plugins:
  - disabled: false
    package: "{{ $config.orchestratorPlugins.scope }}/{{ $config.orchestratorPlugins.orchestratorBackend.package }}"
    integrity: "{{ $config.orchestratorPlugins.orchestratorBackend.integrity }}"
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow-platform-data-index-service.{{ .Release.Namespace }}
  - disabled: false
    package: "{{ $config.orchestratorPlugins.scope }}/{{ $config.orchestratorPlugins.orchestrator.package }}"
    integrity: "{{ $config.orchestratorPlugins.orchestrator.integrity }}"
    pluginConfig:
      dynamicPlugins:
        frontend:
          red-hat-developer-hub.backstage-plugin-orchestrator:
            appIcons:
              - importName: OrchestratorIcon
                module: OrchestratorPlugin
                name: orchestratorIcon
            dynamicRoutes:
              - importName: OrchestratorPage
                menuItem:
                  icon: orchestratorIcon
                  text: Orchestrator
                module: OrchestratorPlugin
                path: /orchestrator
  - disabled: true
    package: "{{ $config.orchestratorPlugins.scope }}/{{ $config.orchestratorPlugins.scaffolderBackendOrchestrator.package }}"
    integrity: "{{ $config.orchestratorPlugins.scaffolderBackendOrchestrator.integrity }}"{{- end }}
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow-platform-data-index-service.{{ .Release.Namespace }}

{{- define "orchestrator.plugins.config" }}
orchestratorPlugins: 
    scope: "@redhat"
    orchestrator:
      package: "backstage-plugin-orchestrator@1.5.1"
      integrity: sha512-7VOe+XGTUzrdO/av0DNHbydOjB3Lo+XdCs6fj3JVODLP7Ypd3GXHf/nssYxG5ZYC9F1t9MNeguE2bZOB6ckqTA==
    orchestratorBackend:
      package: "backstage-plugin-orchestrator-backend-dynamic@1.5.1"
      integrity: sha512-VIenFStdq9QvvmgmEMG8O7b2wqIebvEcqNeJ9SWZ8jen9t+efTK6D3Rde74LQ1no1QaHLx8RoxNCOuTUEF8O/g==
    scaffolderBackendOrchestrator:
      package: "backstage-plugin-scaffolder-backend-module-orchestrator-dynamic@1.5.1"
      integrity: sha512-bnVQjVsUZ470Vgm2kd5Lo/bVa2fF0q4GufBDc/8oTQsnP3zZJQqKFvFElBTCjY76RqkECydlvZ1UFybSzvockQ==
{{- end }}