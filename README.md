# CoachingApp

Claude APIを使用したiOSコーチングアプリ

## 機能

- ✅ Google認証によるログイン
- ✅ Claude APIを使用したAIコーチング
- ✅ 会話履歴の永続化（Firestore）
- ✅ 過去の会話の閲覧
- ✅ メッセージバブルUIでの対話

## セットアップ手順

### 1. Firebaseプロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 新しいプロジェクトを作成
3. iOSアプリを追加（Bundle IDを入力）
4. `GoogleService-Info.plist` をダウンロード

### 2. Firebase SDKの追加

1. Xcodeでプロジェクトを開く：
   ```bash
   open CoachingApp.xcodeproj
   ```

2. プロジェクトナビゲーターで `CoachingApp` プロジェクトを選択
3. `Package Dependencies` タブに移動
4. `+` ボタンをクリックして、以下を追加：
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
5. 最新バージョンを選択
6. 以下のパッケージを追加：
   - FirebaseAuth
   - FirebaseFirestore
   - GoogleSignIn

### 3. GoogleService-Info.plistの配置

ダウンロードした `GoogleService-Info.plist` を `CoachingApp/` フォルダーにドラッグ＆ドロップ

### 4. Firebase Authentication の設定

1. Firebase Consoleで「Authentication」を開く
2. 「Sign-in method」タブを選択
3. 「Google」を有効化
4. プロジェクトのサポートメールを設定

### 5. Firestore Database の設定

1. Firebase Consoleで「Firestore Database」を開く
2. 「データベースの作成」をクリック
3. 本番環境モードで開始（または以下のルールを設定）：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 6. Claude API Keyの設定

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

### 7. ビルド・実行

Xcodeでビルドして、シミュレーターまたは実機で実行してください。

## セキュリティ注意事項

⚠️ **重要**:
- `APIKey.swift` はGitで追跡されません（.gitignoreに含まれています）
- `GoogleService-Info.plist` もGitで追跡されません
- これらのファイルは絶対にGitにコミットしないでください

## データ構造

### Firestore

```
users/{userId}/
  conversations/{conversationId}/
    - title: String
    - createdAt: Timestamp
    - updatedAt: Timestamp

    messages/{messageId}/
      - role: String ("user" | "assistant")
      - content: String
      - timestamp: Timestamp
```

## トラブルシューティング

### ビルドエラーが出る場合

1. Firebase SDKが正しくインストールされているか確認
2. `GoogleService-Info.plist` が正しく配置されているか確認
3. `APIKey.swift` が存在するか確認
4. Clean Build Folder（Cmd + Shift + K）を実行

### ログインできない場合

1. Firebase Consoleで Google 認証が有効になっているか確認
2. `GoogleService-Info.plist` が正しいプロジェクトのものか確認
