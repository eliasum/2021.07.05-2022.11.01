/*2021.07.15 17:13 IMM*/

using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Text;
using System.Windows.Forms;
using System.Xml.Serialization;
using ZedGraph;

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

            optionsForm.Owner                       = this;
            optionsForm.PropertyGrid.SelectedObject = options;

            graphPanelLSF.BackColor   = Color.White;
            graphPanelLSF.BorderStyle = BorderStyle.None;
            graphPanelLSF.Dock        = DockStyle.Fill;

            tabLSF.Controls.Add(graphPanelLSF);

            graphPanelMTF.BackColor   = Color.White;
            graphPanelMTF.BorderStyle = BorderStyle.None;
            graphPanelMTF.Dock        = DockStyle.Fill;

            tabMTF.Controls.Add(graphPanelMTF);

            toolStripStatusLabel.Text = "Open an image to calculate the Modulation Transfer Function.";
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
        /// </summary>
        private void TestA()
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

            graphPanelMTF.Y   = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, (float)(Math.PI), n / 4);
        }

        /// <summary>
        /// Ideal Line Spread Function (LSF).
        /// </summary>
        private void TestB()
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

            graphPanelMTF.Y   = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 1.0f, 1.2f);
        }

        /// <summary>
        /// Non-ideal Line Spread Function (LSF).
        /// </summary>
        private void TestC()
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

            graphPanelMTF.Y   = m;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 1.0f, 2.2f);
        }

        /// <summary>
        /// Conversion of a step response to a Line Spread Function (LSF).
        /// </summary>
        private void TestD()
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

            double[] difference = new double[n];

            for (int i = 0; i < n - 1; i++)
            {
                difference[i] = real[i] - real[i + 1];
            }

            // Use the discrete derivative, which is the LSF, to compute the MTF.

            MTF.HannWindow(difference);

            double[] padded = MTF.ZeroPad(difference);

            MTF.Compute(padded);

            double[] mtf = new double[padded.Length / 2];

            for (int i = 0; i < padded.Length / 2; i++)
            {
                mtf[i] = padded[i];
            }

            graphPanelMTF.Y   = mtf;
            graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, 8.0f, 1.0f);
        }

        /// <summary>
        /// Load an image and display the MTF.
        /// </summary>
        private void TestE()
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

                    MTF.HannWindow(difference);

                    double[] padded = MTF.ZeroPad(difference);

                    MTF.Compute(padded);

                    graphPanelMTF.Y = new double[padded.Length / 2];

                    for (int i = 0; i < padded.Length / 2; i++)
                    {
                        graphPanelMTF.Y[i] = padded[i];
                    }

                    double pixelWidth        = 0.1;                 // mm
                    double samplingFrequency = 1 / pixelWidth;      // cycles / mm

                    graphPanelMTF.X = new double[padded.Length / 2];

                    for (int i = 0; i < padded.Length / 2; i++)
                    {
                        graphPanelMTF.X[i] = ((float)i / (padded.Length / 2)) * (samplingFrequency / 2);
                    }

                    graphPanelMTF.Limits = new RectangleF(0.0f, 0.0f, (float)(samplingFrequency / 2), 1.0f);
                    graphPanelMTF.XUnits = "cycles / mm";
                }
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

            //-----------------------------------------------Brightness averaging------------------------------------------------

            // 2. Find the average pixel values across the top and bottom.///////////////////////////////////////////////////////
            // 2. Находим усреднённые значения яркости пикселей сверху и снизу.//////////////////////////////////////////////////

            Status = "Straightening ...";       // Выпрямление 

            int topEdge    = 0;                 // верхний край
            int bottomEdge = 0;                 // нижний край

            double topAverage    = 0.0;         // усреднённое значение яркости верхних "вертикальных" 8-и пикселей
            double bottomAverage = 0.0;         // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

            StreamWriter sr0 = new StreamWriter(@"The brightness of all pixels of the bitmap.txt");

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

            StreamWriter sr1 = new StreamWriter(@"Brightness and current topAverage.txt");
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

            StreamWriter sr2 = new StreamWriter(@"Brightness and current bottomAverage.txt");
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

            double runningAverage  = 0.0;       // текущее скользящее среднее 
            double previousAverage = 0.0;       // предыдущее скользящее среднее

            // Вычисление начального скользящего среднего яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины' - 'top_moving_average_0'

            StreamWriter sr3 = new StreamWriter(@"Brightness and current top_moving_average_0.txt");

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

            StreamWriter sr4 = new StreamWriter(@"Top Edge.txt");

            // цикл по ширине объекта Image в точках, начиная с '1-го столбца ширины'
            for (int i = 1; i < croppedBitmap.Width; i++)       // цикл сравнения всех 8-пиксельных вертикальных "срезов" *
            {
                previousAverage = runningAverage;       // предыдущее среднее (при i = 0 previousAverage = top_moving_average_0)
                runningAverage  = 0.0;                  // текущее значение скользящего среднего 

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

            StreamWriter sr5 = new StreamWriter(@"Brightness and current bottom_moving_average_0.txt");

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
                    bottomEdge = i; break;
                }
            }

            //-----------------------------------------Calculating Edge Spread Function -----------------------------------------

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

            int w = (int)Math.Ceiling(croppedBitmap.Width  * Math.Tan(angle * Math.PI / 180));
            int h = (int)Math.Ceiling(croppedBitmap.Height * Math.Tan(angle * Math.PI / 180));

            // 8. Rotate and translate the image as appropriate./////////////////////////////////////////////////////////////////
            // 8. Повернуть и сдвинуть изображение соответствующим образом.////////////////////////////////////////////////////// 

            if (croppedBitmap.Width - h <= 0 || croppedBitmap.Height - w <= 0)
            {
                //MessageBox.Show("Not enough of the image was left after cropping and rotating to proceed.  Make sure you have the right image and the right crop rectangle.", Resource.MessageBoxCaption);
                MessageBox.Show("После обрезки и поворота осталось недостаточно изображения для продолжения. Убедитесь, что у вас правильное изображение и правильный прямоугольник обрезки.", Resource.MessageBoxCaption);

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
                g.Transform     = m;

                // Рисует заданную часть указанного объекта System.Drawing.Image в заданном месте, используя заданный размер.
                g.DrawImage(croppedBitmap, new Rectangle(0, -w, croppedBitmap.Width, croppedBitmap.Height),
                    new Rectangle(0, 0, croppedBitmap.Width, croppedBitmap.Height), GraphicsUnit.Pixel);
            }
            
            graphPanelLSF.Panel.BackgroundImageLayout = ImageLayout.Stretch;    // растянуть изображение на всю длину клиентского прямоугольника
            graphPanelLSF.Panel.BackgroundImage       = straightenedBitmap;     // фоновое изображение во вкладке 'Line Spread Function'
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Status = "Calculating the Edge Spread Function ...";

            double[] real = new double[straightenedBitmap.Width];

            for (int i = 0; i < straightenedBitmap.Width; i++)
            {
                real[i] = 0.0;

                for (int j = 0; j < straightenedBitmap.Height; j++)
                {
                    real[i] += (straightenedBitmap as Bitmap).GetPixel(i, j).GetBrightness() / straightenedBitmap.Height;
                }
            }

            // вывод рассчитанных значений ESF в файл типа .csv
            using (var SW_ESF_array = new StreamWriter(@"ESF.csv", false, Encoding.Default))
            {
                SW_ESF_array.WriteLine("i;ESF");
                for (int i = 0; i < straightenedBitmap.Width; i++)
                    SW_ESF_array.WriteLine(i.ToString() + ";" + real[i].ToString());
            }
            
            // График ESF ///////////////////////////////////////////////////////////////////////////////////////////////////////

            // Получим панель для рисования
            GraphPane pane = zedGraph.GraphPane;

            // Очистим список кривых на тот случай, если до этого сигналы уже были нарисованы
            pane.CurveList.Clear();

            // Создадим список точек
            PointPairList list = new PointPairList();

            // Заполняем список точек
            for (int i = 0; i < straightenedBitmap.Width; i++)
            {
                // добавим в список точку
                list.Add(i, real[i]);
            }

            // Создадим кривую с названием "ESF", 
            // которая будет рисоваться голубым цветом (Color.Blue),
            // Опорные точки выделяться не будут (SymbolType.None)
            LineItem myCurve = pane.AddCurve("ESF", list, Color.Blue, SymbolType.None);

            // Вызываем метод AxisChange (), чтобы обновить данные об осях. 
            // В противном случае на рисунке будет показана только часть графика, 
            // которая умещается в интервалы по осям, установленные по умолчанию
            zedGraph.AxisChange();

            // Обновляем график
            zedGraph.Invalidate();
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Status = "Calculating the Line Spread Function ...";

            // Calculate the Line Spread Function from the step response.
            // Вычислить функцию растяжения линии по переходной характеристике. 

            double[] difference = new double[straightenedBitmap.Width];

            for (int i = 0; i < straightenedBitmap.Width - 1; i++)
            {
                difference[i] = real[i] - real[i + 1];
            }

            graphPanelLSF.X = new double[difference.Length];
            graphPanelLSF.Y = new double[difference.Length];

            for (int i = 0; i < difference.Length; i++)
            {
                graphPanelLSF.X[i] = (double)(i) * options.PixelSpacing;
                graphPanelLSF.Y[i] = difference[i];
            }

            graphPanelLSF.Color = Color.Red;
            graphPanelLSF.Limits = new RectangleF(0.0f, -1.0f, (float)(difference.Length) * (float)(options.PixelSpacing), 2.0f);

            // Window the LSF.

            Status = "Calculating the Modulation Transfer Function ...";

            MTF.HannWindow(difference);

            // Pad the windowed Line Spread Function with zeros until its length is equal to a power of 2.

            double[] padded = MTF.ZeroPad(difference);

            // Calculate the Modulation Transfer Function.

            MTF.Compute(padded);

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

            graphPanelMTF.Color           = Color.Black;
            graphPanelMTF.Limits          = new RectangleF(0.0f, -0.1f, (float)(samplingFrequency / 2), 1.2f);
            graphPanelMTF.TenPercentLine  = true;
            graphPanelMTF.XUnits          = options.XUnits;
            graphPanelMTF.YUnits          = options.YUnits;

            graphPanelLSF.Invalidate();
            graphPanelMTF.Invalidate();

            Status = "Calculation succeeded.";
        }

        /// <summary>
        /// Normalizes a function so that its maximum value is unity.
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
                previousOptions.CropRectangle         != options.CropRectangle ||
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
    }
}
