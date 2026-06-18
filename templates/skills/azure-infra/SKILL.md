# Skill: Azure Infrastructure

## Quando usar

- Provisionar recursos no Azure (VMs, AKS, App Services, Storage, etc.)
- Configurar networking (VNet, NSG, Private Endpoints, Front Door)
- Gerenciar identidades e RBAC
- Operar Azure Kubernetes Service (AKS)

## Convenções

### Naming Convention

Padrão: `{prefixo}-{env}-{sistema}-{region}-{tipo}-{seq}`

Exemplos:
- `prc-p-zu1-aks-001` — AKS prod, East US
- `prc-i-zu1-acr-001` — ACR QA, East US
- `prc-p-zu2-kv-001` — Key Vault prod, East US 2

### Regiões

| Código | Azure Region |
|---|---|
| `zu1` | East US |
| `zu2` | East US 2 |
| `zb1` | Brazil South |

### Regras invioláveis

1. **RBAC mínimo**: nunca Owner/Contributor desnecessário. Use roles built-in específicas
2. **Private Endpoints**: todo PaaS acessível por workloads internos deve usar PE
3. **Key Vault**: secrets, certificados e chaves sempre no Key Vault — nunca em app settings diretamente
4. **Diagnostic Settings**: todo recurso crítico com logs enviados pro Log Analytics
5. **Tags obrigatórias**: `environment`, `system`, `owner`, `cost-center`
6. **Lock de recursos**: Production resources com `CanNotDelete` lock
7. **NSG**: toda subnet com NSG associado, deny-all como última regra

### AKS

```bash
# Contexto
az aks get-credentials --resource-group rg-prod --name prc-p-zu1-aks-001

# Node pools: system (infra) + user (workloads)
# Autoscaler: requests realistas obrigatórios
# Pod disruption budget: definir para todo deployment
```

#### Regras AKS
- **Requests realistas** — autoscaler depende disso para scale-down
- **safe-to-evict: "true"** — em pods que podem ser recriados
- **PDB** (PodDisruptionBudget) — para todo deployment crítico
- **Ingress via AGIC ou nginx** — nunca LoadBalancer por serviço
- **Azure CNI Overlay** — preferido para novos clusters (IP space eficiente)

### Networking

```hcl
# VNet com subnets segregadas
# - aks-subnet: /22 (1024 IPs para pods)
# - pe-subnet: /26 (Private Endpoints)
# - agw-subnet: /27 (Application Gateway)
# - bastion-subnet: /27 (AzureBastionSubnet — nome exato)
```

### Identity

- **Managed Identity** (System ou User-Assigned): preferida sobre Service Principal
- **Workload Identity** para pods no AKS: federated credentials
- **OIDC Federation** para pipelines CI/CD: nunca secrets de SP

### Validação

```bash
# Azure CLI
az deployment group validate -g rg-dev -f main.bicep

# Terraform
terraform plan -out=tfplan
terraform validate

# Segurança
checkov -d .
tfsec .
```

### Anti-patterns

- ❌ Public IP em recursos internos sem justificativa
- ❌ Storage Account com acesso público (AllowBlobPublicAccess = true)
- ❌ SQL Server sem firewall rules (default deny)
- ❌ App Service sem VNet integration para acessar recursos internos
- ❌ Key Vault com access policies — use RBAC model
