# Dev Container 環境 (ローカルエミュレータ込み)

`src/` モノレポを VS Code Dev Containers / GitHub Codespaces で開発するための構成。Functions を Azure 環境に近い形で実行し、ストレージ/データはローカルエミュレータ優先で利用する。

## 構成概要

- ベース: Node.js 20 + Azure CLI + Azure Functions Core Tools 4（`.devcontainer/Dockerfile`）
- パッケージ管理/タスク: npm + Turborepo (`npm run dev`/`build`/`lint`)
- サービス (docker-compose):
  - `azurite`: Storage エミュレータ (Blob/Queue/Table) – `UseDevelopmentStorage=true`
  - `cosmos`: Cosmos DB Emulator (SQL API, TLS自己署名)
  - `app`: 開発コンテナ本体。Functions/Next.js を起動
- 前提: Azure Cognitive Search のローカルエミュレータは存在しないため、検索は Azure 本番/検証サービス (Free/Basic) を利用する

## 主要エンドポイント / 接続文字列

- Storage (Azurite): `UseDevelopmentStorage=true`
- Cosmos Emulator: `AccountEndpoint=https://cosmos:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDjEwep0==;ApiKind=SQL;`
  - 証明書は `postStartCommand` で自動インポート。失敗時は `NODE_TLS_REJECT_UNAUTHORIZED=0` を利用（dev container で既定セット済み）
- Cognitive Search: エミュレータなし。`SEARCH_ENDPOINT`, `SEARCH_API_KEY` を `.env.local` 等で実際のサービス値に置き換える

## 使い方

1. 前提ツール: Docker (Linux/macOS/WSL2), VS Code + Dev Containers 拡張。または Codespaces
2. VS Code で `cafe-mapping` を開き、`Dev Containers: Reopen in Container` を実行
   - 初回は Cosmos Emulator が起動するまで 1–2 分程度かかる
3. 依存関係: `postCreateCommand` で `npm install` 済み。追加が必要なら `npm install <pkg> -w <workspace>` を実行
4. バックエンド (Functions) 起動
   ```bash
   cd src/apps/backend
   npm run build   # 必要なら
   func start      # ローカル HTTP トリガー起動 (7071)
   ```
5. フロントエンド (Next.js) 起動
   ```bash
   cd src/apps/frontend
   npm run dev     # 3000 番で起動
   ```
6. Turborepo で一括起動
   ```bash
   npm run dev     # turbo run dev --parallel
   ```

## 環境変数の調整例

- Functions `local.settings.json` は `AzureWebJobsStorage=UseDevelopmentStorage=true` を既定。Cosmos 接続をエミュレータに向ける場合は:
  ```
  COSMOS_CONNECTION_STRING=AccountEndpoint=https://cosmos:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDjEwep0==;ApiKind=SQL;
  ```
- Cognitive Search を実際のサービスに接続する場合:
  ```
  SEARCH_ENDPOINT=https://<your-service>.search.windows.net
  SEARCH_API_KEY=<admin-or-query-key>
  ```
  エミュレータが無いため、Search を使う処理は実サービスまたはスタブで代替する

## 設計ドキュメントとの対応

- Functions 実行: `docs/blueprint/dataflow/DataFlow_SearchIndex.md` の Change Feed トリガーや `docs/blueprint/dataflow/DataFlow_MapTiles.md` の HTTP エンドポイントをローカルで検証可能
- データストア: `docs/blueprint/database/CosmosDB.md` の5コンテナをエミュレータで再現。TTL/インデックスは Bicep (`src/infra/modules/cosmos-db.bicep`) に準拠
- 検索: `docs/blueprint/CognitiveSearchIndex.md` を参照し、Search は Azure 上の Free/Basic サービスでテストする

## トラブルシュート

- Cosmos Emulator への接続で証明書エラー: `NODE_TLS_REJECT_UNAUTHORIZED=0` が有効か確認。`.devcontainer/scripts/setup-certs.sh` を手動実行
- ポート競合: ホストで 3000/7071/8081/10000-10002 を使用中の場合は `docker-compose.yml` のポートを調整
- Cosmos Emulator が重い場合: 一時的に停止し、Azure の Serverless アカウントを接続先に設定する（接続文字列を差し替え）
