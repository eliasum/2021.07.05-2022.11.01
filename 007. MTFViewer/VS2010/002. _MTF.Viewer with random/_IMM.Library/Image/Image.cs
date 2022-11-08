namespace _IMM.Library
{
    using System;
    using System.Windows;

    using Core = _AVM.Library.Core;

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
            public static Point[] Compute(Core.Image._8bit.Pixel[,] pixel)
            {
                if (pixel != null)
                {
                    int width = pixel.GetLength(0), height = pixel.GetLength(1);
                    int topEdge = 0, bottomEdge = 0; // верхний и нижний край
                    double topAverage = 0.0, bottomAverage = 0.0; // усреднённое значение яркости нижних "вертикальных" 8-и пикселей
                    // Вычисление усреднённого значения яркости верхних "вертикальных" 8-и пикселей
                    for (int i = 0; i < width; i++)
                        for (int j = 0; j < options.AveragingWindowLength; j++)
                            topAverage += pixel[i, j].Gray;
                    topAverage /= width * options.AveragingWindowLength; // усреднённое значение яркости верхних "вертикальных" 8-и пикселей
                    // Вычисление усреднённого значения яркости нижних "вертикальных" 8-и пикселей
                    for (int i = 0; i < width; i++)
                        for (int j = height - 1 - options.AveragingWindowLength; j < height - 1; j++)
                            bottomAverage += pixel[i, j].Gray;
                    bottomAverage /= width * options.AveragingWindowLength;  // усреднённое значение яркости нижних "вертикальных" 8-и пикселей
                    // Находим первое место, где текущее скользящее среднее пересекает среднее в верхней части изображения
                    double runningAverage = 0.0, previousAverage = 0.0; // текущее и предыдущее скользящее среднее
                    // Вычисление начального скользящего среднего яркости верхних "вертикальных" 8-и пикселей '0-го столбца ширины'
                    for (int j = 0; j < options.AveragingWindowLength; j++)
                        runningAverage += pixel[0, j].Gray / options.AveragingWindowLength;
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
                    // Отразить изображение по горизонтали, если край идет справа налево./////////////////////////////////////////////
                    if (bottomEdge < topEdge)
                    {
                        //croppedBitmap.RotateFlip(RotateFlipType.Rotate180FlipX);
                    }
                }
                return new Point[] { new Point() };
            }
        }
    }
}
