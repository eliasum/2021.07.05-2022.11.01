namespace TermLib.Converter
{
    using System;
    using System.Xml;
    using System.Windows;
    using System.Windows.Data;
    using System.Globalization;

    /*
        Конвертер значений должен реализовать интерфейс System.Windows.Data.IValueConverter. 
        Этот интерфейс определяет два метода: Convert(), который преобразует пришедшее от 
        привязки значение в тот тип, который понимается приемником привязки, и ConvertBack(), 
        который выполняет противоположную операцию.

        Оба метода принимают четыре параметра:

            object value: значение, которое надо преобразовать

            Type targetType: тип, к которому надо преобразовать значение value

            object parameter: вспомогательный параметр

            CultureInfo culture: текущая культура приложения
    */

    // прямое преобразование Command/@select -> Item[@key]/@title
    public class SelectedItemConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter,
            CultureInfo culture)
        {
            /*
            если значение, которое надо преобразовать, это xml атрибут
            ( {Attribute, Name="select", Value="0003"} )
            Атрибут @select в теге Command имеет значение по умолчанию '0003' (в файле xml)
            */
            if (value is XmlAttribute)
            {
                // присваиваем переменной attribute значение атрибута @select тега Command
                XmlAttribute attribute = (XmlAttribute)value;

                /*
                (XmlNode)attribute.OwnerElement - узел, в котором находится атрибут @select, т.е. тег Command

                возврат первого дочернего для Command узла по выражению "Item[@key=0003]/@title", т.е.
                атрибута @title в теге Item со значением атрибута @key, равным Value="0003":
                {Attribute, Name="title", Value="Общий Стоп"}
                */
                return ((XmlNode)attribute.OwnerElement).SelectSingleNode(string.Format("Item[@key='{0}']/@title", attribute.Value));
            }
            return Binding.DoNothing;
        }


        // обратное преобразование Item[@key]/@title -> Command/@select
        public object ConvertBack(object value, Type targetType, object parameter,
            CultureInfo culture)
        {
            /*
            если значение, которое надо преобразовать, это xml атрибут
            ( {Attribute, Name="title", Value="Выдержка"} )
            */
            if (value is XmlAttribute)
            {
                // присваиваем переменной attribute значение атрибута @title тега Command/Item/@title="Выдержка"
                XmlAttribute attribute = (XmlAttribute)value;

                /*
                (XmlNode)attribute.OwnerElement - узел, в котором находится атрибут @title, т.е. Item

                записать в переменную key атрибут @key тега 'Item со значением атрибута @title из атрибута
                attribute' {Attribute, Name="key", Value="0001"}
                */
                XmlNode key = ((XmlNode)attribute.OwnerElement).SelectSingleNode("@key");

                /*
                записать в переменную node узел, родительский для тега 'Item со значением атрибута 
                @key из атрибута key', т.е. тег Command ({Element, Name="Command"})
                */
                XmlNode node = (XmlNode)(((XmlAttribute)key).OwnerElement).ParentNode;

                /*
                присвоить атрибуту @select тега Command значение атрибута @key выбранного Item из 
                Combobox вместо предыдущего значения @select ("0001")
                */
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