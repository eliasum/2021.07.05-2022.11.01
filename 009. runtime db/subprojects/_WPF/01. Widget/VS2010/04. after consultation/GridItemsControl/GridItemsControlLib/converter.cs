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
            /*
                values[0] = "Item[@key='anode']/Amperage/@title" 
                values[1] = {Element, Name="Pen"}
            */
            if (values.Length == 2 && values[0] is string && values[1] is XmlNode)
            {
                string xpath = (string)values[0];
                XmlNode node = ((XmlNode)values[1]).ParentNode;

                XmlNode itemNode;
                string itemChildXPath = xpath.Replace("/@title", "");
                string itemTitle = null;
                
                while (node != null)
                    /*
                        пока первый выбранный узел не будет иметь путь, указанный в переменной xpath,
                        будем перемещаться к родительскому узлу
                    */
                    if (node.SelectSingleNode(itemChildXPath) == null) node = node.ParentNode;
                    // иначе возвращаем значение первого выбранный узла, указанного в переменной xpath
                    else
                    {
                        itemNode = node.SelectSingleNode(itemChildXPath).ParentNode;
                        itemTitle = itemNode.SelectSingleNode("@title").Value;
                        break;
                    }

                node = ((XmlNode)values[1]).ParentNode;
                
                while (node != null)
                    /*
                        пока первый выбранный узел не будет иметь путь, указанный в переменной xpath,
                        будем перемещаться к родительскому узлу
                    */
                    if (node.SelectSingleNode(xpath) == null) node = node.ParentNode;
                    // иначе возвращаем значение первого выбранный узла, указанного в переменной xpath
                    else return itemTitle + ": " + node.SelectSingleNode(xpath).Value;
            }
            return null;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotSupportedException();
        }
    }
}
