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
using System.Windows.Shapes;

namespace _MTF.Viewer.Source
{
    /// <summary>
    /// Логика взаимодействия для OptionsWindow.xaml
    /// </summary>
    public partial class OptionsWindow : Window
    {
        public event EventHandler<CustomEventArgs> RaiseCustomEvent;
        static double opticalSize = 8.47;

        public OptionsWindow()
        {
            InitializeComponent();
        }

        private void OpticalSizeB_Click(object sender, RoutedEventArgs e)
        {
            RaiseCustomEvent(this, new CustomEventArgs(OpticalSizeTB.Text));
            opticalSize = Convert.ToDouble(OpticalSizeTB.Text);
            this.Close();
        }

        public class CustomEventArgs : EventArgs
        {
            public CustomEventArgs(string s)
            {
                msg = s;
            }
            private string msg;
            public string Message
            {
                get { return msg; }
            }
        }

        private void OpticalSizeTB_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            if (!(Char.IsDigit(e.Text, 0) || (e.Text == ",")
            && (!OpticalSizeTB.Text.Contains(",")
            && OpticalSizeTB.Text.Length != 0)))
            {
                e.Handled = true;
            }
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            OpticalSizeTB.Text = Convert.ToString(opticalSize);
        }
    }
}
