# 📦 GitLab include for DAST — Nuclei + OWASP ZAP

Include GitLab para execução de scans DAST com Nuclei (recon) e OWASP ZAP (baseline, API scan ou full-scan).
Use este template como include em seus projetos para executar verificações automatizadas e, opcionalmente, enviar os relatórios ao DefectDojo de forma idempotente.

> Os nomes dos inputs seguem o padrão `snake_case` exigido pelo `spec:inputs` do GitLab. Referencie-os exatamente como abaixo.

## 🔧 Inputs

### Gerais

| Input | Descrição | Default | Obrigatório |
|---|---|---:|:---:|
| `stage` | Stage onde os jobs rodarão | `dast` | Não |
| `environment` | Nome do ambiente usado pelo job ZAP | `dast` | Não |
| `dependencie_jobs` | Jobs aguardados antes dos scans (YAML list, ex: `["build","test"]`) | `[""]` | Não |

### Nuclei / ZAP

| Input | Descrição | Default | Obrigatório |
|---|---|---:|:---:|
| `zap_target_url` | URL da aplicação a ser escaneada (dev/hml) | `""` | Sim |
| `zap_auth_token` | Bearer token para APIs autenticadas (CI/CD variable masked) | `""` | Não |
| `zap_api_spec_url` | URL do OpenAPI (JSON/YAML) para o API scan | `""` | Só para API scan |
| `zap_api_format` | Formato da spec: `openapi` / `graphql` / `soap` | `openapi` | Não |
| `zap_min_level` | Nível mínimo de alerta passado ao ZAP CLI (`PASS`/`IGNORE`/`INFO`/`WARN`/`FAIL`) | `FAIL` | Não |
| `zap_spider_mins` | Minutos de crawling no full-scan | `3` | Não |
| `zap_rules_file` | Path para arquivo `.conf` de regras customizadas | `""` | Não |
| `zap_api_enabled` | Habilita o API scan dentro do job `zap` (`true`/`false`) | `false` | Não |
| `zap_full_scan` | Se `true`, o job `zap` roda full-scan; se `false`, roda baseline | `true` | Não |
| `zap_allow_prod` | Permite full-scan em URLs de produção quando `true` | `true` | Não |
| `zap_audit_only` | Se `true`, adiciona `-I` (audit-only); se `false`, o ZAP pode falhar o job | `true` | Não |
| `zap_extra_args` | Argumentos extras passados aos scripts ZAP | `""` | Não |
| `zap_contexts_dir` | Diretório local com arquivos `.context` | `contexts` | Não |
| `zap_scripts_dir` | Diretório local com scripts ZAP | `scripts` | Não |
| `zap_runner_tags` | Runner tags para o job ZAP (YAML list, ex: `["linux","docker"]`) | `""` | Não |

### DefectDojo

| Input | Descrição | Default | Obrigatório |
|---|---|---:|:---:|
| `send_to_defectdojo` | Habilita upload dos relatórios ao DefectDojo (`true`/`false`) | `false` | Não |
| `defectdojo_url` | URL base do DefectDojo | `""` | Se `send_to_defectdojo=true` |
| `defectdojo_api_key` | API key do DefectDojo (masked CI variable) | `""` | Se `send_to_defectdojo=true` |
| `defectdojo_product_name` | Nome do produto no DefectDojo (`auto_create_context`) | `""` | Se `send_to_defectdojo=true` |
| `defectdojo_product_type_name` | Product type usado ao criar o produto na primeira execução | `ZAP Scan` | Não |
| `defectdojo_engagement_name` | Nome do engagement (`auto_create_context`) | `CI/CD` | Não |
| `defectdojo_nuclei_product_type_name` | Product type para uploads do Nuclei | `Nuclei Scan` | Não |
| `defectdojo_zap_product_type_name` | Product type para uploads do ZAP | `ZAP Scan` | Não |
| `defectdojo_engagement_id` | **[DEPRECATED]** mantido por compatibilidade | `""` | Não |

> Observação: `zap_target_url` é essencial para qualquer scan; configure `zap_auth_token` como variable masked quando necessário.

## ⚠️ Variáveis obrigatórias

- **`zap_target_url`**: URL da aplicação a ser escaneada — obrigatório para qualquer scan.
- **`defectdojo_url`**, **`defectdojo_api_key`** e **`defectdojo_product_name`**: obrigatórios apenas se `send_to_defectdojo=true`.

## Sobre `dependencie_jobs`

O input `dependencie_jobs` permite declarar uma lista de jobs que os scans devem aguardar (adicionados ao `needs:`). Exemplo no `include`:

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      dependencie_jobs: '["build","test"]'
      zap_target_url: "https://hml.example.com"
```

Ou sobrescrevendo no job que estende o template:

```yaml
zap_run:
  extends: zap
  variables:
    TARGET_URL: "https://hml.example.com"
```

Note: mantenha o formato de lista YAML (string) para compatibilidade com o render dos `inputs`.

Nota sobre `zap_min_level`:

Defina diretamente um dos níveis aceitos pelo ZAP CLI: `PASS`, `IGNORE`, `INFO`, `WARN`, `FAIL`. O valor default é `FAIL`.

## 🚀 How to use

Adicione o include no seu `.gitlab-ci.yml`. Exemplos:

### Include via projeto (recomendado)

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      zap_target_url: "https://hml.example.com"
      zap_api_enabled: "false"
```

### Include via raw (GitHub raw)

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/Tooark/owasp-zap-template-include/main/.gitlab-ci.yml'
    inputs:
      zap_target_url: "https://hml.example.com"
      zap_api_enabled: "false"
```

## ✅ Comportamento dos jobs

O template define **2 jobs**, cada um já executando o scan e o envio ao DefectDojo no mesmo job:

- **`nuclei`**: roda o Nuclei (recon) contra `zap_target_url`, gera `nuclei-report.jsonl` e, se `send_to_defectdojo=true`, envia ao DefectDojo (`scan_type=Nuclei Scan`, `test_title=DAST`).
- **`zap`**: executa o OWASP ZAP conforme os inputs e envia os relatórios JSON ao DefectDojo (`scan_type=ZAP`, `test_title=DAST`). A modalidade do scan é decidida internamente:
  - `zap_full_scan=true` → **full-scan** (bloqueado em URLs de produção, salvo `zap_allow_prod=true`).
  - `zap_full_scan=false` → **baseline**; e, se `zap_api_enabled=true`, também executa o **API scan**.

Ambos os jobs usam `allow_failure: true` e reutilizam a biblioteca interna `.defectdojo_lib`, que envia via `POST /api/v2/reimport-scan/` com `close_old_findings=true` + `auto_create_context=true`, garantindo idempotência (reexecuções consolidam no mesmo teste, sem duplicar findings).

## Exemplos rápidos

- Rodar apenas o baseline do ZAP (sem full-scan) com API scan habilitado:

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      zap_target_url: "https://hml.example.com"
      zap_full_scan: "false"
      zap_api_enabled: "true"
      zap_api_spec_url: "https://hml.example.com/openapi.json"
```

- Bloquear o pipeline em caso de alerta (remover audit-only):

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      zap_target_url: "https://hml.example.com"
      zap_audit_only: "false"
```

## Segurança & produção

- Scans ativos (API/full) podem gerar tráfego similar a ataques; não execute em produção sem controles: janela de manutenção, contas de teste, IP allowlist, e coordenação com times de infra/ops.
- Por padrão, o job `zap` bloqueia o full-scan contra URLs de produção (que contenham `prod`/`production`); para permitir, defina `zap_allow_prod=true`.
- Se você tem apenas um ambiente, prefira rodar somente o `baseline` (`zap_full_scan=false`) em produção e usar um clone mínimo para active scans.

## Extensões recomendadas

- Job `quality_gate` que parseia os JSONs do ZAP e falha o pipeline se houver N alerts acima do nível `zap_min_level`.
- Converter resultados para SARIF para integração com dashboards e runner security scanners.
- Implementar `scripts/zap-report-parser.py` para normalizar filtros e reduzir falsos positivos antes do upload ao DefectDojo.

## Contextos e Scripts do OWASP ZAP

Este template suporta commitar arquivos `.context` e scripts ZAP no repositório e usá-los no CI.

- Coloque seus contextos em `contexts/` (ou defina `zap_contexts_dir`) e scripts em `scripts/` (ou `zap_scripts_dir`).
- O pipeline copia automaticamente essas pastas para `/zap/wrk/` dentro do container, então você pode referenciar `-context /zap/wrk/contexts/<meu>.context` e scripts pelo caminho `/zap/wrk/scripts/...`.
- Para passar argumentos ZAP adicionais (ex: `-context`, `-user`, `-config`), use o input `zap_extra_args`. Exemplo de uso sobrescrevendo o job:

```yaml
dast:api:
  extends: zap
  variables:
    TARGET_URL: "https://hml.seuapp.com"
    ZAP_EXTRA_ARGS: >-
      -z "-config api.key='' -context /zap/wrk/contexts/hml.context -user admin"
```

Isso permite usar contextos exportados do GUI do ZAP e scripts personalizados (Authentication, Passive/Active rules, Proxy, etc.) diretamente no CI.

## Exemplo completo (todos os parâmetros)

Exemplo de include com todos os inputs suportados e um `zap_extra_args` demonstrativo. Ajuste valores/paths conforme seu ambiente; valores sensíveis devem ser definidos como CI/CD variables masked.

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      stage: dast
      environment: dast
      dependencie_jobs: '["build","test"]'
      zap_target_url: "https://hml.example.com"
      zap_auth_token: "${ZAP_AUTH_TOKEN}" # defina como masked CI variable
      zap_api_spec_url: "https://hml.example.com/openapi.json"
      zap_api_format: "openapi"
      zap_min_level: "WARN"
      zap_spider_mins: "5"
      zap_rules_file: "configs/zap-web-rules.conf"
      zap_api_enabled: "true"
      zap_full_scan: "true"
      zap_allow_prod: "false"
      zap_audit_only: "true"
      zap_contexts_dir: "contexts"
      zap_scripts_dir: "scripts"
      zap_runner_tags: '["linux","docker"]'
      zap_extra_args: >-
        -z "-config api.key='' -context /zap/wrk/contexts/hml.context -user admin -config connection.timeout=60000"
      send_to_defectdojo: "true"
      defectdojo_url: "https://defectdojo.example.com"
      defectdojo_api_key: "${DEFECTDOJO_API_KEY}" # defina como masked CI variable
      defectdojo_product_name: "Minha Aplicacao"
      defectdojo_product_type_name: "Web"
      defectdojo_engagement_name: "CI/CD"
      defectdojo_nuclei_product_type_name: "Nuclei Scan"
      defectdojo_zap_product_type_name: "ZAP Scan"
```

Exemplo de job que usa o include e passa `ZAP_EXTRA_ARGS` diretamente (substitui inputs quando usado a nível de job):

```yaml
dast:api:
  extends: zap
  variables:
    TARGET_URL: "https://hml.example.com"
    ZAP_API_ENABLED: "true"
    ZAP_EXTRA_ARGS: >-
      -z "-config api.key='' -context /zap/wrk/contexts/hml.context -user admin -config connection.timeout=60000"
    ZAP_RULES_FILE: "configs/zap-api-rules.conf"
```

## Contribuição

PRs e issues são bem-vindas — abra uma issue no repositório ou envie um pull request com melhorias.

---

## Mantenedores
Membros Tooark

| <img src="https://avatars.githubusercontent.com/u/97809060?v=4" width=120> | 
| :-------------------------------------------------------------------------: |
| [**Stenio Ignacio**](https://Gitlab.com/stenioignacio) |
