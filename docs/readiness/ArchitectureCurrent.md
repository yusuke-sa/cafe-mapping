# 現行アーキテクチャまとめ

## フロントエンド
- **技術**: Next.js 15 (App Router) + React 19 + TypeScript、UIはMUIベースでアクセシビリティ対応。
- **地図/外部表示**: Google Maps JavaScript API + Places API。口コミ取得は最大5件をキャッシュしレビュアー情報を併記（`docs/operations/gcp/GoogleCloudSetup.md`）。
- **ホスティング**: Azure Static Web Apps でエッジ配信。将来的にはFront Door導入を想定。

## 認証・アクセス制御
- 招待コードまたは許可済みアカウントで限定6名が利用（`docs/product/RequirementsDefinition.md#5`）。
- ローカルお気に入りはブラウザStorage、将来のユーザー管理はFunctionsとCosmosで拡張予定。

## バックエンド/API
- **ランタイム**: Azure Functions (Node.js 22 + TypeScript)。
- **フレームワーク**: Hono をHTTPトリガーに統合し、Fetch APIベースの軽量ルーティングと型安全なAPIを提供（`docs/product/RequirementsDefinition.md#9`）。
- **バッチ処理**: タイマートリガーFunctionsでSNS収集・AI要約を実行。
- **CI/CD**: GitHub Actionsから Functions / Static Web Apps へデプロイ（`docs/product/Roadmap.md`）。

## データ処理・AI
- **ETL**: Azure Functions または Data Factory で Instagram Graph API / Google Places API 等から収集、整形、Cosmos DBへ格納。
- **AI要約**: Azure OpenAI (gpt-4o-mini) を Functions から呼び出し、雰囲気タグやレビュー要約を生成（`docs/readiness/CostEstimation.md`）。

## データストア/検索
- **Cosmos DB (Serverless)**: 店舗メタデータ、AIタグ、お気に入り、混雑傾向など。
- **Azure Cognitive Search (Basic)**: 店舗名・タグ・設備検索、ベクトルベースのハイブリッド検索も視野。
- 将来的に Azure Cache for Redis や Front Door キャッシュを追加検討。

## 外部連携
- Instagram Graph API（Meta審査が前提）、Google Maps/Places API（個人利用でも課金設定必須）。
- 位置情報はブラウザ Geolocation APIで取得（`docs/product/RequirementsDefinition.md#10`）。

## 監視・コスト
- Azure Monitor / Application Insights でAPI・バッチを監視。
- Azure Cost Alerts と Google Cloud Billing で費用アラート（`docs/operations/azure/AzureCostAlerts.md`、`docs/readiness/CostEstimation.md`）。

## 法務・広告
- 利用規約 / プライバシーポリシー / ブランドガイドラインを整備済み (`docs/product/TermsOfService.md`, `docs/product/PrivacyPolicy.md`, `docs/product/BrandGuidelines.md`)。
- 広告には「広告/PR」ラベルと広告主表示を必須とし、景品表示法・薬機法等を順守。

## 依存関係・潜在的ボトルネック
- **Google Maps / Places API**: 月次無料クレジット依存。ユーザー増でコストが急増し、クォータ超過時は地図や口コミが取得できずUXが劣化する。
- **Instagram Graph API**: Metaの審査承認と権限維持が必須。ポリシー違反や審査遅延でデータ取得が止まるリスクがある。
- **Cosmos DB Serverless**: RUスパイクでスロットリングが発生する可能性。アクセス増加時はProvisioned/AutoScaleへの移行が必須。
- **Azure Functions 消費プラン**: Cold Startや同時実行数制限がパフォーマンス低下の要因になる。Elastic Premium等への移行想定が必要。
- **AI推論 (Azure OpenAI)**: トークン課金とレート制限があり、バッチが集中すると待ち時間が増える。モデル更新やAPI変更の影響も大きい。
- **ステートレスAPI + ローカルお気に入り**: 現状はブラウザStorage依存のため、マルチデバイス同期ができずUX課題。将来データ整合性を取る仕組みが必要。
- **オペレーションの属人化**: 招待制・手動運用を前提にしているため、ユーザー拡大に合わせた問い合わせ対応・審査フローの仕組み化が未整備。

---
この構成を基に、フェーズ1で設計見直し・キャッシュ戦略・APIクォータ計画を詳細化し、将来スケールに備える。
