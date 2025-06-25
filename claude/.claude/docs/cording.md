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

- すべてのGoソースコードは`gofmt`の出力に準拠する
- 行の長さに固定制限はない（可読性を優先）
- import文は`goimports`で自動整理

## 命名規則

### パッケージ名
- 小文字のみ使用
- 単数形を使用
- アンダースコアやハイフンは使用しない
- 汎用的な名前（`util`、`common`など）は避ける
- 説明的で簡潔な名前を使用

### ファイル名
- スネークケース（snake_case）を使用
- テストファイルは `_test.go` で終わる
- モックファイルは `_mock.go` で終わる

### 変数名
- 小さいスコープ（1-7行）: 短い名前でも可（`i`、`s`、`u`）
- 大きいスコープ（15行以上）: より説明的な名前（`userID`、`titleName`）
- メソッドレシーバー: 1-2文字の短い名前（構造体名の頭文字の小文字）
- 型情報の重複を避ける

```go
// Good
var users []*User
count := len(users)

// Bad
var userSlice []*User
numUsers := len(userSlice)
```

### 関数名
- 複雑な操作には説明的な動詞を使用

```go
// Good
func (s *Service) ComputeStatistics() (*Stats, error)
func (s *Service) FetchExternalData() (*Data, error)
```

### インターフェース名
- 単一メソッドの場合は `-er` で終わる
- 複数メソッドの場合は役割を表す名前を使用

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
- 小文字で始まる
- 句読点で終わらない
- 他のエラーとラップされることを想定

```go
// Good
errors.New("cannot parse config")
fmt.Errorf("failed to connect to database: %w", err)

// Bad
errors.New("Cannot parse config.")
errors.New("Failed to connect to database!")
```

## コメント

### 基本ルール
- すべてのエクスポートされた名前には文章形式のコメントを付ける
- コメントは完全な文で、大文字で始まりピリオドで終わる
- パッケージコメントは`package`句の直前に配置
- 名前で始まる（例：`Title represents...`、`NewTitle creates...`）

```go
// Package sample provides ...
package sample

// Title represents ...
type Title struct {
    ID   uuid.UUID
    Name string
}

// NewTitle creates a new Title ...
func NewTitle(name string) (*Title, error) {
    // implementation
}
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

## テスト

### 基本ルール
- テストファイルは `*_test.go` で終わる
- テスト関数は `Test` で始まる
- ベンチマークは `Benchmark` で始まる
- テストは独立して実行可能であるべき

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

### テストヘルパー
```go
// テストヘルパー関数は t.Helper() を呼ぶ
func assertEqual(t *testing.T, got, want interface{}) {
    t.Helper()
    if got != want {
        t.Errorf("got %v; want %v", got, want)
    }
}

// 一時的なテストデータの作成
func createTestUser(t *testing.T) *User {
    t.Helper()
    return &User{
        ID:   uuid.New().String(),
        Name: "test user",
    }
}
```

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