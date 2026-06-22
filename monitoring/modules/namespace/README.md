# Namespace (Transicional)

## Visao Geral

Este modulo foi originalmente criado para gerenciar o namespace `monitoring` como um recurso separado. Com a evolucao do projeto, cada Helm chart passou a criar seu proprio namespace via `create_namespace = true`.

## Status Atual

Este modulo e **transicional** - ele existe apenas para compatibilidade com referencias existentes. O output `namespace_name` retorna o nome do namespace diretamente da variavel de input.

## Por que foi descontinuado?

Antes:
```
Modulo Namespace -> kubernetes_namespace.resource
                   Helm Charts -> create_namespace = false
```

Problema: Multiplos modulos tentando criar o mesmo namespace causava conflitos.

Depois:
```
Cada Helm Chart -> create_namespace = true
Modulo Namespace -> Apenas output (vazio)
```

Vantagem: Cada chart e auto-suficiente. Se o namespace ja existe, o Helm simplesmente ignora.

## Inputs

| Variavel | Tipo | Default | Descricao |
|----------|------|---------|-----------|
| namespace_name | string | monitoring | Nome do namespace |

## Outputs

| Output | Valor | Descricao |
|--------|-------|-----------|
| namespace_name | var.namespace_name | Nome do namespace monitoring |
