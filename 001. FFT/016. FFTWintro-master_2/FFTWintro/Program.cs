using System;
using System.IO;
using System.Runtime.InteropServices;
using FFTWSharp;
using NAudio.Wave;

namespace FFTWintro
{
    internal class Program
    {
        static readonly bool flag_NAudio_FFTWSharp = true;
        static readonly bool flag_Byte_Freq = false;

        private static void Main()
        {
            if (flag_NAudio_FFTWSharp == false)      // FFT NAudio
            {
                //using (var ms = File.OpenRead(@"d:\source.wav"))
                {
                    //using (WaveFileReader rdr = new WaveFileReader(ms))
                    using (var rdr = new WaveFileReader(@"d:\source.wav"))
                    {
                        int buffer_size = 4096;
                        byte[] buffer = new byte[buffer_size]; 
                        double[] dbuffer = new double[buffer_size];

                        int bytesRead;
                        int total = 0;
                        int count = 0;

                        SampleAggregator sampleAggregator = new SampleAggregator();

                        sampleAggregator.PerformFFT = true;
                        sampleAggregator.FftCalculated += new EventHandler<FftEventArgs>(FftCalculated);

                        /*
                        var newFormat = new WaveFormat(44100, 16, 2);
                        using (var conversionStream = new WaveFormatConversionStream(newFormat, rdr))
                        {
                            WaveFileWriter.CreateWaveFile(@"d:\source1.wav", conversionStream);
                        }
                        */

                        do
                        {
                            bytesRead = rdr.Read(buffer, 0, buffer.Length);

                            count++;

                            for (int startIndex = 0; startIndex < bytesRead - 4; startIndex += 4)
                                sampleAggregator.Add(BitConverter.ToInt32(buffer, startIndex));


                            total += bytesRead;
                        } while (bytesRead > 0);

                        for (int i = 0; i < buffer_size; i++)
                            dbuffer[i] = buffer[i];

                        sampleAggregator.PerformFFT = false;

                    
                        if (flag_Byte_Freq == false)
                        {
                            // вывод байтов аудио до FFT
                            StreamWriter sr = new StreamWriter(@"d:\out.txt");

                            for (int i = 0; i < buffer.Length; i++)
                                sr.Write(buffer[i] + "\n");

                            sr.Close();
                        }


                    }
                }

                // Prevent the console window from closing immediately
                Console.ReadKey();
            }
            else if (flag_NAudio_FFTWSharp == true)     // FFTWSharp
            {
                //using (var ms = File.OpenRead(@"d:\source.wav"))
                {
                    //using (WaveFileReader rdr = new WaveFileReader(ms))
                    using (var rdr = new WaveFileReader(@"d:\source.wav"))
                    {
                        int buffer_size = 512;
                        byte[] buffer = new byte[buffer_size];
                        double[] dbuffer = new double[buffer_size];

                        int bytesRead;
                        int total = 0;
                        int count = 0;

                        do
                        {
                            bytesRead = rdr.Read(buffer, 0, buffer.Length);

                            count++;

                            total += bytesRead;
                        } while (bytesRead > 0);

                        for (int i = 0; i < buffer_size; i++)
                            dbuffer[i] = buffer[i];

                        if (flag_Byte_Freq == false)
                        {
                            // вывод байтов аудио до FFT
                            StreamWriter sr = new StreamWriter(@"d:\out.txt");

                            for (int i = 0; i < buffer.Length; i++)
                                sr.Write(buffer[i] + "\n");

                            sr.Close();
                        }

                        // Test 1: Real input
                        // Compute the FFT
                        var dft = Fft(dbuffer, true);     // true = real input


                        // посчитать параметры
                        int n = dft.Length;

                        double[] X_array = new double[buffer_size]; // X real
                        double[] Y_array = new double[buffer_size]; // Y imaginary
                        double[] A_array = new double[buffer_size]; // magnitude
                        double[] phi_proc = new double[buffer_size]; // new phi
                        double[] frec = new double[buffer_size];

                        int j = 0;
                        for (int i = 0; i < n; i += 2)
                        {
                            X_array[j] = dft[i];
                            j++;
                        }

                        j = 0;
                        for (int i = 1; i < n; i += 2)
                        {
                            Y_array[j] = dft[i];
                            j++;
                        }

                        for (int i = 0; i < buffer_size; i++)
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

                        // Compute the IFFT
                        var idft = Ifft(dft);

                        byte[] bidft = new byte[buffer_size];

                        j = 0;
                        for (int i = 1; i < n; i += 2)
                        {
                            bidft[j] = (byte)idft[i];
                            j++;
                        }

                        File.WriteAllBytes(@"d:\source1.wav", bidft);


                        if (flag_Byte_Freq == true)
                        {
                            // вывод "Амплитуда", "Фаза", "Частота" до IFFT
                            StreamWriter sr1 = new StreamWriter(@"d:\out1.txt");

                            sr1.Write("{0, 15}\t{1, 15}\t{2, 15}\t", "Амплитуда", "Фаза", "Частота\n");

                            for (int i = 0; i < buffer_size; i++)
                            {
                                sr1.Write("{0, 15}\t{1, 15}\t{2, 15}\n", A_array[i], phi_proc[i], frec[i]);
                            }

                            sr1.Close();
                        }
                        else
                        if (flag_Byte_Freq == false)
                        {
                            // вывод байтов аудио после IFFT
                            StreamWriter sr2 = new StreamWriter(@"d:\out1.txt");

                            for (int i = 0; i < idft.Length; i += 2)
                                sr2.Write(idft[i] + "\n");

                            sr2.Close();
                        }


                    }
                }
            }



            /*
            // Test 2: Complex input
            x = new double[] { 1, -2, 3, 4, 5, -6, 7, 8 };  // that is, 1 - 2i, . . . , 7 + 8i
            dft = Fft(x, false);        // false = complex input
            Console.WriteLine("Test 2: Complex input");
            Console.WriteLine();
            Console.WriteLine("FFT =");
            DisplayComplex(dft);
            Console.WriteLine();
            idft = Ifft(dft);
            // Format and display the results of the IFFT
            Console.WriteLine("IFFT =");
            DisplayComplex(idft);
            // Prevent the console window from closing immediately
            */


            Console.ReadKey();
        }

        static void FftCalculated(object sender, FftEventArgs e)
        {
            int n = e.Result.Length / 2;

            double[] X_array = new double[n]; // X real
            double[] Y_array = new double[n]; // Y imaginary
            double[] A_array = new double[n]; // magnitude
            double[] phi_proc = new double[n]; // new phi
            double[] frec = new double[n];

            for (var i = 0; i < n; i++)
            {
                double X = e.Result[i].X;
                double Y = e.Result[i].Y;

                X_array[i] = X;
                Y_array[i] = Y;

                // Magnitude = sqrt(X^2 + Y^2)
                double A = (double)Math.Sqrt(Math.Pow(X, 2) + Math.Pow(Y, 2));
                A_array[i] = A;

                // Phase = ArcTan(Y/X)
                double phi_ = Convert.ToSingle(Math.Atan2(Y, X));
                phi_proc[i] = phi_;

                double F = i * 44100f / (2 * n);
                frec[i] = F;
            }

            if (flag_Byte_Freq == true)
            {
                // вывод "Амплитуда", "Фаза", "Частота" до IFFT
                StreamWriter sr1 = new StreamWriter(@"d:\out1.txt");

                sr1.Write("{0, 15}\t{1, 15}\t{2, 15}\t", "Амплитуда", "Фаза", "Частота\n");

                for (int i = 0; i < n; i++)
                {
                    sr1.Write("{0, 15}\t{1, 15}\t{2, 15}\n", A_array[i], phi_proc[i], frec[i]);
                }

                sr1.Close();
            }
            else
            if (flag_Byte_Freq == false)
            {
                // Compute the IFFT
                var idft = Ifft(X_array);
                // Format and display the results of the IFFT
                DisplayReal(idft);

                // вывод байтов аудио после IFFT
                StreamWriter sr2 = new StreamWriter(@"d:\out1.txt");

                for (int i = 0; i < idft.Length; i += 2)
                    sr2.Write(idft[i] + "\n");

                sr2.Close();
            }
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

        /// <summary>
        /// Displays complex numbers in the form a +/- bi.
        /// </summary>
        /// <param name="x">An array of complex numbers.</param>
        private static void DisplayComplex(double[] x)
        {
            if (x.Length % 2 != 0)
                throw new Exception("The number of elements must be even.");
            for (int i = 0, n = x.Length; i < n; i += 2)
                if (x[i + 1] < 0)
                    Console.WriteLine("{0} - {1}i", x[i], Math.Abs(x[i + 1]));
                else
                    Console.WriteLine("{0} + {1}i", x[i], x[i + 1]);
        }

        /// <summary>
        /// Displays the real parts of complex numbers.
        /// </summary>
        /// <param name="x">An array of complex numbers.</param>
        private static void DisplayReal(double[] x)
        {
            if (x.Length % 2 != 0)
                throw new Exception("The number of elements must be even.");
            for (int i = 0, n = x.Length; i < n; i += 2)
                Console.WriteLine(x[i]);
        }
    }
}