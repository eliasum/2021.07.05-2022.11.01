namespace GridItemsControlLib.Converters
{
    using System;
    using System.Xml;
    using System.Windows;
    using System.Windows.Data;
    using System.Globalization;

    public class KeyMultiConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length == 2 && values[0] is string && values[1] is XmlNode)
            {
                string xpath = (string)values[0];
                XmlNode node = ((XmlNode)values[1]).ParentNode;
                while (node != null)
                    if (node.SelectSingleNode(xpath) == null) node = node.ParentNode;
                    else return node.SelectSingleNode(xpath).Value;
            }
            return null;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotSupportedException();
        }
    }
}
