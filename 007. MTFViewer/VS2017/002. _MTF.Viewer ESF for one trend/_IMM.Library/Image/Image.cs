namespace _IMM.Library
{
    using System;
    using System.Drawing;
    using System.Drawing.Drawing2D;
    using System.Windows.Media.Imaging;
    using System.Windows;

    using Core = _AVM.Library.Core;
    using System.IO;
    using System.Drawing.Imaging;
    using System.Runtime.InteropServices;

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
                    //pixel[36, 70].Gray = byte.MinValue; // black
                    //pixel[36, 71].Gray = byte.MaxValue; // white

                    BitmapSource source = Core.Image._8bit.Create(pixel);
                    JpegBitmapEncoder encoder = new JpegBitmapEncoder();

                    Core.Image.ToFile("01SourceWithBlackPoint.jpg", source, encoder); 
                    /////////////////////////////////////////////////////////////////////////////////////////

                    int width = pixel.GetLength(0), height = pixel.GetLength(1);

                    int[,] iPixel = new int[width, height];

                    for (int i = 0; i < width; i++)
                    {
                        for (int j = 0; j < height; j++)
                        {
                            iPixel[i, j] = Convert.ToInt32(pixel[i, j].Gray);
                        }
                    }
  
                    Rectangle cropRectangle = options.CropRectangle;
                    cropRectangle.Width = width;
                    cropRectangle.Height = height;

                    Bitmap croppedBitmap = FromTwoDimIntArrayGray(iPixel);      // обрезанный рисунок

                    croppedBitmap.Save("02FillCroppedBitmap.jpg", System.Drawing.Imaging.ImageFormat.Jpeg);

                    //-----------------------------------------------Brightness averaging------------------------------------------------

                    // 2. Находим усреднённые значения яркости пикселей сверху и снизу.//////////////////////////////////////////////////

                    int topEdge = 0;                                                       // верхний край
                    int bottomEdge = 0;                                                    // нижний край

                    double topAverage = 0.0;                                               // усреднённое значение яркости верхних "вертикальных" 8-и пикселей
                    double bottomAverage = 0.0;                                            // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

                    // Вычисление усреднённого значения яркости верхних "вертикальных" 8-и пикселей 'topAverage'_________________________

                    for (int i = 0; i < width; i++)
                    {
                        for (int j = 0; j < options.AveragingWindowLength; j++)
                        {
                            topAverage += pixel[i, j].Gray;
                        }
                    }

                    topAverage /= width * options.AveragingWindowLength;     // усреднённое значение яркости верхних "вертикальных" 8-и пикселей

                    // Вычисление усреднённого значения яркости нижних "вертикальных" 8-и пикселей 'bottomAverage'_______________________

                    for (int i = 0; i < width; i++)
                    {
                        for (int j = height - 1 - options.AveragingWindowLength; j < height - 1; j++)
                        {
                            bottomAverage += pixel[i, j].Gray;
                        }
                    }

                    bottomAverage /= width * options.AveragingWindowLength;  // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

                    // 3. Находим первое место, где текущее скользящее среднее пересекает среднее в верхней части изображения.///////////

                    double runningAverage = 0.0;                                           // текущее скользящее среднее 
                    double previousAverage = 0.0;                                          // предыдущее скользящее среднее

                    // Вычисление начального скользящего среднего яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины'

                    for (int j = 0; j < options.AveragingWindowLength; j++)
                    {
                        runningAverage += pixel[0, j].Gray / options.AveragingWindowLength;
                    }

                    for (int i = 1; i < width; i++)                          // цикл сравнения всех 8-пиксельных вертикальных "срезов"
                    {
                        previousAverage = runningAverage;
                        runningAverage = 0.0;

                        for (int j = 0; j < options.AveragingWindowLength; j++)
                        {
                            runningAverage += pixel[i, j].Gray / options.AveragingWindowLength;
                        }

                        if ((previousAverage < topAverage && runningAverage >= topAverage) ||
                            (previousAverage > topAverage && runningAverage <= topAverage))
                        {
                            topEdge = i;

                            break;
                        }
                    }

                    // 4. Находим первое место, где текущее скользящее среднее пересекает среднее в нижней части изображения.////////////

                    runningAverage = 0.0;                                                  // текущее скользящее среднее 
                    previousAverage = 0.0;                                                 // предыдущее скользящее среднее

                    // Вычисление начального скользящего среднего яркости нижних "вертикальных" 8-и пикселей '0-го столбца ширины'

                    for (int j = 0; j < options.AveragingWindowLength; j++)
                    {
                        runningAverage += pixel[0, height - 1 - j].Gray / options.AveragingWindowLength;
                    }

                    for (int i = 1; i < width; i++)
                    {
                        previousAverage = runningAverage;                                  // предыдущее среднее
                        runningAverage = 0.0;                                              // текущее значение скользящего среднего 

                        for (int j = 0; j < options.AveragingWindowLength; j++)
                        {
                            runningAverage += pixel[i, height - 1 - j].Gray / options.AveragingWindowLength;
                        }

                        if ((previousAverage < bottomAverage && runningAverage >= bottomAverage) ||
                            (previousAverage > bottomAverage && runningAverage <= bottomAverage))
                        {
                            bottomEdge = i;

                            break;
                        }
                    }

                    //-----------------------------------------Calculating Edge Spread Function -----------------------------------------

                    // 5. Рассчитаем требуемый угол поворота.//////////////////////////////////////////////////////////////////////////// 

                    double angle = Math.Atan2(Math.Abs(bottomEdge - topEdge), height - options.AveragingWindowLength) * 180 / Math.PI;
                    angle = Math.Round(angle);

                    if (Math.Abs(angle) > 15.0)
                    {
                        Console.WriteLine("Значительная часть изображения может быть потеряна, поскольку требуемый угол поворота превышает 15 градусов." +
                            "Убедитесь, что у вас правильное изображение и правильный прямоугольник обрезки. ");
                    }

                    // 6. Отразить изображение по горизонтали, если край идет справа налево./////////////////////////////////////////////
                    if (bottomEdge < topEdge)
                    {
                        croppedBitmap.RotateFlip(RotateFlipType.Rotate180FlipX);
                    }
                    croppedBitmap.Save("03RotateCroppedBitmap.jpg", System.Drawing.Imaging.ImageFormat.Jpeg);

                    // 7. Вычислить смещения обрезки на основе угла поворота.////////////////////////////////////////////////////////////

                    int w = (int)Math.Ceiling(width * Math.Tan(angle * Math.PI / 180));
                    int h = (int)Math.Ceiling(height * Math.Tan(angle * Math.PI / 180));

                    // 8. Повернуть и сдвинуть изображение соответствующим образом.////////////////////////////////////////////////////// 

                    if (width - h <= 0 || height - w <= 0)
                    {
                        Console.WriteLine("После обрезки и поворота осталось недостаточно изображения для продолжения. Убедитесь, что у вас правильное" +
                            "изображение и правильный прямоугольник обрезки.");

                        return null;
                    }
                    croppedBitmap.Save("04ShiftCroppedBitmap.jpg", System.Drawing.Imaging.ImageFormat.Jpeg);

                    // выпрямленное растровое изображение 
                    Bitmap straightenedBitmap = new Bitmap(croppedBitmap.Width - h, croppedBitmap.Height - w);

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
                    straightenedBitmap.Save("05StraightenedBitmap.jpg", System.Drawing.Imaging.ImageFormat.Jpeg);

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
                        points[i] = new System.Windows.Point(steps[i], real[i]);
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

        public static Bitmap FromTwoDimIntArrayGray(Int32[,] data)
        {
            // Transform 2-dimensional Int32 array to 1-byte-per-pixel byte array
            Int32 width = data.GetLength(0);
            Int32 height = data.GetLength(1);
            Int32 byteIndex = 0;
            Byte[] dataBytes = new Byte[height * width];
            for (Int32 y = 0; y < height; y++)
            {
                for (Int32 x = 0; x < width; x++)
                {
                    // logical AND to be 100% sure the int32 value fits inside
                    // the byte even if it contains more data (like, full ARGB).
                    dataBytes[byteIndex] = (Byte)(((UInt32)data[x, y]) & 0xFF);
                    // More efficient than multiplying
                    byteIndex++;
                }
            }
            // generate palette
            Color[] palette = new Color[256];
            for (Int32 b = 0; b < 256; b++)
                palette[b] = Color.FromArgb(b, b, b);
            // Build image
            return BuildImage(dataBytes, width, height, width, PixelFormat.Format8bppIndexed, palette, null);
        }

        /// <summary>
        /// Creates a bitmap based on data, width, height, stride and pixel format.
        /// </summary>
        /// <param name="sourceData">Byte array of raw source data</param>
        /// <param name="width">Width of the image</param>
        /// <param name="height">Height of the image</param>
        /// <param name="stride">Scanline length inside the data</param>
        /// <param name="pixelFormat">Pixel format</param>
        /// <param name="palette">Color palette</param>
        /// <param name="defaultColor">Default color to fill in on the palette if the given colors don't fully fill it.</param>
        /// <returns>The new image</returns>
        public static Bitmap BuildImage(Byte[] sourceData, Int32 width, Int32 height, Int32 stride, PixelFormat pixelFormat, Color[] palette, Color? defaultColor)
        {
            Bitmap newImage = new Bitmap(width, height, pixelFormat);
            BitmapData targetData = newImage.LockBits(new Rectangle(0, 0, width, height), ImageLockMode.WriteOnly, newImage.PixelFormat);
            Int32 newDataWidth = ((System.Drawing.Image.GetPixelFormatSize(pixelFormat) * width) + 7) / 8;
            // Compensate for possible negative stride on BMP format.
            Boolean isFlipped = stride < 0;
            stride = Math.Abs(stride);
            // Cache these to avoid unnecessary getter calls.
            Int32 targetStride = targetData.Stride;
            Int64 scan0 = targetData.Scan0.ToInt64();
            for (Int32 y = 0; y < height; y++)
                Marshal.Copy(sourceData, y * stride, new IntPtr(scan0 + y * targetStride), newDataWidth);
            newImage.UnlockBits(targetData);
            // Fix negative stride on BMP format.
            if (isFlipped)
                newImage.RotateFlip(RotateFlipType.Rotate180FlipX);
            // For indexed images, set the palette.
            if ((pixelFormat & PixelFormat.Indexed) != 0 && palette != null)
            {
                ColorPalette pal = newImage.Palette;
                for (Int32 i = 0; i < pal.Entries.Length; i++)
                {
                    if (i < palette.Length)
                        pal.Entries[i] = palette[i];
                    else if (defaultColor.HasValue)
                        pal.Entries[i] = defaultColor.Value;
                    else
                        break;
                }
                newImage.Palette = pal;
            }
            return newImage;
        }
    }
}
