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
using System.Xml;

namespace TermLib
{
    /// <summary>
    /// Логика взаимодействия для Termodat.xaml
    /// </summary>
    public partial class Termodat : UserControl
    {
        public Termodat()
        {
            InitializeComponent();
        }

        private void UserControl_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            /*
                Проверка правильного контекста данных для ПЭУ. Аргумент e - контрольное значение.
                Новое значение - 1 элемент <Item key="_Termodat" title="Termodat" description="Электронный модуль: Termodat">
            */
        }

        private void buttonRun_Click(object sender, RoutedEventArgs e)
        {
            buttonRun.Visibility = Visibility.Collapsed;
            buttonAbort.Visibility = Visibility.Visible;

            string title;

            XmlDocument xmlDoc = new XmlDocument();
            xmlDoc.Load("_036CE061.Communicator.xml");

            XmlNode node = xmlDoc.SelectSingleNode("//Item[@key='_Termodat']//Command/@order");

            title = CBCommands.SelectedValue.ToString();

            node.Value = xmlDoc.SelectSingleNode(string.Format("//Item[@key='_Termodat']//Command//Item[@title='{0}']/@key", title)).Value;

            xmlDoc.Save("_036CE061.Communicator.xml");
        }

        private void buttonAbort_Click(object sender, RoutedEventArgs e)
        {
            buttonAbort.Visibility = Visibility.Collapsed;
            buttonRun.Visibility = Visibility.Visible;

            XmlDocument xmlDoc = new XmlDocument();
            xmlDoc.Load("_036CE061.Communicator.xml");

            XmlNode node = xmlDoc.SelectSingleNode("//Item[@key='_Termodat']//Command/@order");
            node.Value = string.Empty;

            xmlDoc.Save("_036CE061.Communicator.xml");
        }
    }
}
