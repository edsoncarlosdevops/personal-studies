# boas praticas terraform

## ordem de destroy para evitar erros

sempre destruir na ordem inversa da criacao:

```bash
terraform destroy -target=module.argocd -auto-approve
terraform destroy -target=module.eks -auto-approve
terraform destroy -target=module.rds -auto-approve
terraform destroy -target=module.bastion -auto-approve
terraform destroy -target=module.vpc -auto-approve
```

## porque o terraform trava no destroy

- recursos criados fora do terraform (helm, kubectl apply) nao estao no state
- ex: argocd cria um loadbalancer que o terraform nao gerencia
- ao destruir a vpc, o loadbalancer ainda esta preso na subnet

## como evitar

- usar `helm_release` do terraform em vez de `helm upgrade --install` via local-exec
- declarar `depends_on` para recursos com dependencias externas
- usar `terraform state rm` para remover recursos problematicos do state
- destruir manualmente recursos orfaos antes do destroy final

## recuperacao rapida

se o destroy travar:

```bash
# 1. remover do state o que nao quer mais
terraform state rm module.vpc.aws_subnet.public

# 2. deletar manualmente na aws
aws elb delete-load-balancer --load-balancer-name <nome>
aws ec2 delete-vpc --vpc-id <vpc-id>

# 3. rodar destroy de novo
terraform destroy
```

## dica final

sempre que possivel, prefira recursos nativos do terraform
(helm_release, kubernetes_namespace) em vez de local-exec.
assim o terraform gerencia o ciclo de vida completo.
