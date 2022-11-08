namespace _IMM.Library
{
    using System;
    using System.Drawing;
    using System.Drawing.Drawing2D;
    using System.Windows.Media.Imaging;
    using System.Windows;

    using Core = _AVM.Library.Core;
    using System.IO;

    public partial class Image
    {
        internal static Options options = new Options();

        /// <summary>Edge Spread Function</summary>
        public static class ESF
        {
            /// <summary>
            /// 
            /// </summary>
            /// <param name="pixel"></param>
            public static System.Windows.Point[] Compute(Core.Image._8bit.Pixel[,] pixel)
            {
                if (pixel != null)
                {
                    ///////////////////////////////////////////TEST//////////////////////////////////////////
                    pixel[36, 70].Gray = byte.MinValue; // black
                    pixel[36, 71].Gray = byte.MaxValue; // white

                    BitmapSource source = Core.Image._8bit.Create(pixel);
                    JpegBitmapEncoder encoder = new JpegBitmapEncoder();

                    Core.Image.ToFile("test.jpg", source, encoder);
                    /////////////////////////////////////////////////////////////////////////////////////////

                    int width = pixel.GetLength(0), height = pixel.GetLength(1);
                    int topEdge = 0, bottomEdge = 0; // верхний и нижний край

                    double topAverage = 0.0, bottomAverage = 0.0; // усреднённое значение яркости верхних и нижних "вертикальных" 8-и пикселей


                    ////////////////////////////////////////////TXT//////////////////////////////////////////
                    int topEdgeTXT = 0, bottomEdgeTXT = 0;
                    double topAverageTXT = 0.0, bottomAverageTXT = 0.0;

                    // проверка существования папки 'txt'
                    if (!Directory.Exists("txt")) Directory.CreateDirectory("txt");

                    StreamWriter sr0 = new StreamWriter(@"txt\The brightness of all pixels of the bitmap.txt");

                    // цикл по ширине croppedBitmap.Width объекта Image в точках
                    for (int i = 0; i < width; i++)
                    {
                        // цикл по высоте объекта Image в точках
                        for (int j = 0; j < height; j++)
                        {
                            sr0.Write("Width = " + i.ToString("000") + "\t" + "Height = " + j.ToString("000") + "\t"
                                + pixel[i, j].Gray.ToString("F9") + "\n");
                        }
                    }

                    sr0.Close();
                    /////////////////////////////////////////////////////////////////////////////////////////

                    // Вычисление усреднённого значения яркости верхних "вертикальных" 8-и пикселей

                    ////////////////////////////////////////////TXT//////////////////////////////////////////
                    StreamWriter sr1 = new StreamWriter(@"txt\Brightness and current topAverage.txt");
                    /*
                        croppedBitmap.Width - ширина объекта Image в точках.
                        Averaging Window Length (Длина окна усреднения) - количество строк для усреднения при вычислении 
                        среднего значения в пикселях вверху и внизу изображения. В Options.cs задано averagingWindowLength = 8
                    */
                    // цикл по ширине объекта Image в точках
                    for (int i = 0; i < width; i++)
                    {
                        // цикл по первым 'AveragingWindowLength' = 8 строкам объекта Image, т.е. j = 0, 1, 2, 3, 4, 5, 6, 7 
                        for (int j = 0; j < options.AveragingWindowLength; j++)
                        {
                            // Σtop8 - Сумма яркостей всех пикселей по всей ширине картинки верхних 8-ми строк 
                            topAverageTXT += pixel[i, j].Gray;

                            sr1.Write(j.ToString("000") + "\tBrightness = " + pixel[i, j].Gray.ToString("F9")
                                + "\tCurrentTopAverage = " + topAverageTXT.ToString("000.0000000000000") + "\n");
                        }
                    }
                    double topAverageTXTCurrent = topAverageTXT;

                    sr1.Close();
                    /////////////////////////////////////////////////////////////////////////////////////////

                    for (int i = 0; i < width; i++)
                        for (int j = 0; j < options.AveragingWindowLength; j++)
                            topAverage += pixel[i, j].Gray;
                    topAverage /= width * options.AveragingWindowLength; // усреднённое значение яркости верхних "вертикальных" 8-и пикселей

                    // Вычисление усреднённого значения яркости нижних "вертикальных" 8-и пикселей

                    ////////////////////////////////////////////TXT//////////////////////////////////////////
                    StreamWriter sr2 = new StreamWriter(@"txt\Brightness and current bottomAverage.txt");
                    /*
                        croppedBitmap.Width - ширина объекта Image в точках.
                        Averaging Window Length (Длина окна усреднения) - количество строк для усреднения при вычислении 
                        среднего значения в пикселях вверху и внизу изображения. В Options.cs задано averagingWindowLength = 8
                    */
                    // цикл по ширине объекта Image в точках
                    for (int i = 0; i < width; i++)
                    {
                        // цикл по последним 'AveragingWindowLength' = 8 строкам объекта Image, т.е. j = Height - 1 - 8, ..., Height - 1 - 1
                        for (int j = height - 1 - options.AveragingWindowLength; j < height - 1; j++)
                        {
                            // Σbottom8 - Сумма яркостей всех пикселей по всей ширине картинки нижних 8-ми строк 
                            bottomAverageTXT += pixel[i, j].Gray;

                            sr2.Write(j + "\tBrightness = " + pixel[i, j].Gray.ToString("F9") +
                                "\tCurrentbottomAverage = " + bottomAverageTXT.ToString("000.0000000000000") + "\n");
                        }
                    }
                    double bottomAverageTXTCurrent = bottomAverageTXT;

                    sr2.Close();
                    /////////////////////////////////////////////////////////////////////////////////////////

                    for (int i = 0; i < width; i++)
                        for (int j = height - 1 - options.AveragingWindowLength; j < height - 1; j++)
                            bottomAverage += pixel[i, j].Gray;
                    bottomAverage /= width * options.AveragingWindowLength;  // усреднённое значение яркости нижних "вертикальных" 8-и пикселей
                   
                    // Находим первое место, где текущее скользящее среднее пересекает среднее в верхней части изображения
                    double runningAverage = 0.0, previousAverage = 0.0; // текущее и предыдущее скользящее среднее

                    ////////////////////////////////////////////TXT//////////////////////////////////////////
                    double runningAverageTXT = 0.0, previousAverageTXT = 0.0;

                    StreamWriter sr3 = new StreamWriter(@"txt\Brightness and current top_moving_average_0.txt");

                    // цикл по длине окна усреднения
                    for (int j = 0; j < options.AveragingWindowLength; j++)     // j = 0, 1, 2, 3, 4, 5, 6, 7
                    {
                        /*
                            начальное скользящее среднее яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины' объекта Image,
                            top_moving_average_0 = Σtop(w0,h8) / AWL, где Σtop(w0,h8) - 
                            сумма яркостей 'AveragingWindowLength' = 8 верхних пикселей '0-го столбца ширины' объекта Image
                        */
                        runningAverageTXT += pixel[0, j].Gray / options.AveragingWindowLength;     // top_moving_average_0

                        sr3.Write("Brightness = " + pixel[0, j].Gray.ToString("F9") +
                            "\tTop_moving_average_0 = " + runningAverageTXT.ToString("F18") + "\n");
                    }

                    sr3.Close();
                    /////////////////////////////////////////////////////////////////////////////////////////

                    // Вычисление начального скользящего среднего яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины'
                    for (int j = 0; j < options.AveragingWindowLength; j++)
                        runningAverage += pixel[0, j].Gray / options.AveragingWindowLength;


                    ////////////////////////////////////////////TXT//////////////////////////////////////////

                    StreamWriter sr4 = new StreamWriter(@"txt\Top Edge.txt");

                    // цикл по ширине объекта Image в точках, начиная с '1-го столбца ширины'
                    for (int i = 1; i < width; i++)       // цикл сравнения всех 8-пиксельных вертикальных "срезов" *
                    {
                        previousAverageTXT = runningAverageTXT;       // предыдущее среднее (при i = 0 previousAverage = top_moving_average_0)
                        runningAverageTXT = 0.0;                  // текущее значение скользящего среднего 

                        // цикл по длине окна усреднения
                        for (int j = 0; j < options.AveragingWindowLength; j++)     // j = 0, 1, 2, 3, 4, 5, 6, 7
                        {
                            runningAverageTXT += pixel[i, j].Gray / options.AveragingWindowLength;     // top_moving_average(wi,h8)
                        }

                        if ((previousAverageTXT < topAverageTXT && runningAverageTXT >= topAverageTXT) ||
                            (previousAverageTXT > topAverageTXT && runningAverageTXT <= topAverageTXT))
                        {
                            topEdgeTXT = i;

                            sr4.Write("topEdge = " + topEdgeTXT.ToString() + "\n");

                            break;
                        }
                    }

                    sr4.Close();
                    /////////////////////////////////////////////////////////////////////////////////////////


                    for (int i = 1; i < width; i++) // цикл сравнения всех 8-пиксельных вертикальных "срезов"
                    {
                        previousAverage = runningAverage;
                        runningAverage = 0.0;

                        for (int j = 0; j < options.AveragingWindowLength; j++)
                            runningAverage += pixel[i, j].Gray / options.AveragingWindowLength;

                        if ((previousAverage < topAverage && runningAverage >= topAverage) ||
                            (previousAverage > topAverage && runningAverage <= topAverage))
                        {
                            topEdge = i; break;
                        }
                    }

                    //Находим первое место, где текущее скользящее среднее пересекает среднее в нижней части изображения
                    runningAverage = 0.0; previousAverage = 0.0; // текущее и предыдущее скользящее среднее
                    // Вычисление начального скользящего среднего яркости нижних "вертикальных" 8-и пикселей '0-го столбца ширины'
                    for (int j = 0; j < options.AveragingWindowLength; j++)
                    {
                        runningAverage += pixel[0, height - 1 - j].Gray / options.AveragingWindowLength;
                    }
                    for (int i = 1; i < width; i++)
                    {
                        previousAverage = runningAverage; // предыдущее среднее
                        runningAverage = 0.0; // текущее значение скользящего среднего 
                        for (int j = 0; j < options.AveragingWindowLength; j++)
                        {
                            runningAverage += pixel[0, height - 1 - j].Gray /
                                options.AveragingWindowLength;
                        }
                        if ((previousAverage < bottomAverage && runningAverage >= bottomAverage) ||
                            (previousAverage > bottomAverage && runningAverage <= bottomAverage))
                        {
                            bottomEdge = i; break;
                        }
                    }
                    // Calculating Edge Spread Function
                    // Рассчитаем требуемый угол поворота
                    double angle = Math.Atan2(Math.Abs(bottomEdge - topEdge),
                        height - options.AveragingWindowLength) * 180 / Math.PI;
                    angle = Math.Round(angle);
                    /*if (Math.Abs(angle) > 15.0)
                    {
                         throw new Exception("Значительная часть изображения может быть потеряна, поскольку требуемый угол поворота превышает 15 градусов." +
                            "Убедитесь, что у вас правильное изображение и правильный прямоугольник обрезки. ");
                    }*/
                    // Отразить изображение по горизонтали, если край идет справа налево.
                    if (bottomEdge < topEdge)
                    {
                        //croppedBitmap.RotateFlip(RotateFlipType.Rotate180FlipX);
                    }
                    // Вычислить смещения обрезки на основе угла поворота.
                    int w = (int)Math.Ceiling(width * Math.Tan(angle * Math.PI / 180));
                    int h = (int)Math.Ceiling(height * Math.Tan(angle * Math.PI / 180));
                    // Повернуть и сдвинуть изображение соответствующим образом. 
                    if (width - h <= 0 || height - w <= 0)
                    {
                        Console.WriteLine("После обрезки и поворота осталось недостаточно изображения для продолжения. Убедитесь, что у вас правильное" +
                            "изображение и правильный прямоугольник обрезки.");
                        return null;
                    }
                    // выпрямленное растровое изображение 
                    Bitmap straightenedBitmap = new Bitmap(width - h, height - w);

                    using (Graphics g = Graphics.FromImage(straightenedBitmap))
                    {
                        Matrix m = new Matrix();

                        m.Rotate((float)angle);

                        g.SmoothingMode = SmoothingMode.AntiAlias;
                        g.Transform = m;

                        // Рисует заданную часть указанного объекта System.Drawing.Image в заданном месте, используя заданный размер.
                        g.DrawImage(straightenedBitmap, new Rectangle(0, -w, width, height),
                            new Rectangle(0, 0, width, height), GraphicsUnit.Pixel);
                    }
                    // собственно расчет массива значений Edge Spread Function
                    int imageWidth = straightenedBitmap.Width;                             // ширина выпрямленного растрового изображения в пикселях

                    double[] real = new double[imageWidth];

                    for (int i = 0; i < imageWidth; i++)
                    {
                        real[i] = 0.0;

                        for (int j = 0; j < straightenedBitmap.Height; j++)
                        {
                            real[i] += (straightenedBitmap as Bitmap).GetPixel(i, j).GetBrightness() / straightenedBitmap.Height;
                        }
                    }

                    // алгоритм разворачивания ESF относительно вертикали, если слева белая область
                    double sum = 0;                                                        // признак белой области слева

                    for (int i = 0; i < 10; i++)
                    {
                        sum += real[i];
                    }

                    sum /= 10;

                    if (sum > 0.8) Array.Reverse(real);                                    // вернёт массив в обратном порядке

                    // рассчитать нормированный к диапазону quickmtf массив шагов ESF
                    double range_quickmtf = 400;                                           // диапазон значений ESF в quickmtf
                    double step_quickmtf = 0.1;                                            // шаг значений ESF в quickmtf
                    double startOfRange = -20.0;                                           // начальное значение диапазона значений ESF в quickmtf

                    double step = (range_quickmtf / real.Length) * step_quickmtf;          // нормированный к диапазону quickmtf шаг ESF

                    double[] steps = new double[imageWidth];                               // массив нормированных к диапазону quickmtf шагов ESF

                    for (int i = 0; i < imageWidth; i++)
                    {
                        steps[i] = startOfRange + step * i;
                    }

                    // Алгоритм нахождения смещения относительно значения 0.5

                    double shift = 0;                                                      // смещение относительно значения 0.5     

                    // найдем значение смещения относительно масштабированных значений абсциссы steps[i] 
                    for (int i = 0; i < imageWidth; i++)
                    {
                        // как только значение real >= 0.5 - нашли смещение
                        if (real[i] >= 0.5)
                        {
                            shift = steps[i];
                            break;
                        }
                    }

                    // смещаем график ESF относительно масштабированных значений абсциссы steps[i] на значение shift
                    for (int i = 0; i < imageWidth; i++)
                    {
                        steps[i] = steps[i] - shift;
                    }

                    System.Windows.Point[] points = new System.Windows.Point[imageWidth];
                    for (int i = 0; i < imageWidth; i++)
                    {
                        points[i] = new System.Windows.Point(real[i], steps[i]);
                    }

                    return points;
                }
                return null;
            }
        }

        public static class LSF
        {
            /// <summary>
            /// 
            /// </summary>
            /// <param name="pixel"></param>
            public static System.Windows.Point[] Compute(System.Windows.Point[] points)
            {
                return null;
            }
        }

        public static class MTF
        {
            /// <summary>
            /// 
            /// </summary>
            /// <param name="pixel"></param>
            public static System.Windows.Point[] Compute(System.Windows.Point[] points)
            {
                return null;
            }
        }
    }
}
