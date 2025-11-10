# コスト試算: ネットワーク/インフラ (最小構成)

## 1. 前提
- 構成: `NetworkDesign.md` の最小構成（Azure DNS → Static Web Apps Free → Functions Consumption → Cosmos/OpenAI）。
- MAU 6名、マップ500ロード/月、AI処理100万token/月。
- 為替 1 USD = 150 JPY。
- 公式価格 (2025/10 時点) をもとに概算。無料枠・クレジットを最大活用。

## 2. サービス別月額試算
| サービス | SKU / プラン | 月額 (USD) | 月額 (JPY) | 備考 |
| --- | --- | --- | --- | --- |
| Azure DNS | Standard ゾーン | $0.80 | ¥120 | クエリは無料枠内。 |
| Azure Static Web Apps | Free (本番) | $0.00 | ¥0 | Preview環境不要の場合。必要ならStandard $9。 |
| Azure Functions | Consumption (無料枠) | $0.00 | ¥0 | 月3,000実行/300MB-s想定。 |
| Cosmos DB for NoSQL | Serverless (30万RU, 5GB) | $3.00 | ¥450 | `CostEstimation.md` と同条件。 |
| Azure Cognitive Search | Free | $0.00 | ¥0 | インデックス3本以内。 |
| (サーバ側キャッシュ) | Functionsメモリ or App Service Cache Basic | $0.00〜$5.00 | ¥0〜750 | Redis撤去。必要時のみ最小プランを追加。 |
| Azure OpenAI | gpt-4o-mini (100万token) | $0.30 | ¥45 | 週次要約バッチ。 |
| Azure Storage | Standard LRS (10GB) | $0.18 | ¥27 | ローデータ/バックアップ。 |
| Azure Monitor / App Insights | 1GB 取り込み | $2.76 | ¥414 | サンプリングを前提。 |
| Azure Key Vault | Standard | $0.30 | ¥45 | Inviteトークン/Secrets保管。 |
| Google Maps Platform | $7.47 - $200 credit | $0.00 | ¥0 | 無料クレジット内。 |
| **合計** |  | **$7.34** | **約¥1,101** | Optionalキャッシュを除いた最小構成。 |

## 3. コメント
- 固定費は DNS / Cosmos / Monitor / Key Vault 程度で、月7ドル前後に収まる。
- サーバ側キャッシュが必要な場合のみ App Service Cache Basic (数ドル) を追加するが、通常はブラウザ＋Cosmosキャッシュで十分。
- Monitorのログ取り込みを1GBに抑えるには、不要な依存ログをサンプリングまたは除外する。
- DNSは年間$0.8程度。証明書はLet's Encrypt等の無料証明書を利用。

## 4. スケール目安
- MAUが100人程度までなら、Cosmos/Monitor/ログ取り込みを2〜3倍にするだけで月額$40〜50で運用可能。
- トラフィック増やWAFが必要になった時点でFront DoorやFunctions Premiumを追加し、本ドキュメントを更新。

## 5. 推奨アクション
1. Cost ManagementでMonitor・Cosmosなど主要リソースのアラートを設定（$5, $10, $20 など）。
2. サーバ側キャッシュが必要になった場合のみ追加費用を見込む（App Service Cache Basic など）。
3. Functions/Static Web Apps の無料枠超過に備え、請求アラートを有効化。
4. スケール計画に応じてFront Door/App Gateway等のオプション費用を別途試算する。
