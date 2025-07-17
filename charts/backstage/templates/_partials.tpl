{{- define "orchestrator.plugins" }}
{{- $config := include "orchestrator.plugins.config" . | fromYaml  }}
plugins:
  - disabled: false
    package: "{{ $config.orchestratorPlugins.orchestratorBackend.package }}"
    integrity: "{{ $config.orchestratorPlugins.orchestratorBackend.integrity }}"
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow-platform-data-index-service.{{ .Release.Namespace }}
  - disabled: false
    package: "{{ $config.orchestratorPlugins.orchestrator.package }}"
    integrity: "{{ $config.orchestratorPlugins.orchestrator.integrity }}"
    pluginConfig:
      dynamicPlugins:
        frontend:
          red-hat-developer-hub.backstage-plugin-orchestrator:
            appIcons:
              - importName: OrchestratorIcon
                name: orchestratorIcon
            dynamicRoutes:
              - importName: OrchestratorPage
                menuItem:
                  icon: orchestratorIcon
                  text: Orchestrator
                path: /orchestrator
  - disabled: false
    package: "{{ $config.orchestratorPlugins.scaffolderBackendOrchestrator.package }}"
    integrity: "{{ $config.orchestratorPlugins.scaffolderBackendOrchestrator.integrity }}"
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow-platform-data-index-service.{{ .Release.Namespace }}
  - disabled: false
    package: "{{ $config.orchestratorPlugins.orchestratorFormWidgets.package }}"
    integrity: "{{ $config.orchestratorPlugins.orchestratorFormWidgets.integrity }}"
    pluginConfig:
      dynamicPlugins:
        frontend:
          red-hat-developer-hub.backstage-plugin-orchestrator-form-widgets: {}
{{- end }}
{{- define "orchestrator.plugins.config" }}
orchestratorPlugins: 
    scope: "@redhat"
    orchestrator:
      package: "https://npm.registry.redhat.com/@redhat/backstage-plugin-orchestrator/-/backstage-plugin-orchestrator-1.6.0.tgz"
      integrity: sha512-fOSJv2PgtD2urKwBM7p9W6gV/0UIHSf4pkZ9V/wQO0eg0Zi5Mys/CL1ba3nO9x9l84MX11UBZ2r7PPVJPrmOtw==
    orchestratorBackend:
      package: "https://npm.registry.redhat.com/@redhat/backstage-plugin-orchestrator-backend-dynamic/-/backstage-plugin-orchestrator-backend-dynamic-1.6.0.tgz"
      integrity: sha512-Kr55YbuVwEADwGef9o9wyimcgHmiwehPeAtVHa9g2RQYoSPEa6BeOlaPzB6W5Ke3M2bN/0j0XXtpLuvrlXQogA==
    scaffolderBackendOrchestrator:
      package: "https://npm.registry.redhat.com/@redhat/backstage-plugin-scaffolder-backend-module-orchestrator-dynamic/-/backstage-plugin-scaffolder-backend-module-orchestrator-dynamic-1.6.0.tgz"
      integrity: sha512-Bueeix4661fXEnfJ9y31Yw91LXJgw6hJUG7lPVdESCi9VwBCjDB9Rm8u2yPqP8sriwr0OMtKtqD+Odn3LOPyVw==
    orchestratorFormWidgets:
      package: "https://npm.registry.redhat.com/@redhat/backstage-plugin-orchestrator-form-widgets/-/backstage-plugin-orchestrator-form-widgets-1.6.0.tgz"
      integrity: sha512-Tqn6HO21Q1TQ7TFUoRhwBVCtSBzbQYz+OaanzzIB0R24O6YtVx3wR7Chtr5TzC05Vz5GkBO1+FZid8BKpqljgA==
{{- end }}