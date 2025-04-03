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
    package: ./dynamic-plugins/dist/backstage-plugin-notifications
    pluginConfig:
      dynamicPlugins:
        frontend:
          backstage.plugin-notifications:
            dynamicRoutes:
              - importName: NotificationsPage
                menuItem:
                  config:
                    props:
                      titleCounterEnabled: true
                      webNotificationsEnabled: false
                  importName: NotificationsSidebarItem
                path: /notifications
  - disabled: true
    package: ./dynamic-plugins/dist/backstage-plugin-signals
    pluginConfig:
      dynamicPlugins:
        frontend:
          backstage.plugin-signals: {}
  - disabled: true
    package: ./dynamic-plugins/dist/backstage-plugin-notifications-backend-dynamic
  - disabled: true
    package: ./dynamic-plugins/dist/backstage-plugin-signals-backend-dynamic
{{- end }}

{{- define "orchestrator.plugins.config" }}
orchestratorPlugins: 
    scope: "https://github.com/rhdhorchestrator/orchestrator-plugins-internal-release/releases/download/1.4.0"
    orchestrator:
      package: "backstage-plugin-orchestrator-1.4.0.tgz"
      integrity: sha512-2yasbfBZ3iKntArIfK+hk9tvv4b/dy9+WKXOcWIotqkI1gv+Nhvy+m55KAUWi2vmfM0rj3EoG6YP+3Zajn1KyA==
    orchestratorBackend:
      package: "backstage-plugin-orchestrator-backend-dynamic-1.4.0.tgz"
      integrity: sha512-2aOHDLFrGMAtyHFiyGZwVBZ9Op+TmKYUwfZxwoaGJ1s6JSy/0qgqineEEE0K3dn/f17XBUj+H1dwa5Al598Ugw==
{{- end }}