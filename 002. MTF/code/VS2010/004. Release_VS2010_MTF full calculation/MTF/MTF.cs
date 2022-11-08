using System;
using System.Drawing;

namespace MTF
{
    public static class MTF
    {
        /// <summary>
        /// Расчёт функции передачи модуляции.
        /// </summary>
        /// <param name="real"></param>
        /// <returns></returns>
        public static void Compute(double[] real)
        {
            double[] imag = new double[real.Length];

            for (int i = 0; i < real.Length; i++)
            {
                imag[i] = 0.0;
            }

            FFT fft = new FFT();

            // Расчёт БПФ
            fft.Compute(real, imag);

            // расчет массива модулей комплексных чисел из результата БПФ над LSF
            for (int i = 0; i < real.Length; i++)
            {
                real[i] = Math.Sqrt(real[i] * real[i] + imag[i] * imag[i]);
            }
        }

        public static double[] ZeroPad(double[] real)
        {
            /*
                2 в степени [округленное значение log₂(real.Length)] - наименьшее число степени 2, 
                которое больше real.Length
            */
            int n = (int)Math.Pow(2.0, Math.Ceiling(Math.Log(real.Length, 2)));

            if (real.Length < n)
            {
                double[] padded = new double[n];

                // нулевые ячейки "слева" от исходного массива 0...a - 1, т.е. a ячеек
                int a = (int)Math.Floor((double)(n - real.Length) / 2);

                // нулевые ячейки "справа" от исходного массива real.Length...b, т.е. a (+ 1) ячеек
                int b = a + real.Length;

                // заполнение массива double[] padded нулевыми ячейками "слева" от исходного массива
                for (int i = 0; i < a; i++)
                {
                    padded[i] = 0.0;                 // a ячеек
                }

                // заполнение массива double[] padded ячейками исходного массива
                for (int i = a; i < b; i++)
                {
                    padded[i] = real[i - a];        // real.Length ячеек
                }

                // заполнение массива double[] padded нулевыми ячейками "справа" от исходного массива
                for (int i = b; i < n; i++)
                {
                    padded[i] = 0.0;                // a (+ 1) ячеек
                }

                // возврат нового массива double[] padded
                return padded;
            }
            else
            {
                return (double[])real.Clone();
            }
        }

        public static void HammingWindow(double[] real)
        {
            for (int i = 0; i < real.Length; i++)
            {
                real[i] = real[i] * (0.53836 - 0.46164 * Math.Cos(2 * Math.PI * i / (real.Length - 1)));
            }
        }

        public static void HannWindow(double[] real)
        {
            for (int i = 0; i < real.Length; i++)
            {
                real[i] = real[i] * (0.5 * (1.0 - Math.Cos(2 * Math.PI * i / (real.Length - 1))));
            }
        }
    }
}
