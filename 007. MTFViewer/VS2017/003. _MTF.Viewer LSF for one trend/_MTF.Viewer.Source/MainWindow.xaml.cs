namespace _MTF.Viewer
{
    using System;
    using System.Windows;
    using System.Windows.Input;
    using System.Windows.Media;
    using System.Windows.Shapes;
    using System.Windows.Navigation;
    using System.Collections.Generic;
    using System.Windows.Media.Imaging;
    using Microsoft.Win32;

    using Core = _AVM.Library.Core;
    using Custom = _AVM.Library.UIElement;

    public partial class MainWindow : Window
    {
        // список выбранных прямоугольных областей типа _AVM.Library.UIElement.Shape.Rectangle
        private List<Custom.Shape.Rectangle> select;

        public MainWindow() { InitializeComponent(); }

        /*
            Функция CanExecute возвращает true, если команда включена и доступна для
            использования, и false, если команда отключена:
            https://metanit.com/sharp/wpf/7.1.php
        */
        private void command_CanExecute(object sender, CanExecuteRoutedEventArgs e)
        {
            switch (((RoutedUICommand)e.Command).Text)
            {
                case "Open": e.CanExecute = true; break;
                case "Save": e.CanExecute = true; break;
                case "Exit": e.CanExecute = true; break;
                    // выполнение команды только если прямоугольные области выбраны
                case "Esf": if (this.select != null) e.CanExecute = true; break;
                case "Mtf": e.CanExecute = true; break;
                case "Lsf": e.CanExecute = true; break;
            }
        }

        /*
            Привязка команд представляет объект CommandBinding. Его событие Executed
            прикрепляет обработчик, который будет выполняться при вызове команды:
        */
        private void command_Executed(object sender, ExecutedRoutedEventArgs e)
        {
            switch (((RoutedUICommand)e.Command).Text)
            {
                case "Open":
                    {
                        OpenFileDialog dialog = new OpenFileDialog
                        {
                            DefaultExt = "bmp",
                            AddExtension = true,
                            Filter = "Файл изображения BITMAP-формата|*.bmp|Файл изображения JPEG-формата|*.jpg|Файл изображения TIFF-формата|*.tif|Файл изображения PNG-формата|*.png|Все файлы (*.*)|*.*"
                        };
                        if (dialog.ShowDialog().Value) this.viewer.FromFile(dialog.FileName);
                    }
                    break;
                case "Save":
                    {
                        SaveFileDialog dialog = new SaveFileDialog
                         {
                             FileName = "",
                             DefaultExt = "bmp",
                             AddExtension = true,
                             Filter = "Файл изображения BITMAP-формата|*.bmp|Файл изображения JPEG-формата|*.jpg|Файл изображения TIFF-формата|*.tif|Файл изображения PNG-формата|*.png|Все файлы (*.*)|*.*"
                         };
                        if (dialog.ShowDialog().Value)
                        {
                            BitmapEncoder encoder = null;
                            switch (System.IO.Path.GetExtension(dialog.FileName).ToLower())
                            {
                                case ".jpg": encoder = new JpegBitmapEncoder(); break;
                                case ".tif": encoder = new TiffBitmapEncoder(); break;
                                case ".png": encoder = new PngBitmapEncoder(); break;
                                default: encoder = new BmpBitmapEncoder(); break;
                            }
                            this.viewer.ToFile(dialog.FileName, encoder);
                        }
                    }
                    break;
                case "Exit": Application.Current.Shutdown(); break;

                // выполнение команды 'Chart.Esf' по нажатию кнопки "Добавить в тренд"
                case "Esf":
                    /*
                        перебор всех прямоугольников в списке выбранных прямоугольных 
                        областей типа _AVM.Library.UIElement.Shape.Rectangle
                    */
                    // TODO: раскомментировать foreach (Shape item in this.select)
                    {
                        // массив пикселей типа Image._8bit.Pixel[,]
                        Core.Image._8bit.Pixel[,] pixel;

                        /*
                            запись прямоугольника из списка выбранных прямоугольных областей типа 
                            _AVM.Library.UIElement.Shape.Rectangle в переменную rectangle 
                            этого же типа
                        */
                        Custom.Shape.Rectangle rectangle = (Custom.Shape.Rectangle)this.select[0];  // TODO: раскомментировать item; вместо select[0];

                        // преобразование rectangle в массив пикселей типа _AVM.Library.Core.Image._8bit.Pixel
                        this.viewer.ToBuffer(new Int32Rect((int)rectangle.Location.X,
                            (int)rectangle.Location.Y, (int)rectangle.Width, (int)rectangle.Height),
                            out pixel);

                        /*
                            1. добавление массива пикселей в экземпляр класса CustomChart
                            с именем chart_ESF
                        */
                        Command.Custom.Chart.Lsf.Execute(this.chart_ESF.AddPixels(pixel), null);
                        this.viewer.Remove(this.select[0]);   // TODO: раскомментировать item;
                    }
                    this.select = null;
                    break;
                case "Lsf":
                    Command.Custom.Chart.Mtf.Execute(this.chart_LSF.AddESFPoints(e.Parameter as Point[]), null);
                    break;
                case "Mtf":
                    //this.chart_MTF.Add(e.Parameter as Point[]);
                    break;
            }
        }

        /*
            обработка события PreviewMouseLeftButtonDown - Происходит при нажатии левой кнопки
            мыши в тот момент, когда указатель мыши находится над данным элементом.
        */
        private void viewer_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            Custom.ImageViewer control = (Custom.ImageViewer)sender;
            if (Keyboard.Modifiers == ModifierKeys.Control)
            {
                control.Cursor = Cursors.Cross;
                if (this.select == null) this.select = new List<Custom.Shape.Rectangle>();
                this.select.Add(new Custom.Shape.Rectangle("1", control.MousePosition, Colors.Red));
                control.Add(this.select[this.select.Count - 1]);
                control.CaptureMouse();
            }
        }

        /*
            обработка события PreviewMouseLeftButtonUp - Происходит при отпускании левой кнопки 
            мыши в тот момент, когда указатель мыши находится над данным элементом.
        */
        private void viewer_PreviewMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            Custom.ImageViewer control = (Custom.ImageViewer)sender;
            if (control.Cursor == Cursors.Cross && this.select != null)
            {
                Custom.Shape.Rectangle rectangle = this.select[this.select.Count - 1];
                rectangle.Width = Math.Abs(rectangle.Location.X - control.MousePosition.X);
                rectangle.Height = Math.Abs(rectangle.Location.Y - control.MousePosition.Y);
            }
            control.ReleaseMouseCapture();
        }

        /*
            обработка события PreviewMouseLeftButtonUp - Происходит, когда указатель мыши 
            перемещается над элементом.
        */
        private void viewer_PreviewMouseMove(object sender, MouseEventArgs e)
        {
            Custom.ImageViewer control = (Custom.ImageViewer)sender;
            if (control.Cursor == Cursors.Cross && this.select != null)
            {
                Custom.Shape.Rectangle rectangle = this.select[this.select.Count - 1];
                rectangle.Width = Math.Abs(rectangle.Location.X - control.MousePosition.X);
                rectangle.Height = Math.Abs(rectangle.Location.Y - control.MousePosition.Y);
            }
        }

        // обработка нажатия на пункт меню "Обновить", загрузка тестовой картинки
        private void MenuItem_Click(object sender, RoutedEventArgs e)
        {
            this.viewer.FromFile(System.IO.Path.Combine(System.IO.Path.GetDirectoryName(
                System.Reflection.Assembly.GetExecutingAssembly().Location), "test.jpg"));
        }
    }
}
