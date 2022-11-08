using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Xml;

namespace DefectCheckControlLibrary
{
    /// <summary>
    /// Логика взаимодействия для DefectCheckControl.xaml
    /// </summary>
    public partial class DefectCheckControl : UserControl
    {
        // строка сохранения значения текста в Textbox
        string save = null;

        public DefectCheckControl()
        {
            InitializeComponent(); 
        }

        private void SnTB_Loaded(object sender, RoutedEventArgs e)
        {
            // не более 10 цифр в поле "№ УЛ"
            TextBox textBox = sender as TextBox;
            textBox.MaxLength = 10;
        }

        private void SnTB_KeyDown(object sender, System.Windows.Input.KeyEventArgs e)
        {
            TextBox textBox = sender as TextBox;

            // отмена ввода при нажатии клавиши Escape
            if (e.Key == Key.Escape)
            {
                textBox.Text = save;
            }
        }

        private void SnTB_PreviewMouseDown(object sender, MouseButtonEventArgs e)
        {
            TextBox textBox = sender as TextBox;

            // сохранить значение текста в Textbox
            save = textBox.Text;
        }

        private void SnTB_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            // ввод только цифр в поле "№ УЛ"
            if (!char.IsDigit(e.Text, 0))
            {
                e.Handled = true;
            }
        }

        private void InsideCB_Loaded(object sender, RoutedEventArgs e)
        {
            ToggleButton toggleButton = FindVisualChild<ToggleButton>((ComboBox)sender);

            if (toggleButton != null)
            {
                Path path = FindVisualChild<Path>(toggleButton);
                if (path != null)
                {
                    path.Width = 5;
                    path.Height = 5;
                    path.Fill = Brushes.Green;
                }
            }
        }

        private static T FindVisualChild<T>(Visual visual) where T : Visual
        {
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(visual); i++)
            {
                Visual child = (Visual)VisualTreeHelper.GetChild(visual, i);
                if (child != null)
                {
                    T correctlyTyped = child as T;
                    if (correctlyTyped != null)
                        return correctlyTyped;

                    T descendent = FindVisualChild<T>(child);
                    if (descendent != null)
                        return descendent;
                }
            }
            return null;
        }

        private void BasisCB_Loaded(object sender, RoutedEventArgs e)
        {
            ToggleButton toggleButton = FindVisualChild<ToggleButton>((ComboBox)sender);

            if (toggleButton != null)
            {
                Path path = FindVisualChild<Path>(toggleButton);
                if (path != null)
                {
                    path.Width = 15;
                    path.Height = 15;
                    path.Fill = Brushes.Red;
                }
            }
        }
    }
}
