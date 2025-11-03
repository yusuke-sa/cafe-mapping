# Azure CLI セットアップ手順 (macOS 想定)

## 1. 事前条件
- macOS (Apple Silicon/Intel いずれも可)
- 管理者権限を持つユーザーでログイン済み
- [Homebrew](https://brew.sh/) がインストール済み（未導入の場合は `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` でセットアップ）
- Microsoft Azure サブスクリプションが有効化されていること

## 2. Azure CLI のインストール
Homebrew を利用して Azure CLI (`azure-cli`) をインストールする。

```bash
brew update
brew install azure-cli
```

インストール後、バージョンを確認して動作チェックを行う。

```bash
az version
```

バージョン番号が表示されれば成功。`az` コマンドが見つからない場合は、ターミナルを再起動するか `eval "$(/opt/homebrew/bin/brew shellenv)"` を実行して PATH を更新する。

## 3. 初回ログイン
ブラウザ認証で Azure にログインする。

```bash
az login
```

コマンド実行後に表示される URL にアクセスし、デバイスコードを入力して Microsoft アカウントでサインインする。完了すると、ターミナルに利用可能なサブスクリプション一覧が JSON 形式で出力される。

> 複数サブスクリプションがある場合は、次のコマンドで対象を選択する。

```bash
az account set --subscription "<サブスクリプション名またはID>"
```

現在利用中のサブスクリプションは `az account show --output table` で確認できる。

## 4. 便利な初期設定
- **既定のリージョン設定**: 頻繁に利用するリージョンを CLI のデフォルトに設定するとコマンドが簡潔になる。

  ```bash
  az configure --defaults location=japaneast group=rg-cafe-mapping-dev
  ```

- **出力形式の指定**: `table` や `jsonc` に設定すると読みやすくなる。

  ```bash
  az configure --defaults output=table
  ```

- **自動補完の有効化**: zsh/bash で `az` コマンドの補完を有効にする。

  ```bash
  az completion -h  # 補完スクリプト生成コマンドを確認
  az completion >> ~/.zshrc
  source ~/.zshrc
  ```

## 5. プロジェクトで利用する主なコマンド例
- サブスクリプション / リソースグループ確認  
  `az account show`, `az group list`
- 予算アラート作成 (Cost Management)  
  `az consumption budget create ...`
- Functions / Static Web Apps / Cosmos DB のデプロイ  
  `az functionapp deploy`, `az staticwebapp up`, `az cosmosdb create`
- ログ / モニター  
  `az monitor metrics list`, `az monitor activity-log list`

必要な拡張機能があれば `az extension add --name <extension>` で追加する（例: `azure-devops`, `account` など）。

## 6. トラブルシューティング
| 症状 | 対処 |
| --- | --- |
| `az: command not found` | Homebrew のパス設定を確認 (`echo $PATH`)、ターミナル再起動。 |
| `az login` がブラウザを開かない | `az login --use-device-code` を利用し、表示されたコードを <https://microsoft.com/devicelogin> で入力。 |
| 権限不足エラー | Azure ポータルでロール割り当てを確認。必要に応じて所有者/共同作成者ロールを付与。 |
| 新しいコマンドが使えない | `brew upgrade azure-cli` で最新版に更新。必要な拡張機能を追加。 |

## 7. 次のステップ
1. `az login` 後に `az account set` で本プロジェクト用サブスクリプションを既定に設定。
2. `az consumption` コマンドを利用して `docs/AzureCostAlerts.md` の予算アラートを CLI で作成。
3. CI/CD やスクリプト内で `az login --service-principal` を利用する場合は、別途サービスプリンシパルを発行し、シークレットを GitHub Actions シークレットに保存する。
