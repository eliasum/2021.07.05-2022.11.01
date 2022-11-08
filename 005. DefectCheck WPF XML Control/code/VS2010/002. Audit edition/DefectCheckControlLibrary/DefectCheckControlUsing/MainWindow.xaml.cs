using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace DefectCheckControlUsing
{
    /// <summary>
    /// Логика взаимодействия для MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private string file = "config.xml";

        public MainWindow()
        {
            InitializeComponent();
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            XmlDataProvider provider = new XmlDataProvider();
            provider.Document = new System.Xml.XmlDocument();
            if(System.IO.File.Exists(file))
                provider.Document.Load(file);
        }

        private void Window_Closed(object sender, EventArgs e)
        {
           ((XmlDataProvider)this.DataContext).Document.Save(file);
        }


    }
}
