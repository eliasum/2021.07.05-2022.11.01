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
            byte[] source = { 0x0, 0x55, 0xAA, 0xFF };      // 0, 85, 170, 255 
            // или 0000 0000, 0101 0101, 1010 1010, 1111 1111

            // вывод source ///////////////////////////////////////////////////////////////////
            StreamWriter sr1 = new StreamWriter(@".\source.txt");

            for (int i = 0; i < source.Length; i++)
                sr1.Write(source[i] + "\n");

            sr1.Close();
            ///////////////////////////////////////////////////////////////////////////////////

            /*
            source.Length = 4
            source.Length >> 1 = 2 - деление на 2
            int[] buffer = new int[2]; - буфер
            */
            int[] buffer = new int[source.Length >> 1];

            /*
            ToInt16(Byte) 	
            Преобразует значение заданного 8-битового целого числа без знака в 
            эквивалентное 16-битовое целое число со знаком.
            int - 32-разрядное целое число со знаком

            В буферный массив записываются каждый i-й байт в младшие 8 бит члена массива,
            а каждый (i+1)-й байт в старшие 8 бит члена массива. Например, source[0] = 0 или
            0000 0000, а source[1] = 85 или 0101 0101, тогда buffer[0] = 0101 0101 0000 0000 
            или 21760
            
            */
            for (int i = 0, k = 0; k < buffer.Length; i += 2, k++)
                buffer[k] = System.Convert.ToUInt16(source[i]) |
                    System.Convert.ToUInt16(source[i + 1] << 8);

            /*
                to Audit.Convert(int[] buffer)
                buffer[0] = 0101 0101 0000 0000 = 0x5500 = 21760
                buffer[1] = 1111 1111 1010 1010 = 0xFFAA = 65450

                Return to Audit.FFT_V1.Calculate(Complex[] buffer)
                buffer[0] = {(0101 0101 0000 0000, 0)} = {(0x5500, 0)} = {(21760, 0)}
                buffer[1] = {(1111 1111 1010 1010, 0)} = {(0xFFAA, 0)} = {(65450, 0)}
            */


            Complex[] spectrum1 = Audit.FFT_V1.Calculate(Audit.Convert(buffer));
            //Complex[] spectrum2 = Audit.FFT_V2.Calculate(Audit.Convert(buffer));


        }
    }
}