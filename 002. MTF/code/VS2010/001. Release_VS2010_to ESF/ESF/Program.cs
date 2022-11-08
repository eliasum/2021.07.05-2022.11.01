using System;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.IO;
using System.Drawing.Drawing2D;

namespace ESF
{
    internal class Program
    {
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

                    Console.WriteLine("Расчёт выполнен. Для выхода нажмите любую клавишу...");
                    Console.ReadKey();
                }
                else
                {
                    Console.WriteLine("Невозможно использовать " + System.IO.Path.GetFileName(dialog.FileName) + " потому что чтение изображения вернуло значение null или потому что изображение было слишком маленьким.");
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

            int topEdge = 0;                    // верхний край
            int bottomEdge = 0;                 // нижний край

            double topAverage = 0.0;            // усреднённое значение яркости верхних "вертикальных" 8-и пикселей
            double bottomAverage = 0.0;         // усреднённое значение яркости нижних "вертикальных" 8-и пикселей

            // Вычисление усреднённого значения яркости верхних "вертикальных" 8-и пикселей 'topAverage'_________________________

            for (int i = 0; i < croppedBitmap.Width; i++)
            {
                for (int j = 0; j < options.AveragingWindowLength; j++)
                {
                    topAverage += croppedBitmap.GetPixel(i, j).GetBrightness();
                }
            }

            topAverage /= croppedBitmap.Width * options.AveragingWindowLength;  // усреднённое значение яркости верхних "вертикальных" 8-и пикселей

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

            double runningAverage = 0.0;        // текущее скользящее среднее 
            double previousAverage = 0.0;       // предыдущее скользящее среднее

            // Вычисление начального скользящего среднего яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины'

            for (int j = 0; j < options.AveragingWindowLength; j++)
            {
                runningAverage += croppedBitmap.GetPixel(0, j).GetBrightness() / options.AveragingWindowLength;     
            }

            for (int i = 1; i < croppedBitmap.Width; i++)       // цикл сравнения всех 8-пиксельных вертикальных "срезов"
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

            runningAverage = 0.0;        // текущее скользящее среднее 
            previousAverage = 0.0;       // предыдущее скользящее среднее

            // Вычисление начального скользящего среднего яркости нижних "вертикальных" 8-и пикселей '0-го столбца ширины'

            for (int j = 0; j < options.AveragingWindowLength; j++)
            {
                runningAverage += croppedBitmap.GetPixel(0, croppedBitmap.Height - 1 - j).GetBrightness() / options.AveragingWindowLength;
            }

            for (int i = 1; i < croppedBitmap.Width; i++)
            {
                previousAverage = runningAverage;       // предыдущее среднее
                runningAverage = 0.0;                   // текущее значение скользящего среднего 

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
                Console.WriteLine("Значительная часть изображения может быть потеряна, поскольку требуемый угол поворота превышает 15 градусов. Убедитесь, что у вас правильное изображение и правильный прямоугольник обрезки. ");
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
                Console.WriteLine("После обрезки и поворота осталось недостаточно изображения для продолжения. Убедитесь, что у вас правильное изображение и правильный прямоугольник обрезки.");

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
        }
    }
}