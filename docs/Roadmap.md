# 開発ロードマップ: カフェ・レストラン可視化アプリ

## フェーズ0: 準備 (Week 0-1)
- アカウント・ライセンス整備（Azure、Google Maps、Instagram Graph API、GitHub）。
- コストアラート設定・無料枠確認、規約・ブランドガイドラインの整理。
- 要件定義・コスト試算・アカウントメモの最終レビューと承認。

## フェーズ1: アーキテクチャ設計 & 基盤構築 (Week 2-3)
- 技術スタックの詳細設計（フロント/バックエンド/データ処理構成図、API仕様書）。
- Azureリソース初期構築（Static Web Apps、Functions、Cosmos DB Serverless、Storage、Monitor）。
- Google Cloudプロジェクト設定、Maps/Places API有効化とキー制限。
- GitHubリポジトリ作成、CI/CD（GitHub Actions → Azure Static Web Apps）の雛形整備。

## フェーズ2: データ収集・AI分析基盤 (Week 4-5)
- SNSデータ取得バッチの実装（Instagram Graph API、Google Places口コミ）。
- ETLパイプライン（Azure Functionsタイマー or Data Factory）でのデータ整形・保存。
- AI要約・雰囲気タグ抽出ロジックの試作（Azure OpenAIを利用したプロンプト設計）。
- データモデル/スキーマ整備、Cosmos DBへの投入とCognitive Searchインデックス作成。

## フェーズ3: フロントエンドMVP (Week 6-7)
- 認証/アクセス制御（招待コードまたは許可済みアカウント）を実装。
- 地図表示（Google Maps JavaScript API）と店舗リスト・検索UIの作成。
- 店舗詳細画面でのAI要約・レビュー表示、お気に入りローカル保存機能の実装。
- UX検証（6名の想定ユーザーに対する操作ヒアリング）と改善。

## フェーズ4: テスト・運用準備 (Week 8)
- 自動テスト整備（ユニット、E2Eの主要シナリオ）、品質チェックリスト策定。
- 監視・ログ設定の調整（Azure Monitor / Application Insights）。
- 障害対応・問い合わせフロー定義、データ更新運用手順書を作成。
- プライバシーポリシー・利用規約ドラフトの用意（限定公開範囲に合わせた内容）。

## フェーズ5: 限定公開 & フィードバック収集 (Week 9-10)
- 本番環境へのデプロイと招待メンバーへのアクセス配布。
- 利用ログ・アンケートから改善点を抽出し、バックログ化。
- コスト・パフォーマンスの初期モニタリング、必要な最適化の実施。
- 次フェーズ（パーソナライズ、通知機能など）に向けた優先順位付け。
