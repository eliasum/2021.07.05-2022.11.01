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
    using System.Windows.Controls;

    using Core = _AVM.Library.Core;
    using Custom = _AVM.Library.UIElement;
    using _MTF.Viewer.Source;
    using System.Runtime.InteropServices;

    public partial class MainWindow : Window
    {
        private List<Custom.Shape.Rectangle> select;
        Custom.ImageViewer control = null;
        double opticalSize = 8.47;

        public MainWindow() { 
            InitializeComponent();
            var x = Add(25, 17);
            MessageBox.Show(x.ToString());
        }

        [DllImport("SFRLib.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern double Add(double a, double b);

        private void command_CanExecute(object sender, CanExecuteRoutedEventArgs e)
        {
            switch (((RoutedUICommand)e.Command).Text)
            {
                case "Open": e.CanExecute = true; break;
                case "Save": e.CanExecute = true; break;
                case "Exit": e.CanExecute = true; break;
                case "Esf": if (this.select != null) e.CanExecute = true; break;
                case "Mtf": e.CanExecute = true; break;
                case "Lsf": e.CanExecute = true; break;
                case "Options": e.CanExecute = true; break; 
            }
        }

        private void command_Executed(object sender, ExecutedRoutedEventArgs e)
        {
            switch (((RoutedUICommand)e.Command).Text)
            {
                case "Open":
                    {
                        OpenFileDialog dialog = new OpenFileDialog
                        {
                            DefaultExt = "jpg",
                            AddExtension = true,
                            Filter = "Файл изображения JPEG-формата|*.jpg|Файл изображения BITMAP-формата|*.bmp|Файл изображения TIFF-формата|*.tif|Файл изображения PNG-формата|*.png|Все файлы (*.*)|*.*"
                        };
                        if (dialog.ShowDialog().Value) this.viewer.FromFile(dialog.FileName);
                    }
                    break;
                case "Save":
                    {
                        SaveFileDialog dialog = new SaveFileDialog
                         {
                             FileName = "",
                             DefaultExt = "jpg",
                             AddExtension = true,
                             Filter = "Файл изображения JPEG-формата|*.jpg|Файл изображения BITMAP-формата|*.bmp|Файл изображения TIFF-формата|*.tif|Файл изображения PNG-формата|*.png|Все файлы (*.*)|*.*"
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

                case "Esf":

                    foreach (Shape item in this.select)
                    {
                        Core.Image._8bit.Pixel[,] pixel;

                        Custom.Shape.Rectangle rectangle = (Custom.Shape.Rectangle)item;  

                        this.viewer.ToBuffer(new Int32Rect((int)rectangle.Location.X,
                            (int)rectangle.Location.Y, (int)rectangle.Width, (int)rectangle.Height),
                            out pixel);

                        Command.Custom.Chart.Lsf.Execute(this.chart_ESF.AddPixels(pixel), null);

                        this.viewer.Remove(item);   
                    }
                    this.select = null;
                    break;
                case "Lsf":
                    if (e.Parameter == null)
                    {
                        Application.Current.Shutdown(); break;
                    }

                    Command.Custom.Chart.Mtf.Execute(this.chart_LSF.AddESFPoints(e.Parameter as Point[]), null);
                    break;
                case "Mtf":
                    this.chart_MTF.AddLSFPoints(e.Parameter as Point[], opticalSize);
                    break;
                case "Options":
                    OptionsWindow ow = new OptionsWindow();
 
                    ow.Owner = this;
                    ow.RaiseCustomEvent += new EventHandler<_MTF.Viewer.Source.OptionsWindow.CustomEventArgs>(ow_RaiseCustomEvent);
                    ow.ShowDialog();
                    break;
            }
        }

        private void ow_RaiseCustomEvent(object sender, _MTF.Viewer.Source.OptionsWindow.CustomEventArgs e)
        {
            opticalSize = Convert.ToDouble(e.Message);
        }

        private void viewer_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            control = (Custom.ImageViewer)sender;
            if (Keyboard.Modifiers == ModifierKeys.Control)
            {
                control.Cursor = Cursors.Cross;
                if (this.select == null) this.select = new List<Custom.Shape.Rectangle>();
                this.select.Add(new Custom.Shape.Rectangle("1", control.MousePosition, Colors.Red));
                control.Add(this.select[this.select.Count - 1]);
                control.CaptureMouse();
            }
        }

        private void viewer_PreviewMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            control = (Custom.ImageViewer)sender;
            if (control.Cursor == Cursors.Cross && this.select != null)
            {
                Custom.Shape.Rectangle rectangle = this.select[this.select.Count - 1];
                rectangle.Width = Math.Abs(rectangle.Location.X - control.MousePosition.X);
                rectangle.Height = Math.Abs(rectangle.Location.Y - control.MousePosition.Y);
            }
            control.ReleaseMouseCapture();
        }

        private void viewer_PreviewMouseMove(object sender, MouseEventArgs e)
        {
            control = (Custom.ImageViewer)sender;
            if (control.Cursor == Cursors.Cross && this.select != null)
            {
                Custom.Shape.Rectangle rectangle = this.select[this.select.Count - 1];
                rectangle.Width = Math.Abs(rectangle.Location.X - control.MousePosition.X);
                rectangle.Height = Math.Abs(rectangle.Location.Y - control.MousePosition.Y);
            }
        }

        private void MenuItem_Click(object sender, RoutedEventArgs e)
        {
            this.viewer.FromFile(System.IO.Path.Combine(System.IO.Path.GetDirectoryName(
                System.Reflection.Assembly.GetExecutingAssembly().Location), "test.jpg"));
        }
    }
}
