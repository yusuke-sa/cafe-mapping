# APIクォータ計画（正式版）

## 1. 目的と範囲
- 対象API: Google Maps Platform（Maps JavaScript / Places Details / Places Autocomplete）および Instagram Graph API。
- 限定ユーザー（最大6名）を前提に、現行負荷での利用上限、アラート設計、フェイルオーバー手順を明文化。将来のユーザー増加時に迅速にスケールできるよう、調整フローを含める。

## 2. Google Maps Platform
### 2.1 利用API・想定コール・コスト
| API | 主用途 | 想定月間コール | 料金見積* | 備考 |
| --- | --- | --- | --- | --- |
| Maps JavaScript API | 地図描画 | 500ロード | $3.50 | 無料クレジット$200/月内に収まる見込み。 |
| Places Details API | 口コミ・詳細取得 | 200コール | $3.40 | 各店舗5件まで、24hキャッシュ。 |
| Places Autocomplete API | 検索補助 | 200コール | $0.57 | 入力制限とキャッシュでコール数を抑制。 |
*`docs/finance/CostEstimation.md` 前提。

### 2.2 クォータ・アラート設計
- **予算アラート**: Google Cloud Console → Billing → Budgets で月額 ¥1,000 を設定。通知閾値 50% / 80% / 100% をメール（個人 + 共有）に送信。
- **APIごとのソフトリミット**:  
  - Maps JS: 400ロード/月でSoft Alert、500ロード到達でHard Alert。  
  - Places Details: 160コール（80%）でSoft、200コールでHard。  
  - Autocomplete: 160/200で同上。
- **通知チャネル**: メール + Slack（Incoming Webhook）で即時共有。
- **キャッシュ連携**: `docs/architecture/CacheStrategy.md` に基づき、CosmosのETagとブラウザ/EdgeキャッシュでGeoJSON・Placesレスポンスを再利用。80%超過時は`Cache-Control` TTLを延長し呼び出しを抑制。

### 2.3 フェイルバック方針
- 地図ロード失敗時: デフォルトエリア（東京23区）のスタティックマップと、最後に取得したGeoJSONを表示。
- Places詳細取得不可時: キャッシュ済み情報を提供し、「最新情報未取得」のバナーを表示。
- 連続エラー発生時はGoogle Cloud Consoleでクォータ増申請または日次利用設定の見直しを行う。

## 3. Instagram Graph API
### 3.1 利用権限と頻度
- 必須権限: `instagram_basic`, `pages_show_list`, `instagram_manage_insights`。Meta App Reviewを通過済みであること（`docs/operations/meta/InstagramSetup.md`）。
- データ更新頻度: 週2回の差分取得（1回あたり150リクエスト以内）。店舗数の増加に応じてバッチ分割。

### 3.2 レート制御とトークン管理
- FunctionsでETLを実行する際、1秒に1リクエスト以下、連続100リクエストごとに1秒待機を挿入。
- 長期アクセストークンはAzure Key Vaultで保管し、期限30日前にAzure Monitorのアラート（メール）を発火。
- Token失効や権限変更が発生した場合は、Metaサポートへの連絡先（アプリID、ビジネスアカウントID）を `docs/operations/meta/InstagramSetup.md` に追記。

### 3.3 アラートとメトリクス
- Meta for Developers → App Dashboard → Insights にてAPIコール数、エラー率を週次確認。
- Functionsのログ（Application Insights）でInstagram API呼び出しの成功/失敗を集計し、失敗連続10回でメール通知。
- ポリシー違反が疑われる場合、アプリを開発モードへ戻すフローをドキュメント化。

## 4. キャッシュ・デグレード戦略
- Google/InstagramレスポンスはCosmos DB + ブラウザ/Edgeキャッシュに保存し、同一データの再取得を最小化（`docs/architecture/CacheStrategy.md`）。
- クォータ超過アラート発生時は以下優先度で対処:
  1. Cache-Control TTLや差分取得間隔を調整し、レスポンスを縮小。
  2. ポーリング間隔を一時的に延長（Instagram週1回、Places詳細48hなど）。
  3. 必要に応じてユーザーへ「最新情報更新を一時的に制限しています」と告知。

## 5. 運用プロセス
1. **月初**: Google/Instagramの計画値をSpreadsheetに記録。予算アラートが有効か確認。
2. **週次**: Google Cloud Console、Meta Insights、Application Insightsを確認し、ソフトリミット到達状況を共有。
3. **アラート発生時**: キャッシュ/ポーリング設定を即時調整 → 影響範囲をSlackで共有。
4. **ユーザー増加時**: 事前にGoogleのクォータ増申請やMetaの権限追加申請を検討（ステークホルダーと合意したレベルで段階的に申請）。
5. **定期レビュー（四半期）**: API利用ログを振り返り、必要に応じて自動テスト/モニタリングを改善。

---
本ドキュメントはフェーズ1の「APIクォータ計画」タスク完了時点で最新化し、クォータ・アラートの設定状況を `docs/product/Roadmap.md` に反映する。
