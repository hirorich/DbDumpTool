using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Excel = Microsoft.Office.Interop.Excel;
using ToolCommon;

namespace DbDumpTool
{
    internal class ExcelSample
    {
        public void Sample()
        {
            using (var excelApp = new ExcelWrapper("TEST.xlsx"))
            {
                using (var excelSheetWrap = excelApp.AddSheet("TEST"))
                {
                }
                excelApp.Save();
            }
        }
    }
}
