# exemplos argo cd

apps para testar app of apps e applicationset.

## estrutura

```
argocd-examples/
├── root-app.yaml           # app raiz que observa a pasta apps/
├── applicationset.yaml     # template que gera apps por ambiente
└── apps/
    ├── namespace.yaml
    ├── nginx-deploy.yaml
    ├── nginx-svc.yaml
    ├── engineering/         # manifestos do ambiente engineering
    └── production/          # manifestos do ambiente production
```

## app of apps

O `root-app` aponta para a pasta `apps/` e deploya tudo que esta la.
Para adicionar um novo recurso, basta criar um yaml dentro de `apps/` e dar push.

## applicationset

O `applicationset.yaml` usa um generator com lista de elementos.
Para cada elemento, ele cria um app apontando para `apps/{{name}}/`.

## na pratica

```bash
# aplicar os exemplos
kubectl apply -f root-app.yaml
kubectl apply -f applicationset.yaml

# ver apps no argocd
kubectl get applications -n argocd

# ver pods
kubectl get pods -n app-examples
kubectl get pods -n guestbook-engineering
kubectl get pods -n guestbook-production
```

## dica

qualquer alteracao nos yamls dentro de `apps/` + git push = argocd sincroniza sozinho.
