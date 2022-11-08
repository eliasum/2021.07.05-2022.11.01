using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using FFTWSharp;

namespace FFTW
{
    internal class Program
    {
        struct WavHeader
        {
            public byte[] riffID;
            public uint size;
            public byte[] wavID;
            public byte[] fmtID;
            public uint fmtSize;
            public ushort format;
            public ushort channels;
            public uint sampleRate;
            public uint bytePerSec;
            public ushort blockSize;
            public ushort bit;
            public byte[] dataID;
            public uint dataSize;
        }

        private static void Main()
        {
            WavHeader Header = new WavHeader();
            List<short> lDataList = new List<Int16>();
            long br_BaseStream_Length = 0;
            long lDataList_count = 0;
            double[] dbuffer = null;

            double[] X_array = null; // X real
            double[] Y_array = null; // Y imaginary
            double[] A_array = null; // magnitude
            double[] phi_proc = null; // new phi
            double[] frec = null;

            double SDWN = 0;

            byte[] bidft = null;

            string path = System.Reflection.Assembly.GetExecutingAssembly().Location;


            using (FileStream fs = new FileStream(@".\source.wav", FileMode.Open, FileAccess.Read))
            using (BinaryReader br = new BinaryReader(fs))
            {
                try
                {
                    Header.riffID = br.ReadBytes(4);//1
                    Header.size = br.ReadUInt32();//2
                    Header.wavID = br.ReadBytes(4);//3
                    Header.fmtID = br.ReadBytes(4);//4
                    Header.fmtSize = br.ReadUInt32();//5
                    Header.format = br.ReadUInt16();//6
                    Header.channels = br.ReadUInt16();//7
                    Header.sampleRate = br.ReadUInt32();//8
                    Header.bytePerSec = br.ReadUInt32();//9
                    Header.blockSize = br.ReadUInt16();//10
                    Header.bit = br.ReadUInt16();//11
                    Header.dataID = br.ReadBytes(6);//12
                    Header.dataSize = br.ReadUInt32();//13

                    while (br.BaseStream.Position != br.BaseStream.Length)
                    {
                        Int16 tmp = 0;
                        tmp = br.ReadInt16();
                        lDataList.Add(tmp);
                        lDataList_count++;
                    }

                    br_BaseStream_Length = br.BaseStream.Length;

                    dbuffer = new double[lDataList_count];
                    for (int i = 0; i < lDataList_count; i++)
                        dbuffer[i] = lDataList[i];

                    // Test 1: Real input
                    // Compute the FFT
                    var dft = Fft(dbuffer, true);     // true = real input

                    // посчитать параметры
                    int n = dft.Length / 2;

                    X_array = new double[n]; // X real
                    Y_array = new double[n]; // Y imaginary
                    A_array = new double[n]; // magnitude
                    phi_proc = new double[n]; // new phi
                    frec = new double[n];

                    int j = 0;
                    for (int i = 0; i < dft.Length; i += 2)
                    {
                        X_array[j] = dft[i];
                        j++;
                    }

                    j = 0;
                    for (int i = 1; i < dft.Length; i += 2)
                    {
                        Y_array[j] = dft[i];
                        j++;
                    }

                    for (int i = 0; i < n; i++)
                    {
                        // Magnitude = sqrt(X^2 + Y^2)
                        double A = (double)Math.Sqrt(Math.Pow(X_array[i], 2) + Math.Pow(Y_array[i], 2));
                        A_array[i] = A;

                        // Phase = ArcTan(Y/X)
                        double phi_ = Convert.ToSingle(Math.Atan2(Y_array[i], X_array[i]));
                        phi_proc[i] = phi_;

                        double F = i * 44100f / (2 * n);
                        frec[i] = F;
                    }

                    using (var SW_A_array = new StreamWriter(@".\ACH.csv", false, Encoding.Default))
                    {
                        SW_A_array.WriteLine("Амплитуда;Частота");
                        for (int i = 0; i < n; i++)
                            SW_A_array.WriteLine(A_array[i].ToString() + ";" + frec[i].ToString());
                    }

                    // СКО
                    SDWN = Math.Sqrt(10000 * Header.sampleRate);

                    // функция распределения гармоник:
                    int N = A_array.Length;                     // количество измерений
                    double maxA_array = A_array.Max();
                    double minA_array = A_array.Min();
                    double R = maxA_array - minA_array;
                    int K = (int)Math.Sqrt(N);                  // количество интервалов
                    double d = R / K;                           // ширина интервала
                    double[] m = new double[K];                 // массив максимумов интервалов
                    int[] numb = new int[K];                    // массив количества максимумов интервалов
                    List<double> clone = new List<double>();    // список клон1 массива Magnitude
                    List<double> list2 = new List<double>();    // список клон2 массива Magnitude

                    // заполнение массива максимумов интервалов
                    for (int i = 0; i < K; i++)
                        m[i] = minA_array + i * d;

                    // первоначальное заполнение списка клон1 из массива Magnitudeмассива
                    for (int i = 0; i < n; i++)
                        clone.Insert(i, A_array[i]);

                    // первоначальное заполнение списка клон2 из массива Magnitudeмассива
                    list2 = new List<double>(clone);

                    // перебор по максимумам
                    for (int k = 0; k < K; k++)
                    {
                        // перебор по значениям Magnitude
                        foreach (var value in clone)
                        {
                            if (m[k] >= value)
                            {
                                list2.Remove(value);
                                numb[k]++;      // заполнение массива количества максимумов интервалов
                            }
                        }
                        clone = new List<double>(list2);
                    }

                    using (var SW_A_array = new StreamWriter(@".\Harmonics.csv", false, Encoding.Default))
                    {
                        SW_A_array.WriteLine("Амплитуда;Количество");
                        for (int i = 0; i < K; i++)
                            SW_A_array.WriteLine(m[i].ToString() + ";" + numb[i].ToString());
                    }

                    // Фильтрация шума:
                    for (int i = 0; i < n; i++)
                    {
                        if (A_array[i] < SDWN)
                            A_array[i] = 0;

                        X_array[i] = Math.Cos(phi_proc[i]) * A_array[i];
                        Y_array[i] = Math.Sin(phi_proc[i]) * A_array[i];
                    }

                    j = 0;
                    for (int i = 0; i < dft.Length; i += 2)
                    {
                        dft[i] = X_array[j];
                        j++;
                    }

                    j = 0;
                    for (int i = 1; i < dft.Length; i += 2)
                    {
                        dft[i] = Y_array[j];
                        j++;
                    }

                    // Compute the IFFT
                    var idft = Ifft(dft);

                    bidft = new byte[n];

                    j = 0;
                    for (int i = 1; i < n; i += 2)
                    {
                        bidft[j] = (byte)idft[i];
                        j++;
                    }
                }
                finally
                {
                    if (br != null)
                    {
                        br.Close();
                    }
                    if (fs != null)
                    {
                        fs.Close();
                    }
                }
            }
            Console.WriteLine("Открыт");

            using (FileStream fs = new FileStream(@".\source1.wav", FileMode.Create, FileAccess.Write))
            using (BinaryWriter bw = new BinaryWriter(fs))
            {
                try
                {
                    bw.Write(Header.riffID);//1
                    bw.Write(Header.size);//2
                    bw.Write(Header.wavID);//3
                    bw.Write(Header.fmtID);//4
                    bw.Write(Header.fmtSize);//5
                    bw.Write(Header.format);//6
                    bw.Write(Header.channels);//7
                    bw.Write(Header.sampleRate);//8
                    bw.Write(Header.bytePerSec);//9
                    bw.Write(Header.blockSize);//10
                    bw.Write(Header.bit);//11
                    bw.Write(Header.dataID);//12
                    bw.Write(Header.dataSize);//13

                    int i = 0;
                    while (bw.BaseStream.Position != br_BaseStream_Length)
                    {
                        Int16 tmp = lDataList[i];
                        bw.Write(tmp);
                        i++;
                    }
                }
                finally
                {
                    if (bw != null)
                    {
                        bw.Close();
                    }
                    if (fs != null)
                    {
                        fs.Close();
                    }
                }
            }

            return;
        }

        /// <summary>
        /// Computes the fast Fourier transform of a 1-D array of real or complex numbers.
        /// </summary>
        /// <param name="data">Input data.</param>
        /// <param name="real">Real or complex input flag.</param>
        /// <returns>Returns the FFT.</returns>
        private static double[] Fft(double[] data, bool real)
        {
            // If the input is real, make it complex
            if (real)
                data = ToComplex(data);
            // Get the length of the array
            int n = data.Length;
            /* Allocate an unmanaged memory block for the input and output data.
             * (The input and output are of the same length in this case, so we can use just one memory block.) */
            IntPtr ptr = fftw.malloc(n * sizeof(double));
            // Pass the managed input data to the unmanaged memory block
            Marshal.Copy(data, 0, ptr, n);
            // Plan the FFT and execute it (n/2 because complex numbers are stored as pairs of doubles)
            IntPtr plan = fftw.dft_1d(n / 2, ptr, ptr, fftw_direction.Forward, fftw_flags.Estimate);
            fftw.execute(plan);
            // Create an array to store the output values
            var fft = new double[n];
            // Pass the unmanaged output data to the managed array
            Marshal.Copy(ptr, fft, 0, n);
            // Do some cleaning
            fftw.destroy_plan(plan);
            fftw.free(ptr);
            fftw.cleanup();
            // Return the FFT output
            return fft;
        }

        /// <summary>
        /// Computes the inverse fast Fourier transform of a 1-D array of complex numbers.
        /// </summary>
        /// <param name="data">Input data.</param>
        /// <returns>Returns the normalized IFFT.</returns>
        private static double[] Ifft(double[] data)
        {
            // Get the length of the array
            int n = data.Length;
            /* Allocate an unmanaged memory block for the input and output data.
             * (The input and output are of the same length in this case, so we can use just one memory block.) */
            IntPtr ptr = fftw.malloc(n * sizeof(double));
            // Pass the managed input data to the unmanaged memory block
            Marshal.Copy(data, 0, ptr, n);
            // Plan the IFFT and execute it (n/2 because complex numbers are stored as pairs of doubles)
            IntPtr plan = fftw.dft_1d(n / 2, ptr, ptr, fftw_direction.Backward, fftw_flags.Estimate);
            fftw.execute(plan);
            // Create an array to store the output values
            var ifft = new double[n];
            // Pass the unmanaged output data to the managed array
            Marshal.Copy(ptr, ifft, 0, n);
            // Do some cleaning
            fftw.destroy_plan(plan);
            fftw.free(ptr);
            fftw.cleanup();
            // Scale the output values
            for (int i = 0, nh = n / 2; i < n; i++)
                ifft[i] /= nh;
            // Return the IFFT output
            return ifft;
        }

        /// <summary>
        /// Interlaces an array with zeros to match the FFTW convention of representing complex numbers.
        /// </summary>
        /// <param name="real">An array of real numbers.</param>
        /// <returns>Returns an array of complex numbers.</returns>
        private static double[] ToComplex(double[] real)
        {
            int n = real.Length;
            var comp = new double[n * 2];
            for (int i = 0; i < n; i++)
                comp[2 * i] = real[i];
            return comp;
        }
    }
}