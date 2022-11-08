using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

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
    }
}
