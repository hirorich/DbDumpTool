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

namespace ToolSample
{
    public partial class Form1 : Form
    {
        private Logger logger;

        public Form1()
        {
            InitializeComponent();
            this.logger = new Logger(this.GetType());
        }

        private void button1_Click(object sender, EventArgs e)
        {
            var excelSample = new ExcelSample();
            excelSample.Sample();
            this.logger.Info("finish: excelSample.Sample");
        }
    }
}
