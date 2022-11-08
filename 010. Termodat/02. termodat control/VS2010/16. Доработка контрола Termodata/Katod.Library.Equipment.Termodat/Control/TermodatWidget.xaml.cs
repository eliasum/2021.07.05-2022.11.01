namespace Katod.Library.Control
{
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

    public partial class TermodatWidget : UserControl
    {
        public TermodatWidget() { InitializeComponent(); }


        private void button_Click(object sender, RoutedEventArgs e)
        {
            Control control = (Control)sender;
            switch (control.Name)
            {
                case "buttonRun":

                    buttonRun.Visibility = Visibility.Collapsed;
                    buttonAbort.Visibility = Visibility.Visible;

                    IEnumerable<XmlNode> collection = (IEnumerable<XmlNode>)control.DataContext;

                    XmlNode nodeOrderRun = null;
                    XmlNode nodeTitle = null;

                    // узел Command
                    foreach (var item in collection)
                    {
                        nodeOrderRun = item; break;
                    }

                    // получение значения атрибута @title тега Item, выбранного в ComboBox
                    string title = this.comboBoxCommand.SelectedValue.ToString();

                    // получение атрибута @title тега Item, выбранного в ComboBox
                    nodeTitle = nodeOrderRun.SelectSingleNode(string.Format("//Item[@title='{0}']/@key", title));

                    // изменение атрибута @order тега Command 
                    for (int i = 0; i < nodeOrderRun.Attributes.Count; i++)
                    {
                        if (nodeOrderRun.Attributes[i].Name == "order") nodeOrderRun.Attributes[i].Value = nodeTitle.Value;
                    }

                    break;

                case "buttonAbort":

                    buttonAbort.Visibility = Visibility.Collapsed;
                    buttonRun.Visibility = Visibility.Visible;

                    IEnumerable<XmlNode> collection1 = (IEnumerable<XmlNode>)control.DataContext;

                    XmlNode nodeOrderAbort = null;

                    // узел Command
                    foreach (var item in collection1)
                    {
                        nodeOrderAbort = item; break;
                    }

                    // изменение атрибута @order тега Command 
                    for (int i = 0; i < nodeOrderAbort.Attributes.Count; i++)
                    {
                        if (nodeOrderAbort.Attributes[i].Name == "order") nodeOrderAbort.Attributes[i].Value = string.Empty;
                    }

                    break;
            }
        }

        private void UserControl_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {

        }
    }
}
