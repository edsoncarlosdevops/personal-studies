# Cert-Manager

## Visao Geral

cert-manager e um operador Kubernetes que automatiza a gestao e renovacao de certificados TLS. Ele pode obter certificados de diversas fontes (Let's Encrypt, AWS ACM, HashiCorp Vault, CA interna) e injeta-los nos Ingresses automaticamente.

## O que ele faz no projeto

No contexto da stack de monitoramento, o cert-manager e usado como dependencia para:
- OTEL Operator webhooks - os webhooks de admission precisam de certificados TLS
- Futuros Ingresses - Quando expor Grafana/Prometheus com HTTPS

## Arquitetura

```
cert-manager
    |
    +-> Issuer / ClusterIssuer (autoridade certificadora)
    |       |
    |       +-> Let's Encrypt (ACME)
    |       +-> AWS ACM (Private CA)
    |       +-> Self-Signed (dev)
    |       +-> Vault
    |
    +-> Certificate (recurso que solicita o certificado)
    |       |
    |       +-> Gera Secret com TLS
    |
    +-> Ingress Shoehorn
            |
            +-> Injeta certificado no Ingress automaticamente
```

## CRDs Instalados

| CRD | Funcao |
|-----|--------|
| Issuer | Autoridade certificadora (por namespace) |
| ClusterIssuer | Autoridade certificadora (global) |
| Certificate | Solicita um certificado |
| CertificateRequest | Requisicao de certificado (interno) |

## Exemplo: Certificado com Let's Encrypt

### 1. Criar ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@dominio.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### 2. Solicitar certificado automaticamente no Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
    - hosts:
        - grafana.seudominio.com
      secretName: grafana-tls
  rules:
    - host: grafana.seudominio.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 80
```

## Comandos Uteis

```bash
# Verificar pods
kubectl get pods -n cert-manager

# Ver CRDs instalados
kubectl get crd | grep cert-manager

# Ver certificados
kubectl get certificates --all-namespaces

# Ver detalhes de um certificado
kubectl describe certificate <nome> -n <namespace>
```

## Referencias

- Documentacao Oficial: https://cert-manager.io/docs/
- Configuracao ACME: https://cert-manager.io/docs/configuration/acme/
- Helm Chart: https://cert-manager.io/docs/installation/helm/
