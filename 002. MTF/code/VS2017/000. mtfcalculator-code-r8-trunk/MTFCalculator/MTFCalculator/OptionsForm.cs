using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace MTFCalculator
{
    public partial class OptionsForm : Form
    {
        public PropertyGrid PropertyGrid
        {
            get
            {
                return propertyGrid;
            }
        }

        public OptionsForm()
        {
            InitializeComponent();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (e.CloseReason == CloseReason.UserClosing)
            {
                e.Cancel = true;

                Hide();
            }
            else
            {
                base.OnFormClosing(e);
            }
        }
    }
}
