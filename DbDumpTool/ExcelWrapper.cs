using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Excel = Microsoft.Office.Interop.Excel;
using ToolCommon;
using Microsoft.Office.Interop.Excel;

namespace DbDumpTool
{
    internal class ExcelWrapper : IDisposable
    {
        private bool disposedValue;
        private bool isCreatedSheet;
        private ComWrapper<Excel.Application> excelApp;
        private ComWrapper<Excel.Workbooks> excelBooks;
        private ComWrapper<Excel.Workbook> excelBook;

        public ExcelWrapper(string filename)
        {
            this.excelApp = new ComWrapper<Excel.Application>(new Excel.Application() { Visible = false, DisplayAlerts = false });
            this.excelBooks = new ComWrapper<Excel.Workbooks>(this.excelApp.ComObject.Workbooks);
            this.excelBook = new ComWrapper<Excel.Workbook>(this.excelBooks.ComObject.Add());
            this.excelBook.ComObject.SaveAs(filename);
        }

        public ComWrapper<Excel.Worksheet> AddSheet(string sheetname)
        {
            // デフォルトで作成されたシート名を取得
            var defaultSheetnames = new List<string>();
            if (!this.isCreatedSheet)
            {
                foreach (Excel.Worksheet sheet in this.excelBook.ComObject.Worksheets)
                {
                    using (var excelSheetWrap = new ComWrapper<Excel.Worksheet>(sheet))
                    {
                        defaultSheetnames.Add(excelSheetWrap.ComObject.Name);
                    }
                }
            }

            // 新規シート作成
            Excel.Worksheet excelSheet = this.excelBook.ComObject.Worksheets.Add(After: excelBook.ComObject.ActiveSheet);
            excelSheet.Name = sheetname;

            // シート内の全セルの設定
            excelSheet.Cells.Font.Name = "Meiryo UI"; //フォント
            excelSheet.Cells.NumberFormat = "@"; //書式: 文字列
            excelSheet.Cells.VerticalAlignment = Excel.Constants.xlTop; //上下揃え: 上揃え

            // デフォルトで作成されたシートを削除
            if (!this.isCreatedSheet)
            {
                foreach (var name in defaultSheetnames)
                {
                    using (var excelSheetWrap = new ComWrapper<Excel.Worksheet>(this.excelBook.ComObject.Worksheets[name]))
                    {
                        excelSheetWrap.ComObject.Delete();
                    }
                }
                this.isCreatedSheet = true;
            }

            return new ComWrapper<Excel.Worksheet>(excelSheet);
        }

        public void Save()
        {
            if (this.excelBook != null)
            {
                this.excelBook.ComObject.Save();
            }
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!this.disposedValue)
            {
                if (disposing)
                {
                    // TODO: マネージド状態を破棄します (マネージド オブジェクト)
                }

                if (this.excelBook != null)
                {
                    this.excelBook.ComObject.Save();
                    this.excelBook.Dispose();
                    this.excelBook = null;
                }
                if (this.excelBooks != null)
                {
                    this.excelBooks.Dispose();
                    this.excelBooks = null;
                }
                if (this.excelApp != null)
                {
                    this.excelApp.ComObject.Quit();
                    this.excelApp.Dispose();
                    this.excelApp = null;
                }
                this.disposedValue = true;
            }
        }

        ~ExcelWrapper()
        {
            // このコードを変更しないでください。クリーンアップ コードを 'Dispose(bool disposing)' メソッドに記述します
            this.Dispose(disposing: false);
        }

        public void Dispose()
        {
            // このコードを変更しないでください。クリーンアップ コードを 'Dispose(bool disposing)' メソッドに記述します
            this.Dispose(disposing: true);
            GC.SuppressFinalize(this);
        }
    }
}
