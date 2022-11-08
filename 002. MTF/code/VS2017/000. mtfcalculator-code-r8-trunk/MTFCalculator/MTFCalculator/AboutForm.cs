using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace MTFCalculator
{
    public partial class AboutForm : Form
    {
        public AboutForm()
        {
            InitializeComponent();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            StringFormat format = new StringFormat();

            format.LineAlignment = StringAlignment.Center;
            format.Alignment     = StringAlignment.Center;

            string version = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version.ToString();

            e.Graphics.DrawString(Resource.AboutText + "\n\n Version " + version, new Font("Helvetica", 10), Brushes.Black,
                new RectangleF(60, 0, Width - 120, Height - 60), format);
        }
    }
}
