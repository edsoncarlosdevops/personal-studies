# eks + rds

infra completa de devops na aws com terraform.

## o que tem aqui

- **vpc** com subnets publicas e privadas, nat gateway
- **eks** cluster kubernetes 1.30 com node group
- **rds** postgresql 16.14
- **bastion** ec2 para acesso ao banco (psql)
- **argocd** instalado via helm no cluster

## como usar

```bash
cd environments/dev
terraform init
terraform apply
```

## acessando o cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster
kubectl get nodes
```

## acessando o banco

```bash
ssh -i bastion-key.pem ec2-user@<bastion_ip>
psql -h <rds_endpoint> -U dbadmin -d appdb
```

## argocd

```bash
kubectl get svc -n argocd argocd-server  # pegar o dns do loadbalancer
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d
```

login: admin / senha acima
