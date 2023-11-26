using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DbType = System.Data.DbType;

namespace DbDumpTool
{
    internal class DbSample
    {
        void Sample(DbConnection connection)
        {
            var creater = new DbCommandCreater(connection);
            var parameters = new List<string>();
            parameters.Add("param");
            var keys = new List<string>();
            parameters.Add("key");
            var command = creater.CreateCommand<string>("TABLE_NAME", "COLUMN_NAME", DbType.String, parameters, keys);
            using (command)
            {
                var reader = command.ExecuteReader();
            }
        }
    }
}
