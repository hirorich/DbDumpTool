using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using ToolCommon;

namespace DbDumpTool
{
    public partial class Form1 : Form
    {
        private Logger logger;

        public Form1()
        {
            InitializeComponent();
            this.logger = new Logger(this.GetType());
        }

        private void ExcelSample_Click(object sender, EventArgs e)
        {
            this.logger.Info("ExcelSample: Start");
            var sample = new ExcelSample();
            sample.Sample();
            this.logger.Info("ExcelSample: End");
        }
    }
}
