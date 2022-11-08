using System;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.IO;
using System.Drawing.Drawing2D;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Linq;

namespace LSF
{
    internal class Program
    {
        public static string InputFileName { get; set; }
        public static string OutputFileName { get; set; }

        // настройки программы
        public static Options options = new Options();

        [STAThread]
        private static void Main()
        {
            // загружаемый точечный рисунок
            Bitmap bitmap = null;

            OpenFileDialog dialog = new OpenFileDialog();

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                InputFileName = Path.GetFileName(dialog.FileName);

                try
                {
                    bitmap = (Bitmap)Bitmap.FromFile(dialog.FileName);
                }
                catch (Exception exception)
                {
                    Console.WriteLine("Ошибка загрузки " + System.IO.Path.GetFileName(dialog.FileName) + " по следующей причине: " + exception.Message);
                }

                if (bitmap != null && bitmap.Height > options.AveragingWindowLength && bitmap.Width > 0)
                {
                    Compute(bitmap);

                    Console.WriteLine("Данные LSF успешно записаны в файл " + OutputFileName + ". Для выхода нажмите любую клавишу...");
                    Console.ReadKey();
                }
                else
                {
                    Console.WriteLine("Невозможно использовать " + System.IO.Path.GetFileName(dialog.FileName) + " потому что чтение изображения вернуло" +
                        "значение null или потому что изображение было слишком маленьким.");
                    Console.WriteLine("Для выхода нажмите любую клавишу...");
                    Console.ReadKey();
                }
            }
            else
            {
                Console.WriteLine("Картинка не загружена!");
                Console.WriteLine("Для выхода нажмите любую клавишу...");
                Console.ReadKey();
            }
        }

        public static void Compute(Bitmap bitmap)
        {
            // 1. Обрезать изображение до прямоугольника обрезки, используя ширину и высоту изображения, если не указано другое значение. 

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

            using (Graphics g = Graphics.FromImage(croppedBitmap))
            {
                g.DrawImage(bitmap, new Rectangle(-cropRectangle.Left, -cropRectangle.Top, bitmap.Width, bitmap.Height),
                    new Rectangle(0, 0, bitmap.Width, bitmap.Height), GraphicsUnit.Pixel);
            }

            //-----------------------------------------------Brightness averaging------------------------------------------------

            // 2. Находим усреднённые значения яркости пикселей сверху и снизу.//////////////////////////////////////////////////

            int topEdge = 0;                                                       // верхний край
            int bottomEdge = 0;                                                    // нижний край

            double topAverage = 0.0;                                               // усреднённое значение яркости верхних "вертикальных" 8-и пикселей
            double bottomAverage = 0.0;                                            // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

            // Вычисление усреднённого значения яркости верхних "вертикальных" 8-и пикселей 'topAverage'_________________________

            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    topAverage += croppedBitmap.GetPixel(i, j).GetBrightness();
                }
            }

            topAverage /= croppedBitmap.Width * options.AveragingWindowLength;     // усреднённое значение яркости верхних "вертикальных" 8-и пикселей

            // Вычисление усреднённого значения яркости нижних "вертикальных" 8-и пикселей 'bottomAverage'_______________________

            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                for (int j = croppedBitmap.Height - 1 - options.AveragingWindowLength; j < croppedBitmap.Height - 1; j++)
                {
                    bottomAverage += croppedBitmap.GetPixel(i, j).GetBrightness();
                }
            }

            bottomAverage /= croppedBitmap.Width * options.AveragingWindowLength;  // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

            // 3. Находим первое место, где текущее скользящее среднее пересекает среднее в верхней части изображения.///////////

            double runningAverage = 0.0;                                           // текущее скользящее среднее 
            double previousAverage = 0.0;                                          // предыдущее скользящее среднее

            // Вычисление начального скользящего среднего яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины'

            for (int j = 0; j < options.AveragingWindowLength; j++)
            {
                runningAverage += croppedBitmap.GetPixel(0, j).GetBrightness() / options.AveragingWindowLength;     
            }

            for (int i = 1; i < croppedBitmap.Width; i++)                          // цикл сравнения всех 8-пиксельных вертикальных "срезов"
            {
                previousAverage = runningAverage;
                runningAverage = 0.0;

                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    runningAverage += croppedBitmap.GetPixel(i, j).GetBrightness() / options.AveragingWindowLength;
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
                runningAverage += croppedBitmap.GetPixel(0, croppedBitmap.Height - 1 - j).GetBrightness() / options.AveragingWindowLength;
            }

            for (int i = 1; i < croppedBitmap.Width; i++)
            {
                previousAverage = runningAverage;                                  // предыдущее среднее
                runningAverage = 0.0;                                              // текущее значение скользящего среднего 

                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    runningAverage += croppedBitmap.GetPixel(i, croppedBitmap.Height - 1 - j).GetBrightness() / options.AveragingWindowLength;
                }

                if ((previousAverage < bottomAverage && runningAverage >= bottomAverage) ||
                    (previousAverage > bottomAverage && runningAverage <= bottomAverage))
                {
                    bottomEdge = i; break;
                }
            }

            //-----------------------------------------Calculating Edge Spread Function -----------------------------------------

            // 5. Рассчитаем требуемый угол поворота.//////////////////////////////////////////////////////////////////////////// 

            double angle = Math.Atan2(Math.Abs(bottomEdge - topEdge), croppedBitmap.Height - options.AveragingWindowLength) * 180 / Math.PI;
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

            // 7. Вычислить смещения обрезки на основе угла поворота.////////////////////////////////////////////////////////////

            int w = (int)Math.Ceiling(croppedBitmap.Width * Math.Tan(angle * Math.PI / 180));
            int h = (int)Math.Ceiling(croppedBitmap.Height * Math.Tan(angle * Math.PI / 180));

            // 8. Повернуть и сдвинуть изображение соответствующим образом.////////////////////////////////////////////////////// 

            if (croppedBitmap.Width - h <= 0 || croppedBitmap.Height - w <= 0)
            {
                Console.WriteLine("После обрезки и поворота осталось недостаточно изображения для продолжения. Убедитесь, что у вас правильное" +
                    "изображение и правильный прямоугольник обрезки.");

                return;
            }

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

            // формирование имени файла данных LSF

            string output_string = null;                                           // имя файла тестируемой картинки без расширения

            // шаблон Regex - точка \.
            var pattern = @"\.";                                                   // расширение файла в полном имени файла тестируемой картинки

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
            if (!Directory.Exists("csv")) Directory.CreateDirectory("csv");        // имя файла тестируемой картинки без расширения

            OutputFileName = @"csv\" + output_string + @"_LSF.csv";                // имя файла с данными LSF

            //-----------------------------------------Calculating Line Spread Function -----------------------------------------

            // 9. Вычислить функцию растяжения линии по переходной характеристике. 

            Array.Reverse(real);                                                   // вернёт массив в обратном порядке

            double[] difference = new double[imageWidth];

            for (int i = 0; i < imageWidth - 1; i++)
            {
                difference[i] = real[i] - real[i + 1];
            }

            // Алгорим сглаживания графика данных LSF для "восстановления срезанных пиков" //////////////////////////////////////

            Dictionary<double, double> DdifferenceIn = new Dictionary<double, double>();
            Dictionary<double, double> DdifferenceOut = new Dictionary<double, double>();

            // запись данных LSF во входной словарь - аргумент метода Antialiasing()
            for (int i = 0; i < difference.Length; i++)
            {
                DdifferenceIn.Add(steps[i], difference[i]);
            }

            // сглаживание данных LSF и запись обработанных данных в выходной словарь, возвращаемый методом Antialiasing()
            DdifferenceOut = Antialiasing(DdifferenceIn);

            // заполнение массивов сглаженных данных LSF
            steps = DdifferenceOut.Keys.ToArray();
            difference = DdifferenceOut.Values.ToArray();

            // Алгоритм нахождения смещения относительно максимального значения

            double shiftLSF = 0;                                                   // смещение относительно максимального значения         
            double maxDouble = Double.MinValue;                                    // инициализация значения максимума       

            // найдем максимальное значение массива относительно исходных значений абсциссы i ///////////////////////////////////
            for (int i = 0; i < difference.Length; i++)
            {
                double value = difference[i];
                if (value > maxDouble)
                {
                    maxDouble = value;
                }
            }

            // найдем значение смещения относительно масштабированных значений абсциссы steps[i] ////////////////////////////////
            for (int i = 0; i < difference.Length; i++)
            {
                if (difference[i] == maxDouble)
                {
                    shiftLSF = steps[i];
                    break;
                }
            }

            // смещаем график LSF относительно масштабированных значений абсциссы steps[i] на значение shift ////////////////////
            for (int i = 0; i < difference.Length; i++)
            {
                steps[i] = steps[i] - shiftLSF;
            }

            // нормировка графика LSF относительно вертикальной оси /////////////////////////////////////////////////////////////
            double delta = 0;

            if (maxDouble < 1)
            {
                delta = 1 / maxDouble;

                for (int i = 0; i < difference.Length; i++)
                {
                    difference[i] *= delta;
                }
            }

            // запись в файл исходных данных LSF
            using (var SW_LSF_array = new StreamWriter(OutputFileName, false, Encoding.Default))
            {
                for (int i = 0; i < difference.Length; i++)
                    SW_LSF_array.WriteLine(steps[i].ToString() + ";" + difference[i].ToString());
            }
        }

        /// <summary>
        /// Метод сглаживания графика данных для "восстановления срезанных пиков"
        /// </summary>
        /// <param name="spectrum"></param>
        /// <returns></returns>
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