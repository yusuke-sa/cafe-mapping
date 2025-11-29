# iijan-map プロジェクト ドキュメント

本リポジトリでは、カフェ向けサービスの計画・要件定義・コスト試算、およびモノレポ構成のアプリ/インフラコードを管理しています。以下の資料を参照してください。

- [要件定義](docs/RequirementsDefinition.md)
- [ロードマップ](docs/Roadmap.md)
- [アカウントとライセンス管理](docs/AccountsAndLicensing.md)
- [コスト試算](docs/CostEstimation.md)
- [Azure サブスクリプション作成と支払い情報登録手順](docs/AzureSubscriptionSetup.md)

## ディレクトリ構成（抜粋）

- `docs/` … 企画・要件・設計ドキュメント。
- `src/apps/frontend/` … Next.jsベースのフロントエンド（静的配信は Azure Static Web Apps を想定）。
- `src/apps/backend/` … Azure Functions (Node.js) のAPIコード配置予定地。
- `src/packages/` … フロント/バックエンドで共有するユーティリティやUIコンポーネント。
- `src/infra/` … Azure Bicep テンプレート。`src/infra/main.bicep` から Static Web Apps などをデプロイ。
- `.devcontainer/` … VS Code Dev Container 設定。Azurite/Cosmos Emulator を含むローカル環境は `docs/operations/devcontainer.md` を参照。

各ドキュメント/コードは必要に応じて更新し、関係者間での情報共有に活用してください。

## モノレポ開発環境

- パッケージマネージャー: `npm`（workspaces で `src/apps/*`, `src/packages/*`, `src/infra` を管理）。
- ビルド/タスクランナー: `Turborepo`。`turbo.json` のパイプラインに沿って `dev/build/lint/deploy:infra` を実行。
- 代表コマンド
  - `npm install` … 依存関係のセットアップ（初回のみ）。
  - `npm run dev` … フロントエンド/バックエンドの開発サーバーを並列起動（現状はTODOのエコーのみ）。
  - `npm run build` / `npm run lint` … 各パッケージのビルド・ESLintチェックをタスクグラフ順に実行。
  - `npm run lint:fix` … 各パッケージのESLintを`--fix`付きで実行。
  - `npm run format` … Prettierでリポジトリ全体をフォーマット。
  - `npm run deploy:infra` … `src/infra` パッケージの `deploy:infra` タスク（Bicepデプロイ想定）を実行。

共通処理を切り出す場合は `src/packages/` 配下にディレクトリを追加し、`npm init -w src/packages/<name>` でワークスペースを作成してください。

## 新規メンバー向けセットアップ手順

1. **Node.js / npm の準備**
   - Node.js 20 以上をインストール（`node -v` / `npm -v` で確認）。
   - `package.json` の `"packageManager": "npm@10.x"` に合わせて npm をアップデート。
2. **リポジトリの取得**
   ```bash
   git clone git@github.com:yusuke/cafe-mapping.git
   cd cafe-mapping
   ```
3. **依存関係のインストール**
   ```bash
   npm install
   ```
4. **Git hooks の有効化（推奨）**

   ```bash
   git config core.hooksPath .githooks
   ```

   - コミット前に `npm run lint` が自動実行され、品質チェックを強制できる。

5. **Azure Functions Core Tools のインストール**（バックエンド開発に必須）
   - macOS (Homebrew):
     ```bash
     brew tap azure/functions
     brew install azure-functions-core-tools@4
     ```
   - `func --version` でインストール確認。
6. **ローカル設定ファイルの確認**
   - `src/apps/backend/local.settings.json` にストレージ接続などを設定。開発用途なら既定の `UseDevelopmentStorage=true` で可。
7. **開発サーバーの起動**

   ```bash
   npm run dev
   ```

   - フロントエンド: 現状はプレースホルダ。今後 Next.js プロジェクトに差し替え予定。
   - バックエンド: `func start` で HTTP トリガー (`GET /api/ping`) を起動。

8. **ビルド / 型チェック / Lint / フォーマット**
   ```bash
   npm run build       # TypeScript を含む各アプリのビルド
   npm run lint        # ESLint + Prettier規約でスタイル・品質チェック
   npm run lint:fix    # Lint指摘を自動修正
   npm run format      # Prettierで全ファイルを整形
   ```
9. **インフラ (Bicep) デプロイ**
   - Azure CLI で `az login` し、対象サブスクリプションを選択。
   - GitHub PAT や `repositoryToken` を環境変数にセットしたうえで実行。
     ```bash
     npm run deploy:infra
     ```
   - `src/infra/environments/dev.bicepparam` を編集して `staticWebAppName` や `apiLocation` 等を環境ごとに調整。
10. **共有パッケージの追加**

```bash
npm init -w src/packages/shared-utils
```

- 追加後は `turbo run build` / `lint` の対象に自動で含まれる。

11. **推奨ツール**
    - VS Code + `Prettier - Code formatter`, `ESLint`, `Azure Functions`, `Bicep` 拡張（`.vscode/settings.json` で保存時フォーマットを有効化済み）。
    - GitHub CLI (`gh`) や Azure CLI (`az`) を利用するとレビュー/デプロイが容易。

問題が発生した場合は `README.md` と `docs/operations/azure` 以下の手順書を参照し、Issue に記録してください。
