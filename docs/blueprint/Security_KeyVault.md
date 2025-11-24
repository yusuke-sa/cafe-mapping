# Key Vault 秘密情報管理ガイド (Bicep前提)

本ドキュメントは Azure Key Vault (Standard) を前提に、Bicep で IaC 化する際の秘密情報の棚卸しと設定方針をまとめる。

## 1. 格納対象（必須/任意）

- 認証・アクセス制御
  - 招待コード/共通パスコード（本番用）、ワンタイムコード発行シード
  - OAuth クライアントシークレット（Entra ID/B2C の client secret）、JWT サイン鍵（発行する場合）
  - Meta Webhook検証トークン（Instagram Graph 用）
- Azure リソースキー
  - Azure Cognitive Search 管理キー（admin/query）
  - Azure OpenAI APIキー
  - Cosmos DB キーまたは接続文字列（RBAC に置き換え可能な場合は格納不要）
  - Storage アカウントキー（Functions バインド/キュー利用時に必要な場合）
  - Functions Host/Default キー（外部呼び出しを許可する場合のみ）
  - Application Insights 接続文字列
- 外部 API
  - Google Maps JavaScript APIキー（HTTP リファラ制限済みの本番用）
  - Google Places / Autocomplete APIキー
  - Instagram Graph API: App Secret、長期有効アクセストークン、App ID
  - その他 SNS/口コミ API クライアントID/シークレット（Twitter/X, TikTok, Yelp 等）
- アプリ固有
  - 署名付きリンク/CSRF/暗号化用シークレット（実装する場合のみ）

短命アクセストークン/リフレッシュトークンは Key Vault に置かず、アプリ内安全ストアを利用する。

## 2. アクセスモデル

- 原則、Managed Identity (System-Assigned) を Functions と Static Web Apps に付与し、Key Vault の RBAC で `Key Vault Secrets User` を付与する。
- 人的アクセスは最小限（Owner/Contributor に加えて必要時のみ `Key Vault Secrets Officer`）。CI は OIDC (federated credential) で発行し、クライアントシークレットは KV に置かない。
- ログ監査: Key Vault 診断ログを Log Analytics に送信し、Get/List/Set 失敗をアラート化。

## 3. Bicep サンプル

```bicep
@description('Key Vault name')
param keyVaultName string
@description('Location')
param location string = resourceGroup().location
@description('Objects to grant secret read')
param miReaders array = []

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: { family: 'A'; name: 'standard' }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 90
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
  }
}

// Managed Identity に RBAC でシークレット取得権限付与
@batchSize(20)
module kvRbac 'br/public:azurerm/keyvault-rbac:1.0.0' = [for principalId in miReaders: {
  name: 'kv-rbac-${principalId}'
  params: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    scope: kv.id
  }
}]

// 初期シークレットの例（値はデプロイ時に `--parameters` で渡す）
param googleMapsApiKey string
resource kvSecretMaps 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${kv.name}/google-maps-api-key'
  properties: { value: googleMapsApiKey }
}
```

補足:
- 値は Git に含めない。デプロイ時に CI から `--parameters googleMapsApiKey=$(...)` で注入。
- Cosmos/Storage は可能なら RBAC + マネージドID経由で接続し、鍵格納を減らす。

## 4. 運用/ローテーション

- ローテーション方針: Google/Instagram/OpenAI/APIキーは 90日以内目標、Meta/Entra クライアントシークレットは 180日以内でローテーション。JWT サイン鍵を更新する場合はキーバージョンを並行運用し、`kid` で判別。
- アラート: 有効期限 30日前で通知（App Insights または Logic App でスケジュールチェック）。
- バックアップ: リソースバックアップではなく、シークレット値は再発行を前提とし、必要時のみ Key Vault バックアップ機能を利用。

## 5. 次アクション

1. Bicep のパラメータ設計（環境別 KV 名、初期投入するシークレット種別）を決定。
2. Functions/SWA の Managed Identity を有効化し、`Key Vault Secrets User` を付与する RBAC を Bicep に組み込む。
3. CI を OIDC 化し、Key Vault からシークレットを取得するジョブテンプレートを用意。
