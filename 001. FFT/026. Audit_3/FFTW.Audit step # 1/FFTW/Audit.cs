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


        /*
            value = 
            value[0] = 0011 0011 0000 0000 = 0x3300 = 13056
            value[1] = 0111 0111 0101 0101 = 0x7755 = 30549
            value[2] = 1100 1100 1010 1010 = 0xCCAA = 52394
            value[3] = 1111 1111 1110 1110 = 0xFFEE = 65518
        */
        internal static Complex[] Convert(int[] value)
        {
            Complex[] buffer = new Complex[value.Length];   // value.Length - 2
            for (int i = 0; i < value.Length; i++)
            {
                // Re = value[i], Im = 0
                buffer[i] = new Complex(value[i], 0);
                buffer[i] *= 1;                             // ???

            }

            /*
                buffer = 
                buffer[0] = {(0011 0011 0000 0000, 0)} = {(0x3300, 0)} = {(13056, 0)}
                buffer[1] = {(0111 0111 0101 0101, 0)} = {(0x7755, 0)} = {(30549, 0)}
                buffer[2] = {(1100 1100 1010 1010, 0)} = {(0xCCAA, 0)} = {(52394, 0)}
                buffer[3] = {(1111 1111 1110 1110, 0)} = {(0xFFEE, 0)} = {(65518, 0)}
            */
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

            /*
                Первый проход:
                value = 
                value[0] = {(0011 0011 0000 0000, 0)} = {(0x3300, 0)} = {(13056, 0)}
                value[1] = {(0111 0111 0101 0101, 0)} = {(0x7755, 0)} = {(30549, 0)}
                value[2] = {(1100 1100 1010 1010, 0)} = {(0xCCAA, 0)} = {(52394, 0)}
                value[3] = {(1111 1111 1110 1110, 0)} = {(0xFFEE, 0)} = {(65518, 0)}

                Второй проход:
                value = 
                value[0] = {(0011 0011 0000 0000, 0)} = {(0x3300, 0)} = {(13056, 0)}
                value[1] = {(1100 1100 1010 1010, 0)} = {(0xCCAA, 0)} = {(52394, 0)}

                Третий проход:
                value = 
                value[0] = {(0011 0011 0000 0000, 0)} = {(0x3300, 0)} = {(13056, 0)}
            */
            public static Complex[] Calculate(Complex[] value)
            {
                // условие окончания рекурсии
                // Check if it is splitted enough
                /*
                Второй проход:
                return value =
                value[0] = { (0101 0101 0000 0000, 0)} = { (0x5500, 0)} = { (21760, 0)}

                Третий проход:
                return value =
                value[0] = { (1111 1111 1010 1010, 0)} = { (0xFFAA, 0)} = { (65450, 0)}
                */
                if (value != null && value.Length <= 1) { return value; }   // value.Length = 4

                /*
                    Сначала на входе Calculate() массив комплексных чисел размерности 2,
                    сформированный из байтового массива данных source[2] в методе Convert(), 
                    причем заполнены значения Re, а Im = 0. Далее размерность массива делится 
                    на 2, а значения входного массива разбиваются на два массива - odd[] и even[].
                    Потом происходит заполнение этих массивов значениями. И так до тех пор, пока 
                    длина входящего в рекурсию массива не станет <= 1. Потом идёт "обратное следование"
                    рекурсии, в цикл Calculate DFT подставляются однобайтовые массивы  odd[] и even[].
                    Через метод w() рассчитываются k-й и (n + k)-й значения цикла Calculate DFT.

                */

                // размерность массива комплексных чисел
                int n = value.Length >> 1;  // 4/2 = 2, 2/2 = 1

                if (n == 2)
                    Console.WriteLine("1 проход рекурсии: n = 2\n");

                if (n == 1 && value[0].Real == 13056)
                    Console.WriteLine("2 проход рекурсии, even: n = 1\n");

                if (n == 1 && value[0].Real == 30549)
                    Console.WriteLine("2 проход рекурсии, odd: n = 1\n");

                // Split even and odd
                Complex[] odd = new Complex[n];     // нечетный
                Complex[] even = new Complex[n];    // четный

                for (int i = 0; i < n; i++)    
                {
                    /*
                        Первый проход:
                        even[0] = {(0011 0011 0000 0000, 0)} = {(0x3300, 0)} = {(13056, 0)}
                        even[1] = {(1100 1100 1010 1010, 0)} = {(0xCCAA, 0)} = {(52394, 0)}

                        odd[0] = {(0111 0111 0101 0101, 0)} = {(0x7755, 0)} = {(30549, 0)}
                        odd[1] = {(1111 1111 1110 1110, 0)} = {(0xFFEE, 0)} = {(65518, 0)}

                        Второй проход, even:
                        even[0] = {(0011 0011 0000 0000, 0)} = {(0x3300, 0)} = {(13056, 0)}

                        odd[1] = {(1100 1100 1010 1010, 0)} = {(0xCCAA, 0)} = {(52394, 0)}
                    */
                    even[i] = value[i * 2];         // нечетный
                    odd[i] = value[i * 2 + 1];      // четный
                }

                for (int i = 0; i < n; i++)
                {
                    Console.WriteLine("even[{0}] = {1}", i, even[i]);
                }

                Console.WriteLine("\n");

                for (int i = 0; i < n; i++)
                {
                    Console.WriteLine("odd[{0}] = {1}", i, odd[i]);
                }

                Console.WriteLine("\n");

                // Split on tasks
                even = Calculate(even); 
                odd = Calculate(odd);
                // -----------------------выход из "прямого следования" рекурсии-----------------------
                // -----------------------на return value;

                // Calculate DFT
                for (int k = 0; k < n; k++)
                {
                    /*
                        value = 
                        value[0] = {(0101 0101 0000 0000, 0)} = {(0x5500, 0)} = {(21760, 0)}
                        value[1] = {(1111 1111 1010 1010, 0)} = {(0xFFAA, 0)} = {(65450, 0)}
                    */
                    value[k] = even[k] + w(k, value.Length) * odd[k];
                    value[n + k] = even[k] - w(k, value.Length) * odd[k];
                }
                return value;
            }
        }
    }
}
