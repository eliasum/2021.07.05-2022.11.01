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

        private void header_DataContextChanged(object sender,
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
    }
    /*
    // https://www.cyberforum.ru/csharp-beginners/thread2866534.html
    class XmlAttributeConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value is IEnumerable<XmlNode>
                        ? (value as IEnumerable<XmlNode>).OfType<XmlAttribute>().Select(xa => xa.Value)
                        : value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        { throw new NotImplementedException(); }
    }
    */
    /*
    // https://qna.habr.com/answer?answer_id=2006668
    class XmlAttributeConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is IEnumerable<XmlNode>)
            {
                return ((IEnumerable<XmlNode>)value).OfType<XmlAttribute>().Select(xa => xa.Value);
            }

            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
    */

    // https://ru.stackoverflow.com/questions/1319667/%d0%9a%d0%b0%d0%ba-%d0%bf%d0%b5%d1%80%d0%b5%d0%bf%d0%b8%d1%81%d0%b0%d1%82%d1%8c-%d0%ba%d0%bb%d0%b0%d1%81%d1%81-%d0%b1%d0%b5%d0%b7-%d0%be%d0%bf%d0%b5%d1%80%d0%b0%d1%82%d0%be%d1%80%d0%be%d0%b2-%d0%b8
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
