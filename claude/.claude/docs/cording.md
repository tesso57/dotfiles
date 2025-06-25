# Go コーディングTIPS・規約

このドキュメントは、Go言語での開発におけるコーディング規約とベストプラクティスをまとめたものです。

## 基本原則

- **明確性 > 賢さ**: シンプルで理解しやすいコードを書く
- **エラーを無視しない**: すべてのエラーを適切に処理する
- **早期リターン**: ネストを減らし、読みやすさを向上させる
- **ゼロ値を活用**: 明示的な初期化が不要な設計を心がける
- **インターフェースは小さく**: 単一責任の原則に従う
- **並行性は共有メモリではなく通信で**: "Don't communicate by sharing memory; share memory by communicating"

## フォーマット

### 基本原則
- すべてのGoソースコードは`gofmt`の出力に準拠する
- `gofmt`はコードを標準的なスタイルに自動整形し、フォーマットに関する議論を減らす
- 行の長さに固定制限はない（可読性を優先）
- import文は`goimports`で自動整理

### インデントとスペース
- インデントにはタブ文字を使用
- スペースは整列が必要な場合のみ使用
- `gofmt`が構造体フィールドのコメント位置なども自動整列
- **行長制限なし**: 極端に長い場合はリファクタリングを検討

```go
type T struct {
    name string // name of the object
    value int   // its value
}
```

### インポートの整理
インポートは以下の順序でグループ化し、グループ間は空行で区切ります：

1. 標準ライブラリ
2. サードパーティ/自社パッケージ  
3. プロトコルバッファ関連（必要な場合）
4. 副作用目的のパッケージ（`_ import`）

```go
import (
    // 標準ライブラリ
    "context"
    "fmt"
    
    // サードパーティ
    "github.com/pkg/errors"
    "golang.org/x/sync/errgroup"
    
    // 自社パッケージ
    "mycompany.com/myproject/pkg/auth"
    
    // 副作用インポート
    _ "net/http/pprof"
)
```

### ブレースとセミコロン挿入ルール
Goのレキサーは行末で自動的にセミコロンを挿入するため、制御構造の開きブレース `{` は必ず同じ行に置く必要があります。

```go
// 正しい
if condition {
    // ...
}

// 誤り（コンパイルエラー）
if condition
{  // 前の行でセミコロンが挿入されてしまう
    // ...
}
```

### 制御構造での括弧の省略
C言語やJavaと異なり、Goでは制御構造の条件式に括弧は不要です。

```go
// Good
if x > 0 {
    fmt.Println("Positive")
}

// Bad - 不要な括弧
if (x > 0) {
    fmt.Println("Positive")
}
```

## 命名規則

### 基本スタイル
- **MixedCaps（キャメルケース）を使用**: Goでは単語間にアンダースコアは使わず、`CamelCase`または`camelCase`を採用
- **大文字/小文字でエクスポート制御**: 先頭大文字でエクスポート、先頭小文字でパッケージプライベート
- **定数も同様**: `MaxLength`（公開）、`maxLength`（非公開）のように記述し、`MAX_LENGTH`や`kMaxLength`は避ける

### パッケージ名
- 小文字のみ使用（複数単語でもアンダースコアや大文字は含めない）
- 単数形を使用
- 汎用的な名前（`util`、`common`、`helper`など）は避ける
- 説明的で簡潔な名前を使用
- 変数名として頻出する単語との衝突を避ける（例：`count`より`usercount`）
- テスト専用パッケージは元のパッケージ名に`_test`を付加（例：`linkedlist_test`）

### ファイル名
- スネークケース（snake_case）を使用
- テストファイルは `_test.go` で終わる
- モックファイルは `_mock.go` で終わる

### 変数名
- **スコープの大きさに応じた長さ**: 短いスコープ（数行）では一文字でも可、広いスコープでは説明的な名前
- 小さいスコープ（1-7行）: 短い名前でも可（`i`、`s`、`u`）
- 大きいスコープ（15行以上）: より説明的な名前（`userID`、`titleName`）
- メソッドレシーバー: 1-2文字の短い名前（構造体名の頭文字の小文字）
- **型情報や用途を名前に含めない**: `users`で十分、`userSlice`は不要
- **慣用的な短縮名**: `io.Reader`→`r`、`http.ResponseWriter`→`w`、エラー→`err`

```go
// Good
var users []*User
count := len(users)

// Bad
var userSlice []*User
numUsers := len(userSlice)
```

### 関数名
- **動詞/名詞の使い分け**: 副作用のない関数は名詞的、処理を行う関数は動詞的
- Getterに`Get`プレフィックスは付けない（例外：HTTP GETなど）
- 同じ機能で型が異なる場合は型名を付加（例：`ParseInt`、`ParseInt64`）
- 1つのパッケージで主要な型が1つなら、コンストラクタは単に`New`

```go
// Good
func (u *User) Name() string { return u.name }     // Getter
func (u *User) SetName(name string) { u.name = name } // Setter
func (s *Service) ComputeStatistics() (*Stats, error)
func (s *Service) FetchExternalData() (*Data, error)

// Bad
func (u *User) GetName() string { return u.name }  // 不要なGet
```

### インターフェース名
- 単一メソッドの場合は `-er` で終わる
- 複数メソッドの場合は役割を表す名前を使用
- `IName`のような接頭辞は使わない（Goの慣習）

```go
// Good
type Reader interface {
    Read([]byte) (int, error)
}

type UserRepository interface {
    FindByID(context.Context, uuid.UUID) (*User, error)
    Save(context.Context, *User) error
}
```

### 構造体名と型名
- 内容を表す名詞をキャメルケースで命名
- パッケージ名との繰り返しを避ける（例：`reporting`パッケージなら`Report`型、`ReportingReport`は冗長）
- 型のメソッドでもパッケージで明らかな情報は含めない（例：`Project`型なら`Name()`メソッド、`ProjectName()`は不要）

### 定数名と略語
- 定数もキャメルケースを使用（`MaxUsers`は良い、`MAX_USERS`や`kMaxUsers`は避ける）
- 略語（ID、API、URLなど）は一貫した大小文字にする
  - すべて大文字（`URL`、`API`）またはすべて小文字（`url`、`api`）
  - 部分的な大文字（`Url`、`Api`）は避ける
  - 連続する略語も同様（例：`XMLAPI`で`XML`と`API`を統一）

## 制御構造

### if文の初期化文
`if`文では条件の前に簡単な初期化文を書くことができます。この変数のスコープは`if`ブロック内に限定されます。

```go
// ファイルを開いてエラーチェック
if err := file.Chmod(0664); err != nil {
    log.Print(err)
    return err
}

// 値の存在チェックとともに使用
if val, ok := myMap[key]; ok {
    // valを使用
    return val
}
```

### switch文の柔軟性
Goの`switch`は他言語より強力で柔軟です。

```go
// 式なしswitch（if-elseチェーンの代替）
switch {
case score >= 90:
    grade = "A"
case score >= 80:
    grade = "B"
default:
    grade = "F"
}

// 複数の値にマッチ
switch c {
case ' ', '\t', '\n':
    return true
}

// 型switch
switch v := i.(type) {
case int:
    fmt.Printf("Integer: %d\n", v)
case string:
    fmt.Printf("String: %s\n", v)
default:
    fmt.Printf("Unknown type\n")
}
```

**注意**: Goの`switch`は自動的にbreakするため、`fallthrough`を明示的に書かない限り次のcaseには進みません。

### for文とrangeイディオム
Goには`while`文がなく、すべて`for`で表現します。

```go
// 無限ループ
for {
    // ...
}

// 条件付きループ（whileの代替）
for condition {
    // ...
}

// rangeを使った反復
for i, v := range slice {
    fmt.Printf("%d: %v\n", i, v)
}

// インデックスが不要な場合
for _, v := range slice {
    sum += v
}

// 値が不要な場合
for i := range slice {
    slice[i] = 0
}
```

### ブランク識別子 (_)
ブランク識別子は値を明示的に無視するために使用します。

```go
// 不要な戻り値を無視
_, err := io.Copy(dst, src)

// rangeでインデックスを無視
for _, value := range array {
    sum += value
}

// インターフェース実装の確認
var _ io.Writer = (*MyWriter)(nil)

// importの副作用のみを利用
import _ "net/http/pprof"
```

## エラーハンドリング

### 基本原則
- エラーは値として扱い、明示的に処理する
- パニックは本当に回復不可能な場合のみ使用
- エラーメッセージは文脈を提供し、デバッグを容易にする

### エラーの返却
```go
// Good - エラーは最後の戻り値
func DoSomething() (*Result, error) {
    if err := validate(); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }
    return &Result{}, nil
}

// Bad
func DoSomething() (error, *Result) {
    // エラーを最初に返すのは避ける
}
```

### 早期リターンパターン
エラー処理でネストが深くならないよう、エラーが発生したら即座にreturnする「早期リターン」パターンを使用します。

```go
// Good - 早期リターンでネストを避ける
func ReadFile(filename string) ([]byte, error) {
    f, err := os.Open(filename)
    if err != nil {
        return nil, err
    }
    defer f.Close()
    
    data, err := ioutil.ReadAll(f)
    if err != nil {
        return nil, err
    }
    
    return data, nil
}

// Bad - 不要なelse節
func ReadFile(filename string) ([]byte, error) {
    f, err := os.Open(filename)
    if err == nil {
        defer f.Close()
        data, err := ioutil.ReadAll(f)
        if err == nil {
            return data, nil
        } else {
            return nil, err
        }
    } else {
        return nil, err
    }
}
```

### エラーのラップ
```go
// Good - コンテキストを追加しながらエラーをラップ
if err := db.Query(ctx, query); err != nil {
    return fmt.Errorf("failed to fetch user id=%s: %w", userID, err)
}

// errors.Is と errors.As で検査可能
if errors.Is(err, ErrNotFound) {
    // 特定のエラー処理
}
```

### センチネルエラー
```go
// パッケージレベルで定義
var (
    ErrNotFound = errors.New("not found")
    ErrInvalidInput = errors.New("invalid input")
)

// 使用例
func FindUser(id string) (*User, error) {
    if id == "" {
        return nil, ErrInvalidInput
    }
    // ...
    return nil, ErrNotFound
}
```

### カスタムエラー型
```go
// エラーに構造化された情報を含める場合
type ValidationError struct {
    Field string
    Value interface{}
    Msg   string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error: field=%s value=%v msg=%s", 
        e.Field, e.Value, e.Msg)
}

// 使用例
func Validate(input *Input) error {
    if input.Age < 0 {
        return &ValidationError{
            Field: "age",
            Value: input.Age,
            Msg:   "must be non-negative",
        }
    }
    return nil
}
```

### エラー文字列のフォーマット
- 小文字で始まる（固有名詞やエクスポート名で始まる場合を除く）
- 句読点で終わらない
- 他のエラーとラップされることを想定
- エラーメッセージだけで文脈が分かるようにする

```go
// Good
errors.New("cannot parse config")
fmt.Errorf("failed to connect to database: %w", err)

// Bad
errors.New("Cannot parse config.")
errors.New("Failed to connect to database!")
```

### エラーの無視
エラーは**必ず処理**します。`_`でエラーを無視することは基本的に避けてください。

```go
// Bad - エラーを無視
val, _ := strconv.Atoi(str)

// Good - エラーを処理
val, err := strconv.Atoi(str)
if err != nil {
    return err
}

// どうしても無視する必要がある例外的なケース
n, _ := b.Write(p) // bytes.Buffer.Writeは常に成功するためエラーは無視
```

### エラー型の設計
- エラーを表す具体型をエクスポートしない（Googleの推奨）
- 公開関数の戻り値は`error`インタフェース型にする
- エラー判定には`errors.Is/As`を使用
- センチネルエラーは公開変数として定義

```go
// Good - センチネルエラーの定義
var ErrNotFound = errors.New("not found")

// Bad - 具体的なエラー型をエクスポート
type NotFoundError struct{} // 避ける
```

## コメント

### コメントの目的
- **「なぜ」を説明する**: コードの意図や背景を伝える
- **「何を」はコード自体で表現**: 明確な命名と構造で示す
- 冗長なコメントは避ける（コードから明白なことを繰り返さない）

### ドキュメンテーションコメント
- すべてのエクスポートされた名前には文章形式のコメントを付ける
- コメントは完全な文で、大文字で始まりピリオドで終わる
- パッケージコメントは`package`句の直前に配置（1パッケージに1箇所のみ）
- 名前で始まる（例：`Title represents...`、`NewTitle creates...`）
- 必要に応じて冠詞（A、The）で始めても良い

```go
// Package sample provides utility functions for sample processing.
// This package includes various helper functions and types that
// make sample manipulation easier and more efficient.
package sample

// A Title represents a document title with unique identifier.
type Title struct {
    ID   uuid.UUID
    Name string
}

// NewTitle creates a new Title with the given name.
// It returns an error if the name is empty.
func NewTitle(name string) (*Title, error) {
    if name == "" {
        return nil, errors.New("name cannot be empty")
    }
    return &Title{
        ID:   uuid.New(),
        Name: name,
    }, nil
}
```

### コメントのスタイル
- 文章として完結するコメントは大文字始まり、ピリオド終わり
- 短いフレーズの行末コメントは形式に拘らない
- 長いコメントは80文字前後で適切に改行
- `//`による複数行コメントまたは`/* */`ブロックコメントを使用

### TODOコメント
- 将来的な課題には`// TODO:`を使用
- 必要に応じて担当者名やチケット番号を記載
- 恒久的に残さず、後で対処する前提で使用

```go
// TODO(alice): Add validation for special characters
// TODO: Implement caching mechanism (see issue #123)
```

## 構造体とメソッド

### レシーバー名
- 1-2文字の短い名前を使用（構造体名の頭文字の小文字）
- 同じ型のすべてのメソッドで一貫性を保つ
- `self`、`this`、`me`などは使用しない

```go
// Good
func (t *Title) Name() string {
    return t.Name
}

func (t *Title) SetName(name string) {
    t.Name = name
}

// Bad
func (title *Title) Name() string { // レシーバー名が長すぎる
    return title.Name
}

func (self *Title) SetName(name string) { // self は使用しない
    self.Name = name
}
```

### ポインタ vs 値レシーバー
以下の場合はポインタレシーバーを使用：
- メソッドがレシーバーを変更する場合
- レシーバーが大きな構造体の場合
- 同じ型の他のメソッドがポインタレシーバーの場合（一貫性のため）
- レシーバーがsync.Mutexなどコピー不可能なフィールドを含む場合

```go
// ポインタレシーバー - 状態を変更
func (u *User) UpdateName(name string) {
    u.Name = name
    u.UpdatedAt = time.Now()
}

// 値レシーバー - 小さく不変な型
func (p Point) Distance(q Point) float64 {
    return math.Sqrt(math.Pow(p.X-q.X, 2) + math.Pow(p.Y-q.Y, 2))
}
```

### Nil安全性
```go
// Good - nilチェックを含む
func (t *Title) GetName() string {
    if t == nil {
        return ""
    }
    return t.Name
}
```

### ゼロ値を活用した設計
```go
// ゼロ値で使用可能な型
type Buffer struct {
    buf []byte
}

// ゼロ値でも安全に動作
func (b *Buffer) Write(p []byte) (int, error) {
    b.buf = append(b.buf, p...)
    return len(p), nil
}

// 使用例 - 初期化不要
var buf Buffer
buf.Write([]byte("hello"))
```

### コンストラクタとファクトリ関数
ゼロ値で不十分な場合はコンストラクタ関数を提供します。Goではローカル変数のアドレスを返しても安全です。

```go
func NewFile(fd int, name string) *File {
    if fd < 0 {
        return nil
    }
    // 複合リテラルを使用
    f := File{fd: fd, name: name}
    return &f  // ローカル変数のアドレスを返しても安全
}

// より簡潔な書き方
func NewUser(name string, age int) *User {
    return &User{
        Name:      name,
        Age:       age,
        CreatedAt: time.Now(),
    }
}

// オプション付きコンストラクタパターン
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) {
        s.port = port
    }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        port: 8080,  // デフォルト値
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

## テスト

### 基本ルール
- テストファイルは `*_test.go` で終わる
- テスト関数は `Test` で始まる（`TestXxx_Yyy`のようにアンダースコアでケース名を区切ることも可）
- ベンチマークは `Benchmark` で始まる
- テストは独立して実行可能であるべき
- **標準の`testing`パッケージを使用**（Googleは外部アサーションライブラリを非推奨）

### テーブルドリブンテスト
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -1, -2, -3},
        {"mixed", -1, 1, 0},
        {"zero", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d", 
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### エラーのテスト
```go
func TestDivide(t *testing.T) {
    _, err := Divide(10, 0)
    if err == nil {
        t.Fatal("expected error for division by zero")
    }
    
    // 特定のエラーをチェック
    if !errors.Is(err, ErrDivisionByZero) {
        t.Errorf("got %v; want %v", err, ErrDivisionByZero)
    }
}
```

### モックの使用
```go
// インターフェースの定義
type UserRepository interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

// テストでのモック使用
func TestUserService(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()
    
    mockRepo := mocks.NewMockUserRepository(ctrl)
    mockRepo.EXPECT().
        GetUser(gomock.Any(), "123").
        Return(&User{ID: "123", Name: "test"}, nil)
    
    service := NewUserService(mockRepo)
    user, err := service.GetUser(context.Background(), "123")
    
    assert.NoError(t, err)
    assert.Equal(t, "test", user.Name)
}
```

### Googleのテスト推奨事項
- **アサーションライブラリを避ける**: `t.Errorf`を直接使用
- **失敗判定はTest関数内で行う**: ヘルパー関数は`error`を返し、Test関数で判定
- **明示的なエラーメッセージ**: どの条件が失敗したか明確に出力

```go
// Good - Googleスタイル
func TestDivide(t *testing.T) {
    result, err := Divide(10, 2)
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if result != 5 {
        t.Errorf("Divide(10, 2) = %d; want 5", result)
    }
}

// Bad - アサーションライブラリの使用
func TestDivide(t *testing.T) {
    result, err := Divide(10, 2)
    assert.NoError(t, err)    // 避ける
    assert.Equal(t, 5, result) // 避ける
}
```

### テストヘルパー
```go
// テストヘルパー関数は t.Helper() を呼ぶ
// 失敗判定は呼び出し元で行う（errorを返す）
func setupTestDB(t *testing.T) (*sql.DB, error) {
    t.Helper()
    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        return nil, err
    }
    return db, nil
}

// セットアップ専用ヘルパーはt.Fatalを使っても良い
func mustCreateTestUser(t *testing.T) *User {
    t.Helper()
    user := &User{
        ID:   uuid.New().String(),
        Name: "test user",
    }
    if err := user.Validate(); err != nil {
        t.Fatal(err) // セットアップの失敗
    }
    return user
}
```

### テストパッケージの構成
- **ユニットテスト**: 同じパッケージ内の`*_test.go`に記述
- **ブラックボックステスト**: `packagename_test`パッケージで公開APIのみテスト
- **テストダブル（モック等）はエクスポートしない**: 必要なら専用パッケージ（例：`creditcardtest`）を作成

## Context の使用

### 基本原則
- 関数の第一引数として `context.Context` を渡す
- Context は構造体に格納しない
- nil Context を渡さない（`context.TODO()` を使用）
- 必要に応じて適切なタイムアウトを設定

```go
// Good
func GetUser(ctx context.Context, id string) (*User, error) {
    // タイムアウト付きコンテキスト
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    // データベースクエリ
    row := db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = ?", id)
    // ...
}

// Bad
func GetUser(id string) (*User, error) {
    // Context を受け取らない
}
```

### キャンセレーションの伝播
```go
func ProcessItems(ctx context.Context, items []Item) error {
    for _, item := range items {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            if err := processItem(ctx, item); err != nil {
                return err
            }
        }
    }
    return nil
}
```

## defer文の使用

### リソースの解放
```go
func ReadFile(filename string) ([]byte, error) {
    f, err := os.Open(filename)
    if err != nil {
        return nil, err
    }
    defer f.Close() // 関数終了時に必ず実行される
    
    return ioutil.ReadAll(f)
}
```

### ロックの解放
```go
func (c *Counter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock() // パニック時も解放される
    
    c.value++
}
```

### defer の実行順序（LIFO）
```go
func example() {
    defer fmt.Println("third")
    defer fmt.Println("second")
    defer fmt.Println("first")
    // Output: first, second, third
}
```

## 並行処理とゴルーチン

### 基本原則
- ゴルーチンの起動時は何をするか明確にする
- ゴルーチンのライフサイクルを管理する
- リーク防止のため、ゴルーチンの終了を保証する
- **「共有メモリによる通信ではなく、通信によるメモリ共有」** - チャネルを使ってデータを受け渡す

### 並行性の設計指針
Goでは、複数のゴルーチンが同じメモリを直接共有するのではなく、チャネルを通じてデータをやり取りすることで、データ競合を防ぎます。

```go
// Bad - 共有メモリとロック
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Inc() {
    c.mu.Lock()
    c.value++
    c.mu.Unlock()
}

// Good - チャネルによる通信
type Counter struct {
    ch chan int
}

func (c *Counter) run() {
    value := 0
    for delta := range c.ch {
        value += delta
    }
}

func (c *Counter) Inc() {
    c.ch <- 1
}
```

ただし、単純なカウンタのような場合は、ミューテックスの方が適切な場合もあります。問題に応じて最適な方法を選択してください。

### sync.WaitGroup の使用
```go
func ProcessConcurrently(items []Item) error {
    var wg sync.WaitGroup
    errCh := make(chan error, len(items))
    
    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            if err := process(item); err != nil {
                errCh <- err
            }
        }(item) // ループ変数をキャプチャ
    }
    
    wg.Wait()
    close(errCh)
    
    // エラーをチェック
    for err := range errCh {
        if err != nil {
            return err
        }
    }
    return nil
}
```

### コンテキストによるキャンセレーション
```go
func Worker(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case work := <-workQueue:
            if err := doWork(work); err != nil {
                return err
            }
        }
    }
}
```

## チャネルの使用

### 基本パターン
```go
// 送信専用チャネル
func sender(ch chan<- int) {
    ch <- 42
}

// 受信専用チャネル
func receiver(ch <-chan int) {
    value := <-ch
    fmt.Println(value)
}
```

### バッファ付きチャネル
```go
// セマフォとして使用
sem := make(chan struct{}, maxConcurrency)

for _, item := range items {
    sem <- struct{}{} // トークンを取得
    go func(item Item) {
        defer func() { <-sem }() // トークンを解放
        process(item)
    }(item)
}
```

### select文の使用
```go
func fanIn(ch1, ch2 <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for {
            select {
            case v, ok := <-ch1:
                if !ok {
                    ch1 = nil
                    continue
                }
                out <- v
            case v, ok := <-ch2:
                if !ok {
                    ch2 = nil
                    continue
                }
                out <- v
            }
            if ch1 == nil && ch2 == nil {
                return
            }
        }
    }()
    return out
}
```

## その他のベストプラクティス

### 定数の使用
```go
const (
    MaxTitleLength     = 128
    MaxPageSize        = 100
    DefaultTimeout     = 30 * time.Second
)
```

### early returnの活用
```go
// Good
func DoSomething(input string) error {
    if input == "" {
        return errors.New("input is required")
    }
    if len(input) > MaxLength {
        return errors.New("input is too long")
    }
    // メイン処理
    return nil
}
```

### スライスの事前割り当て
```go
// Good - 容量を事前に確保
users := make([]*User, 0, len(userIDs))
for _, id := range userIDs {
    user, err := getUser(id)
    if err != nil {
        return nil, err
    }
    users = append(users, user)
}

// Bad - 容量を指定しない
var users []*User
for _, id := range userIDs {
    // append のたびに再割り当てが発生する可能性
}
```

### 短い変数宣言 (:=) の活用
`:=`は変数宣言と初期化を同時に行う便利な記法です。

```go
// 基本的な使い方
name := "Alice"
count := 42

// 既存変数の再利用
// 左辺に新しい変数が1つでも含まれていれば、既存変数も再利用可能
f, err := os.Open("file1.txt")
if err != nil {
    return err
}

// 既存のerrを再利用しつつ、新しい変数dを宣言
d, err := f.Stat()
if err != nil {
    f.Close()
    return err
}
```

### newとmakeの使い分け
Goには2つのメモリ割り当て関数がありますが、用途が異なります。

```go
// new(T) - 型Tのゼロ値へのポインタを返す
p := new(int)        // *int型、値は0
s := new([]int)      // *[]int型、値はnil（実用的でない）

// make - スライス、マップ、チャネル専用
// 初期化された値そのものを返す
slice := make([]int, 10, 100)    // 長さ10、容量100のスライス
m := make(map[string]int)        // 空のマップ
ch := make(chan int, 5)          // バッファサイズ5のチャネル

// 構造体は複合リテラルを使うのがイディオマティック
user := &User{Name: "Alice", Age: 30}  // new(User)より簡潔
```

### 複合リテラルの活用
構造体の初期化には複合リテラルを使うと簡潔に書けます。

```go
// フィールド名を指定（推奨）
p := Point{X: 10, Y: 20}

// 配列・スライスの初期化
primes := []int{2, 3, 5, 7, 11}

// マップの初期化
ages := map[string]int{
    "Alice": 30,
    "Bob":   25,
}

// ネストした構造体
req := Request{
    Method: "GET",
    URL:    url,
    Header: map[string][]string{
        "Accept": {"application/json"},
    },
}
```

### 配列とスライス
配列は値型、スライスは参照型という違いを理解して使い分けます。

```go
// 配列 - サイズが型の一部、値渡し
var a [3]int
b := [...]int{1, 2, 3}  // 要素数を推論

// スライス - 可変長、参照渡し
var s []int
s = make([]int, 10)     // 長さ10
s = make([]int, 0, 10)  // 長さ0、容量10

// 配列からスライスを作成
arr := [5]int{1, 2, 3, 4, 5}
slice := arr[1:4]  // [2, 3, 4]
```

## インターフェース設計

- インターフェースは使用する側のパッケージで定義する
- 実装より先にインターフェースを定義しない
- 不要なインターフェースのエクスポートは避ける
- Goのインターフェースは暗黙的に満たされる（明示的な宣言は不要）

```go
// Good - 使用する側で定義
package usecase

type TitleRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*Title, error)
}

// Writerインターフェースを暗黙的に実装
type Buffer struct {
    data []byte
}

func (b *Buffer) Write(p []byte) (int, error) {
    b.data = append(b.data, p...)
    return len(p), nil
}
```

## パフォーマンス

### N+1問題の回避
```go
// Bad - N+1クエリ
titles, _ := titleRepo.FindAll(ctx)
for _, title := range titles {
    authors, _ := authorRepo.FindByTitleID(ctx, title.ID)
    // ...
}

// Good - JOIN または バッチ取得
titles, _ := titleRepo.FindAllWithAuthors(ctx)
```

## パッケージ設計

### パッケージの責務
- **論理的な単位でまとめる**: 関連する機能や型は同じパッケージに
- **概念的に異なる部分は分離**: 巨大パッケージを避ける
- **ユーティリティパッケージを避ける**: `util`、`common`、`helper`などは使わない
- 機能ごとに適切な名前のパッケージに属させる

### 依存関係の管理
- **グローバル変数や状態を避ける**: 明示的に依存を注入
- **`init`関数での隠れた依存を避ける**: 明示的な初期化を推奨
- **ライブラリがフラグを登録しない**: `main`関数で処理

### インターフェースの設計原則
- **必要になってから作成**（YAGNIの原則）
- **利用する側のパッケージに置く**: 実装側でインターフェースを公開しない
- **引数にはインターフェース型、戻り値には具体型**を基本とする

```go
// Good - 利用側でインターフェースを定義
// package usecase
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

// Bad - 実装側でインターフェースを公開
// package repository
type UserRepositoryInterface interface { // 避ける
    // ...
}
```

### 循環依存の回避
```go
// Bad - 循環依存
// package user imports package order
// package order imports package user

// Good - インターフェースによる依存性の逆転
// package user
type OrderService interface {
    GetOrdersByUserID(userID string) ([]*Order, error)
}

// package order は user パッケージをインポートしない
```

### 内部パッケージの使用
```go
// internal パッケージは外部から参照できない
myproject/
├── cmd/
├── internal/
│   ├── auth/     // 外部パッケージから参照不可
│   └── database/ // 外部パッケージから参照不可
└── pkg/
    └── api/      // 公開API
```

## コードの簡潔性

### 中間変数の削減
不要な中間変数を削除することで、コードをより簡潔で読みやすくできます。

```go
// Bad - 不要な中間変数
func GetUserAge(id string) (int, error) {
    user, err := getUserByID(id)
    if err != nil {
        return 0, err
    }
    age := user.Age
    return age, nil
}

// Good - 直接返す
func GetUserAge(id string) (int, error) {
    user, err := getUserByID(id)
    if err != nil {
        return 0, err
    }
    return user.Age, nil
}

// Bad - 複数の中間変数
func CalculateTotal(items []Item) float64 {
    subtotal := calculateSubtotal(items)
    tax := subtotal * taxRate
    total := subtotal + tax
    return total
}

// Good - 式を直接使用（読みやすさを損なわない範囲で）
func CalculateTotal(items []Item) float64 {
    subtotal := calculateSubtotal(items)
    return subtotal + (subtotal * taxRate)
}

// Bad - 一時的な変数への代入
func FormatUserName(user *User) string {
    name := user.FirstName + " " + user.LastName
    formatted := strings.TrimSpace(name)
    return formatted
}

// Good - メソッドチェーンや直接返却
func FormatUserName(user *User) string {
    return strings.TrimSpace(user.FirstName + " " + user.LastName)
}
```

ただし、以下の場合は中間変数を使用する方が良い：
- デバッグやロギングに必要な場合
- 複雑な計算で段階的な結果を確認したい場合
- 変数名が処理の意図を明確にする場合
- 同じ値を複数回使用する場合

```go
// 中間変数が有用な例 - 意図の明確化
func IsValidEmail(email string) bool {
    hasAtSymbol := strings.Contains(email, "@")
    hasDot := strings.Contains(email, ".")
    isLongEnough := len(email) >= 5
    
    return hasAtSymbol && hasDot && isLongEnough
}

// 中間変数が有用な例 - 再利用
func ProcessOrder(order *Order) error {
    total := calculateTotal(order)
    
    if total > maxOrderAmount {
        return fmt.Errorf("order total %v exceeds maximum", total)
    }
    
    order.Total = total
    return nil
}
```

## コードレビューチェックリスト

### フォーマットとスタイル
- [ ] `gofmt`でフォーマットされているか
- [ ] `goimports`でインポートが整理されているか
- [ ] 命名規則に従っているか（パッケージ名、変数名、関数名）

### エラーハンドリング
- [ ] すべてのエラーが適切に処理されているか
- [ ] エラー文字列のフォーマットが正しいか（小文字始まり、句読点なし）
- [ ] エラーのラップが適切か（コンテキストの追加）

### テスト
- [ ] テストが書かれているか
- [ ] テーブルドリブンテストが活用されているか
- [ ] エラーケースがテストされているか

### 並行処理
- [ ] ゴルーチンのリークがないか
- [ ] 適切な同期処理がされているか
- [ ] context によるキャンセレーションが実装されているか

### パフォーマンス
- [ ] N+1問題がないか
- [ ] スライスの事前割り当てが適切か
- [ ] 不要なメモリアロケーションがないか

### 設計
- [ ] インターフェースは小さく保たれているか
- [ ] ゼロ値で使用可能な設計になっているか
- [ ] 循環依存がないか
- [ ] DRY原則に従っているか

## 参考文献

- [Effective Go](https://go.dev/doc/effective_go) - Go言語の公式ガイドライン
- [Google Go Style Guide](https://google.github.io/styleguide/go/) - GoogleのGoスタイルガイド
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments) - Goコードレビューコメント集
- [The Go Programming Language Specification](https://go.dev/ref/spec) - Go言語仕様
- [Go Proverbs](https://go-proverbs.github.io/) - Go言語の格言集
