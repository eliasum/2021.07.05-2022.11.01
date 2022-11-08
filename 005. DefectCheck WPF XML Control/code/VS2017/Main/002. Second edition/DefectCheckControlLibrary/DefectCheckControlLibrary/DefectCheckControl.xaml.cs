/*
2021.08.20 17:17 IMM
*/

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

        /*
            FrameworkElement.DataContextChanged Событие - Происходит при изменении
            контекста данных для элемента. 

            FrameworkElement.DataContext Свойство - Получает или задает контекст 
            данных для элемента, участвующего в привязке данных.

            Таким образом, метод header_DataContextChanged() обрабатывает событие
            при изменении объекта текущих привязываемых данных для элемента колонки
            таблицы

            sender - это указатель на объект, вызвавший это событие, объект-источник события, 
            объект, который вызвал событие, запустившее обработчик события

            в данном случае System.Windows.Controls.TextBlock
        */
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

    // конвертер для CheckComboBox
    class XmlAttributeConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
          => value is IEnumerable<XmlNode> values
            ? values.OfType<XmlAttribute>().Select(xa => xa.Value)
            : value;

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
          => throw new NotImplementedException();
    }

    // конвертер для RadioButton
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
