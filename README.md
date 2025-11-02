# CoachingApp

Claude APIを使用したiOSコーチングアプリ

## セットアップ手順

### 1. API Keyの設定

1. [Anthropic Console](https://console.anthropic.com/) でClaude APIキーを取得
2. `CoachingApp/APIKey.swift.example` を `CoachingApp/APIKey.swift` にコピー
3. `APIKey.swift` を開いて、`YOUR_API_KEY_HERE` を実際のAPIキーに置き換え

```bash
cp CoachingApp/APIKey.swift.example CoachingApp/APIKey.swift
```

その後、`CoachingApp/APIKey.swift` を編集：
```swift
struct APIKey {
    static let claude = "sk-ant-api03-..." // ← あなたの実際のAPIキー
}
```

### 2. プロジェクトを開く

```bash
open CoachingApp.xcodeproj
```

### 3. ビルド・実行

Xcodeでビルドして、シミュレーターまたは実機で実行してください。

## セキュリティ注意事項

⚠️ **重要**: `APIKey.swift` はGitで追跡されません（.gitignoreに含まれています）。APIキーは絶対にGitにコミットしないでください。

## 機能

- Claude APIを使用したAIコーチング
- メッセージバブルUIでの対話
- ダークモード対応
