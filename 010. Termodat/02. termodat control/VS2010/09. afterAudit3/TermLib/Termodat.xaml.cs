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

        private void buttonRun_Click(object sender, RoutedEventArgs e)
        {
            Control control = (Control)sender;

            buttonRun.Visibility = Visibility.Collapsed;
            buttonAbort.Visibility = Visibility.Visible;

            IEnumerable<XmlNode> collection = (IEnumerable<XmlNode>)control.DataContext;

            XmlNode nodeOrder = null;
            XmlNode nodeTitle = null;

            // узел Command
            foreach (var item in collection)
            {
                nodeOrder = item; break;
            }

            // получение значения атрибута @title тега Item, выбранного в ComboBox
            //string title = this.comboBoxCommand.SelectedValue.ToString();

            string key = nodeOrder.SelectSingleNode("...").Value;

            // изменение атрибута @order тега Command 
            for (int i = 0; i < nodeOrder.Attributes.Count; i++)
            {
                if (nodeOrder.Attributes[i].Name == "order") nodeOrder.Attributes[i].Value = key;
            }

            //control.DataContext = nodeOrder;
        }

        private void buttonAbort_Click(object sender, RoutedEventArgs e)
        {
            Control control = (Control)sender;

            buttonAbort.Visibility = Visibility.Collapsed;
            buttonRun.Visibility = Visibility.Visible;

            IEnumerable<XmlNode> collection = (IEnumerable<XmlNode>)control.DataContext;

            XmlNode nodeOrder = null;
            XmlNode nodeTitle = null;

            // узел Command
            foreach (var item in collection)
            {
                nodeOrder = item; break;
            }

            // получение значения атрибута @title тега Item, выбранного в ComboBox
            //string title = CBCommands.SelectedValue.ToString();

            // изменение атрибута @order тега Command
            for (int i = 0; i < nodeOrder.Attributes.Count; i++)
            {
                if (nodeOrder.Attributes[i].Name == "order") nodeOrder.Attributes[i].Value = string.Empty;
            }

            control.DataContext = nodeOrder;
        }

        private void button_Click(object sender, RoutedEventArgs e)
        {
            Control control = (Control)sender;
            switch (control.Name)
            {
                case "buttonRun":
                    break;
                case "buttonAbort":
                    break;
            }
        }
    }
}
