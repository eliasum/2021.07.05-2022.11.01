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

        }

        private void ComboBoxItem_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {

        }

        private void cBCommands_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {/*
            if (cBCommands.SelectedIndex == 0) gBholding.Visibility = Visibility.Visible;
            else gBholding.Visibility = Visibility.Hidden;

            if (cBCommands.SelectedIndex == 2) gBHeating.Visibility = Visibility.Visible;
            else gBHeating.Visibility = Visibility.Hidden;

            if (cBCommands.SelectedIndex == 1)
            {
                gBholding.Visibility = Visibility.Hidden;
                gBHeating.Visibility = Visibility.Hidden;
            }*/
        }
    }
}
