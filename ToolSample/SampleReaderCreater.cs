using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ToolSample
{
    internal class SampleReaderCreater
    {
        public static DbDataReader Create()
        {
            DataTable table = new DataTable();

            // カラム指定
            table.Columns.Add("StringCol", typeof(string));
            table.Columns.Add("IntCol", typeof(int));
            table.Columns.Add("DoubleCol", typeof(double));
            table.Columns.Add("FloatCol", typeof(float));
            table.Columns.Add("DecimalCol", typeof(decimal));
            table.Columns.Add("DateTimeCol", typeof(DateTime));
            table.Columns.Add("ObjectCol", typeof(Object));

            // 行追加
            var row = table.NewRow();
            row[0] = "1行目";
            row[1] = 123;
            row[2] = 45.6d;
            row[3] = 7.89f;
            row[4] = 10.3m;
            row[5] = DateTime.Now;
            row[6] = null;
            table.Rows.Add(row);

            // 行追加
            row = table.NewRow();
            row[0] = "2行目" + Environment.NewLine + "改行";
            row[1] = 456;
            row[2] = 78.9d;
            row[3] = 1.03f;
            row[4] = 12.3m;
            row[5] = DateTime.Now;
            row[6] = new SampleReaderCreater();
            table.Rows.Add(row);

            // リーダー作成
            var reader = table.CreateDataReader();
            return reader;
        }
    }
}
