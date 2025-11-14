# Infra (Azure Bicep)

Monorepo の IaC レイヤー。`main.bicep` とモジュール群で Azure Static Web Apps などのリソースを管理する。CostEstimation ドキュメントで想定した Free SKU / Serverless 構成を再現できる。

## ディレクトリ構成

```
src/infra/
├── main.bicep                # リソースグループ単位のエントリーポイント
├── modules/
│   └── static-web-app.bicep  # Static Web Apps 単体モジュール
└── environments/
    └── dev.bicepparam        # `cafemap-dev` 環境のパラメータ例
```

## 前提
- Azure CLI 2.60+ (`az bicep version` で確認)。
- 対象リソースグループ（例: `rg-cafemap-dev`）が作成済み。未作成の場合は `az group create --name rg-cafemap-dev --location japaneast`。
- GitHub の PAT や Static Web Apps のリポジトリ接続情報を `repositoryToken` パラメータで渡す。Key Vault / GitHub Actions シークレットから `--parameters repositoryToken=...` で供給する。

## デプロイ方法

```bash
# ログインとサブスクリプション選択
az login
az account set --subscription <SUBSCRIPTION_ID>

# Bicep デプロイ（リソースグループスコープ）
pnpm deploy:infra  # Turborepo経由で `turbo run deploy:infra --filter=@cafemap/infra`

# 直接CLIを叩く場合の例
az deployment group create \
  --name cafemap-dev-swa \
  --resource-group rg-cafemap-dev \
  --template-file src/infra/main.bicep \
  --parameters @src/infra/environments/dev.bicepparam \
  --parameters repositoryToken="$(op read op://Azure/github-pat/dev)"
```

`repositoryToken` を省略すると GitHub Actions 連携は構成されない（後から Azure Portal/CLI で接続が必要）。

## 出力
- `staticWebAppResourceId`: 作成した SWA のリソースID。
- `staticWebAppDefaultHostname`: `https://<hash>.azurestaticapps.net` 形式のデフォルトホスト。

## 今後の拡張
- `modules/` 配下に Functions / Cosmos DB / Key Vault などを追加し、`main.bicep` から組み合わせる。
- `.bicepparam` を `dev/stg/prod` など複数環境分用意し、GitHub Actions から `az deployment group create` を実行するワークフローを整備。
