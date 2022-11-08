using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Xml;

namespace DefectCheckControlLibrary
{
    /// <summary>
    /// Логика взаимодействия для DefectCheckControl.xaml
    /// </summary>
    public partial class DefectCheckControl : UserControl
    {
        public DefectCheckControl()
        {
            InitializeComponent();
        }

        private void Header_DataContextChanged(object sender,
            DependencyPropertyChangedEventArgs e)
        {
            if (e.OldValue == null)
                ((TextBlock)sender).DataContext = this.DataContext;
        }

        private void CheckComboBox_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            Xceed.Wpf.Toolkit.CheckComboBox control =
                (Xceed.Wpf.Toolkit.CheckComboBox)sender;

            if (e.OldValue == null)
            {
                control.DataContext = this.DataContext;
            }
        }

        private void TextBox_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {

        }

        private void ComboBox_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {

        }

        private void ComboBox_DataContextChanged_1(object sender, DependencyPropertyChangedEventArgs e)
        {

        }
    }

    class XmlAttributeConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is IEnumerable<XmlNode>)
            {
                IEnumerable<XmlNode> values = (IEnumerable<XmlNode>)value;
                return values.OfType<XmlAttribute>().Select(xa => xa.Value);
            }
            else
                return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BoolInverterConverter : IValueConverter
    {
        #region IValueConverter Members

        public object Convert(object value, Type targetType, object parameter,
            System.Globalization.CultureInfo culture)
        {
            if (value is bool)
            {
                return !(bool)value;
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter,
            System.Globalization.CultureInfo culture)
        {
            if (value is bool)
            {
                return !(bool)value;
            }
            return value;
        }

        #endregion
    }
}
