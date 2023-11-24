using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace ToolCommon
{
    public class ComWrapper<T> : IDisposable
    {
        public T ComObject { get; }

        public ComWrapper(T comObject)
        {
            this.ComObject = comObject;
        }

        private bool disposedValue = false;

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    //nop
                }
                Marshal.ReleaseComObject(ComObject);
                disposedValue = true;
            }
        }

        ~ComWrapper()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
        }
    }
}
