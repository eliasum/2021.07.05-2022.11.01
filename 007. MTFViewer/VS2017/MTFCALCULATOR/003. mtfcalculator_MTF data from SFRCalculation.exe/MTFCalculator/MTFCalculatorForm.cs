/*2021.09.13 16:56 IMM*/

using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Text;
using System.Windows.Forms;
using System.Xml.Serialization;
using ZedGraph;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Collections;
using System.Linq;
using System.Diagnostics;

namespace MTFCalculator
{
    public partial class MTFCalculatorForm : Form
    {
        // загружаемый точечный рисунок
        Bitmap bitmap = null;

        // имя сохраняемого файла с типом .csv, содержащего данные MTF  
        private string filename = string.Empty;

        // строка статуса внизу формы
        public string Status
        {
            get
            {
                return toolStripStatusLabel.Text;
            }
            set
            {
                toolStripStatusLabel.Text = value;
                toolStripStatusLabel.Invalidate();
            }
        }

        public string InputFileName { get; set; }

        // инициализация объектов:

        // графика LSF
        private GraphPanel graphPanelLSF = new GraphPanel();

        // графика MTF
        private GraphPanel graphPanelMTF = new GraphPanel();

        // формы "О программе"
        private AboutForm aboutForm = new AboutForm();

        // настроек программы
        private Options options = new Options();

        // формы настроек программы
        private OptionsForm optionsForm = new OptionsForm();

        public MTFCalculatorForm()
        {
            InitializeComponent();

            // Вызываем метод AxisChange(), чтобы обновить данные об осях. 
            // В противном случае на рисунке будет показана только часть графика, 
            // которая умещается в интервалы по осям, установленные по умолчанию
            zGC_MyESF.AxisChange();
            zGC_MyLSF.AxisChange();
            zGC_MyMTF.AxisChange();

            // Обновляем графики
            zGC_MyESF.Invalidate();
            zGC_MyLSF.Invalidate();
            zGC_MyMTF.Invalidate();
            /*  
                путь к особой системной папке, указанной в заданном перечислении, в данном случае LocalApplicationData - 
                Каталог, служащий общим хранилищем данных приложения, используемых текущим пользователем, который не перемещается.
                "C:\\Users\\user\\AppData\\Local"
            */
            string directory = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);

            if (System.IO.File.Exists(directory + "\\" + Resource.OptionsFileName))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(Options));

                try
                {
                    using (System.IO.Stream stream = System.IO.File.OpenRead(directory + "\\" + Resource.OptionsFileName))
                    {
                        options = (Options)serializer.Deserialize(stream);
                    }
                }
                catch
                {
                    MessageBox.Show("There was a problem deserializing MTFCalculator.xml.  Using the default options.",
                        Resource.MessageBoxCaption);
                }
            }

            aboutForm.Owner = this;

            optionsForm.Owner = this;
            optionsForm.PropertyGrid.SelectedObject = options;

            graphPanelLSF.BackColor = Color.White;
            graphPanelLSF.BorderStyle = BorderStyle.None;
            graphPanelLSF.Dock = DockStyle.Fill;

            tabLSF.Controls.Add(graphPanelLSF);

            graphPanelMTF.BackColor = Color.White;
            graphPanelMTF.BorderStyle = BorderStyle.None;
            graphPanelMTF.Dock = DockStyle.Fill;

            tabMTF.Controls.Add(graphPanelMTF);

            toolStripStatusLabel.Text = "Open an image to calculate the Modulation Transfer Function.";

            Tests();
        }

        private void Save()
        {
            System.IO.StreamWriter writer = new System.IO.StreamWriter(filename);

            if (writer != null)
            {
                string s = options.XLabel;

                if (graphPanelMTF.XUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.XUnits + " )";
                }

                s += "," + options.YLabel;

                if (graphPanelMTF.YUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.YUnits + " )";
                }

                s += "\n";

                for (int i = 0; i < graphPanelMTF.X.Length; i++)
                {
                    s += graphPanelMTF.X[i].ToString() + "," + graphPanelMTF.Y[i].ToString() + "\n";
                }

                writer.Write(s);
                writer.Close();
            }
        }

        /// <summary>
        /// Single-frequency sinusoid.
        /// Одночастотная синусоида. 
        /// </summary>
        private double[] TestA()
        {
            int n = 256;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                real[i] = Math.Sin((double)(i) / 2);
                imag[i] = 0.0;
            }

            MTF.HannWindow(real);

            double[] padded = MTF.ZeroPad(real);

            MTF.Compute(padded);

            double[] m = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                m[i] = padded[i];
            }

            graphPanelMTF.Y = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, (float)(Math.PI), n / 4);

            return m;
        }

        /// <summary>
        /// Ideal Line Spread Function (LSF).
        /// Идеальная функция растяжения линии (LSF). 
        /// </summary>
        private double[] TestB()
        {
            int n = 128;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                if (i == 64)
                {
                    real[i] = 1.0;
                }
                else
                {
                    real[i] = 0.0;
                }

                imag[i] = 0.0;
            }

            MTF.HannWindow(real);

            double[] padded = MTF.ZeroPad(real);

            MTF.Compute(padded);

            double[] m = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                m[i] = padded[i];
            }

            graphPanelMTF.Y = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 1.0f, 1.2f);

            return m;
        }

        /// <summary>
        /// Non-ideal Line Spread Function (LSF).
        /// Идеальная функция растяжения линии (LSF). 
        /// </summary>
        private double[] TestC()
        {
            int n = 128;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                if (i == 63)
                {
                    real[i] = 0.5;
                }
                else if (i == 64)
                {
                    real[i] = 1.0;
                }
                else if (i == 65)
                {
                    real[i] = 0.5;
                }
                else
                {
                    real[i] = 0.0;
                }

                imag[i] = 0.0;
            }

            MTF.HannWindow(real);

            double[] padded = MTF.ZeroPad(real);

            MTF.Compute(padded);

            double[] m = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                m[i] = padded[i];
            }

            graphPanelMTF.Y = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 1.0f, 2.2f);

            return m;
        }

        /// <summary>
        /// Conversion of a step response to a Line Spread Function (LSF).
        /// Преобразование ступенчатой характеристики в функцию линейного расширения (LSF). 
        /// </summary>
        private double[] TestD()
        {
            int n = 256;
            int m = 8;

            double[] real = new double[n];
            double[] imag = new double[n];

            for (int i = 0; i < n; i++)
            {
                if (i < n / 2 - m / 2)
                {
                    real[i] = 1.0;
                }
                else if (i >= n / 2 - m / 2 && i <= n / 2 + m / 2)
                {
                    real[i] = 0.5 + 0.5 * Math.Cos(2 * Math.PI * ((double)(i - n / 2 + m / 2) / (2 * m)));
                }
                else
                {
                    real[i] = 0.0;
                }

                imag[i] = 0.0;
            }

            // Calculate the discrete derivative of the step response in real.
            // Вычислить дискретную производную переходной характеристики в реальном масштабе времени. 

            double[] difference = new double[n];

            for (int i = 0; i < n - 1; i++)
            {
                difference[i] = real[i] - real[i + 1];
            }

            // Use the discrete derivative, which is the LSF, to compute the MTF.
            // Использовать дискретную производную, которой является LSF, для вычисления MTF. 

            MTF.HannWindow(difference);

            double[] padded = MTF.ZeroPad(difference);

            MTF.Compute(padded);

            double[] mtf = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                mtf[i] = padded[i];
            }

            graphPanelMTF.Y = mtf;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 8.0f, 1.0f);

            return mtf;
        }

        /// <summary>
        /// Load an image and display the MTF.
        /// Загрузить изображение и отобразить MTF. 
        /// </summary>
        private double[] TestE()
        {
            OpenFileDialog dialog = new OpenFileDialog();

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                Image image = Bitmap.FromFile(dialog.FileName);

                if (image != null)
                {
                    double[] real = new double[image.Width];

                    for (int i = 0; i < image.Width; i++)
                    {
                        real[i] = 0.0;

                        for (int j = 0; j < image.Height; j++)
                        {
                            real[i] += (image as Bitmap).GetPixel(i, j).GetBrightness() / image.Height;
                        }
                    }

                    double[] difference = new double[image.Width];

                    for (int i = 0; i < image.Width - 1; i++)
                    {
                        difference[i] = real[i] - real[i + 1];
                    }

                    // Use the discrete derivative, which is the LSF, to compute the MTF.
                    // Использовать дискретную производную, которой является LSF, для вычисления MTF. 

                    MTF.HannWindow(difference);

                    double[] padded = MTF.ZeroPad(difference);

                    MTF.Compute(padded);

                    graphPanelMTF.Y = new double[padded.Length / 2];

                    for (int i = 0; i < padded.Length / 2; i++)
                    {
                        graphPanelMTF.Y[i] = padded[i];
                    }

                    double pixelWidth = 0.1;                        // mm
                    double samplingFrequency = 1 / pixelWidth;      // cycles / mm

                    graphPanelMTF.X = new double[padded.Length / 2];

                    for (int i = 0; i < padded.Length / 2; i++)
                    {
                        graphPanelMTF.X[i] = ((float)i / (padded.Length / 2)) * (samplingFrequency / 2);
                    }

                    graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, (float)(samplingFrequency / 2), 1.0f);
                    graphPanelMTF.XUnits = "cycles / mm";

                    return graphPanelMTF.Y;
                }
                return null; 
            }
            return null;
        }

        private void Tests()
        {
            double[] m = TestA();

            if (m != null)
            {
                // График Tests /////////////////////////////////////////////////////////////////////////////////////////////////////

                // Получим панель для рисования
                GraphPane paneTests = zGC_Tests.GraphPane;

                // граниные значения по осям
                paneTests.XAxis.Scale.Min = m[0];
                paneTests.XAxis.Scale.Max = m.Length - 1;
                paneTests.YAxis.Scale.Min = m.Min();
                paneTests.YAxis.Scale.Max = m.Max() + .1;

                // Очистим список кривых на тот случай, если до этого сигналы уже были нарисованы
                paneTests.CurveList.Clear();

                // Создадим список точек
                PointPairList listTests = new PointPairList();

                // Заполняем список точек
                for (int i = 0; i < m.Length; i++)
                {
                    // добавим в список точку
                    listTests.Add(i, m[i]);
                }

                // Создадим кривую с названием "Tests",  
                // которая будет рисоваться голубым цветом (Color.Blue),
                // Опорные точки выделяться не будут (SymbolType.None)
                LineItem curveTests = paneTests.AddCurve("Tests", listTests, Color.Blue, SymbolType.None);

                // Вызываем метод AxisChange(), чтобы обновить данные об осях. 
                // В противном случае на рисунке будет показана только часть графика, 
                // которая умещается в интервалы по осям, установленные по умолчанию
                zGC_MyLSF.AxisChange();

                // Обновляем график
                zGC_MyLSF.Invalidate();
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            }
        }

        protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
        {
            string directory = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);

            if (System.IO.File.Exists(directory + "\\" + Resource.OptionsFileName))
            {
                System.IO.File.Delete(directory + "\\" + Resource.OptionsFileName);
            }

            using (System.IO.Stream stream = System.IO.File.OpenWrite(directory + "\\" + Resource.OptionsFileName))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(Options));

                serializer.Serialize(stream, options);
            }

            base.OnClosing(e);
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);

            graphPanelMTF.Invalidate();
        }

        private void aboutToolStripMenuItem_Click(object sender, EventArgs e)
        {
            aboutForm.ShowDialog();
        }

        private void copyToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (graphPanelMTF.X != null && graphPanelMTF.Y != null && graphPanelMTF.X.Length == graphPanelMTF.Y.Length)
            {
                string s = options.XLabel;

                if (graphPanelMTF.XUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.XUnits + " )";
                }

                s += "\t" + options.YLabel;

                if (graphPanelMTF.YUnits != string.Empty)
                {
                    s += " ( " + graphPanelMTF.YUnits + " )";
                }

                s += "\n";

                for (int i = 0; i < graphPanelMTF.X.Length; i++)
                {
                    s += graphPanelMTF.X[i].ToString() + "\t" + graphPanelMTF.Y[i].ToString() + "\n";
                }

                Clipboard.SetData(DataFormats.StringFormat, s);
            }
            else
            {
                MessageBox.Show("An image must be loaded before the Modulation Transfer Function can be copied to the clipboard.",
                    Resource.MessageBoxCaption);
            }
        }

        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void openToolStripMenuItem_Click(object sender, EventArgs e)
        {
            OpenFileDialog dialog = new OpenFileDialog();

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                InputFileName = Path.GetFileName(dialog.FileName);
                Status = "Loading " + System.IO.Path.GetFileName(dialog.FileName) + " ...";

                try
                {
                    bitmap = (Bitmap)Bitmap.FromFile(dialog.FileName);
                }
                catch (Exception exception)
                {
                    MessageBox.Show("Failed to load " + System.IO.Path.GetFileName(dialog.FileName) + " for the following reason: " + exception.Message, Resource.MessageBoxCaption);
                }

                if (bitmap != null && bitmap.Height > options.AveragingWindowLength && bitmap.Width > 0)
                {
                    Text = "Modulation Transfer Function Calculator (" + System.IO.Path.GetFileName(dialog.FileName) + ")";

                    Compute(bitmap);
                }
                else
                {
                    MessageBox.Show("Cannot use " + System.IO.Path.GetFileName(dialog.FileName) + " because reading the image returned null or because the image was too small.", Resource.MessageBoxCaption);
                }
            }
        }

        private void Compute(Bitmap bitmap)
        {
            // вывод оригинальной картинки
            pB_Original_Image.Image = bitmap;

            // 1. Crop the image to the crop rectangle, using the image width and height if no other value is specified.
            // 1. Обрезать изображение до прямоугольника обрезки, используя ширину и высоту изображения, если не указано другое значение. 

            Status = "Cropping ...";        // Обрезка
            /*
               Содержит набор из четырех целых чисел, определяющих расположение и размер прямоугольника.
               Для расширения функций области используйте объект System.Drawing.Region.
            */
            Rectangle cropRectangle = options.CropRectangle;

            if (cropRectangle.Width == 0 || cropRectangle.Width > bitmap.Width)
            {
                cropRectangle.Width = bitmap.Width;
            }

            if (cropRectangle.Height == 0 || cropRectangle.Height > bitmap.Height)
            {
                cropRectangle.Height = bitmap.Height;
            }

            Bitmap croppedBitmap = new Bitmap(cropRectangle.Width, cropRectangle.Height);       // обрезанный рисунок

            /*
                Создание нового объект Graphics из указанного рисунка Image и запись в переменную типа Graphics

                Конструкция using оформляет блок кода и создает объект некоторого класса, который реализует интерфейс
                IDisposable, в частности, его метод Dispose. При завершении блока кода у объекта вызывается метод Dispose.

                Важно, что данная конструкция применяется только для классов, которые реализуют интерфейс IDisposable.
                https://metanit.com/sharp/tutorial/8.5.php
            */
            using (Graphics g = Graphics.FromImage(croppedBitmap))
            {
                /*
                    Рисует заданную часть указанного объекта System.Drawing.Image в заданном месте, используя заданный размер. 
                */
                g.DrawImage(bitmap, new Rectangle(-cropRectangle.Left, -cropRectangle.Top, bitmap.Width, bitmap.Height),
                    new Rectangle(0, 0, bitmap.Width, bitmap.Height), GraphicsUnit.Pixel);
            }

            // проверка существования папки 'imgs'
            if (!Directory.Exists("imgs")) Directory.CreateDirectory("imgs");

            // сохранить обрезанную картинку
            croppedBitmap.Save(@"imgs\CroppedImage.jpg", System.Drawing.Imaging.ImageFormat.Jpeg);

            //-----------------------------------------------Brightness averaging------------------------------------------------

            // 2. Find the average pixel values across the top and bottom.///////////////////////////////////////////////////////
            // 2. Находим усреднённые значения яркости пикселей сверху и снизу.//////////////////////////////////////////////////

            Status = "Straightening ...";       // Выпрямление 

            int topEdge = 0;                 // верхний край
            int bottomEdge = 0;                 // нижний край

            double topAverage = 0.0;         // усреднённое значение яркости верхних "вертикальных" 8-и пикселей
            double bottomAverage = 0.0;         // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

            // проверка существования папки 'txt'
            if (!Directory.Exists("txt")) Directory.CreateDirectory("txt");

            StreamWriter sr0 = new StreamWriter(@"txt\The brightness of all pixels of the bitmap.txt");

            // цикл по ширине croppedBitmap.Width объекта Image в точках
            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                // цикл по высоте объекта Image в точках
                for (int j = 0; j < croppedBitmap.Height; j++)
                {
                    sr0.Write("Width = " + i.ToString("000") + "\t" + "Height = " + j.ToString("000") + "\t"
                        + croppedBitmap.GetPixel(i, j).GetBrightness().ToString("F9") + "\n");
                }
            }

            sr0.Close();

            // Вычисление усреднённого значения яркости верхних "вертикальных" 8-и пикселей 'topAverage'_________________________

            StreamWriter sr1 = new StreamWriter(@"txt\Brightness and current topAverage.txt");
            /*
                croppedBitmap.Width - ширина объекта Image в точках.
                Averaging Window Length (Длина окна усреднения) - количество строк для усреднения при вычислении 
                среднего значения в пикселях вверху и внизу изображения. В Options.cs задано averagingWindowLength = 8
            */
            // цикл по ширине объекта Image в точках
            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                // цикл по первым 'AveragingWindowLength' = 8 строкам объекта Image, т.е. j = 0, 1, 2, 3, 4, 5, 6, 7 
                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    // Σtop8 - Сумма яркостей всех пикселей по всей ширине картинки верхних 8-ми строк 
                    topAverage += croppedBitmap.GetPixel(i, j).GetBrightness();

                    sr1.Write(j.ToString("000") + "\tBrightness = " + croppedBitmap.GetPixel(i, j).GetBrightness().ToString("F9")
                        + "\tCurrentTopAverage = " + topAverage.ToString("000.0000000000000") + "\n");
                }
            }

            sr1.Close();

            // topAverage = Σtop8 / (Width * AWL)
            topAverage /= croppedBitmap.Width * options.AveragingWindowLength;  // усреднённое значение яркости верхних "вертикальных" 8-и пикселей

            // Вычисление усреднённого значения яркости нижних "вертикальных" 8-и пикселей 'bottomAverage'_______________________

            StreamWriter sr2 = new StreamWriter(@"txt\Brightness and current bottomAverage.txt");
            /*
                croppedBitmap.Width - ширина объекта Image в точках.
                Averaging Window Length (Длина окна усреднения) - количество строк для усреднения при вычислении 
                среднего значения в пикселях вверху и внизу изображения. В Options.cs задано averagingWindowLength = 8
            */
            // цикл по ширине объекта Image в точках
            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                // цикл по последним 'AveragingWindowLength' = 8 строкам объекта Image, т.е. j = Height - 1 - 8, ..., Height - 1 - 1
                for (int j = croppedBitmap.Height - 1 - options.AveragingWindowLength; j < croppedBitmap.Height - 1; j++)
                {
                    // Σbottom8 - Сумма яркостей всех пикселей по всей ширине картинки нижних 8-ми строк 
                    bottomAverage += croppedBitmap.GetPixel(i, j).GetBrightness();

                    sr2.Write(j + "\tBrightness = " + croppedBitmap.GetPixel(i, j).GetBrightness().ToString("F9") +
                        "\tCurrentbottomAverage = " + bottomAverage.ToString("000.0000000000000") + "\n");
                }
            }

            sr2.Close();

            // bottomAverage = Σbottom8 / (Width * AWL)
            bottomAverage /= croppedBitmap.Width * options.AveragingWindowLength;  // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

            // 3. Find the first place the running average crosses the average across the top of the image.//////////////////////
            // 3. Находим первое место, где текущее скользящее среднее пересекает среднее в верхней части изображения.///////////

            double runningAverage = 0.0;       // текущее скользящее среднее 
            double previousAverage = 0.0;       // предыдущее скользящее среднее

            // Вычисление начального скользящего среднего яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины' - 'top_moving_average_0'

            StreamWriter sr3 = new StreamWriter(@"txt\Brightness and current top_moving_average_0.txt");

            // цикл по длине окна усреднения
            for (int j = 0; j < options.AveragingWindowLength; j++)     // j = 0, 1, 2, 3, 4, 5, 6, 7
            {
                /*
                    начальное скользящее среднее яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины' объекта Image,
                    top_moving_average_0 = Σtop(w0,h8) / AWL, где Σtop(w0,h8) - 
                    сумма яркостей 'AveragingWindowLength' = 8 верхних пикселей '0-го столбца ширины' объекта Image
                */
                runningAverage += croppedBitmap.GetPixel(0, j).GetBrightness() / options.AveragingWindowLength;     // top_moving_average_0

                sr3.Write("Brightness = " + croppedBitmap.GetPixel(0, j).GetBrightness().ToString("F9") +
                    "\tTop_moving_average_0 = " + runningAverage.ToString("F18") + "\n");
            }

            sr3.Close();

            StreamWriter sr4 = new StreamWriter(@"txt\Top Edge.txt");

            // цикл по ширине объекта Image в точках, начиная с '1-го столбца ширины'
            for (int i = 1; i < croppedBitmap.Width; i++)       // цикл сравнения всех 8-пиксельных вертикальных "срезов" *
            {
                previousAverage = runningAverage;       // предыдущее среднее (при i = 0 previousAverage = top_moving_average_0)
                runningAverage = 0.0;                  // текущее значение скользящего среднего 

                /*
                    Вычисление текущего скользящего среднего яркости верхних "вертикальных" 8-и пикселей 
                    'i-го столбца ширины' - 'top_moving_average(w1...wn,h8)' '___________________________________________________
                */

                // цикл по длине окна усреднения
                for (int j = 0; j < options.AveragingWindowLength; j++)     // j = 0, 1, 2, 3, 4, 5, 6, 7
                {
                    /*
                        Текущее скользящее среднее яркости верхних "вертикальных" 8-и пикселей 
                        'i-го столбца ширины' объекта Image, начиная с '1-го столбца ширины',
                        top_moving_average(wi,h8) = Σtop(wi,h8) / AWL, где Σtop(wi,h8) - 
                        сумма яркостей 'AveragingWindowLength' = 8 верхних пикселей 'i-го столбца ширины' объекта Image,
                        начиная с '1-го столбца ширины',
                    */
                    runningAverage += croppedBitmap.GetPixel(i, j).GetBrightness() / options.AveragingWindowLength;     // top_moving_average(wi,h8)
                }

                /*
                    -------------------------------------------------------------------------------------------------------------
                    Алгоритм нахождения края сверху картинки:

                    topAverage - это вертикальная область у верхнего края картинки "шириной" 1 пиксель и "высотой" 8 пикселей, 
                    находящаяся в центре между "черной" и "белой" зонами картинки и обладающая относительно них средней яркостью
                    (из-за неидеальности перехода между черным и белым цветом это промежуточная "серая" зона). topAverage 
                    необходима для нахождения края перехода с "черной" зоны на "белую" путем сравнения в цикле * всех 
                    8-пиксельных вертикальных "срезов" у верхнего края картинки, пока текущее скользящее среднее значение яркости 
                    "среза" не превысит значения topAverage, которое является средним значением яркости края перехода ч/б у 
                    верхнего края картинки. Аналогично объяснение bottomAverage для нахождения края перехода с "черной" зоны на
                    "белую" у нижнего края картинки. topAverage и bottomAverage могут быть не равными, т.к. кромка может иметь 
                    какой либо наклон относительно вертикали.
                    -------------------------------------------------------------------------------------------------------------

                    if ((top_moving_average(wi-1,h8) < topAverage && top_moving_average(wi,h8) >= topAverage) || 
                        (top_moving_average(wi-1,h8) > topAverage && top_moving_average(wi,h8) <= topAverage))
                */
                if ((previousAverage < topAverage && runningAverage >= topAverage) ||
                    (previousAverage > topAverage && runningAverage <= topAverage))
                {
                    topEdge = i;

                    sr4.Write("topEdge = " + topEdge.ToString() + "\n");

                    break;
                }
            }

            sr4.Close();

            // 4. Find the first place the running average crosses the average across the bottom of the image./////////////////// 
            // 4. Находим первое место, где текущее скользящее среднее пересекает среднее в нижней части изображения.////////////

            runningAverage = 0.0;       // текущее скользящее среднее 
            previousAverage = 0.0;       // предыдущее скользящее среднее

            // Вычисление начального скользящего среднего яркости нижних "вертикальных" 8-и пикселей '0-го столбца ширины' - 'bottom_moving_average_0'

            StreamWriter sr5 = new StreamWriter(@"txt\Brightness and current bottom_moving_average_0.txt");

            // цикл по длине окна усреднения
            for (int j = 0; j < options.AveragingWindowLength; j++)
            {
                /*
                    начальное скользящее среднее яркости нижних "вертикальных" 8-и пикселей 'j = Height - 1 - 0, ..., Height - 1 - 7'
                    '0-го столбца ширины' объекта Image, bottom_moving_average_0 = Σbottom(w0,h8) / AWL, где Σbottom(w0,h8) - 
                    сумма яркостей 'AveragingWindowLength' = 8 нижних пикселей '0-го столбца ширины' объекта Image
                */
                runningAverage += croppedBitmap.GetPixel(0, croppedBitmap.Height - 1 - j).GetBrightness() / options.AveragingWindowLength;// bottom_moving_average_0
                sr5.Write("Brightness = " + croppedBitmap.GetPixel(0, j).GetBrightness().ToString("F9") +
                    "\tCurrentRunningAverage = " + runningAverage.ToString("F18") + "\n");
            }

            sr5.Close();

            // цикл по ширине объекта Image в точках, начиная с '1-го столбца ширины'
            for (int i = 1; i < croppedBitmap.Width; i++)
            {
                previousAverage = runningAverage;       // предыдущее среднее (при i = 0 previousAverage = bottom_moving_average_0)
                runningAverage = 0.0;                   // текущее значение скользящего среднего 

                /*
                    Вычисление текущего скользящего среднего яркости нижних "вертикальных" 8-и пикселей 
                    'i-го столбца ширины' - 'bottom_moving_average(w1...wn,h8)' '___________________________________________________
                */

                // цикл по длине окна усреднения
                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    /*
                        Текущее скользящее среднее яркости нижних "вертикальных" 8-и пикселей 
                        'i-го столбца ширины' объекта Image, начиная с '1-го столбца ширины',
                        bottom_moving_average(wi,h8) = Σbottom(wi,h8) / AWL, где Σbottom(wi,h8) - 
                        сумма яркостей 'AveragingWindowLength' = 8 нижних пикселей 'i-го столбца ширины' объекта Image,
                        начиная с '1-го столбца ширины',
                    */
                    runningAverage += croppedBitmap.GetPixel(i, croppedBitmap.Height - 1 - j).GetBrightness() / options.AveragingWindowLength;// bottom_moving_average(wi,h8)
                }

                /*
                    if ((bottom_moving_average(wi-1,h8) < bottomAverage && bottom_moving_average(wi,h8) >= bottomAverage) || 
                        (bottom_moving_average(wi-1,h8) > bottomAverage && bottom_moving_average(wi,h8) <= bottomAverage))
                */
                if ((previousAverage < bottomAverage && runningAverage >= bottomAverage) ||
                    (previousAverage > bottomAverage && runningAverage <= bottomAverage))
                {
                    bottomEdge = i;

                    break;
                }
            }

            //---------------------------------------Calculating the Edge Spread Function ---------------------------------------

            // 5. Calculate the required rotation angle./////////////////////////////////////////////////////////////////////////
            // 5. Рассчитаем требуемый угол поворота.//////////////////////////////////////////////////////////////////////////// 

            double angle = Math.Atan2(Math.Abs(bottomEdge - topEdge), croppedBitmap.Height - options.AveragingWindowLength) * 180 / Math.PI;
            angle = Math.Round(angle);

            if (Math.Abs(angle) > 15.0)
            {
                //MessageBox.Show("A significant portion of the image may be lost because the required rotation angle is larger than 15 degrees.  Make sure you have the right image and the right crop rectangle.", Resource.MessageBoxCaption);
                MessageBox.Show("Значительная часть изображения может быть потеряна, поскольку требуемый угол поворота превышает 15 градусов. Убедитесь, что у вас правильное изображение и правильный прямоугольник обрезки. ", Resource.MessageBoxCaption);
            }


            // 6. Flip the image horizontally if the edge runs from right to left.///////////////////////////////////////////////
            // 6. Отразить изображение по горизонтали, если край идет справа налево./////////////////////////////////////////////

            if (bottomEdge < topEdge)
            {
                croppedBitmap.RotateFlip(RotateFlipType.Rotate180FlipX);
            }

            // 7. Calculate the crop offsets based on the rotation angle.////////////////////////////////////////////////////////
            // 7. Вычислить смещения обрезки на основе угла поворота.////////////////////////////////////////////////////////////

            int w = (int)Math.Ceiling(croppedBitmap.Width * Math.Tan(angle * Math.PI / 180));
            int h = (int)Math.Ceiling(croppedBitmap.Height * Math.Tan(angle * Math.PI / 180));

            // 8. Rotate and translate the image as appropriate./////////////////////////////////////////////////////////////////
            // 8. Повернуть и сдвинуть изображение соответствующим образом.////////////////////////////////////////////////////// 

            if (croppedBitmap.Width - h <= 0 || croppedBitmap.Height - w <= 0)
            {
                /*
                    MessageBox.Show("Not enough of the image was left after cropping and rotating to proceed. 
                    Make sure you have the right image and the right crop rectangle.", Resource.MessageBoxCaption);
                */
                MessageBox.Show("После обрезки и поворота осталось недостаточно изображения для продолжения. Убедитесь, " +
                    "что у вас правильное изображение и правильный прямоугольник обрезки.", Resource.MessageBoxCaption);

                return;
            }

            // выпрямленное растровое изображение 
            Bitmap straightenedBitmap = new Bitmap(croppedBitmap.Width - h, croppedBitmap.Height - w);

            // вкладка 'Line Spread Function'////////////////////////////////////////////////////////////////////////////////////
            using (Graphics g = Graphics.FromImage(straightenedBitmap))
            {
                Matrix m = new Matrix();

                m.Rotate((float)angle);

                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Transform = m;

                // Рисует заданную часть указанного объекта System.Drawing.Image в заданном месте, используя заданный размер.
                g.DrawImage(croppedBitmap, new Rectangle(0, -w, croppedBitmap.Width, croppedBitmap.Height),
                    new Rectangle(0, 0, croppedBitmap.Width, croppedBitmap.Height), GraphicsUnit.Pixel);
            }

            graphPanelLSF.Panel.BackgroundImageLayout = ImageLayout.Stretch;    // растянуть изображение на всю длину клиентского прямоугольника
            graphPanelLSF.Panel.BackgroundImage = straightenedBitmap;     // фоновое изображение во вкладке 'Line Spread Function'
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Status = "Calculating the Edge Spread Function ...";

            // собственно расчет массива значений Edge Spread Function___________________________________________________________
            int imageWidth = straightenedBitmap.Width;                          // ширина выпрямленного растрового изображения в пикселях

            double[] real = new double[imageWidth];                             // массив значений ESF

            for (int i = 0; i < imageWidth; i++)                                // заполнение массива значений ESF
            {
                real[i] = 0.0;

                for (int j = 0; j < straightenedBitmap.Height; j++)
                {
                    real[i] += (straightenedBitmap as Bitmap).GetPixel(i, j).GetBrightness() / straightenedBitmap.Height;
                }
            }
            
            // убрать min и max значения
            real = real.Where(x => x != real.Min()).ToArray();
            real = real.Where(x => x != real.Max()).ToArray();
            
            // алгоритм разворачивания ESF относительно вертикали, если слева белая область______________________________________
            /*
                Когда у тестируемой картинки левая область черная, а правая белая, то график ESF строится "правильно" как и в quickMTF.
                Если же левая область белая, а правая - черная, то данные ESF нужно зеркально развернуть, чтобы было соответствие с графиком
                ESF quickMTF. Таким образом, перед расчетом LSF график ESF всегда имеет вид "Ч/Б".
            */
            double sum = 0;                                                     // признак белой области слева

            for (int i = 0; i < 10; i++)
            {
                sum += real[i];
            }

            sum /= 10;

            if (sum > 0.8) Array.Reverse(real);                                 // вернёт массив в обратном порядке
             
            // рассчитать нормированный к диапазону quickmtf массив шагов ESF для сравнения на одном графике_____________________
            double range_quickmtf = 400;                                        // диапазон значений ESF в quickmtf
            double step_quickmtf = 0.1;                                         // шаг значений ESF в quickmtf
            double startOfRange = -20.0;                                        // начальное значение диапазона значений ESF в quickmtf

            double step = (range_quickmtf / real.Length) * step_quickmtf;       // нормированный к диапазону quickmtf шаг ESF
            double[] steps = new double[real.Length];                           // массив нормированных к диапазону quickmtf шагов ESF

            for (int i = 0; i < real.Length; i++)
            {
                steps[i] = startOfRange + step * i;
            }

            // Алгоритм нахождения смещения для совмещения графиков исходной ESF и ESF в quickmtf________________________________

            double shift = 0;                                                   // смещение для совмещения графиков        

            // найдем значение смещения относительно масштабированных значений абсциссы steps[i] 
            for (int i = 0; i < real.Length; i++)
            {
                // как только значение real >= 0.5 - нашли смещение
                if (real[i] >= 0.5)
                {
                    shift = steps[i];
                    break;
                }
            }
            
            // смещаем график ESF относительно масштабированных значений абсциссы steps[i] на значение shift
            for (int i = 0; i < real.Length; i++)
            {
                steps[i] = steps[i] - shift;
            }
            
            // формирование имён файлов выходных данных__________________________________________________________________________

            string output_string = null;                                        // имя файла тестируемой картинки без расширения

            // шаблон Regex - точка \.
            var pattern = @"\.";                                                // расширение файла в полном имени файла тестируемой картинки

            /*
                найти во входной строке первое вхождение регулярного выражения, предоставленное 
                в параметре pattern справа налево. 
            */
            var match = Regex.Match(InputFileName, pattern, RegexOptions.RightToLeft);

            // если есть совпадение
            if (match.Success)
            {
                // извлечь подстроку с начала входной строки длиной, равной позиции последней точки
                output_string = InputFileName.Substring(0, match.Index);
            }

            // проверка существования папки 'csv'
            if (!Directory.Exists("csv")) Directory.CreateDirectory("csv");

            // считать данные ESF из файла, сформированного quickmtf для сравнения на одном графике______________________________

            // проверка существования папок 'QuickMTF_output\ESF'
            if (!Directory.Exists("QuickMTF_output\\ESF")) Directory.CreateDirectory("QuickMTF_output\\ESF");

            // путь к файлу ESF из папки QuickMTF_output, имя которого аналогично имени тестируемой картинки
            string filePath = @"QuickMTF_output\ESF\" + output_string + ".txt";

            // массивы для заполнения данными из файла, сформированного quickmtf
            double[] steps_quickESF = null;              // шаги значений ESF в quickmtf
            double[] ESF1 = null;                        // значения ESF1 в quickmtf
            double[] ESF2 = null;                        // значения ESF2 в quickmtf
            double[] ESF3 = null;                        // значения ESF3 в quickmtf
            double[] ESF4 = null;                        // значения ESF4 в quickmtf

            // если файл ESF из папки QuickMTF_output существует
            if (File.Exists(filePath))
            {
                // считать файл построчно в массив строк
                var lines = File.ReadAllLines(filePath);

                // массив вида [№строки][данные_строки]
                string[][] text = new string[lines.Length][];

                // заполнения массива вида [№строки][данные_строки]
                for (var i = 0; i < text.Length; i++)
                {
                    text[i] = lines[i].Split('\t');
                }

                // массивы для заполнения данными из файла, сформированного quickmtf
                steps_quickESF = new double[text.Length];              // шаги значений ESF в quickmtf
                ESF1 = new double[text.Length];                        // значения ESF1 в quickmtf
                ESF2 = new double[text.Length];                        // значения ESF2 в quickmtf
                ESF3 = new double[text.Length];                        // значения ESF3 в quickmtf
                ESF4 = new double[text.Length];                        // значения ESF4 в quickmtf

                // заполнение массивов данными из файла, сформированного quickmtf

                // цикл по строкам
                for (int i = 0; i < text.Length; i++)
                {
                    // цикл по длинам строк
                    for (int j = 0; j < text[i].Length; j++)
                    {
                        steps_quickESF[i] = Convert.ToDouble(text[i][0].Replace('.', ','));
                        ESF1[i] = Convert.ToDouble(text[i][1].Replace('.', ','));
                        ESF2[i] = Convert.ToDouble(text[i][2].Replace('.', ','));
                        ESF3[i] = Convert.ToDouble(text[i][3].Replace('.', ','));
                        ESF4[i] = Convert.ToDouble(text[i][4].Replace('.', ','));
                    }
                }

                // массив сглаживаемых данных ESF для вывода на графике
                double[] realGraph = new double[real.Length];

                // заполнение массив сглаживаемых данных ESF для вывода на графике
                for (int i = 0; i < real.Length; i++)
                {
                    realGraph[i] = real[i];
                }

                // сглаживание графиков
                if (croppedBitmap.Width <= 100) Smooth(realGraph, 3);
                else
                if (croppedBitmap.Width <= 300) Smooth(realGraph, 11);

                // График ESF ///////////////////////////////////////////////////////////////////////////////////////////////////////

                // Получим панель для рисования
                GraphPane paneMyESF = zGC_MyESF.GraphPane;

                // граниные значения по осям
                paneMyESF.XAxis.Scale.Min = steps[0];
                paneMyESF.XAxis.Scale.Max = steps[steps.Length - 1];
                paneMyESF.YAxis.Scale.Min = realGraph[0];
                paneMyESF.YAxis.Scale.Max = realGraph[realGraph.Length - 1];

                // Очистим список кривых на тот случай, если до этого сигналы уже были нарисованы
                paneMyESF.CurveList.Clear();

                // Создадим список точек
                PointPairList listMyESF = new PointPairList();
                PointPairList listESF1 = new PointPairList();
                PointPairList listESF2 = new PointPairList();
                PointPairList listESF3 = new PointPairList();
                PointPairList listESF4 = new PointPairList();

                // Заполняем список точек
                for (int i = 0; i < realGraph.Length; i++)
                {
                    // добавим в список точку
                    listMyESF.Add(steps[i], realGraph[i]);
                }

                for (int i = 0; i < text.Length; i++)
                {
                    // добавим в списки точку
                    listESF1.Add(steps_quickESF[i], ESF1[i]);
                    listESF2.Add(steps_quickESF[i], ESF2[i]);
                    listESF3.Add(steps_quickESF[i], ESF3[i]);
                    listESF4.Add(steps_quickESF[i], ESF4[i]);
                }

                // Создадим кривую с названием "ESF", 
                // которая будет рисоваться голубым цветом (Color.Blue),
                // Опорные точки выделяться не будут (SymbolType.None)
                LineItem curveMyESF = paneMyESF.AddCurve("ESF", listMyESF, Color.Blue, SymbolType.None);
                LineItem curveESF1 = paneMyESF.AddCurve("ESF1", listESF1, Color.Red, SymbolType.None);
                //LineItem curveESF2  = paneMyESF.AddCurve("ESF2", listESF2,  Color.Green,  SymbolType.None);
                //LineItem curveESF3  = paneMyESF.AddCurve("ESF3", listESF3,  Color.Violet, SymbolType.None);
                //LineItem curveESF4  = paneMyESF.AddCurve("ESF4", listESF4,  Color.Orange, SymbolType.None);

                // Вызываем метод AxisChange(), чтобы обновить данные об осях. 
                // В противном случае на рисунке будет показана только часть графика, 
                // которая умещается в интервалы по осям, установленные по умолчанию
                zGC_MyESF.AxisChange();

                // Обновляем график
                zGC_MyESF.Invalidate();
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            }
            else MessageBox.Show("Файл ESF, имя которого аналогично имени тестируемой картинки, " +
                "не существует! Совместный график ESF не будет построен!");

            //---------------------------------------Calculating the Line Spread Function ---------------------------------------

            Status = "Calculating the Line Spread Function ...";

            // 9. Calculate the Line Spread Function from the step response.
            // 9. Вычислить функцию растяжения линии по переходной характеристике. 
            /*
                Чтобы график LSF рассчитывался в соответствии с графиком LSF quickMTF, ESF должна иметь вид "Б/Ч", поэтому перед 
                расчетом LSF данные ESF всегда нужно "отзеркаливать", т.к. они всегда имеют вид "Ч/Б".
            */
            Array.Reverse(real);                                                // вернёт массив в обратном порядке

            // double[] difference = new double[real.Length];   // TODO: после проверки вернуть обратно!
            double[] difference = new double[ESF1.Length];

            /*
                http://ru.quickmtf.com/slantededge.html
                LSF это первая производная ESF по координате. 
             
                http://aco.ifmo.ru/el_books/numerical_methods/lectures/glava1.html
                значение производной в точке Xi оценивается по значению функции в этой и в следующей точке Xi+1.
                Т.е. производная в данной точке есть отношение приращения функции к приращению аргумента, а приращение
                аргумента = 1 (массив с индексом i = 0,1,2...), что еще более упрощает формулу расчёта дискретной производной.
            */


            // for (int i = 0; i < real.Length - 1; i++)    // TODO: после проверки вернуть обратно!
            for (int i = 0; i < difference.Length - 1; i++)
            {
                // difference[i] = real[i] - real[i + 1];   // TODO: после проверки вернуть обратно!
                difference[i] = ESF1[i] - ESF1[i + 1]; 
            }

            // TODO: после проверки вернуть обратно!
            for (int i = 0; i < difference.Length; i++)
            {
                difference[i] = -difference[i];
            }

            // TODO: после проверки вернуть обратно!
            Normalize(difference);

            // вкладка 'Line Spread Function'////////////////////////////////////////////////////////////////////////////////////
            graphPanelLSF.X = new double[difference.Length];
            graphPanelLSF.Y = new double[difference.Length];

            for (int i = 0; i < difference.Length; i++)
            {
                graphPanelLSF.X[i] = (double)(i) * options.PixelSpacing;
                graphPanelLSF.Y[i] = difference[i];
            }

            graphPanelLSF.Color = Color.Red;
            graphPanelLSF.Limits = new RectangleF(0.0f, -1.0f, (float)(difference.Length) * (float)(options.PixelSpacing), 2.0f);
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // запись данных LSF в выходной файл ////////////////////////////////////////////////////////////////////////////////

            // запись в файл масштабированных под QuickMTF данных LSF
            // using (var SW_LSF_array = new StreamWriter(@"csv\" + output_string + @"_VS2017_QuickMTF_LSF.csv", false, Encoding.Default))  // TODO: Исправить!
            using (var SW_LSF_array = new StreamWriter(@"csv\" + output_string + @"_LSF.csv", false, Encoding.Default))
            {
                for (int i = 0; i < difference.Length; i++)
                    // SW_LSF_array.WriteLine(steps[i].ToString() + ";" + difference[i].ToString());    // TODO: Исправить!
                    SW_LSF_array.WriteLine(steps_quickESF[i].ToString() + ";" + difference[i].ToString()); 
            }

            // считать данные LSF из файла, сформированного quickmtf для сравнения на одном графике______________________________

            // проверка существования папок 'QuickMTF_output\LSF'
            if (!Directory.Exists("QuickMTF_output\\LSF")) Directory.CreateDirectory("QuickMTF_output\\LSF");

            // путь к файлу LSF из папки QuickMTF_output, имя которого аналогично имени тестируемой картинки
            string filePathLSF = @"QuickMTF_output\LSF\" + output_string + ".txt";

            // если файл LSF из папки QuickMTF_output существует
            if (File.Exists(filePathLSF))
            {
                // считать файл построчно в массив строк
                var lines = File.ReadAllLines(filePathLSF);

                // массив вида [№строки][данные_строки]
                string[][] text = new string[lines.Length][];

                // заполнения массива вида [№строки][данные_строки]
                for (var i = 0; i < text.Length; i++)
                {
                    text[i] = lines[i].Split('\t');
                }

                // массивы для заполнения данными из файла, сформированного quickmtf
                double[] steps_quickLSF = new double[text.Length];              // шаги значений LSF в quickmtf
                double[] LSF1 = new double[text.Length];                        // значения LSF1 в quickmtf
                double[] LSF2 = new double[text.Length];                        // значения LSF2 в quickmtf
                double[] LSF3 = new double[text.Length];                        // значения LSF3 в quickmtf
                double[] LSF4 = new double[text.Length];                        // значения LSF4 в quickmtf

                // заполнение массивов данными из файла, сформированного quickmtf

                // цикл по строкам
                for (int i = 0; i < text.Length; i++)
                {
                    // цикл по длинам строк
                    for (int j = 0; j < text[i].Length; j++)
                    {
                        steps_quickLSF[i] = Convert.ToDouble(text[i][0].Replace('.', ','));
                        LSF1[i] = Convert.ToDouble(text[i][1].Replace('.', ','));
                        LSF2[i] = Convert.ToDouble(text[i][2].Replace('.', ','));
                        LSF3[i] = Convert.ToDouble(text[i][3].Replace('.', ','));
                        LSF4[i] = Convert.ToDouble(text[i][4].Replace('.', ','));
                    }
                }

                // График LSF ///////////////////////////////////////////////////////////////////////////////////////////////////////

                // Получим панель для рисования
                GraphPane paneMyLSF = zGC_MyLSF.GraphPane;

                // граниные значения по осям
                paneMyLSF.XAxis.Scale.Min = steps[0];
                paneMyLSF.XAxis.Scale.Max = steps[steps.Length - 1];
                paneMyLSF.YAxis.Scale.Min = difference.Min();
                paneMyLSF.YAxis.Scale.Max = difference.Max();

                // Очистим список кривых на тот случай, если до этого сигналы уже были нарисованы
                paneMyLSF.CurveList.Clear();

                // Создадим список точек
                PointPairList listMyLSF = new PointPairList();
                PointPairList listMyLSFOut = new PointPairList();
                PointPairList listLSF1 = new PointPairList();
                PointPairList listLSF2 = new PointPairList();
                PointPairList listLSF3 = new PointPairList();
                PointPairList listLSF4 = new PointPairList();

                /*
                // Заполняем список точек
                for (int i = 0; i < difference.Length; i++)
                {
                    // добавим в список точку
                    listMyLSF.Add(steps[i], difference[i]);
                }

                for (int i = 0; i < differenceOut.Length; i++)
                {
                    // добавим в список точку
                    listMyLSFOut.Add(stepsOut[i], differenceOut[i]);
                }
                */

                // Заполняем список точек
                for (int i = 0; i < difference.Length; i++)
                {
                    // добавим в список точку
                    // listMyLSF.Add(steps[i], difference[i]);  // TODO: Исправить!
                    listMyLSF.Add(steps_quickLSF[i], difference[i]); 
                }

                for (int i = 0; i < difference.Length; i++)
                {
                    // добавим в список точку
                    listMyLSFOut.Add(steps_quickLSF[i], difference[i]);
                }

                for (int i = 0; i < text.Length; i++)
                {
                    // добавим в списки точку
                    listLSF1.Add(steps_quickLSF[i], LSF1[i]);
                    listLSF2.Add(steps_quickLSF[i], LSF2[i]);
                    listLSF3.Add(steps_quickLSF[i], LSF3[i]);
                    listLSF4.Add(steps_quickLSF[i], LSF4[i]);
                }

                // Создадим кривую с названием "LSF",  
                // которая будет рисоваться голубым цветом (Color.Blue),
                // Опорные точки выделяться не будут (SymbolType.None)
                LineItem curveMyLSF = paneMyLSF.AddCurve("LSF", listMyLSF, Color.Blue, SymbolType.None);
                //LineItem curveMyLSOut = paneMyLSF.AddCurve("LSFOut", listMyLSFOut, Color.Violet, SymbolType.None);
                LineItem curveLSF1 = paneMyLSF.AddCurve("LSF1", listLSF1, Color.Red, SymbolType.None);
                //LineItem curveLSF2    = paneMyLSF.AddCurve("LSF2",   listLSF2,     Color.Green,       SymbolType.None);
                //LineItem curveLSF3    = paneMyLSF.AddCurve("LSF3",   listLSF3,     Color.YellowGreen, SymbolType.None);
                //LineItem curveLSF4    = paneMyLSF.AddCurve("LSF4",   listLSF4,     Color.Orange,      SymbolType.None);           

                // Вызываем метод AxisChange(), чтобы обновить данные об осях. 
                // В противном случае на рисунке будет показана только часть графика, 
                // которая умещается в интервалы по осям, установленные по умолчанию
                zGC_MyLSF.AxisChange();

                // Обновляем график
                zGC_MyLSF.Invalidate();
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            }
            else MessageBox.Show("Файл LSF, имя которого аналогично имени тестируемой картинки, " +
                "не существует! Совместный график LSF не будет построен!");

            //------------------------------------Calculating the Modulation Transfer Function-----------------------------------

            // 10. Window the LSF.
            // 10. Окно LSF. 

            Status = "Calculating the Modulation Transfer Function ...";
            /*
                https://en.wikipedia.org/wiki/Window_function
                In either case, the Fourier transform (or a similar transform) can be applied on one or more finite intervals of the
                waveform. In general, the transform is applied to the product of the waveform and a window function. Any window 
                (including rectangular) affects the spectral estimate computed by this method. 

                В любом случае преобразование Фурье (или аналогичное преобразование) может применяться к одному или нескольким 
                конечным интервалам сигнала. Как правило, преобразование применяется к произведению формы сигнала и оконной функции. 
                Любое окно (включая прямоугольное) влияет на спектральную оценку, вычисленную этим методом.

                http://ru.quickmtf.com/slantededge.html
                После вычисления LSF в Quick MTF, sfrmat и Mitre SFR 1.4 к ней применяется окно Хемминга.
            */
            MTF.HannWindow(difference);     // HammingWindow    HannWindow

            // 11. Pad the windowed Line Spread Function with zeros until its length is equal to a power of 2.
            // 11. Заполнить оконную функцию Line Spread нулями до тех пор, пока ее длина не станет равной степени 2. 
            /*
                https://ru.dsplib.org/content/fft_composite/fft_composite.html
                алгоритмы БПФ по основанию два с прореживанием по времени и с прореживанием по частоте. Данные алгоритмы очень
                эффективны, но они имеют существенное ограничение: длина входных данных и выходного вектора должна быть целой степенью двойки
            */
            double[] padded = MTF.ZeroPad(difference);

            // 12. Calculate the Modulation Transfer Function.
            // 12. Вычислить функцию передачи модуляции. 

            MTF.Compute(padded);

            // вкладка 'Modulation Transfer Function'////////////////////////////////////////////////////////////////////////////
            graphPanelMTF.Y = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                graphPanelMTF.Y[i] = padded[i];
            }

            Smooth(graphPanelMTF.Y, options.SmoothingKernelLength);

            Normalize(graphPanelMTF.Y);

            double samplingFrequency = 1 / options.PixelSpacing;

            graphPanelMTF.X = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                graphPanelMTF.X[i] = ((float)i / (padded.Length / 2)) * (samplingFrequency / 2);
            }

            graphPanelMTF.Color = Color.Black;
            graphPanelMTF.Limits = new RectangleF(0.0f, -0.1f, (float)(samplingFrequency / 2), 1.2f);
            graphPanelMTF.TenPercentLine = true;
            graphPanelMTF.XUnits = options.XUnits;
            graphPanelMTF.YUnits = options.YUnits;

            graphPanelLSF.Invalidate();
            graphPanelMTF.Invalidate();
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // данные MTF - это "левая" половина данных, полученных после MTF.Compute()
            // double[] myGraphPanelMTF_Y = new double[padded.Length / 2];  // TODO: Исправить!
            double[] myGraphPanelMTF_Y = new double[padded.Length / 10];

            // длина массива данных MTF
            int MTF_Length = myGraphPanelMTF_Y.Length;

            // заполнение массива данных MTF
            for (int i = 0; i < MTF_Length; i++)
            {
                myGraphPanelMTF_Y[i] = padded[i];
            }

            // минимальное значение массива данных MTF
            double min = myGraphPanelMTF_Y.Min();

            // совместить график MTF с нулём по оси ординат
            for (int i = MTF_Length-1; i >= 0; i--)
            {
                myGraphPanelMTF_Y[i] -= min;
            }

            // сглаживание графика MTF
            Smooth(myGraphPanelMTF_Y, options.SmoothingKernelLength);

            // нормализация графика MTF
            Normalize(myGraphPanelMTF_Y);

            // рассчитать нормированный к диапазону quickmtf массив шагов MTF для сравнения на одном графике_____________________
            double step_quickmtf_MTF = 0.0025;                                      // шаг значений MTF в quickmtf
            double startOfRangeMTF = 0;                                             // начальное значение диапазона значений MTF в quickmtf
            double stepMTF = (range_quickmtf / MTF_Length) * step_quickmtf_MTF;     // нормированный к диапазону quickmtf шаг MTF

            double[] stepsMTF = new double[MTF_Length];                             // массив нормированных к диапазону quickmtf шагов MTF

            // заполнение массива нормированных к диапазону quickmtf шагов MTF
            for (int i = 0; i < MTF_Length; i++)
            {
                stepsMTF[i] = startOfRangeMTF + stepMTF * i;
            }

            // для совмещения с данными quickmtf на одном графике
            for (int i = 0; i < MTF_Length; i++)
            {
                myGraphPanelMTF_Y[i] *= 100;
            }

            // запись данных MTF в выходной файл ////////////////////////////////////////////////////////////////////////////////

            // запись в файл масштабированных под QuickMTF данных MTF
            //using (var SW_MTF_array = new StreamWriter(@"csv\" + output_string + @"_VS2017_QuickMTF_MTF.csv", false, Encoding.Default))   // TODO: Исправить!
            using (var SW_MTF_array = new StreamWriter(@"csv\" + output_string + @"_MTF.csv", false, Encoding.Default))
            {
                for (int i = 0; i < MTF_Length; i++)
                    SW_MTF_array.WriteLine(stepsMTF[i].ToString() + ";" + myGraphPanelMTF_Y[i].ToString());
            }

            // считать данные MTF из файла, сформированного quickmtf для сравнения на одном графике______________________________

            // путь к испольняемому файлу SFR_Calculation.exe
            var path = System.IO.Path.GetDirectoryName(Process.GetCurrentProcess().MainModule.FileName)+ @"\SFR\SFR_Calculation.exe";

            // запуск SFR_Calculation.exe
            Process process = Process.Start(path);

            // ждать завершения работы SFR_Calculation.exe 
            process.WaitForExit();

            // проверка существования папок 'QuickMTF_output\MTF'
            if (!Directory.Exists("QuickMTF_output\\MTF")) Directory.CreateDirectory("QuickMTF_output\\MTF");
            if (!Directory.Exists("SFRCalculation_output\\MTF")) Directory.CreateDirectory("SFRCalculation_output\\MTF");

            // путь к файлу MTF из папки QuickMTF_output, имя которого аналогично имени тестируемой картинки
            string filePathMTF = @"QuickMTF_output\MTF\" + output_string + ".txt";
            string filePathSFR = @"SFRCalculation_output\MTF\" + output_string + ".csv";
            string filePathSFRexe = @"ref\mtf.csv";

            // если файл MTF из папки QuickMTF_output существует
            if (File.Exists(filePathMTF) && 
                File.Exists(filePathSFR) && 
                File.Exists(filePathSFRexe))
            {
                // считать файл построчно в массив строк
                var lines = File.ReadAllLines(filePathMTF);
                var lines2 = File.ReadAllLines(filePathSFR);
                var lines3 = File.ReadAllLines(filePathSFRexe);

                // массив вида [№строки][данные_строки]
                string[][] text = new string[lines.Length][];
                string[][] text2 = new string[lines2.Length][];
                string[][] text3 = new string[lines3.Length][];

                // заполнения массива вида [№строки][данные_строки]
                for (var i = 0; i < text.Length; i++)
                {
                    text[i] = lines[i].Split('\t');
                }

                for (var i = 0; i < text2.Length; i++)
                {
                    text2[i] = lines2[i].Split(',');
                }

                for (var i = 0; i < text3.Length; i++)
                {
                    text3[i] = lines3[i].Split(',');
                }

                // массивы для заполнения данными из файла, сформированного quickmtf
                double[] steps_quickMTF = new double[text.Length];              // шаги значений MTF в quickmtf
                double[] MTF1 = new double[text.Length];                        // значения MTF1 в quickmtf
                double[] MTF2 = new double[text.Length];                        // значения MTF2 в quickmtf
                double[] MTF3 = new double[text.Length];                        // значения MTF3 в quickmtf
                double[] MTF4 = new double[text.Length];                        // значения MTF4 в quickmtf

                double[] stepsSFR = new double[text2.Length];             
                double[] SFR = new double[text2.Length];

                double[] stepsSFRexe = new double[text3.Length];
                double[] SFRexe = new double[text3.Length];

                // заполнение массивов данными из файла, сформированного quickmtf

                // цикл по строкам
                for (int i = 0; i < text.Length; i++)
                {
                    // цикл по длинам строк
                    for (int j = 0; j < text[i].Length; j++)
                    {
                        steps_quickMTF[i] = Convert.ToDouble(text[i][0].Replace('.', ','));
                        MTF1[i] = Convert.ToDouble(text[i][1].Replace('.', ','));
                        MTF2[i] = Convert.ToDouble(text[i][2].Replace('.', ','));
                        MTF3[i] = Convert.ToDouble(text[i][3].Replace('.', ','));
                        MTF4[i] = Convert.ToDouble(text[i][4].Replace('.', ','));
                    }
                }

                // цикл по строкам
                for (int i = 0; i < text2.Length; i++)
                {
                    // цикл по длинам строк
                    for (int j = 0; j < text2[i].Length; j++)
                    {
                        stepsSFR[i] = Convert.ToDouble(text2[i][0].Replace('.', ','));
                        SFR[i] = Convert.ToDouble(text2[i][1].Replace('.', ','))*100;
                    }
                }

                // цикл по строкам
                for (int i = 0; i < text3.Length; i++)
                {
                    // цикл по длинам строк
                    for (int j = 0; j < text3[i].Length; j++)
                    {
                        stepsSFRexe[i] = Convert.ToDouble(text3[i][0].Replace('.', ','));
                        SFRexe[i] = Convert.ToDouble(text3[i][1].Replace('.', ',')) * 100;
                    }
                }

                // График MTF ///////////////////////////////////////////////////////////////////////////////////////////////////////

                // Получим панель для рисования

                GraphPane paneMyMTF = zGC_MyMTF.GraphPane;

                // граниные значения по осям
                paneMyMTF.XAxis.Scale.Min = stepsMTF[0];
                paneMyMTF.XAxis.Scale.Max = stepsMTF[stepsMTF.Length - 1];
                paneMyMTF.YAxis.Scale.Min = myGraphPanelMTF_Y[myGraphPanelMTF_Y.Length - 1];
                paneMyMTF.YAxis.Scale.Max = myGraphPanelMTF_Y[0];

                // Очистим список кривых на тот случай, если до этого сигналы уже были нарисованы
                paneMyMTF.CurveList.Clear();

                // Создадим список точек
                PointPairList listMyMTF = new PointPairList();
                PointPairList listMTF1  = new PointPairList();
                PointPairList listMTF2  = new PointPairList();
                PointPairList listMTF3  = new PointPairList();
                PointPairList listMTF4  = new PointPairList();

                PointPairList listSFR = new PointPairList();
                PointPairList listSFRexe = new PointPairList();

                // Заполняем список точек
                for (int i = 0; i < myGraphPanelMTF_Y.Length; i++)
                {
                    // добавим в список точку
                    listMyMTF.Add(stepsMTF[i], myGraphPanelMTF_Y[i]);
                }

                for (int i = 0; i < text.Length; i++)
                {
                    // добавим в списки точку
                    listMTF1.Add(steps_quickMTF[i], MTF1[i]);
                    listMTF2.Add(steps_quickMTF[i], MTF2[i]);
                    listMTF3.Add(steps_quickMTF[i], MTF3[i]);
                    listMTF4.Add(steps_quickMTF[i], MTF4[i]);
                }

                for (int i = 0; i < text2.Length; i++)
                {
                    // добавим в списки точку
                    listSFR.Add(stepsSFR[i], SFR[i]);
                }

                for (int i = 0; i < text3.Length; i++)
                {
                    // добавим в списки точку
                    listSFRexe.Add(stepsSFRexe[i], SFRexe[i]);
                }

                // Создадим кривую с названием "MTF", 
                // которая будет рисоваться голубым цветом (Color.Blue),
                // Опорные точки выделяться не будут (SymbolType.None)
                LineItem curveMyMTF = paneMyMTF.AddCurve("MTF",  listMyMTF, Color.Blue,        SymbolType.None);
                LineItem curveMTF1  = paneMyMTF.AddCurve("MTF1", listMTF1,  Color.Red,         SymbolType.None);
                //LineItem curveMTF2  = paneMyMTF.AddCurve("MTF2", listMTF2,  Color.Green,       SymbolType.None);
                //LineItem curveMTF3  = paneMyMTF.AddCurve("MTF3", listMTF3,  Color.YellowGreen, SymbolType.None);
                //LineItem curveMTF4  = paneMyMTF.AddCurve("MTF4", listMTF4,  Color.Orange,      SymbolType.None);   

                LineItem curveSFR  = paneMyMTF.AddCurve("SFR", listSFR,  Color.Black, SymbolType.None);
                LineItem curveSFRexe = paneMyMTF.AddCurve("SFRexe", listSFRexe, Color.Brown, SymbolType.None);

                // Вызываем метод AxisChange(), чтобы обновить данные об осях. 
                // В противном случае на рисунке будет показана только часть графика, 
                // которая умещается в интервалы по осям, установленные по умолчанию
                zGC_MyMTF.AxisChange();

                // Обновляем график
                zGC_MyMTF.Invalidate();
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            }

            Status = "Calculation succeeded.";
        }

        /// <summary>
        /// Normalizes a function so that its maximum value is unity.
        /// Нормализует функцию так, чтобы ее максимальное значение было равно единице. 
        /// </summary>
        /// <param name="x"></param>
        private void Normalize(double[] x)
        {
            double maximum = 0.0;

            for (int i = 0; i < x.Length; i++)
            {
                if (x[i] > maximum) maximum = x[i];
            }

            for (int i = 0; i < x.Length; i++)
            {
                x[i] = x[i] / maximum;
            }
        }

        /// <summary>
        /// Smooth the input using a simple averaging window.
        /// Сглаживание входных данных, используя простое окно усреднения. 
        /// </summary>
        /// <param name="x">Function to be smoothed.</param>
        /// <param name="n">Smoothing kernel length.</param>
        private void Smooth(double[] x, int n)
        {
            if (n > 0)
            {
                double[] y = new double[x.Length];

                for (int i = 0; i < x.Length; i++)
                {
                    y[i] = 0.0;
                }

                for (int i = 0; i < x.Length; i++)
                {
                    for (int j = 0; j < n; j++)
                    {
                        int k = Math.Min(x.Length - 1, Math.Max(0, i - (j - n / 2)));

                        y[i] = y[i] + x[k] / n;
                    }
                }

                for (int i = 0; i < x.Length; i++)
                {
                    x[i] = y[i];
                }
            }
        }

        private void optionsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Options previousOptions = options.Clone() as Options;

            optionsForm.ShowDialog();

            graphPanelMTF.XUnits = options.XUnits;
            graphPanelMTF.YUnits = options.YUnits;

            if (previousOptions.PixelSpacing != options.PixelSpacing)
            {
                if (graphPanelMTF.X != null)
                {
                    double samplingFrequency = 1 / options.PixelSpacing;

                    for (int i = 0; i < graphPanelMTF.X.Length; i++)
                    {
                        graphPanelMTF.X[i] = ((float)i / graphPanelMTF.X.Length) * (samplingFrequency / 2);
                    }

                    graphPanelMTF.Limits = new RectangleF(0.0f, -0.1f, (float)(samplingFrequency / 2), 1.2f);
                }
            }

            if (previousOptions.AveragingWindowLength != options.AveragingWindowLength ||
                previousOptions.CropRectangle != options.CropRectangle ||
                previousOptions.SmoothingKernelLength != options.SmoothingKernelLength)
            {
                if (bitmap != null)
                {
                    Compute(bitmap);
                }
            }

            graphPanelLSF.Invalidate();
            graphPanelMTF.Invalidate();
        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (filename != string.Empty)
            {
                Save();
            }
            else
            {
                saveAsToolStripMenuItem_Click(this, EventArgs.Empty);
            }
        }

        private void saveAsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            // если картинка была загружена
            if (graphPanelMTF.X != null && graphPanelMTF.Y != null)
            {
                SaveFileDialog dialog = new SaveFileDialog();

                dialog.Filter = "Comma-Separated Values (*.csv)|*.csv";

                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    filename = dialog.FileName;

                    Save();
                }
            }
            else    // иначе если картина не была загружена, то вывести сообщение
            {
                //MessageBox.Show("An image must be loaded before saving the Modulation Transfer Function.",
                MessageBox.Show("Перед сохранением функции передачи модуляции необходимо загрузить изображение.",
                    Resource.MessageBoxCaption);
            }
        }

        /*
            https://habr.com/ru/post/247385/
            Метод сглаживания графика данных для "восстановления срезанных пиков"
        */
        public static Dictionary<double, double> Antialiasing(Dictionary<double, double> spectrum)
        {
            var result = new Dictionary<double, double>();
            var data = spectrum.ToList();
            for (var j = 0; j < spectrum.Count - 4; j++)
            {
                var i = j;
                var x0 = data[i].Key;
                var x1 = data[i + 1].Key;   
                var y0 = data[i].Value;
                var y1 = data[i + 1].Value;

                var a = (y1 - y0) / (x1 - x0);
                var b = y0 - a * x0;

                i += 2;
                var u0 = data[i].Key;
                var u1 = data[i + 1].Key;
                var v0 = data[i].Value;
                var v1 = data[i + 1].Value;

                var c = (v1 - v0) / (u1 - u0);
                var d = v0 - c * u0;

                var x = (d - b) / (a - c);
                var y = (a * d - b * c) / (a - c);

                if (y > y0 && y > y1 && y > v0 && y > v1 &&
                    x > x0 && x > x1 && x < u0 && x < u1)
                {
                    result.Add(x1, y1);
                    result.Add(x, y);
                }
                else
                {
                    result.Add(x1, y1);
                }
            }

            return result;
        }
    }
}
