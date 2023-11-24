using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Excel = Microsoft.Office.Interop.Excel;
using ToolCommon;

namespace ToolSample
{
    internal class ExcelSample
    {
        public void Sample()
        {
            using (var excelAppWrap = new ComWrapper<Excel.Application>(new Excel.Application() { Visible = false, DisplayAlerts = false }))
            {
                var excelApp = excelAppWrap.ComObject;
                using (var excelBooksWrap = new ComWrapper<Excel.Workbooks>(excelApp.Workbooks))
                {
                    var excelBooks = excelBooksWrap.ComObject;
                    using (var excelBookWrap = new ComWrapper<Excel.Workbook>(excelBooks.Add()))
                    {
                        var excelBook = excelBookWrap.ComObject;

                        // デフォルトで作成されたシート名を取得
                        var defaultSheetnames = new List<string>();
                        foreach (Excel.Worksheet excelSheet in excelBook.Worksheets)
                        {
                            using (var excelSheetWrap = new ComWrapper<Excel.Worksheet>(excelSheet))
                            {
                                defaultSheetnames.Add(excelSheet.Name);
                            }
                        }

                        using (var excelSheetWrap = new ComWrapper<Excel.Worksheet>(excelBook.Worksheets.Add()))
                        {
                            var excelSheet = excelSheetWrap.ComObject;
                            excelSheet.Name = "TEST";
                        }

                        // デフォルトで作成されたシートを削除
                        foreach (var sheetname in defaultSheetnames)
                        {
                            using (var excelSheetWrap = new ComWrapper<Excel.Worksheet>(excelBook.Worksheets[sheetname]))
                            {
                                var excelSheet = excelSheetWrap.ComObject;
                                excelSheet.Delete();
                            }
                        }

                        // ファイルを保存
                        excelBook.SaveAs("TEST.xlsx");
                    }
                }
                excelApp.Quit();
            }
        }
    }
}
