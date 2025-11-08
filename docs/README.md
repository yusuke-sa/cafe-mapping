# Documentation Index

## ドキュメント構成

### product/
- `RequirementsDefinition.md`: 要件定義・最新技術要項（Next.js 15, Azure Functions + Hono 等）。
- `Roadmap.md`: 10週間ロードマップと日次タスク、参照資料リンク付き。
- `TermsOfService.md` / `PrivacyPolicy.md` / `BrandGuidelines.md`: 正式な利用規約・プライバシー・ブランド/広告ガイドライン。
- `ui/`: 画面仕様・モック（Mermaid/AsciiDoc等）。

### architecture/
- `ArchitectureCurrent.md`: 現行アーキテクチャ + 依存関係/ボトルネック。
- `architecture.drawio`: 全体構成図（draw.io形式）。
- `CacheStrategy.md`: Redis / Front Door を使ったキャッシュ戦略。
- `APIQuotaPlan.md`: Google Maps / Instagram のクォータ & アラート設計。
- `DataFlow_*.md`: SNS→AI、Places詳細、検索インデックス更新、お気に入り同期、Map描画、監視など6本のデータフロー。

### operations/
- `AccountsAndLicensing.md`: 必要アカウント/ライセンス一覧。
- `azure/` (SubscriptionSetup / CLISetup / CostAlerts)。
- `gcp/` (GoogleCloudSetup / GoogleMapsApiKey)。
- `meta/InstagramSetup.md`: Meta開発者/Instagram準備手順。

### compliance/
- `LegalGuidelines.md`: 法令・広告表示・ブランドポリシー整理メモ（正式文書との差分、今後のTODO記載）。

### finance/
- `CostEstimation.md`: 限定利用時のコスト試算（Google Mapsクレジット反映）。

### blueprint/
- `dataflow/`: 主要データフロー (SNS→AI, Google Places, Search, Favorites, Map, Monitoring)。

## 推奨読了順
1. **RequirementsDefinition.md** → プロダクト全体の目的・要件・最新技術決定を把握。
2. **Roadmap.md** → 作業スケジュールと成果物リンクを確認。
3. **ArchitectureCurrent.md / architecture.drawio** → 全体構成・ボトルネックを理解。
4. **CacheStrategy.md / APIQuotaPlan.md** → パフォーマンス・クォータ設計を事前に把握。
5. **blueprint/dataflow/** → 各処理のETLシーケンスを順番に参照。
6. **Operations & Compliance** → 実装前にアカウント・法務要件を確認。
7. **Finance** → コスト前提をチェックし、必要なアラート設定を反映。

> 新しい資料を追加する際は、上記カテゴリに合わせて配置し、このREADMEを更新してください。
