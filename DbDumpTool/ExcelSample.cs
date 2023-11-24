﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Excel = Microsoft.Office.Interop.Excel;
using ToolCommon;
using Microsoft.Office.Interop.Excel;
using System.Drawing;

namespace DbDumpTool
{
    internal class ExcelSample
    {
        public void Sample()
        {
            using (var excelApp = new ExcelWrapper("TEST.xlsx"))
            {
                using (var excelSheetWrap = excelApp.AddSheet("Sample"))
                {
                    this.CreateSampleSheet(excelSheetWrap.ComObject);
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
    }
}