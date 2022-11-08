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
            byte[] source = { 0x0, 0x33, 0x55, 0x77, 0xAA, 0xCC, 0xEE, 0xFF };      
            // 0000 0000, 0011 0011, 0101 0101, 0111 0111, 1010 1010, 1100 1100, 1110 1110, 1111 1111
            // 0        , 51       , 85       , 119      , 170      , 204      , 238      , 255   

            // вывод source ///////////////////////////////////////////////////////////////////
            StreamWriter sr1 = new StreamWriter(@".\source.txt");

            for (int i = 0; i < source.Length; i++)
                sr1.Write(source[i] + "\n");

            sr1.Close();
            ///////////////////////////////////////////////////////////////////////////////////

            /*
            source.Length = 8
            source.Length >> 1 = 4 - деление на 2
            int[] buffer = new int[4]; - буфер
            */
            int[] buffer = new int[source.Length >> 1];

            /*
            ToInt16(Byte) 	
            Преобразует значение заданного 8-битового целого числа без знака в 
            эквивалентное 16-битовое целое число со знаком.
            int - 32-разрядное целое число со знаком

            В буферный массив записываются каждый i-й байт в младшие 8 бит члена массива,
            а каждый (i+1)-й байт в старшие 8 бит члена массива. Например, source[0] = 0 или
            0000 0000, а source[1] = 51 или 0011 0011, тогда buffer[0] = 0011 0011 0000 0000 
            или 13056
            
            */
            for (int i = 0, k = 0; k < buffer.Length; i += 2, k++)
                buffer[k] = System.Convert.ToUInt16(source[i]) |
                    System.Convert.ToUInt16(source[i + 1] << 8);

            /*
                to Audit.Convert(int[] buffer)
                buffer[0] = 0011 0011 0000 0000 = 0x3300 = 13056
                buffer[1] = 0111 0111 0101 0101 = 0x7755 = 30549
                buffer[2] = 1100 1100 1010 1010 = 0xCCAA = 52394
                buffer[3] = 1111 1111 1110 1110 = 0xFFEE = 65518

                Return to Audit.FFT_V1.Calculate(Complex[] buffer)
                buffer[0] = {(0011 0011 0000 0000, 0)} = {(0x3300, 0)} = {(13056, 0)}
                buffer[1] = {(0111 0111 0101 0101, 0)} = {(0x7755, 0)} = {(30549, 0)}
                buffer[2] = {(1100 1100 1010 1010, 0)} = {(0xCCAA, 0)} = {(52394, 0)}
                buffer[3] = {(1111 1111 1110 1110, 0)} = {(0xFFEE, 0)} = {(65518, 0)}
            */


            Complex[] spectrum1 = Audit.FFT_V1.Calculate(Audit.Convert(buffer));
            //Complex[] spectrum2 = Audit.FFT_V2.Calculate(Audit.Convert(buffer));


        }
    }
}