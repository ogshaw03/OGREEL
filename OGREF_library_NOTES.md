# OGREF_library 開発ノート（引き継ぎ用）

OGREF本体とは別の新規アプリ「**OGREF_library**」の引き継ぎ資料。別チャットでもこのファイルを冒頭に参照すれば文脈を把握できる。
（OGREF本体の知見は `TECH_NOTES.md` / `RELEASE_NOTES.md` を参照）

## 1. 目的・コンセプト
- ワークスペースごとにユーザーが**自分でレイアウトを組んでライブラリを作成**するアプリ。
- パネルレイアウト（グリッド配置）＋テキスト挿入＋区切り線で、動画/画像をまとめて見せる。
- 想定: 学校→企業へ学生作品をまとめて提示／個人が作ったライブラリを複数人で観覧 など。
- OGREF本体（複数人で共同ライブラリ）とは別物。**編集面（要ログイン）**と**観覧面（認証不要・読み取り専用URL）**を持つ。

## 2. 確定済みの方針（擦り合わせ結果）
1. Firestoreは**同一Firebaseプロジェクト内で `lib_` プレフィックス分離**（dev は `lib_dev_`）。将来、別プロジェクトに分離する可能性あり。
2. 「ワークスペースは共有できない」＝**他者は編集WSに参加できず、読み取り専用の観覧URLのみ共有**。
3. 観覧URLは**WS単位**（そのWSの全ライブラリをサイドバーに縦並び表示）。
4. 編集WSは**個人専用**（招待・複数人編集なし）。
5. メディアは**URL指定のみ**（アップロード/Storage不使用、Googleドライブ等を利用）。
6. 観覧は**限定公開＋パスワード保護**。
7. 初版レイアウト機能: **グリッド列数・サイズ可変・ドラッグ配置・テキスト・区切り線**。
   - サイズ可変は**ライブラリ内タイルすべてを一律サイズ**（タイルごとに違うサイズにしない）。

## 3. 成果物 / 現状
- ファイル: **`OGREF_library.html`**（編集モードと観覧モードを1ファイルに内包・dev版・単一HTML）
- 公開URL（編集）: https://ogshaw03.github.io/OGREF/OGREF_library.html
- 観覧URL: `OGREF_library.html?view=<token>`（公開設定で生成）
- 状態: **MVP（叩き台）まで実装済み。ここで一旦ストップ。**

## 4. データモデル（Firestore / OGREFとは別系統）
- 定数: `C_WS = lib_dev_workspaces`（本番 `lib_workspaces`）, `C_PUB = lib_dev_public`（本番 `lib_public`）
- `lib_dev_workspaces/{wsId}` = `{ name, ownerUid, createdAt, viewToken?, viewPassword? }`
  - 一覧取得は `where('ownerUid','==', uid)`（個人専用）
  - `/libraries/{libId}` = `{ name, order, cols, aspect, gap, items:[], createdAt, updatedAt, ownerUid }`
    - **items は配列フィールド**（ドラッグ並べ替え・レイアウト順を1ドキュメントで管理）
    - item types:
      - `{ id, type:'media', kind:'video'|'image', url, cap }`
      - `{ id, type:'text', content }`
      - `{ id, type:'separator' }`
- `lib_dev_public/{token}` = `{ wsId, wsName, pwHash(SHA-256), libraries:[{id,name,cols,aspect,gap,items}], updatedAt }`
  - 公開（パブリッシュ）操作で編集側からミラー作成。観覧側は**これだけ**を読む。

## 5. 上限
- 1ワークスペースあたりライブラリ **10**（`LIB_LIMIT`）
- 1ライブラリあたりメディア **200**（`ITEM_LIMIT`、media要素のみカウント）
- いずれもアプリ側で制御（Firestoreルールでの個数強制はしていない）

## 6. 必要な Firestore ルール（OGREF全体の全文版）
Firebaseコンソールに以下を全文貼り付け。`lib_*_public` のみ観覧用に `read: if true`。
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // OGREF 本番
    match /workspaces/{wsId}/{document=**} { allow read, write: if request.auth != null; }
    match /access_control/{docId}          { allow read, write: if request.auth != null; }
    match /users/{uid}/{document=**}        { allow read, write: if request.auth != null; }
    match /feedback/{id}                    { allow read, create, update, delete: if request.auth != null; }
    // OGREF DEV
    match /dev_workspaces/{wsId}/{document=**} { allow read, write: if request.auth != null; }
    match /dev_access_control/{docId}          { allow read, write: if request.auth != null; }
    match /dev_users/{uid}/{document=**}        { allow read, write: if request.auth != null; }
    match /dev_feedback/{id}                    { allow read, create, update, delete: if request.auth != null; }
    // OGREF Library 本番
    match /lib_workspaces/{wsId}/{document=**} { allow read, write: if request.auth != null; }
    match /lib_public/{token}                  { allow read: if true; allow write: if request.auth != null; }
    // OGREF Library DEV
    match /lib_dev_workspaces/{wsId}/{document=**} { allow read, write: if request.auth != null; }
    match /lib_dev_public/{token}                  { allow read: if true; allow write: if request.auth != null; }
  }
}
```

## 7. 実装済みの機能（MVP）
- 認証（Google）・WS選択（作成/一覧/削除、個人専用）
- ライブラリ一覧（作成/リネーム/削除、≤10）
- エディタ: メディア追加（URL・種別auto/動画/画像・キャプション、≤200）/ テキスト追加・編集 / 区切り線
- レイアウト: 列数(2-6) / 形(16:9・正方形・4:3・縦長) / 余白(0-28px)、**全タイル一律**
- ドラッグ並べ替え（HTML5 drag、items配列を入れ替えて保存）
- 公開設定: パスワード設定→観覧URL生成（`lib_dev_public/{token}` にミラー）/ 公開更新 / 公開停止
- 観覧モード（`?view=token`）: パスワードゲート（SHA-256比較）→ サイドバー＋読み取り専用グリッド
- メディア埋め込み: YouTube / Vimeo / Google Drive(preview) / 画像(img) / その他は汎用iframe
- Firestore永続キャッシュ有効（OGREF同様）

## 8. 既知の制約・今後の検討（TODO）
- **セキュリティ（重要）**: 観覧ミラー(`lib_*_public`)は認証なしで読めるため、パスワードはハッシュ保存でもブラウザから`pwHash`は見え得る（ブルートフォース可能）。**高機密用途には非推奨**。本格的にやるなら Cloud Functions 等でサーバー側検証が必要。
- 画像/動画の表示確認（Googleドライブの権限「リンクを知る全員」が必要等）。
- レイアウトの高度化（タイルの行スパン/列スパン、ドラッグの行間移動の体験、テキストの装飾）。
- 観覧URLの per-library ディープリンク（`?view=token&lib=ID`）は未実装。
- モバイル最適化（観覧/編集とも現状はPC前提のレイアウト）。
- 上限（10/200）超過時のUI・大量items時のパフォーマンス（配列1ドキュメントのサイズ上限1MBに注意。200件・URLのみなら問題ない想定）。
- 本番（`lib_`）への展開はまだ。dev検証後に。

## 9. 進め方（チャット分割後）
- 新チャット冒頭でこのノートと `OGREF_library.html` を参照すれば再開可能。
- 開発はまず dev（`lib_dev_`）で。OGREF本体（`OGREF_dev.html` / `OGREF_Beta.html`）とはコードもFirestoreも独立。
- ブランチ運用・コミット/PRフローは OGREF と同様（このリポジトリ `ogshaw03/OGREF`）。
