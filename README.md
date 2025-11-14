# Cafe Mapping プロジェクト ドキュメント

本リポジトリでは、カフェ向けサービスの計画・要件定義・コスト試算、およびモノレポ構成のアプリ/インフラコードを管理しています。以下の資料を参照してください。

- [要件定義](docs/RequirementsDefinition.md)
- [ロードマップ](docs/Roadmap.md)
- [アカウントとライセンス管理](docs/AccountsAndLicensing.md)
- [コスト試算](docs/CostEstimation.md)
- [Azure サブスクリプション作成と支払い情報登録手順](docs/AzureSubscriptionSetup.md)

## ディレクトリ構成（抜粋）
- `docs/` … 企画・要件・設計ドキュメント。
- `src/frontend/` … Next.jsベースのフロントエンド（静的配信は Azure Static Web Apps を想定）。
- `src/backend/` … Azure Functions (Node.js) のAPIコード配置予定地。
- `src/infra/` … Azure Bicep テンプレート。`src/infra/main.bicep` から Static Web Apps などをデプロイ。

各ドキュメント/コードは必要に応じて更新し、関係者間での情報共有に活用してください。

## モノレポ開発環境
- パッケージマネージャー: `pnpm`（`packageManager: pnpm@9` を定義済み）。
- ビルド/タスクランナー: `Turborepo`。`turbo.json` のパイプラインに沿って `dev/build/lint/deploy:infra` を実行。
- 代表コマンド
  - `pnpm install` … 依存関係のセットアップ（初回のみ）。
  - `pnpm dev` … フロントエンド/バックエンドの開発サーバーを並列起動（現状はTODOのエコーのみ）。
  - `pnpm build` / `pnpm lint` … 各パッケージのビルド・Lintをタスクグラフ順に実行。
  - `pnpm deploy:infra` … `src/infra` パッケージの `deploy:infra` タスク（Bicepデプロイ想定）を実行。

共通処理を切り出す場合は今後 `src/packages/` のようなディレクトリを追加し、`pnpm-workspace.yaml` にパスを追記してください。
