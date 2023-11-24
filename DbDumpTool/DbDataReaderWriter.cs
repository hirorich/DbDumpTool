using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Excel = Microsoft.Office.Interop.Excel;
using ToolCommon;

namespace DbDumpTool
{
    internal class DbDataReaderWriter
    {
        private const int MAX_COLUMN_WIDTH = 100; //最大列幅
        private static DbDataReaderWriter instance;

        private Logger logger;

        private DbDataReaderWriter()
        {
            this.logger = new Logger(this.GetType());
        }

        public static DbDataReaderWriter GetInstance()
        {
            if (instance == null)
            {
                instance = new DbDataReaderWriter();
            }
            return instance;
        }

        public void Write(Excel.Worksheet sheet, DbDataReader reader)
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
