using System;
using System.Drawing;

namespace MTFCalculator
{
    public static class MTF
    {
        /// <summary>
        /// Compute the Modulation Transfer Function.
        /// Расчёт функции передачи модуляции.
        /// </summary>
        /// <param name="real"></param>
        /// <returns></returns>
        public static void Compute(double[] real)
        {
            double[] imag = new double[real.Length];

            /*
                https://ru.stackoverflow.com/questions/913771/%D0%91%D1%8B%D1%81%D1%82%D1%80%D0%BE%D0%B5-%D0%BF%D1%80%D0%B5%D0%BE%D0%B1%D1%80%D0%B0%D0%B7%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D0%A4%D1%83%D1%80%D1%8C%D0%B5-%D0%BA%D0%B0%D0%BA-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%D1%82%D1%8C-%D1%81-%D0%BA%D0%BE%D0%BC%D0%BF%D0%BB%D0%B5%D0%BA%D1%81%D0%BD%D1%8B%D0%BC%D0%B8-%D1%87%D0%B8%D1%81%D0%BB%D0%B0%D0%BC%D0%B8-%D0%B5%D1%81%D0%BB%D0%B8-%D0%B8%D1%85-%D0%BD%D0%B5%D1%82 
                Для fft нужны равномерные отсчёты, т.е. массив Y с постоянным шагом по X.
                Данные заносятся в вещественную часть, мнимая заполняется нулями.
            */
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
                https://ru.wikipedia.org/wiki/%D0%9B%D0%BE%D0%B3%D0%B0%D1%80%D0%B8%D1%84%D0%BC
                Нахождение x = logₐb равносильно решению уравнения aˣ = b

                https://ru.wikipedia.org/wiki/%D0%9B%D0%BE%D0%B3%D0%B0%D1%80%D0%B8%D1%84%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B8%D0%B5_%D1%82%D0%BE%D0%B6%D0%B4%D0%B5%D1%81%D1%82%D0%B2%D0%B0
                Основное логарифмическое тождество: a^logₐb = b

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
