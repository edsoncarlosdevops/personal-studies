## Aplicacao CRUD (App RDS)

Aplicacao Node.js que conecta no RDS PostgreSQL, instrumentada pelo OTEL Operator.

---

## Testes e Dashboards

O projeto inclui recursos auxiliares em `monitoring/` (raiz do repo):

### App de Teste (auto-instrumentacao Python)

| Recurso | Localizacao | Descricao |
|---------|-------------|-----------|
| App de teste | `monitoring/tests/apps/api-pedidos.yaml` | API Flask com auto-instrumentacao Python (OTEL Operator) |
| Script de setup | `monitoring/tests/setup-lab.sh` | Sobe a app, gera trafego HTTP, verifica traces no Tempo |
| Annotation chave | `instrumentation.opentelemetry.io/inject-python: "monitoring/python-instrumentation"` | Habilita auto-instrumentation sem modificar codigo |

**Como usar:**

