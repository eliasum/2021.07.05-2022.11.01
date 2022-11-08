using System;
using System.Collections.Generic;
using System.IO;    
using System.Linq;
using System.Numerics;
using System.Runtime.InteropServices;
using System.Text;
using FFTWSharp;

namespace FFTW
{
    internal class Program
    {
        private static void Main()
        {
            // байтовый массив данных source.wav, т.е. 387116-44=387072 байт
            byte[] source = Audit.OpenWAVFile(@".\source.wav");

            // вывод source ///////////////////////////////////////////////////////////////////
            StreamWriter sr1 = new StreamWriter(@".\source.txt");

            for (int i = 0; i < source.Length; i++)
                sr1.Write(source[i] + "\n");

            sr1.Close();
            ///////////////////////////////////////////////////////////////////////////////////

            /*
            source.Length = 387072
            source.Length >> 1 = 193536 - деление на 2
            int[] buffer = new int[193536]; - буфер
            */
            int[] buffer = new int[source.Length >> 1];

            /*
            ToInt16(Byte) 	
            Преобразует значение заданного 8-битового целого числа без знака в 
            эквивалентное 16-битовое целое число со знаком.
            int - 32-разрядное целое число со знаком

            В буферный массив записываются каждый i-й байт в младшие 8 бит члена массива,
            а каждый (i+1)-й байт в старшие 8 бит члена массива. Например, source[0] = 207 или
            1100 1111, а source[1] = 18 или 0001 0010, тогда buffer[0] = 0001 0010 1100 1111 
            или 4815
            
            */
            for (int i = 0, k = 0; k < buffer.Length; i += 2, k++)
                buffer[k] = System.Convert.ToUInt16(source[i]) |
                    System.Convert.ToUInt16(source[i + 1] << 8);

            Complex[] spectrum1 = Audit.FFT_V1.Calculate(Audit.Convert(buffer));
            //Complex[] spectrum2 = Audit.FFT_V2.Calculate(Audit.Convert(buffer));


        }
    }
}