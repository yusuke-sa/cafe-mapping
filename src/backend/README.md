# Backend App

Azure Functions (Node.js 22 + TypeScript) を想定。Static Web Apps の `api_location` に指定することで、フロントエンドと同じリポジトリからビルド・デプロイできる構成。

- Hono ベースのHTTPトリガー/APIを配置予定。
- `package.json`、`tsconfig.json` 等は後続タスクで整備。
- `src/infra/environments/*.bicepparam` で `apiLocation` を `src/backend` に切り替えることで連携可能。
