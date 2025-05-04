# rules_extras

## 詳細な運用方針や具体的コード例

こちらには、.clinerules に記載するには詳細すぎるポリシー、手順、サンプルコードなどを記述します。

### テスト実行ポリシー

1. **テスト実行の基本ルール**

- **テスト実行方法**
   - `go test -list '.' ./...` を実行し TestName を得る
   - `go test ./path/to/dir/ -run <TestName>` (実際のテスト名に置き換えてください)
   - `go test` 等の実行時は必ずターゲットを明示し、`-run` などでフィルタする
   - テストは最小単位で実行し、必要な部分のみをテスト
   - 全体テストは変更完了後に実施

- **テスト実行方法 (補足)**
  - テストスイートのメソッドを実行する場合: `go test ./test/ -run <TestSuiteName>/<TestMethodName>`
  - 例: `Day03Suite` の `TestHarib00g` メソッドを実行する場合: `go test ./test/ -run Day03Suite/TestHarib00g`

2. **テストケース作成ガイドライン**
   - 各機能の基本動作を確認するテスト
   - エッジケースの網羅
   - 他の機能との相互作用の確認

### JSON調査方法

1. **asmdb JSONファイルの調査**
   ```bash
   # 特定の命令のエンコーディング情報を取得
   cat pkg/asmdb/json-x86-64/x86_64.json | jq '.instructions["INST_NAME"]'

   # オペランドタイプの一覧を取得
   cat pkg/asmdb/json-x86-64/x86_64.json | jq '.instructions["INST_NAME"].forms[].operands[].type'
   ```

2. **jqクエリのベストプラクティス**
   - パイプを使用して段階的にフィルタリング
   - 必要な情報のみを抽出
   - 結果は可読性の高いフォーマットで出力

2. **JSON DBに命令が存在しない場合の対応**
   - `pkg/asmdb/json-x86-64/x86_64.json` に命令情報が存在しない場合は、`pkg/asmdb/instruction_table_fallback.go` にGo言語で命令のエンコーディング情報を直接追記します。
   - 追記する際は、既存のフォーマットに合わせて `InstructionInfo` 構造体を定義します。

### jq を用いた JSON データ調査 (詳細)

#### json-x86-64/x86_64.json の構造

`pkg/asmdb/json-x86-64/x86_64.json` は、x86-64 アーキテクチャの命令セットに関する詳細な情報を含む JSON ファイルです。このファイルは、命令の名前、オペランド、エンコーディング、属性などの情報を提供します。

ファイルは、トップレベルで `instructions` というキーを持つオブジェクトを含み、`instructions` は命令名 (例: "ADD", "MOV", "IMUL" など) をキーとするオブジェクトの配列です。

各命令オブジェクトは、以下のプロパティを持つ `forms` 配列を含みます。

- `forms`: 命令のエンコーディング形式の配列。各要素はエンコーディング形式に関する情報を持つオブジェクトです。
  - `encodings`: エンコーディングの詳細情報の配列。通常、最初の要素 (`encodings[0]`) が主要なエンコーディング情報です。
    - `opcode`: オペコードに関する情報を持つオブジェクト
      - `byte`: オペコードのバイト表現 (16進数文字列)
    - `operands`: オペランドに関する情報の配列
      - `type`: オペランドのタイプ (例: "r8", "r16", "r32", "r64", "m8", "m16", "m32", "m64" など)
    - `ModRM`: (存在する場合) ModR/M バイトに関する情報
      - `mode`: アドレッシングモード ("11", "#0", "#1", "#2")
      - `reg`: reg フィールドの値 (固定値またはオペランドインデックス "#N")
      - `rm`: r/m フィールドの値 (固定値またはオペランドインデックス "#N")
    - `immediate`: (存在する場合) 即値に関する情報
      - `size`: 即値のバイトサイズ (1, 2, 4, 8)
      - `value`: 即値として使用するオペランドのインデックス ("#N")

#### jq コマンド例 (追加)

```bash
# 特定命令の全フォームのオペコードとオペランドタイプをTSVで表示
cat pkg/asmdb/json-x86-64/x86_64.json | jq -r '.instructions["INST_NAME"].forms[]? | [.encodings[0].opcode.byte, (.operands | map(.type)? | join(","))] | @tsv'

# 特定命令の特定フォーム (例: r32, imm32) のエンコーディング詳細を表示
cat pkg/asmdb/json-x86-64/x86_64.json | jq '.instructions["INST_NAME"].forms[] | select(.operands[0].type == "r32" and .operands[1].type == "imm32") | .encodings[0]'

# 特定のオペコードバイトを持つ命令を検索 (部分一致)
cat pkg/asmdb/json-x86-64/x86_64.json | jq '.. | objects | select(.opcode? and .opcode.byte? and (.opcode.byte | contains("OPCODE_BYTE")))'
```

### ソースコード修正ポリシー

1. **コード変更の基本ルール**
   - 変更は最小限に留める
   - 既存のパターンを踏襲
   - コメントで変更理由を明記

2. **リファクタリングガイドライン**
   - 同様のパターンが3回以上出現したら抽象化を検討
   - ユーティリティ関数は適切な場所に配置
   - テストカバレッジを維持

3. **命名規則**
   - 関数名は動詞から始める（例：processINST, handleINST）
   - 変数名は目的を明確に（例：opcodeBytes, registerNum）
   - 定数は大文字のスネークケース（例：MAX_OPERANDS）

4. **エラー処理**
   - エラーは適切な層で処理
   - エラーメッセージは具体的に
   - パニックは最小限に

### レビュー・デプロイのポリシー

1. **コードレビューのチェックポイント**
   - 既存の実装パターンとの整合性
   - テストの十分性
   - エラー処理の適切性
   - ドキュメントの更新

2. **デプロイ前の確認事項**
   - 全テストの成功
   - lint エラーの解消
   - ドキュメントの更新確認

### アセンブル結果の確認例 (PUSHF/POPFD)

`PUSHF` (オペコード `0x9C`) と `POPFD` (オペコード `0x9D`) を含むアセンブリファイルを `gosk` でアセンブルし、`hexdump` で確認する手順の例です。

### e2eテストケース作成の指示名 (2025/04/05)

- **指示名:** `generate_e2e_test_case`
- **目的:** 指定されたアセンブリコードに対するe2eテストケース（期待値生成、テストコード雛形作成を含む）を生成・実装する一連のプロセスを実行する。
- **詳細プロセス:** `memory-bank/details/technical_notes.md` の「e2e テスト作成プロセスの標準化案」を参照。

1.  **アセンブリファイルの作成 (`test.asm`)**:
    ```assembly
    [BITS 32]
    ORG 0x7c00

    PUSHF
    POPFD
    ```

2.  **アセンブルと hexdump**:
    ```bash
    # gosk でアセンブル (出力ファイルは2番目の引数で指定)
    ./gosk test.asm test.bin

    # hexdump でバイナリを確認
    hexdump -C test.bin
    ```

3.  **期待される hexdump 出力**:
    ```
    00000000  9c 9d                                             |..|
    00000002
    ```
    (アドレス `0x7c00` から `9c 9d` が出力されるはずですが、`hexdump` はファイル先頭からのオフセットを表示するため `00000000` から始まります。)
