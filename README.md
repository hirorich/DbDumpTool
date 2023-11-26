# DbDumpTool
## 主要なクラス
- DbDumpTool
  - DbDataReaderWriter
    - DbDataReader の内容をExcelシートに出力する

    ``` c#
    DbDataReader reader; //インスタンスを事前に生成

    DbDataReaderWriter writer = DbDataReaderWriter.GetInstance();
    string filename = Path.Combine(Environment.CurrentDirectory, "output.xlsx");
    using (var excelApp = new ExcelWrapper(filename))
    {
        using (var excelSheet = excelApp.AddSheet())
        {
            writer.Write(excelSheet.ComObject, reader); //内容を出力
            excelSheet.ComObject.Name = "Sample"; //シート名
        }
        excelApp.Save(); //保存
    }
    ```

  - DbCommandCreater
    - DBダンプ取得クエリを生成する

    ``` c#
    using DbType = System.Data.DbType; //エイリアス
    DbConnection connection; //インスタンスを事前に生成

    // パラメータ指定
    var parameters = new List<string>();
    parameters.Add("param");

    // ソートキー指定(指定なしの場合は null)
    var keys = new List<string>();
    parameters.Add("key");

    // コマンド生成
    var creater = new DbCommandCreater(connection);
    var command = creater.CreateCommand<string>("TABLE_NAME", "COLUMN_NAME", DbType.String, parameters, keys);

    // コマンド実行
    using (command)
    {
        var reader = command.ExecuteReader();
    }
    ```

- ToolCommon
  - Logger
    - ログ出力部品

    ``` c#
    class Example
    {
        private Logger logger;
    
        public Example()
        {
            this.logger = new Logger(this.GetType());
        }
        
        public void Method()
        {
            this.logger.Info("ログ出力内容");
        }
    }
    ```

## 参考
- [Worksheet インターフェイス](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.office.interop.excel.worksheet?view=excel-pia)
- [Range インターフェイス](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.office.interop.excel.range?view=excel-pia)
- [Font インターフェイス](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.office.interop.excel.font?view=excel-pia)
- [Interior インターフェイス](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.office.interop.excel.interior?view=excel-pia)
- [Borders インターフェイス](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.office.interop.excel.borders?view=excel-pia)
- [Constants 列挙型](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.office.interop.excel.constants?view=excel-pia)
- [XlBordersIndex 列挙型](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.office.interop.excel.xlbordersindex?view=excel-pia)
- [DbDataReader クラス](https://learn.microsoft.com/ja-jp/dotnet/api/system.data.common.dbdatareader?view=netframework-4.7.2)
- [C#でエクセル、ワード、パワーポイントのテキスト抽出](https://qiita.com/tashxii/items/ae32d62bc0420347fad3)
