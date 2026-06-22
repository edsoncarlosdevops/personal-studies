########
# Helm #
########

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = var.grafana_namespace
  }

  data = {
    "dashboard-cost.json" = <<-EOF
{
  "dashboard": {
    "title": "Custo por Namespace (OpenCost)",
    "uid": "cost-dashboard",
    "tags": [
      "observabilidade",
      "custo",
      "opencost",
      "finops"
    ],
    "timezone": "browser",
    "refresh": "5m",
    "schemaVersion": 39,
    "panels": [
      {
        "id": 1,
        "title": "Custo Acumulado por Namespace (Hoje)",
        "type": "barchart",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 10,
          "w": 24,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "sum by (namespace) (container_memory_allocation_bytes * on(instance, node) group_right() node_ram_hourly_cost + container_cpu_allocation * on(instance, node) group_right() node_cpu_hourly_cost)",
            "legendFormat": "{{namespace}}",
            "interval": "5m"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "currencyUSD",
            "custom": {
              "stacking": {
                "mode": "none"
              }
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Top 10 Pods Mais Caros",
        "type": "table",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 10,
          "w": 12,
          "x": 0,
          "y": 10
        },
        "targets": [
          {
            "expr": "topk(10, sum by (pod_name, namespace) (pod_cost))",
            "legendFormat": "{{namespace}}/{{pod_name}}",
            "format": "table",
            "instant": true
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "currencyUSD",
            "custom": {
              "align": "left"
            }
          }
        }
      },
      {
        "id": 3,
        "title": "Custo por Servico (7 dias)",
        "type": "timeseries",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 20
        },
        "targets": [
          {
            "expr": "sum by (namespace) (pod_cost)",
            "legendFormat": "{{namespace}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "currencyUSD"
          }
        }
      }
    ]
  },
  "overwrite": true
}
    EOF
    "dashboard-deployments.json" = <<-EOF
{
  "dashboard": {
    "title": "Estado dos Deployments",
    "uid": "deployments-dashboard",
    "tags": [
      "observabilidade",
      "deployments",
      "k8s",
      "health"
    ],
    "timezone": "browser",
    "refresh": "30s",
    "schemaVersion": 39,
    "panels": [
      {
        "id": 1,
        "title": "Replicas Desejadas vs Disponiveis por Deployment",
        "type": "barchart",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "kube_deployment_spec_replicas",
            "legendFormat": "desejado - {{namespace}}/{{deployment}}"
          },
          {
            "expr": "kube_deployment_status_replicas_available",
            "legendFormat": "disponivel - {{namespace}}/{{deployment}}"
          },
          {
            "expr": "kube_deployment_status_replicas_unavailable",
            "legendFormat": "indisponivel - {{namespace}}/{{deployment}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "short",
            "custom": {
              "stacking": {
                "mode": "none"
              }
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Pods com Problemas",
        "type": "table",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "kube_pod_status_phase{phase!=\"Running\"}",
            "legendFormat": "{{namespace}}/{{pod}} - {{phase}}",
            "format": "table",
            "instant": true
          }
        ],
        "fieldConfig": {
          "defaults": {
            "custom": {
              "align": "left"
            }
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "phase"
              },
              "properties": [
                {
                  "id": "color",
                  "value": {
                    "mode": "thresholds",
                    "thresholds": {
                      "steps": [
                        {
                          "color": "red",
                          "value": 0
                        },
                        {
                          "color": "orange",
                          "value": 1
                        },
                        {
                          "color": "green",
                          "value": 2
                        }
                      ]
                    }
                  }
                }
              ]
            }
          ]
        }
      },
      {
        "id": 3,
        "title": "Restarts por Pod (ultimas 24h)",
        "type": "barchart",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        },
        "targets": [
          {
            "expr": "topk(20, increase(kube_pod_container_status_restarts_total[24h]))",
            "legendFormat": "{{namespace}}/{{pod}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "short",
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": 0
                },
                {
                  "color": "orange",
                  "value": 3
                },
                {
                  "color": "red",
                  "value": 10
                }
              ]
            }
          }
        }
      },
      {
        "id": 4,
        "title": "Deployments com Replicas Indisponiveis",
        "type": "stat",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 12,
          "y": 8
        },
        "targets": [
          {
            "expr": "count(kube_deployment_status_replicas_unavailable > 0) by (namespace)",
            "legendFormat": "{{namespace}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "short",
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": 0
                },
                {
                  "color": "red",
                  "value": 1
                }
              ]
            }
          }
        }
      }
    ]
  },
  "overwrite": true
}
    EOF
    "dashboard-observabilidade.json" = <<-EOF
{
  "dashboard": {
    "title": "Stack de Observabilidade",
    "tags": [
      "observabilidade",
      "otel",
      "eks"
    ],
    "timezone": "browser",
    "refresh": "30s",
    "schemaVersion": 39,
    "panels": [
      {
        "id": 1,
        "title": "CPU dos Containers (top 5)",
        "type": "timeseries",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "topk(5, sum(rate(container_cpu_usage_seconds_total{namespace!=\"\"}[5m])) by (container, namespace))",
            "legendFormat": "{{namespace}}/{{container}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Memory dos Containers (top 5)",
        "type": "timeseries",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "topk(5, sum(container_memory_working_set_bytes{namespace!=\"\"}) by (container, namespace))",
            "legendFormat": "{{namespace}}/{{container}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        }
      },
      {
        "id": 3,
        "title": "Pods por Namespace",
        "type": "stat",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 4,
          "w": 8,
          "x": 0,
          "y": 8
        },
        "targets": [
          {
            "expr": "count(kube_pod_status_phase{phase=\"Running\"}) by (namespace)",
            "legendFormat": "{{namespace}}"
          }
        ]
      },
      {
        "id": 4,
        "title": "Nodes - CPU (%)",
        "type": "timeseries",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 8,
          "x": 8,
          "y": 8
        },
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[1m])) by (instance) * 100)",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "id": 5,
        "title": "Nodes - Memory (%)",
        "type": "timeseries",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 8,
          "x": 16,
          "y": 8
        },
        "targets": [
          {
            "expr": "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "id": 6,
        "title": "Traces - api-pedidos",
        "type": "table",
        "datasource": {
          "type": "tempo",
          "uid": "P214B5B846CF3925F"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 16
        },
        "targets": [
          {
            "query": "{\"rootServiceName\"=\"api-pedidos\"}",
            "limit": 20
          }
        ],
        "fieldConfig": {
          "defaults": {
            "custom": {
              "align": "left"
            }
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "traceID"
              },
              "properties": [
                {
                  "id": "links",
                  "value": [
                    {
                      "title": "Ver detalhes",
                      "url": "",
                      "internal": {
                        "queryType": "traceId",
                        "datasourceUid": "P214B5B846CF3925F",
                        "datasourceName": "Tempo"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      },
      {
        "id": 7,
        "title": "Logs (Loki)",
        "type": "logs",
        "datasource": {
          "type": "loki",
          "uid": "P8E80F9AEF21F6940"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 16
        },
        "targets": [
          {
            "expr": "{stream=~\".+\"}",
            "limit": 50
          }
        ]
      },
      {
        "id": 8,
        "title": "Uptime dos Pods",
        "type": "table",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 24
        },
        "targets": [
          {
            "expr": "time() - kube_pod_start_time",
            "legendFormat": "{{pod}}",
            "format": "table",
            "instant": true
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s",
            "custom": {
              "align": "left"
            }
          }
        }
      }
    ]
  },
  "overwrite": true
}
    EOF
    "dashboard-resources.json" = <<-EOF
{
  "dashboard": {
    "title": "Recursos por Namespace (Requests vs Limits)",
    "uid": "resources-dashboard",
    "tags": [
      "observabilidade",
      "recursos",
      "capacity",
      "requests-limits"
    ],
    "timezone": "browser",
    "refresh": "30s",
    "schemaVersion": 39,
    "panels": [
      {
        "id": 1,
        "title": "CPU - Requests vs Limits por Namespace",
        "type": "barchart",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "sum(kube_pod_container_resource_requests{resource=\"cpu\"}) by (namespace)",
            "legendFormat": "requests - {{namespace}}"
          },
          {
            "expr": "sum(kube_pod_container_resource_limits{resource=\"cpu\"}) by (namespace)",
            "legendFormat": "limits - {{namespace}}"
          },
          {
            "expr": "sum by (namespace) (rate(container_cpu_usage_seconds_total{namespace!=\"\"}[5m]))",
            "legendFormat": "uso - {{namespace}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "cores",
            "custom": {
              "stacking": {
                "mode": "none"
              }
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Memoria - Requests vs Limits por Namespace",
        "type": "barchart",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "sum(kube_pod_container_resource_requests{resource=\"memory\"}) by (namespace)",
            "legendFormat": "requests - {{namespace}}"
          },
          {
            "expr": "sum(kube_pod_container_resource_limits{resource=\"memory\"}) by (namespace)",
            "legendFormat": "limits - {{namespace}}"
          },
          {
            "expr": "sum by (namespace) (container_memory_working_set_bytes{namespace!=\"\"})",
            "legendFormat": "uso - {{namespace}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes",
            "custom": {
              "stacking": {
                "mode": "none"
              }
            }
          }
        }
      },
      {
        "id": 3,
        "title": "Uso vs Request (%) por Namespace",
        "type": "timeseries",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        },
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{namespace!=\"\"}[5m])) by (namespace) / sum(kube_pod_container_resource_requests{resource=\"cpu\"}) by (namespace)",
            "legendFormat": "CPU - {{namespace}}"
          },
          {
            "expr": "sum(container_memory_working_set_bytes{namespace!=\"\"}) by (namespace) / sum(kube_pod_container_resource_requests{resource=\"memory\"}) by (namespace)",
            "legendFormat": "MEM - {{namespace}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit"
          }
        }
      },
      {
        "id": 4,
        "title": "Pods sem Limits (CPU)",
        "type": "stat",
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "gridPos": {
          "h": 6,
          "w": 6,
          "x": 0,
          "y": 16
        },
        "targets": [
          {
            "expr": "count(kube_pod_container_resource_limits{resource=\"cpu\"} == 0) by (namespace)",
            "legendFormat": "{{namespace}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": 0
                },
                {
                  "color": "red",
                  "value": 1
                }
              ]
            }
          }
        }
      }
    ]
  },
  "overwrite": true
}
    EOF
    "dashboard-slo.json" = <<-EOF
{
  "dashboard": {
    "title": "SLO - Stack de Observabilidade",
    "uid": "slo-dashboard",
    "tags": [
      "slo",
      "sli",
      "sla"
    ],
    "timezone": "browser",
    "editable": true,
    "refresh": "30s",
    "schemaVersion": 39,
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "panels": [
      {
        "title": "Disponibilidade dos Servicos",
        "type": "gauge",
        "gridPos": {
          "h": 8,
          "w": 8,
          "x": 0,
          "y": 0
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "targets": [
          {
            "expr": "avg(kube_pod_status_ready{namespace=\"monitoring\", condition=\"true\"})",
            "legendFormat": "Disponibilidade",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "red",
                  "value": null
                },
                {
                  "color": "red",
                  "value": 0.95
                },
                {
                  "color": "green",
                  "value": 0.96
                }
              ]
            }
          }
        },
        "options": {
          "reduceOptions": {
            "values": false,
            "calcs": [
              "lastNotNull"
            ]
          },
          "showThresholdLabels": true,
          "showThresholdMarkers": true
        }
      },
      {
        "title": "Uso de Memoria",
        "type": "gauge",
        "gridPos": {
          "h": 8,
          "w": 8,
          "x": 8,
          "y": 0
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "targets": [
          {
            "expr": "avg(container_memory_working_set_bytes{namespace=\"monitoring\", container!=\"\"} / on(container,pod) group_left() kube_pod_container_resource_requests{namespace=\"monitoring\", resource=\"memory\"})",
            "legendFormat": "Memoria",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 0.85
                },
                {
                  "color": "red",
                  "value": 0.95
                }
              ]
            }
          }
        },
        "options": {
          "reduceOptions": {
            "values": false,
            "calcs": [
              "lastNotNull"
            ]
          },
          "showThresholdLabels": true,
          "showThresholdMarkers": true
        }
      },
      {
        "title": "Uso de CPU",
        "type": "gauge",
        "gridPos": {
          "h": 8,
          "w": 8,
          "x": 16,
          "y": 0
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "targets": [
          {
            "expr": "avg(rate(container_cpu_usage_seconds_total{namespace=\"monitoring\", container!=\"\"}[5m]) / on(container,pod) group_left() kube_pod_container_resource_requests{namespace=\"monitoring\", resource=\"cpu\"})",
            "legendFormat": "CPU",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 0.85
                },
                {
                  "color": "red",
                  "value": 0.95
                }
              ]
            }
          }
        },
        "options": {
          "reduceOptions": {
            "values": false,
            "calcs": [
              "lastNotNull"
            ]
          },
          "showThresholdLabels": true,
          "showThresholdMarkers": true
        }
      },
      {
        "title": "Disponibilidade (Stat)",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 8,
          "x": 0,
          "y": 24
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "targets": [
          {
            "expr": "avg(kube_pod_status_ready{namespace=\"monitoring\", condition=\"true\"})",
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "decimals": 1,
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "#F2495C",
                  "value": null
                },
                {
                  "color": "#F2495C",
                  "value": 0.95
                },
                {
                  "color": "#73BF69",
                  "value": 0.96
                }
              ]
            }
          }
        },
        "options": {
          "colorMode": "background",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "horizontal",
          "reduceOptions": {
            "values": false,
            "calcs": [
              "lastNotNull"
            ]
          },
          "textMode": "auto"
        }
      },
      {
        "title": "Memoria (Stat)",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 8,
          "x": 8,
          "y": 24
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "targets": [
          {
            "expr": "avg(container_memory_working_set_bytes{namespace=\"monitoring\", container!=\"\"} / on(container,pod) group_left() kube_pod_container_resource_requests{namespace=\"monitoring\", resource=\"memory\"})",
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "decimals": 1,
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "#73BF69",
                  "value": null
                },
                {
                  "color": "#FF9830",
                  "value": 0.85
                },
                {
                  "color": "#F2495C",
                  "value": 0.95
                }
              ]
            }
          }
        },
        "options": {
          "colorMode": "background",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "horizontal",
          "reduceOptions": {
            "values": false,
            "calcs": [
              "lastNotNull"
            ]
          },
          "textMode": "auto"
        }
      },
      {
        "title": "CPU (Stat)",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 8,
          "x": 16,
          "y": 24
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "targets": [
          {
            "expr": "avg(rate(container_cpu_usage_seconds_total{namespace=\"monitoring\", container!=\"\"}[5m]) / on(container,pod) group_left() kube_pod_container_resource_requests{namespace=\"monitoring\", resource=\"cpu\"})",
            "legendFormat": "",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "decimals": 1,
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "#73BF69",
                  "value": null
                },
                {
                  "color": "#FF9830",
                  "value": 0.85
                },
                {
                  "color": "#F2495C",
                  "value": 0.95
                }
              ]
            }
          }
        },
        "options": {
          "colorMode": "background",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "horizontal",
          "reduceOptions": {
            "values": false,
            "calcs": [
              "lastNotNull"
            ]
          },
          "textMode": "auto"
        }
      }
    ]
  },
  "overwrite": true
}
    EOF
  }
}


resource "helm_release" "grafana" {
  name             = var.grafana_release_name
  chart            = var.grafana_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.grafana_namespace
  version          = var.grafana_chart_version
  repository       = var.grafana_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true
  values           = [data.template_file.values.rendered]
}

data "template_file" "values" {
  template = file("${path.module}/config/values.yaml")
  vars = {
    grafana_replica_count = var.grafana_replica_count
  }
}

