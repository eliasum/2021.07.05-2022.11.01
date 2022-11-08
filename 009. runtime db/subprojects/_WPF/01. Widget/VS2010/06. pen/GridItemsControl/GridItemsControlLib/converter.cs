namespace GridItemsControlLib.Converters
{
    using System;
    using System.Xml;
    using System.Windows;
    using System.Windows.Media;
    using System.Windows.Data;
    using System.Globalization;
    using System.Linq;

    public class KeyMultiConverter : IMultiValueConverter
    {
        /*
            На вход конвертера поступает 2 интересующих параметра:
            values[1] - элемент Item {Element, Name="Item"}
            values[0] - значение его атрибута @key = "Item[@key='photocathode']/Voltage/@title"
        */
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length == 2 && values[0] is string && values[1] is XmlNode)
            {
                /*
                    1й параметр используется для вычисления родительских узлов текущего атрибута Item, 
                    удовлетворяющих условию наличия атрибутов @key и @title, а так же для вычисления 
                    самого ближнего родительского узла при первой итерации - Pen
                */
                XmlNode node = ((XmlNode)values[1]).ParentNode;             //[System.Xml.XmlElement] = {Element, Name="Pen"} 

                // 2й параметр - значение атрибута @key текущего узла Item
                string xpath = (string)values[0];                           //"Item[@key='photocathode']/Amperage/@title" 

                // строка для записи значений атрибута @title всех предков с атрибутами @key и @title через ": " - названия пера
                string ancestorsPath  = null;

                /*
                    1й цикл while используется для вычисления первой части строки названия текущего пера - последовательности 
                    атрибутов @title через ":", например, "АРМ: СУБД: Установка {@key}: Поз.№ {@key}: ", пока имя текущего узла
                    не равно "Configuration" - корневому узлу xml документа
                */
                while (node.Name != "Configuration")
                {
                    // если текущий узел имеет родителя
                    if (node.ParentNode != null)
                    {
                        // переходим на родителя текущего узла 
                        node = node.ParentNode;
                        // если текущий узел имеет атрибуты @key и @title
                        if(node.SelectSingleNode("@key") != null && node.SelectSingleNode("@title") != null)
                            /*
                                записать в строку ancestorsPath значение атрибута @title и ": " впереди 
                                предыдущего значения ancestorsPath
                            */
                            ancestorsPath = node.SelectSingleNode("@title").Value + ": " + ancestorsPath;
                    }
                }

                /*
                    Восстановление первоначального значения переменной node - самого ближнего родительского 
                    узла при первой итерации - Pen
                */
                node = ((XmlNode)values[1]).ParentNode;

                /*
                    2й цикл while используется для вычисления второй части строки названия текущего пера - значения 
                    атрибута @title, указанного во 2м входном параметре - значении атрибута @key текущего узла Item, 
                    который находится в переменной xpath, например, "Ток", пока первый выбранный узел не будет иметь 
                    путь, указанный в переменной xpath, будем перемещаться к родительскому узлу.
                    Тогда полная строка текущего пера, например, - "АРМ: СУБД: Установка {@key}: Поз.№ {@key}: Ток"
                */
                while (node != null)
                    /*
                        если первый выбранный узел не находится по пути xpath, тогда перемещаемся на родительский узел
                    */
                    if (node.SelectSingleNode(xpath) == null) node = node.ParentNode;

                    /*
                        иначе возвращаем полное значение строки названия текущего пера, где node.SelectSingleNode(xpath).Value - 
                        значение первого выбранного узла ("Item[@key='photocathode']/Amperage/@title") по пути из переменной
                        xpath, т.е. "Ток"
                    */
                    else
                    {
                        string str = ancestorsPath + node.SelectSingleNode(xpath).Value; // "АРМ: СУБД: Установка {@key}: Поз.№ {@key}: Ток"
                        return str;
                    }
            }
            return null;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotSupportedException();
        }
    }
}
