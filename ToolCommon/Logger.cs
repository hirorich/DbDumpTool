using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ToolCommon
{
    public class Logger
    {
        public const string DEBUG = "DEBUG";
        public const string INFO = "INFO";
        public const string WARN = "WARN";
        public const string ERROR = "ERROR";
        public const string FATAL = "FATAL";

        private Type type;
        private LoggerImpl loggerImpl;

        public Logger(Type type)
        {
            this.type = type;
            this.loggerImpl = LoggerImpl.GetInstance();
        }

        public void Debug(string message)
        {
            this.Log(DEBUG, message);
        }

        public void Info(string message)
        {
            this.Log(INFO, message);
        }

        public void Warn(string message)
        {
            this.Log(WARN, message);
        }

        public void Error(string message)
        {
            this.Log(ERROR, message);
        }

        public void Exception(Exception exception)
        {
            this.Error(exception.ToString());
        }

        public void Fatal(string message)
        {
            this.Log(FATAL, message);
        }

        private void Log(string level, string message)
        {
            this.loggerImpl.Log(this.type, level, message);
        }

        private class LoggerImpl
        {
            private const string MESSAGE_FORMAT = "{0}[{1}][{2}] - {3}";
            private const string TIMSTAMP_FORMAT = "yyyy-MM-dd HH:mm:ss.fff";
            private const string DATE_FORMAT = "yyyyMMdd";

            private static LoggerImpl instance;

            private LoggerImpl() { }

            public static LoggerImpl GetInstance()
            {
                if (instance == null)
                {
                    instance = new LoggerImpl();
                }
                return instance;
            }

            public void Log(Type type, string level, string message)
            {
                string now = DateTime.Now.ToString(TIMSTAMP_FORMAT);
                string msg = String.Format(MESSAGE_FORMAT, now, level, type.FullName, message);
                Console.WriteLine(msg);
            }
        }
    }
}
