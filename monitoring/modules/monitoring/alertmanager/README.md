# Alertmanager

## Visao Geral

O Alertmanager gerencia alertas enviados pelo Prometheus. Ele faz deduplicacao, agrupamento, silenciamento e roteamento para canais de notificacao como email, Slack, PagerDuty.

## O que ele faz no projeto

O Alertmanager recebe alertas do Prometheus e os encaminha para canais de notificacao configurados.

## Arquitetura

```
Prometheus (alerta disparado)
       |
       | POST /api/v1/alerts (JSON)
       v
Alertmanager
       |
       +-- Grupo por similaridade
       +-- Deduplica alertas repetidos
       +-- Aplica silenciamentos (se houver)
       |
       v
    Notificacao
  (email/slack/PagerDuty/etc)
```

## Como funciona o fluxo de alerta

### 1. Regra de alerta no Prometheus

No Prometheus, voce define regras que disparam alertas:

```yaml
# prometheus.rules.yml
groups:
  - name: app-rules
    rules:
      - alert: HighErrorRate
        expr: rate(http.server.request_count{status_code=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Taxa de erro alta ({{ $value }})"
```

### 2. Alerta disparado -> Alertmanager

Quando a condicao e verdadeira por 5 minutos, o Prometheus envia o alerta.

### 3. Alertmanager processa

- **Agrupa** alertas similares para evitar spam
- **Deduplica** alertas repetidos
- **Roteia** para o canal correto (email, Slack, etc)

## Configuracao Atual

Atualmente o Alertmanager roda com configuracao basica. Para produzir notificacoes, voce precisa:

### Exemplo: Notificacao no Slack

```yaml
# values.yaml do Alertmanager
config:
  global:
    slack_api_url: "https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXX"

  route:
    receiver: slack-notifications
    group_by: [alertname, severity]
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 4h

  receivers:
    - name: slack-notifications
      slack_configs:
        - channel: "#alerts-kubernetes"
          title: "{{ .GroupLabels.alertname }}"
          text: "{{ .CommonAnnotations.description }}"
```

### Exemplo: Notificacao por Email

```yaml
config:
  global:
    smtp_smarthost: "smtp.gmail.com:587"
    smtp_from: "monitoring@seudominio.com"
    smtp_auth_username: "seuemail@gmail.com"
    smtp_auth_password: "sua-senha-app"

  route:
    receiver: email-notifications

  receivers:
    - name: email-notifications
      email_configs:
        - to: "devops@seudominio.com"
```

## Comandos Uteis

```bash
# Ver status do Alertmanager
kubectl get pods -n monitoring | grep alertmanager

# Port-forward para UI do Alertmanager
kubectl port-forward -n monitoring svc/alertmanager 9093:9093

# Ver alertas ativos
# http://localhost:9093/#/alerts

# Ver configuracao atual
# http://localhost:9093/#/status

# Silenciar um alerta
# http://localhost:9093/#/silences
```

## Referencias

- [Documentacao Oficial](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Configuracao](https://prometheus.io/docs/alerting/latest/configuration/)
- [Integracoes](https://prometheus.io/docs/operating/integrations/#alertmanager)
