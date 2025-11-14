# Azure Static Web Apps 初期セットアップ手順 (Bicep)

Azure Static Web Apps (SWA) を Bicep で構築し、モノレポ（frontend / backend / IaC）体制で管理する手順。`docs/finance/CostEstimation.md` および `CostEstimation_Network.md` の前提どおり Free SKU を利用し、月額 $0 の範囲に収める。

## 1. モノレポ構成

| パス                | 役割                                   | 備考                                                                          |
| ------------------- | -------------------------------------- | ----------------------------------------------------------------------------- |
| `src/apps/frontend` | Next.js 15 + React 19 のフロントエンド | `appLocation` として `src/infra` から参照。                                   |
| `src/apps/backend`  | Azure Functions (Node.js 22)           | `apiLocation` に設定可能（初期値は空文字で未連携）。                          |
| `src/infra`         | Bicep テンプレート群                   | `main.bicep` / `modules/static-web-app.bicep` / `environments/*.bicepparam`。 |

## 2. 前提

- Azure CLI 2.60+（`az bicep version` でBicepサポートを確認）。
- サブスクリプション例: `iijan-map-dev`。`az account set --subscription <id>` で選択。
- リソースグループ `rg-iijan-map-dev`（なければ `az group create --name rg-iijan-map-dev --location japaneast`）。
- GitHub PAT など Static Web Apps とリポジトリを紐付けるための `repositoryToken` を安全に保管（1Password / Key Vault / GitHub Actions シークレットなど）。

## 3. Bicep テンプレート概要

- エントリーポイント: `src/infra/main.bicep`（`targetScope = 'resourceGroup'`）。
- モジュール: `src/infra/modules/static-web-app.bicep` が `Microsoft.Web/staticSites` を管理。
- 既定パラメータ: `location='East Asia'`, `skuName='Free'`, `appLocation='src/apps/frontend'`, `appArtifactLocation='.next'`。
- `repositoryToken` は `@secure()` パラメータ。渡さない場合は GitHub 連携を後で設定。

## 4. パラメータファイル

`src/infra/environments/dev.bicepparam` で dev 環境を定義済み。

```bicep
using '../main.bicep'

param location = 'East Asia'
param staticWebAppName = 'swa-iijan-map-dev'
param repositoryUrl = 'https://github.com/yusuke/cafe-mapping'
param branch = 'main'
param appLocation = 'src/apps/frontend'
param appArtifactLocation = '.next'
param tags = {
  project: 'cafe-mapping'
  environment: 'dev'
}
```

必要に応じて `apiLocation` を `src/apps/backend` に設定する。

## 5. デプロイ手順

### 5.1 CLI 拡張アップデート

```bash
az bicep upgrade
```

### 5.2 リソースグループ確認

```bash
az group show --name rg-iijan-map-dev --output table
```

存在しなければ作成する。

### 5.3 Bicep デプロイ

```bash
az deployment group create \
  --name iijan-map-dev-swa \
  --resource-group rg-iijan-map-dev \
  --template-file src/infra/main.bicep \
  --parameters @src/infra/environments/dev.bicepparam \
  --parameters repositoryToken=$GITHUB_PAT
```

- `repositoryToken` は GitHub PAT（`repo` + `workflow` 権限）を環境変数や Key Vault から注入。PAT を扱いたくない場合は `--parameters repositoryToken=` で空文字を渡し、後から Portal/CLI で連携。
- `skuName` を `Standard` にすると Preview/Stage 環境が使えるが、CostEstimation に基づく無料運用では `Free` を推奨。

### 5.4 出力確認

```bash
az deployment group show \
  --name iijan-map-dev-swa \
  --resource-group rg-iijan-map-dev \
  --query '{id:properties.outputs.staticWebAppResourceId.value, host:properties.outputs.staticWebAppDefaultHostname.value}'
```

## 6. GitHub Actions 連携

- デプロイ時に PAT を渡した場合、`azure-static-web-apps.yml` が自動で main ブランチに作成される。`app_location`, `api_location`, `output_location` がモノレポディレクトリと一致するか確認。
- PAT を渡していない場合は、Azure Portal で Static Web App → Deployment Center → GitHub 連携を設定する。
- `deployment_environment` を `dev` 固定にし、Free SKU の仕様に合わせて Preview ビルドを無効化。

## 7. コスト & モニタリング

- Free SKUのため `docs/finance/CostEstimation.md` で想定した $0 運用が可能。100GB/月の転送量が無料枠。
- Functions / API ログは Application Insights (Consumption) に送る。SWA単独では追加課金なし。
- 帯域監視: `az monitor metrics list --resource <SWA_ID> --metric ReceivedBytes TotalRequests`。Cosmos/Monitorと合わせて Cost Management アラートを設定。

## 8. 次アクション

1. `src/infra/modules` に Functions・Cosmos DB・Key Vault などを追加し、`src/infra/main.bicep` から呼び出して一括デプロイ可能にする。
2. GitHub Actions で `src/infra` を lint / validate（`az bicep build` や `what-if`）する CI を追加。
3. カスタムドメインと DNS (Azure DNS) を `NetworkDesign.md` の手順で割り当て、`src/infra` にも CNAME/証明書を反映する。
