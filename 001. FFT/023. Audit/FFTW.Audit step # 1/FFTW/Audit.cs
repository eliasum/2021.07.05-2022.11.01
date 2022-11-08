namespace FFTW
{
    using NAudio.Wave;
    using System;
    using System.Numerics;

    internal static class Audit
    {
        internal static byte[] OpenWAVFile(string file)
        {
            using (WaveFileReader reader = new WaveFileReader(file))
            {
                byte[] buffer = new byte[reader.Length];
                reader.Read(buffer, 0, buffer.Length);
                return buffer;
            }
        }

        internal static Complex[] Convert(int[] value)
        {
            Complex[] buffer = new Complex[value.Length];   // value.Length - 193536
            for (int i = 0; i < value.Length; i++)
            {
                // Re = value[i], Im = 0
                buffer[i] = new Complex(value[i], 0);
                buffer[i] *= 1;                             // ???
            }
            return buffer;
        }

        internal static class FFT_V1
        {
            private static Complex w(int k, int n)
            {
                if (k % n == 0) return 1;
                double arg = -2 * Math.PI * k / n;
                return new Complex(Math.Cos(arg), Math.Sin(arg));
            }

            public static Complex[] Calculate(Complex[] value)
            {
                // условие окончания рекурсии
                // Check if it is splitted enough
                if (value != null && value.Length <= 1) { return value; }

                /*
                    Сначала на входе Calculate() массив комплексных чисел размерности 193536,
                    сформированный из байтовый массив данных source.wav в методе Convert(), 
                    причем заполнены значения Re, а Im = 0. Далее размерность массива делится 
                    на 2, а значения входного массива разбиваются на два массива - odd[] и even[].
                    Потом происходит заполнение этих массивов значениями. И так до тех пор, пока 
                    длина входящего в рекурсию массива не станет <= 1. Потом идёт "обратное следование"
                    рекурсии, в цикл Calculate DFT подставляются однобайтовые массивы  odd[] и even[].
                    Через метод w() рассчитываются k-й и (n + k)-й значения цикла Calculate DFT.

                */

                // размерность массива комплексных чисел
                int n = value.Length >> 1;  // 193536/2 = 96768/2 = 48384/2 = 24192...

                // Split even and odd
                Complex[] odd = new Complex[n];     // нечетный
                Complex[] even = new Complex[n];    // четный

                for (int i = 0; i < n; i++)
                {
                    even[i] = value[i * 2];         // нечетный
                    odd[i] = value[i * 2 + 1];      // четный
                }

                // Split on tasks
                even = Calculate(even); // из value[i], где i = 0, 2, 4...
                odd = Calculate(odd);   // из value[i], где i = 1, 3, 5...
                // -----------------------выход из "прямого следования" рекурсии-----------------------

                // Calculate DFT
                for (int k = 0; k < n; k++)
                {
                    value[k] = even[k] + w(k, value.Length) * odd[k];
                    value[n + k] = even[k] - w(k, value.Length) * odd[k];
                }
                return value;
            }
        }
    }
}
