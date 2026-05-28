# modulos terraform

modulos reutilizaveis para provisionar infra na aws.

## modulos disponiveis

| modulo | descricao |
|--------|-----------|
| **vpc** | vpc com subnets publicas/privadas, nat gateway, internet gateway |
| **eks** | cluster kubernetes eks com node group, iam roles e policies |
| **rds** | postgresql em subnets privadas com security group |
| **bastion** | ec2 para acesso ao banco (psql + git) |
| **argocd** | instalacao do argocd via helm no cluster eks |

## variaveis comuns

| variavel | descricao |
|----------|-----------|
| environment | dev, staging, prod |
| vpc_id | id da vpc onde os recursos serao criados |
| private_subnet_ids | subnets privadas para recursos internos |

## como usar

```hcl
module "eks" {
  source = \"../../modules/eks\"

  environment    = \"dev\"
  k8s_version    = \"1.30\"
  subnet_ids     = module.vpc.private_subnet_ids
}
```
