namespace Katod.Library.Control.TermodatConverter
{
    using System;
    using System.Xml;
    using System.Windows;
    using System.Windows.Data;
    using System.Windows.Media;
    using System.Globalization;
    using System.Windows.Shapes;

    public class SelectedItemConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter,
            CultureInfo culture)
        {
            if (value is XmlAttribute)
            {
                XmlAttribute attribute = (XmlAttribute)value;

                return ((XmlNode)attribute.OwnerElement).SelectSingleNode(string.Format("Item[@key='{0}']/@title", attribute.Value));
            }
            return Binding.DoNothing;
        }

        public object ConvertBack(object value, Type targetType, object parameter,
            CultureInfo culture)
        {
            if (value is XmlAttribute)
            {
                XmlAttribute attribute = (XmlAttribute)value;

                XmlNode key = ((XmlNode)attribute.OwnerElement).SelectSingleNode("@key");

                XmlNode node = (XmlNode)(((XmlAttribute)key).OwnerElement).ParentNode;

                node.SelectSingleNode("@select").Value = key.Value;
                return node.Value;
            }
            
            return Binding.DoNothing;
        }
    }

    public class VisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter,
            CultureInfo culture)
        {
            return value is string && parameter is string ?
                (string)value == (string)parameter ? Visibility.Visible :
                    Visibility.Collapsed : Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter,
            CultureInfo culture)
        {
            throw new NotSupportedException();
        }
    }
}