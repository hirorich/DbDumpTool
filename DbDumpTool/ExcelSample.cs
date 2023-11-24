using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Excel = Microsoft.Office.Interop.Excel;
using ToolCommon;
using Microsoft.Office.Interop.Excel;
using System.Drawing;
using System.Reflection;

namespace DbDumpTool
{
    internal class ExcelSample
    {
        private const int MAX_COLUMN_WIDTH = 100; //最大列幅

        private Logger logger;

        public ExcelSample()
        {
            this.logger = new Logger(this.GetType());
        }

        public void Sample()
        {
            using (var excelApp = new ExcelWrapper("TEST.xlsx"))
            {
                using (var excelSheetWrap = excelApp.AddSheet("Sample"))
                {
                    this.CreateSampleSheet(excelSheetWrap.ComObject);
                }
                excelApp.Save();

                using (var excelSheetWrap = excelApp.AddSheet("Reader"))
                {
                    var reader = SampleReaderCreater.Create();
                    this.CreateReaderSheet(excelSheetWrap.ComObject, reader);
                }
                excelApp.Save();
            }
        }

        private void CreateSampleSheet(Excel.Worksheet sheet)
        {
            // 値設定(正常(null以外))
            string value = "Value";
            Excel.Range cells = sheet.Cells[2, 1]; //セル: A2
            cells.Value = value;

            // 値設定(正常(null))
            cells = sheet.Cells[2, 2]; //セル: B2
            cells.Value = "null";
            cells.Interior.Color = Color.FromArgb(255, 255, 0); //背景色: #FFFF00

            // 値設定(異常)
            cells = sheet.Cells[2, 3]; //セル: C2
            cells.Value = "error";
            cells.Interior.Color = Color.FromArgb(255, 0, 0); //背景色: #FF0000
            cells.Font.Color = Color.FromArgb(255, 255, 255); //文字色: #FFFFFF

            // テーブル
            Excel.Range table = sheet.Range[sheet.Cells[1, 1], sheet.Cells[2, 3]]; //セル: A1:C2
            Excel.Borders borders = table.Borders; //罫線: すべて
            borders.LineStyle = Excel.XlLineStyle.xlContinuous; //枠線: 実線
            borders.Color = Color.FromArgb(0, 0, 0); //枠線色: #000000
            //border.Weight = 2d; // 枠線幅
            table.WrapText = true; //折り返して全体を表示

            // テーブルヘッダー
            Excel.Range header = sheet.Range[sheet.Cells[1, 1], sheet.Cells[1, 3]]; //セル: A1:C1
            sheet.Cells[1, 1].Value = "正常(null以外)";
            sheet.Cells[1, 2].Value = "正常(null)";
            sheet.Cells[1, 3].Value = "異常";
            header.Cells.Interior.Color = Color.FromArgb(31, 78, 120); //背景色: #1F4E78
            header.Cells.Font.Color = Color.FromArgb(255, 255, 255); //文字色: #FFFFFF
            Excel.Border border = header.Borders[Excel.XlBordersIndex.xlInsideVertical]; //罫線: 垂直罫線
            border.Color = Color.FromArgb(255, 255, 255); //枠線色: #FFFFFF

            // ウィンドウ枠の固定
            sheet.Cells[2, 1].Select();
            var activeWindow = sheet.Application.ActiveWindow;
            activeWindow.FreezePanes = true;

            // 幅調整
            table.ColumnWidth = 100; //最大列幅指定: 100pt
            table.Columns.AutoFit(); //列幅の自動調整
            foreach (Excel.Range item in header)
            {
                //最大列幅超過列に最大列幅指定
                if (item.ColumnWidth > 100)
                {
                    item.ColumnWidth = 100;
                }
            }
            table.Rows.AutoFit(); //行幅の自動調整
        }

        private void CreateReaderSheet(Excel.Worksheet sheet, DbDataReader reader)
        {
            for (int ColNum = 1; ColNum <= reader.FieldCount; ColNum++)
            {
                sheet.Cells[1, ColNum].Value = reader.GetName(ColNum - 1);
            }

            int RowNum = 1;
            while (reader.Read())
            {
                RowNum++;
                for (int ColNum = 1; ColNum <= reader.FieldCount; ColNum++)
                {
                    string value = null;
                    if (GetValue(ref value, reader, ColNum - 1))
                    {
                        if (value == null)
                        {
                            InputNull(sheet, RowNum, ColNum);
                        }
                        else
                        {
                            Input(sheet, RowNum, ColNum, value);
                        }
                    }
                    else
                    {
                        InputError(sheet, RowNum, ColNum);
                    }
                }
            }

            DecorateSheet(sheet, RowNum, reader.FieldCount);
        }

        private bool GetValue(ref string value, DbDataReader reader, int index)
        {
            value = null;
            if (reader.IsDBNull(index))
            {
                return true;
            }
            else
            {
                try
                {
                    value = reader.GetValue(index).ToString();
                    return true;
                }
                catch (Exception e)
                {
                    this.logger.Exception(e);
                    return false;
                }
            }
        }

        private void Input(Excel.Worksheet sheet, int RowNum, int ColNum, string value)
        {
            Excel.Range cell = sheet.Cells[RowNum, ColNum];
            cell.Value = value;
        }

        private void InputNull(Excel.Worksheet sheet, int RowNum, int ColNum)
        {
            Excel.Range cell = sheet.Cells[RowNum, ColNum];
            cell.Value = "null";
            cell.Interior.Color = Color.FromArgb(255, 255, 0); //背景色: #FFFF00
        }

        private void InputError(Excel.Worksheet sheet, int RowNum, int ColNum)
        {
            Excel.Range cell = sheet.Cells[RowNum, ColNum];
            cell.Value = "error";
            cell.Interior.Color = Color.FromArgb(255, 0, 0); //背景色: #FF0000
            cell.Font.Color = Color.FromArgb(255, 255, 255); //文字色: #FFFFFF
        }

        private void DecorateSheet(Excel.Worksheet sheet, int RowNum, int ColNum)
        {
            // テーブル
            Excel.Range table = sheet.Range[sheet.Cells[1, 1], sheet.Cells[RowNum, ColNum]];
            Excel.Borders borders = table.Borders; //罫線: すべて
            borders.LineStyle = Excel.XlLineStyle.xlContinuous; //枠線: 実線
            borders.Color = Color.FromArgb(0, 0, 0); //枠線色: #000000
            //border.Weight = 2d; // 枠線幅
            table.WrapText = true; //折り返して全体を表示

            // テーブルヘッダー
            Excel.Range header = sheet.Range[sheet.Cells[1, 1], sheet.Cells[1, ColNum]];
            header.Cells.Interior.Color = Color.FromArgb(31, 78, 120); //背景色: #1F4E78
            header.Cells.Font.Color = Color.FromArgb(255, 255, 255); //文字色: #FFFFFF
            Excel.Border border = header.Borders[Excel.XlBordersIndex.xlInsideVertical]; //罫線: 垂直罫線
            border.Color = Color.FromArgb(255, 255, 255); //枠線色: #FFFFFF

            // ウィンドウ枠の固定
            sheet.Cells[2, 1].Select();
            var activeWindow = sheet.Application.ActiveWindow;
            activeWindow.FreezePanes = true;

            // 幅調整
            table.ColumnWidth = MAX_COLUMN_WIDTH; //最大列幅指定
            table.Columns.AutoFit(); //列幅の自動調整
            foreach (Excel.Range item in header)
            {
                //最大列幅超過列に最大列幅指定
                if (item.ColumnWidth > MAX_COLUMN_WIDTH)
                {
                    item.ColumnWidth = MAX_COLUMN_WIDTH;
                }
            }
            table.Rows.AutoFit(); //行幅の自動調整
        }
    }
}
