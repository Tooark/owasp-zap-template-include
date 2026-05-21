# 📦 GitLab include for OWASP ZAP DAST — zap-template-include

Include GitLab para execução de scans DAST com OWASP ZAP (baseline, API scan e full-scan).
Use este template como include em seus projetos para executar verificações automatizadas e opcionalmente enviar relatórios para DefectDojo.

## 🔧 Inputs (principais)

| Input | Descrição | Default | Obrigatório |
|---|---|---:|:---:|
| `stage` | Stage onde os jobs rodarão | `dast` | Não |
| `environment` | Nome do ambiente usado em gates/opções | `dast` | Não |
| `DEPENDENCIE_JOBS` | Jobs que o pipeline deve aguardar antes de rodar os jobs ZAP (YAML list, ex: ["build","test"]) | `[]` | Não |
| `ZAP_TARGET_URL` | URL da aplicação a ser escaneada (HML/DEV) | `""` | Sim |
| `ZAP_AUTH_TOKEN` | Bearer token para APIs (CI/CD variable masked) | `""` | Não |
| `ZAP_API_SPEC_URL` | URL do OpenAPI (JSON/YAML) para API scan | `""` | Só para `api-scan` |
| `ZAP_API_FORMAT` | Formato da spec: `openapi` / `graphql` / `soap` | `openapi` | Não |
| `ZAP_MIN_LEVEL` | Nível mínimo para considerar alerta (`PASS|IGNORE|INFO|WARN|FAIL`) | `FAIL` | Não |
| `ZAP_SPIDER_MINS` | Minutos de crawling no full-scan | `3` | Não |
| `ZAP_RULES_FILE` | Path para arquivo `.conf` de regras customizadas | `""` | Não |
| `ZAP_API_ENABLED` | Habilita job de API scan (`true|false`) | `false` | Não |
| `ZAP_ALLOW_PROD` | Permite execução em produção quando `true` (usar com cautela) | `false` | Não |
| `ZAP_AUDIT_ONLY` | Se `true`, adiciona `-I` (audit-only). Se `false`, ZAP pode retornar exit code que falha o job | `true` | Não |
| `SEND_TO_DEFECTDOJO` | Habilita upload dos relatórios para DefectDojo (`true|false`) | `false` | Não |
| `DEFECTDOJO_URL` | URL base do DefectDojo | `""` | Se `SEND_TO_DEFECTDOJO=true` |
| `DEFECTDOJO_API_KEY` | API key do DefectDojo (masked CI variable) | `""` | Se `SEND_TO_DEFECTDOJO=true` |
| `DEFECTDOJO_ENGAGEMENT_ID` | Engagement ID no DefectDojo para associar scans | `""` | Opcional |
| `ZAP_EXTRA_ARGS` | Argumentos extras passados para os scripts ZAP (ex: `-z "-config api.key='' -context /zap/wrk/contexts/hml.context -user admin"`) | `""` | Não |
| `ZAP_CONTEXTS_DIR` | Diretório local no repo contendo `.context` (padrão `contexts`) | `contexts` | Não |
| `ZAP_SCRIPTS_DIR` | Diretório local no repo contendo scripts ZAP (padrão `scripts`) | `scripts` | Não |
| `ZAP_RUNNER_TAGS` | Runner tags para os jobs ZAP (formato YAML list, ex: `["linux","docker"]`) | `[]` | Não |

> Observação: `ZAP_TARGET_URL` é essencial para qualquer scan; configure `ZAP_AUTH_TOKEN` como variable masked quando necessário.

## ⚠️ Variáveis obrigatórias

- **`ZAP_TARGET_URL`**: URL da aplicação a ser escaneada — obrigatório para qualquer scan.
- **`DEFECTDOJO_URL`** e **`DEFECTDOJO_API_KEY`**: obrigatórios apenas se `SEND_TO_DEFECTDOJO=true`.

## About `DEPENDENCIE_JOBS`

`DEPENDENCIE_JOBS` (input) permite que você declare uma lista de jobs que os jobs ZAP devem depender (ser adicionados como `needs:`). Exemplo de uso no `include`:

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      DEPENDENCIE_JOBS: '["build","test"]'
      ZAP_TARGET_URL: "https://hml.example.com"
```

Ou sobrescrevendo no job que estende o template:

```yaml
zap_api_run:
  extends: zap_api_scan
  variables:
    DEPENDENCIE_JOBS: '["build","test"]'
    ZAP_TARGET_URL: "https://hml.example.com"
```

Note: mantenha o formato de lista YAML (string) para compatibilidade com o render do `inputs`.

Nota sobre `ZAP_MIN_LEVEL`:

O template não realiza mapeamento de valores legados; defina diretamente um dos níveis aceitos pelo ZAP CLI: `PASS`, `IGNORE`, `INFO`, `WARN`, `FAIL`. O valor default é `FAIL`.

## 🚀 How to use

Adicione o include no seu `.gitlab-ci.yml`. Exemplos:

### Include via projeto (recomendado)

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      ZAP_TARGET_URL: "https://hml.example.com"
      ZAP_API_ENABLED: "false"
```

### Include via raw (GitHub raw)

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/Tooark/owasp-zap-template-include/main/.gitlab-ci.yml'
    inputs:
      ZAP_TARGET_URL: "https://hml.example.com"
      ZAP_API_ENABLED: "false"
```

## ✅ Comportamento dos jobs

- `zap_baseline`: roda em todos os cenários (push, MR, pipeline manual), em modo passivo por padrão (`ZAP_AUDIT_ONLY=true`).
- `zap_api_scan`: executa quando `ZAP_API_ENABLED=true` e em branches de ambiente (dev/hml/stg/staging/homolog/development). Execução em produção só com `ZAP_ALLOW_PROD=true` e será manual (safety).
- `zap_full_scan`: reservado para `dev` e `hml` e sempre manual (pesado, pode gerar tráfego intenso).
- `zap_defectdojo`: job opcional que faz upload dos JSONs para DefectDojo quando `SEND_TO_DEFECTDOJO=true` e as variáveis `DEFECTDOJO_*` estiverem configuradas (manual por padrão).

## Exemplos rápidos

- Executar API scan via trigger (dev):

```bash
curl -X POST \
  -F token=TRIGGER_TOKEN \
  -F ref=dev \
  -F "variables[ZAP_API_ENABLED]=true" \
  https://gitlab.example.com/api/v4/projects/PROJECT_ID/trigger/pipeline
```

- Executar pipeline que bloqueia em caso de alerta (remover audit-only):

```bash
curl -X POST \
  -F token=TRIGGER_TOKEN \
  -F ref=dev \
  -F "variables[ZAP_API_ENABLED]=true" \
  -F "variables[ZAP_AUDIT_ONLY]=false" \
  https://gitlab.example.com/api/v4/projects/PROJECT_ID/trigger/pipeline
```

## Segurança & produção

- Scans ativos (API/full) podem gerar tráfego similar a ataques; não execute em produção sem controles: janela de manutenção, contas de teste, IP allowlist, e coordenação com times de infra/ops.
- Por padrão, este template evita rodar full-scan em produção e exige `ZAP_ALLOW_PROD=true` para permitir API scan em produção (manual).
- Se você tem apenas um ambiente, prefira rodar somente `baseline` em produção e usar um clone mínimo para active scans.

## Extensões recomendadas

- Job `quality_gate` que parseia os JSONs do ZAP e falha o pipeline se houver N alerts acima do nível `ZAP_MIN_LEVEL`.
- Converter resultados para SARIF para integração com dashboards e runner security scanners.
- Implementar `scripts/zap-report-parser.py` para normalizar filtros e reduzir falsos positivos antes do upload ao DefectDojo.

## Contextos e Scripts do OWASP ZAP

Este template suporta commitar arquivos `.context` e scripts ZAP no repositório e usá-los no CI.

- Coloque seus contextos em `contexts/` (ou defina `ZAP_CONTEXTS_DIR`) e scripts em `scripts/` (ou `ZAP_SCRIPTS_DIR`).
- O pipeline copia automaticamente essas pastas para `/zap/wrk/` dentro do container, então você pode referenciar `-context /zap/wrk/contexts/<meu>.context` e scripts pelo caminho `/zap/wrk/scripts/...`.
- Para passar argumentos ZAP adicionais (ex: `-context`, `-user`, `-config`), use `ZAP_EXTRA_ARGS`. Exemplo de uso:

```yaml
dast:api:
  extends: .zap_api_scan
  variables:
    ZAP_TARGET_URL: "https://hml.seuapp.com"
    ZAP_EXTRA_ARGS: >-
      -z "-config api.key='' -context /zap/wrk/contexts/hml.context -user admin"
```

Isso permite usar contextos exportados do GUI do ZAP e scripts personalizados (Authentication, Passive/Active rules, Proxy, etc.) diretamente no CI.

## Exemplo completo (todos os parâmetros)

Exemplo de include com todos os inputs suportados e um `ZAP_EXTRA_ARGS` demonstrativo. Ajuste valores/paths conforme seu ambiente; valores sensíveis devem ser definidos como CI/CD variables masked.

```yaml
include:
  - project: 'Tooark/owasp-zap-template-include'
    file: '/.gitlab-ci.yml'
    ref: 'main'
    inputs:
      stage: dast
      environment: dast
      ZAP_TARGET_URL: "https://hml.example.com"
      ZAP_AUTH_TOKEN: "${ZAP_AUTH_TOKEN}" # defina como masked CI variable
      ZAP_API_SPEC_URL: "https://hml.example.com/openapi.json"
      ZAP_API_FORMAT: "openapi"
      ZAP_MIN_LEVEL: "MEDIUM"
      ZAP_SPIDER_MINS: "5"
      ZAP_RULES_FILE: "configs/zap-web-rules.conf"
      ZAP_API_ENABLED: "true"
      SEND_TO_DEFECTDOJO: "true"
      DEFECTDOJO_URL: "https://defectdojo.example.com"
      DEFECTDOJO_API_KEY: "${DEFECTDOJO_API_KEY}" # defina como masked CI variable
      DEFECTDOJO_ENGAGEMENT_ID: "123"
      ZAP_ALLOW_PROD: "false"
      ZAP_AUDIT_ONLY: "true"
      ZAP_CONTEXTS_DIR: "contexts"
      ZAP_SCRIPTS_DIR: "scripts"
      ZAP_RUNNER_TAGS: '["linux","docker"]'
      ZAP_EXTRA_ARGS: >-
        -z "-config api.key='' -context /zap/wrk/contexts/hml.context -user admin -config connection.timeout=60000"

```

Exemplo de job que usa o include e passa `ZAP_EXTRA_ARGS` diretamente (substitui inputs quando usado a nível de job):

```yaml
dast:api:
  extends: .zap_api_scan
  variables:
    ZAP_TARGET_URL: "https://hml.example.com"
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
