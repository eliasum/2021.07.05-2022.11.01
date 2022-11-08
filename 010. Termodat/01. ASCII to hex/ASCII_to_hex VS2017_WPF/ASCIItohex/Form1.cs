using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ASCIItohex
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            string str = textBox1.Text;
            char[] charValues = str.ToCharArray();
            string hexOutput = "";

            foreach (char _eachChar in charValues)
            {

                int value = Convert.ToInt32(_eachChar);

                hexOutput += String.Format("{0:X}", value);

                hexOutput +=" ";
            }

            textBox2.Text = hexOutput;
        }
    }
}
