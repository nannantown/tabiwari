# 🚀 App Store 申請準備完了チェックリスト

## ✅ 完了済み項目

### 📱 **アプリ設定**

- [x] **アプリ名**: 旅ワリ
- [x] **Bundle ID**: com.kokinaniwa.tabimori-warikan
- [x] **バージョン**: 1.0.0+1
- [x] **iOS ビルド**: 成功 ✓
- [x] **Xcode プロジェクト**: 準備完了

### 🎨 **デザインリソース**

- [x] **アプリアイコン**: assets/app_icon_1024.png (89KB, 1024x1024px)
- [x] **スクリーンショット**: screenshots/01_main_screen.png (4MB, iPhone 16 Pro Max)
- [ ] **追加スクリーンショット**: 2-3 枚追加推奨

### 📄 **ドキュメント**

- [x] **プライバシーポリシー**: docs/privacy_policy.html
- [x] **利用規約**: terms_of_service.md
- [x] **App Store 説明文**: app_store_metadata.md

### 🌐 **Web 公開**

- [x] **プライバシーポリシー HTML**: 作成完了
- [ ] **GitHub Pages 有効化**: 要実行
- [ ] **プライバシーポリシー URL**: GitHub Pages 公開後取得

## 🔄 **今すぐ実行可能**

### **1. 追加スクリーンショット撮影**

シミュレーター上で各タブをタップしてから実行：

```bash
# 参加者画面
xcrun simctl io "753AB8AA-6D2B-4DB5-8684-3D3A116BD7B6" screenshot screenshots/02_participants.png

# 支出画面
xcrun simctl io "753AB8AA-6D2B-4DB5-8684-3D3A116BD7B6" screenshot screenshots/03_expenses.png

# 精算画面
xcrun simctl io "753AB8AA-6D2B-4DB5-8684-3D3A116BD7B6" screenshot screenshots/04_settlement.png
```

### **2. GitHub Pages 有効化**

```bash
# Git リポジトリに追加・コミット
git add docs/ assets/ screenshots/
git commit -m "App Store申請用リソース追加: プライバシーポリシー、アイコン、スクリーンショット"
git push origin main

# GitHub.com > Settings > Pages > Source: Deploy from a branch > main/docs
```

### **3. Xcode でアーカイブ作成**

```bash
# Xcode ワークスペースを開く（既に開いてる）
open ios/Runner.xcworkspace

# Xcode で：
# Product → Archive → Distribute App → App Store Connect
```

## 📊 **App Store Connect 設定データ**

すべての情報は `app_store_metadata.md` に記載済み：

- **アプリ名**: 旅ワリ
- **サブタイトル**: シンプル割り勘計算
- **カテゴリ**: ユーティリティ
- **価格**: 無料
- **年齢制限**: 4+
- **説明文**: 完成済み（4000 文字以内）
- **キーワード**: 完成済み（100 文字以内）

## 🎯 **残り作業時間: 約 30 分**

1. **スクリーンショット撮影**: 5 分
2. **GitHub Pages 設定**: 10 分
3. **Xcode アーカイブ**: 10 分
4. **App Store Connect 申請**: 5 分

## 🏆 **準備完了度: 90%**

主要なリソースとドキュメントはすべて準備完了！
残りは撮影と公開のみです。
