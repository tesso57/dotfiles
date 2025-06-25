# テスト実装ガイド
## 概要
このドキュメントは，テスト実装方法を定義します。

### 基本方針
- **Goのイディオムに従う**: 標準的なGoのテストパターンを採用
- **AAAパターンを優先**: ユニットテスト・統合テストではAAA（Arrange-Act-Assert）パターンを基本とする
- **TDTは選択的使用**: テストデータの網羅性が重要な場合のみテーブル駆動テストを採用

## 1. ユニットテスト

### 1.1 テストパターンの選択基準

#### AAAパターン（優先的に使用）
**使用場面**：
- ビジネスロジックのテスト
- 複雑な処理フローのテスト
- エラーハンドリングのテスト
- 状態変更を伴うテスト

#### テーブル駆動テスト（TDT）
**使用場面**：
- バリデーションの網羅的なテスト
- 境界値テスト
- 文字列フォーマットの変換テスト
- 同一ロジックに対する多数の入力パターン

**判断基準**：
- 10個以上の類似したテストケースがある
- パラメータの組み合わせが重要
- 網羅性の証明が必要

### 1.2 実装例

#### AAAパターンの実装（推奨）
```go
func TestAnimal_Run(t *testing.T) {
    t.Run("nilのAnimalの場合", func(t *testing.T) {
        // Arrange
        var animal *Animal = nil

        // Act
        result := animal.Run()

        // Assert
        assert.Equal(t, "", result)
    })

    t.Run("正常系：猫の場合", func(t *testing.T) {
        // Arrange
        animal := &Animal{
            ID:   uuid.New(),
            Type: "Cat",
            Name: "Tama",
            Age:  3,
        }

        // Act
        result := animal.Run()

        // Assert
        assert.Equal(t, "Tama is running!", result)
    })
}
```

#### TDTの実装（網羅性が重要な場合）
```go
func TestLanguageType_String(t *testing.T) {
    tests := []struct {
        name         string
        languageType *LanguageType
        want         string
    }{
        {
            name: "英語の場合",
            languageType: &LanguageType{
                Code: "en",
                Name: "English",
            },
            want: "English",
        },
        {
            name: "日本語の場合",
            languageType: &LanguageType{
                Code: "ja",
                Name: "日本語",
            },
            want: "日本語",
        },
        {
            name: "空文字の場合",
            languageType: &LanguageType{
                Code: "",
                Name: "",
            },
            want: "",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := tt.languageType.String()
            assert.Equal(t, tt.want, result)
        })
    }
}
```
