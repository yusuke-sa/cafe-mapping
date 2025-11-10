# ネットワーク & インフラ構成 (最小構成)

`docs/architecture/network.drawio` はコスト最適化版の構成を示している。

## 1. 概要
- Internet → Azure DNS → Custom Domain → Azure Static Web Apps (グローバルエッジ) → Azure Functions (Consumption) → データレイヤ（Cosmos DB Serverless, Azure OpenAI）で構成。
- VNetやApplication Gatewayを使わないことで固定費を抑え、少人数利用に最適化。必要に応じて将来 Front Door / App Gateway を追加可能。

## 2. 構成要素とSKU
| 層 | サービス / SKU | 役割 |
| --- | --- | --- |
| DNS | Azure DNS Standard | カスタムドメインと証明書(CNAME / TXT)管理。年間数ドル。 |
| CDN & Web | Azure Static Web Apps Free (必要なら Standard) | Next.js 15 フロントをホスティング。Preview含めても低コスト。 |
| API | Azure Functions Consumption | Hono + Node.js 22。無料枠で稼働。 |
| データ | Cosmos DB Serverless、Azure OpenAI (gpt-4o-mini)、（オプション）App Service Cache/Functions内メモリ | 店舗データ、要約。Redisを撤去しブラウザ/Edge/Cosmosでキャッシュ。 |
| 監視 | Azure Monitor / App Insights Basic | API/バッチのログとアラート通知。 |
| ストレージ | Azure Storage (Hot Blob) | SNSローデータ・静的アセットの保持。 |
| Secrets | Azure Key Vault Standard | Inviteトークン、OAuth Client Secretを保管。 |

## 3. 通信フロー
1. ユーザー → Azure DNS で名前解決 → Static Web Apps (エッジ) へアクセス。HTTPS終端もSWAで完結。
2. クライアントからのAPI呼び出しは Static Web Apps 経由で Functions (Consumption) のHTTPトリガーへ送信。
3. Functions から Cosmos DB / Azure OpenAI へアウトバウンド通信。インターネット経路(HTTPS)のみ、Private Endpointは未使用。
4. Monitor / App Insights がテレメトリを収集し、CostManagement / APIQuotaPlan に基づくアラートを発火。

## 4. コスト特性
- 固定費は Azure DNS (約$0.8/月) と Application Insights 取り込み (~$3/月) のみ。Functions・Static Web Apps は無料枠主体。Cosmos/OpenAI も軽負荷のため数ドル。
- 詳細な費用は `docs/finance/CostEstimation.md` と `CostEstimation_Network.md` を参照。利用量が増えたら App Gateway / Front Door / Functions Premium へアップグレードする計画。

## 5. 拡張パス
- トラフィックが増えたら Front Door Standard + WAF を追加し、Functionsを Premium Plan (EP1) へ移行、Private Endpoint を導入する段階的プランを検討。
- VNet化した場合は、network.drawioを新バージョンとして作成し、本ドキュメントを更新する。
