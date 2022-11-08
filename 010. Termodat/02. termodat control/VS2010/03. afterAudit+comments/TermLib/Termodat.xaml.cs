using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace TermLib
{
    /// <summary>
    /// Логика взаимодействия для Termodat.xaml
    /// </summary>
    public partial class Termodat : UserControl
    {
        public Termodat()
        {
            InitializeComponent();
        }

        private void UserControl_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            /*
                Проверка правильного контекста данных для ПЭУ. Аргумент e - контрольное значение.
                Новое значение - 1 элемент <Item key="_Termodat" title="Termodat" description="Электронный модуль: Termodat">
            */
        }
    }
}
