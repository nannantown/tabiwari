# App Store スクリーンショット撮影ガイド

## 📱 スクリーンショット一覧

### 必要な画面（iPhone 16 Pro Max - 1290×2796px）

1. **01_main_screen.png** ✅ - メイン画面（タブ表示全体）
2. **02_participants.png** ⏳ - 参加者管理画面
3. **03_expenses.png** ⏳ - 支出記録画面
4. **04_settlement.png** ⏳ - 精算結果画面
5. **05_csv_import.png** ⏳ - CSV 読込機能（オプション）

## 🎯 撮影手順

シミュレーター上でタブを切り替えながら、以下のコマンドを実行：

```bash
# 参加者タブをタップしてから
xcrun simctl io "753AB8AA-6D2B-4DB5-8684-3D3A116BD7B6" screenshot screenshots/02_participants.png

# 支出タブをタップしてから
xcrun simctl io "753AB8AA-6D2B-4DB5-8684-3D3A116BD7B6" screenshot screenshots/03_expenses.png

# 精算タブをタップしてから
xcrun simctl io "753AB8AA-6D2B-4DB5-8684-3D3A116BD7B6" screenshot screenshots/04_settlement.png
```

## 📋 App Store 要件

- **解像度**: 1290×2796px (iPhone 16 Pro Max)
- **枚数**: 3-10 枚（最低 3 枚）
- **形式**: PNG
- **内容**: 実際のアプリ機能を示すもの

## ✅ 完了状況

- [x] メイン画面
- [ ] 参加者画面
- [ ] 支出画面
- [ ] 精算画面
