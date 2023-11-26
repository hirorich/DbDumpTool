using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace DbDumpTool
{
    internal class DbCommandCreater
    {
        private DbConnection connection;

        public DbCommandCreater(DbConnection connection)
        {
            this.connection = connection;
        }

        public DbCommand CreateCommand<T>(string tableName, string columnName, DbType type, List<T> paramList, List<string> orderKeys)
        {
            var command = this.connection.CreateCommand();

            // パラメータリスト作成
            List<DbParameter> parameters = this.CreateParameterList<T>(command, type, paramList);
            foreach (DbParameter parameter in parameters)
            {
                command.Parameters.Add(parameter);
            }

            // コマンド作成
            command.CommandText = this.CreateCommandString(tableName, columnName, parameters, orderKeys);
            command.Prepare();

            return command;
        }

        private List<DbParameter> CreateParameterList<T>(DbCommand command, DbType type, List<T> paramList)
        {
            List<DbParameter> parameters = new List<DbParameter>();
            for (int i = 0; i < paramList.Count; i++)
            {
                var param = command.CreateParameter();
                param.ParameterName = String.Format(":param{0}", i);
                param.DbType = type;
                param.Value = paramList[i];
                parameters.Add(param);
            }
            return parameters;
        }

        private string CreateCommandString(string tableName, string columnName, List<DbParameter> parameters, List<string> orderKeys)
        {
            var builder = new StringBuilder();
            builder.Append(String.Format("SELECT * FROM {0} WHERE {1} in (", tableName, columnName));
            builder.Append(String.Join(", ", parameters.ConvertAll<String>(e => e.ParameterName)));
            builder.Append(")");

            if (orderKeys != null && orderKeys.Count > 0)
            {
                builder.Append(String.Format(" ORDER BY {0}", String.Join(", ", orderKeys)));
            }
            return builder.ToString();
        }
    }
}
