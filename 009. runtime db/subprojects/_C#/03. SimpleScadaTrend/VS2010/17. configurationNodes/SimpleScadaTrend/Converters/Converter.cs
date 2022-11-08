using System;
using System.Xml;
using System.Windows;
using System.Windows.Media;
using System.Windows.Data;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;

namespace SimpleScadaTrend.Converters
{
    public class TitleMultiConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length == 2 && values[0] is string && values[1] is XmlElement)
            {
                XmlNode node = (XmlNode)values[1];
                string key = node.Attributes["key"].Value.Trim(new char[] { '{', '}' });
                if (!string.IsNullOrEmpty(key))
                {
                    node = node.SelectSingleNode("../../../../*");
                    if (node != null && node.ParentNode != null)
                    {
                        node = node.ParentNode.SelectSingleNode(key.Trim(new char[] { '.', '/' }));
                        if (node != null)
                        {
                            string buffer = node.Value;
                            node = ((XmlAttribute)node).OwnerElement;
                            foreach (var item in key.Split(new string[] { "../" }, StringSplitOptions.None))
                            {
                                if (node.ParentNode != null && item == string.Empty)
                                {
                                    node = node.ParentNode;
                                    if (node.Attributes["title"] != null &&
                                        node.Attributes["key"] != null)
                                        buffer = string.Concat(node.Attributes["title"].Value,
                                            ": ", buffer);
                                }
                                else break;
                            }
                            return buffer;
                        }
                    }
                }
                return string.Empty;
            }
            return string.Empty;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotSupportedException();
        }
    }
}
