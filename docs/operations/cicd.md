# CI/CD パイプライン設計書（GitHub Actions + Azure）

## 1. 目的とスコープ
- 対象: モノレポ (`src/apps/frontend` Next.js / `src/apps/backend` Azure Functions / `src/infra` Bicep)。
- 環境: `dev` (自動), `stg` (承認あり), `prod` (承認あり)。
- 対象リソース: Azure Static Web Apps, Azure Functions, Cosmos DB (Serverless), Cognitive Search, Key Vault, Storage, Application Insights (Bicepで管理)。

## 2. ブランチ/タグとトリガーポリシー
- PR: `ci-pr` ワークフロー。lint/test/build のみ。デプロイなし。
- dev: `main` push で `deploy-dev`。自動デプロイ（承認なし）。
- stg: `release/**` ブランチ push で `deploy-stg`。GitHub Environment の承認必須。
- prod: `v*` タグ push で `deploy-prod`。GitHub Environment の承認必須。緊急時のみ `hotfix/*` → タグを許容。

## 3. ワークフロー構成（概要）
- 共通: checkout → Node 20 セットアップ → `npm ci` → `npm run lint` → `npm run build` → アーカイブ (backend.zip/frontend.zip)。
- dev/stg/prod デプロイ手順:
  1. OIDC + azure/login でサブスクリプションにログイン。
  2. Bicep (`src/infra/main.bicep` + 環境別 `.bicepparam`) で IaC 反映。
  3. Functions: `azure/functions-action@v1` で Zip デプロイ（publish profile利用）。
  4. SWA: `Azure/static-web-apps-deploy@v1` でアップロード（skip build）。必要ならビルドを有効化に切替可。

## 4. シークレット一覧（GitHub Environments 推奨）

| 環境 | シークレットキー | 用途 |
| --- | --- | --- |
| dev | `AZURE_CLIENT_ID_DEV` | OIDC ログイン (Federated Credential) |
|  | `AZURE_TENANT_ID` | 共通 |
|  | `AZURE_SUBSCRIPTION_ID` | 共通 |
|  | `AZURE_RG_DEV` | デプロイ先リソースグループ |
|  | `SWA_NAME_DEV` | Static Web Apps 名 |
|  | `FUNC_APP_NAME_DEV` | Functions App 名 |
|  | `AZURE_FUNCAPP_PUBLISH_PROFILE_DEV` | Functions Zip デプロイ用 |
|  | `AZURE_STATIC_WEB_APPS_API_TOKEN_DEV` | SWA デプロイ用 |
|  | `SEARCH_ENDPOINT_DEV`, `SEARCH_API_KEY_DEV` | Cognitive Search 接続 |
|  | `OPENAI_ENDPOINT_DEV`, `OPENAI_API_KEY_DEV` | Azure OpenAI 接続 |
|  | 必要に応じ `COSMOS_CONNECTION_STRING_DEV` | Cosmos 直指定が必要な場合 |
| stg/prod | 上記の `_DEV` を `_STG` / `_PROD` に読み替え | 同様 |

※ Secrets は GitHub Environments に置き、Environment Protection で承認者を設定（stg/prod）。
※ `AZURE_CLIENT_SECRET` は使わず OIDC + Federated Credential を基本とする。

### OIDC Federated Credential と RBAC（例）

| 環境 | Federated Credential (GitHub → Entra ID) | 付与ロール（最小権限の目安） |
| --- | --- | --- |
| dev | 発行先: `AZURE_CLIENT_ID_DEV` のアプリ。<br>Subject: `repo:<owner>/<repo>:ref:refs/heads/main`（`deploy-dev` 用） | RGスコープ `Contributor`（インフラ反映に必要）、`Static Web App Contributor`（SWA）、`Search Service Contributor`（Cognitive Search）、`Key Vault Secrets User`（シークレット読取）、Functions/Storage/Cosmos を含む Contributor を RG で包括付与でも可 |
| stg | 発行先: `AZURE_CLIENT_ID_STG` のアプリ。<br>Subject: `repo:<owner>/<repo>:ref:refs/heads/release/*` | RGスコープ `Contributor` + `Static Web App Contributor` + `Search Service Contributor` + `Key Vault Secrets User` |
| prod | 発行先: `AZURE_CLIENT_ID_PROD` のアプリ。<br>Subject: `repo:<owner>/<repo>:ref:refs/tags/v*` | RGスコープ `Contributor`（必要ならリソース単位に分割）、`Static Web App Contributor`、`Search Service Contributor`、`Key Vault Secrets User`。承認者付き Environment Protection を必須化 |

補足:
- Functions Zip デプロイは publish profile を使用しているため、現行ロールでは Contributor で十分。将来 Run-From-Package/slot 切替にする場合も同等。
- Key Vault は読み取りのみで済むように設計し、書き込み権限 (`Secrets Officer`) は付与しない運用を推奨。

## 5. RBAC（最小権限の目安）
- サブスクリプション/リソースグループスコープ: `Contributor`（最低限）または各リソースの専用ロールを付与。
- Static Web Apps: `Static Web App Contributor`。
- Functions: `Contributor`（Functions 部分の更新に必要）。
- Cognitive Search: `Search Service Contributor`（インデックス更新含む）。
- Key Vault: `Key Vault Secrets User`（読み取りのみ）。書き込みが必要なら `Key Vault Secrets Officer` だが可能な限り避ける。
- Cosmos DB: 可能なら RBAC。キー使用の場合は接続文字列を Secret で供給。

## 6. 成否とゲート
- テスト/ビルド失敗でデプロイしない（CI job 失敗でデプロイ job を走らせない依存設定済み）。
- stg/prod: GitHub Environment の Required reviewers で手動承認必須。
- タグ/ブランチ保護: `main`, `release/**`, `v*` への直pushを制限し、PR必須に設定。
- 通知: Actions 失敗時は GitHub 通知 + （必要なら）Teams/Slack webhook を追加。

## 7. 失敗時ハンドリング
- IaC 失敗: `az deployment group create` のエラーログを確認し、パラメータ/権限を見直す。ロール不足が多いので RBAC を優先確認。
- Functions デプロイ失敗: publish profile の有効性、ランタイムバージョン、Zip サイズを確認。
- SWA デプロイ失敗: API トークン、SWA 名の一致、ビルドの有無を確認。必要なら `skip_app_build=false` でビルド実施。
- 検索/外部APIエラー: Search/OpenAI/Cosmos 接続情報の環境毎の整合性を確認。

## 8. 将来拡張
- E2E テスト（Playwright/Cypress）を stg で動かし、成功時のみ prod 承認を解放するゲートを追加。
- Blue/Green / Deployment Slots（Functions Premium/SWA Standard）による無停止切替。
- Front Door/WAF 導入後の CDN キャッシュパージやヘルスチェック組み込み。
- SBOM/Dependabotアラートの自動対応、CodeQL/SASTの導入。
- コスト・ドリフト検知の定期実行（nightly）を追加。
