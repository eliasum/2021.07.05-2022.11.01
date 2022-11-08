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

namespace TermApp
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

        // по закрытию окна
        private void Window_Closed(object sender, EventArgs e)
        {/*
            // записать контекст данных (TermApp\MainWindow.xaml) в коллекцию
            IEnumerable<XmlNode> collection1 = this.Termodat1.DataContext as IEnumerable<XmlNode>;

            // файл на 2 директории выше текущей
            string file = Path.Combine(
                Environment.CurrentDirectory, "..\\..\\_036CE061.Communicator.xml");

            // записать коллекцию в файл на 2 директории выше текущей
            collection1.First<XmlNode>().OwnerDocument.Save(file);*/
        }
    }
}
