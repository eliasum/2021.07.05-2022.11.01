using System;
using System.Collections;
using System.Collections.Generic;
using System.Xml;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.IO;

namespace usingTerm
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

        private void Window_Closed(object sender, EventArgs e)
        {
            IEnumerable<XmlNode> collection1 = this.Termodat1.DataContext as IEnumerable<XmlNode>;
            string file = Path.Combine(
                Environment.CurrentDirectory, "_036CE061.Communicator.xml");
            collection1.First<XmlNode>().OwnerDocument.Save(file);
        }
    }
}
