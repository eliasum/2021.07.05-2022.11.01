using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace ASCII_to_hex
{
    /// <summary>
    /// Логика взаимодействия для MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void textBox1_TextChanged(object sender, TextChangedEventArgs e)
        {
            string str = textBox1.Text;
            char[] charValues = str.ToCharArray();
            string hexOutput = "";

            foreach (char _eachChar in charValues)
            {
                int value = Convert.ToInt32(_eachChar);

                hexOutput += String.Format("{0:X}", value);

                hexOutput += " ";
            }

            hexOutput += "0D 0A";

            textBox2.Text = hexOutput;

        }
    }
}
