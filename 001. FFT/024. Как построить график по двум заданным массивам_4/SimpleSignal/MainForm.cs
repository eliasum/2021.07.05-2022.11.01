using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;

using ZedGraph;

using NAudio.Wave;
using NAudio.Dsp;
using System.Diagnostics;
using System.Runtime.InteropServices;
using FFTW;

namespace SimpleSignal
{
    public partial class MainForm : Form
    {
        static int n = 0;

        static double[] X_array = null; // X real
        static double[] Y_array = null; // Y imaginary
        static double[] A_array = null; // magnitude
        static double[] phi_proc = null; // new phi
        static double[] frec = null;
        static double[] p = null;

        static int flag = 0;

        public MainForm()
        {
            InitializeComponent();

            DrawGraph();
        }

        private void DrawGraph()
        {
            flag = 0;

            if (flag == 1)
            {
                using (var ms = File.OpenRead(@"d:\source.wav"))
                {
                    using (WaveFileReader rdr = new WaveFileReader(ms))
                    {
                        byte[] buffer = new byte[4096]; //4096 buffer size

                        int bytesRead;
                        int total = 0;
                        int count = 0;

                        SampleAggregator sampleAggregator = new SampleAggregator();

                        sampleAggregator.PerformFFT = true;
                        sampleAggregator.FftCalculated += new EventHandler<FftEventArgs>(FftCalculated);

                        do
                        {
                            bytesRead = rdr.Read(buffer, 0, buffer.Length);

                            count++;

                            for (int startIndex = 0; startIndex < bytesRead - 4; startIndex += 4)
                                sampleAggregator.Add(BitConverter.ToInt32(buffer, startIndex));


                            total += bytesRead;
                        } while (bytesRead > 0);

                        sampleAggregator.PerformFFT = false;
                    }
                }
            }
            else if (flag == 2)
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


                        // Test 1: Real input
                        // Compute the FFT
                        var dft = Fft(dbuffer, true);     // true = real input
                                                          // Format and display the results of the FFT
                        Console.WriteLine("Test 1: Real input");
                        Console.WriteLine();
                        Console.WriteLine("FFT =");

                        DisplayComplex(dft);
                        Console.WriteLine();

                        n = dft.Length;

                        X_array = new double[n]; // X real
                        Y_array = new double[n]; // Y imaginary
                        A_array = new double[n]; // magnitude
                        phi_proc = new double[n]; // new phi
                        frec = new double[n];

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
                        {/*
                            // Magnitude = sqrt(X^2 + Y^2)
                            double A = (double)Math.Sqrt(Math.Pow(X_array[i], 2) + Math.Pow(Y_array[i], 2));
                            A_array[i] = A;

                            // Phase = ArcTan(Y/X)
                            double phi_ = Convert.ToSingle(Math.Atan2(Y_array[i], X_array[i]));
                            phi_proc[i] = phi_;

                            double F = i * 44100f / (2 * n);
                            frec[i] = F;*/
                        }

                        StreamWriter sr = new StreamWriter(@"d:\out1.txt");

                        sr.Write("{0, 15}\t{1, 15}\t{2, 15}\t", "Амплитуда", "Фаза", "Частота\n");

                        for (int i = 0; i < buffer_size; i++)
                        {
                            sr.Write("{0, 15}\t{1, 15}\t{2, 15}\n", A_array[i], phi_proc[i], frec[i]);
                        }

                        sr.Close();

                        /*
                        // Compute the IFFT
                        var idft = Ifft(dft);
                        // Format and display the results of the IFFT
                        Console.WriteLine("IFFT =");
                        DisplayReal(idft);
                        Console.WriteLine();
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
                    }
                }
            }
            else
            {
                byte[] source = Audit.OpenWAVFile(@".\source.wav");
                int[] buffer = new int[source.Length >> 1];
                for (int i = 0, k = 0; k < buffer.Length; i += 2, k++)
                    buffer[k] = System.Convert.ToUInt16(source[i]) |
                        System.Convert.ToUInt16(source[i + 1] << 8);
                System.Numerics.Complex[] spectrum1 = Audit.FFT_V1.Calculate(Audit.Convert(buffer));
                //Complex[] spectrum2 = Audit.FFT_V2.Calculate(Audit.Convert(buffer));

                n = spectrum1.Length;

                X_array = new double[n]; // X real
                Y_array = new double[n]; // Y imaginary
                A_array = new double[n]; // magnitude
                phi_proc = new double[n]; // new phi
                frec = new double[n];

                int j = 0;
                for (int i = 0; i < n; i += 2)
                {
                    X_array[j] = spectrum1[i].Real;
                    j++;
                }

                j = 0;
                for (int i = 1; i < n; i += 2)
                {
                    Y_array[j] = spectrum1[i].Imaginary;
                    j++;
                }

                for (int i = 0; i < spectrum1.Length; i++)
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
            }

            // Получим панель для рисования
            GraphPane pane = zedGraph.GraphPane;

            // Очистим список кривых на тот случай, если до этого сигналы уже были нарисованы
            pane.CurveList.Clear();

            // Создадим список точек
            PointPairList list = new PointPairList();
            PointPairList list2 = new PointPairList();

            // Заполняем список точек
            for (int i = 0; i < n; i++)

            {
                // добавим в список точку
                list.Add(frec[i], A_array[i]);
                list2.Add(frec[i], phi_proc[i]);
            }

            // Создадим кривую с названием "Sinc", 
            // которая будет рисоваться голубым цветом (Color.Blue),
            // Опорные точки выделяться не будут (SymbolType.None)
            LineItem myCurve = pane.AddCurve("АЧХ", list, Color.Blue, SymbolType.None);
            //LineItem myCurve2 = pane.AddCurve("ФЧХ", list2, Color.Red, SymbolType.None);

            // Вызываем метод AxisChange (), чтобы обновить данные об осях. 
            // В противном случае на рисунке будет показана только часть графика, 
            // которая умещается в интервалы по осям, установленные по умолчанию
            zedGraph.AxisChange();

            // Обновляем график
            zedGraph.Invalidate();
        }

        static void FftCalculated(object sender, FftEventArgs e)
        {
            n = e.Result.Length / 2;

            X_array = new double[n]; // X real
            Y_array = new double[n]; // Y imaginary
            A_array = new double[n]; // magnitude
            phi_proc = new double[n]; // new phi
            frec = new double[n];

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

            p = PeakDetection(A_array);

            for (int i = 0; i < n; i++) Console.WriteLine(p[i]);

            StreamWriter sr = new StreamWriter(@"d:\out.txt");

            sr.Write("{0, 15}\t{1, 15}\t{2, 15}", "Амплитуда", "Фаза", "Частота\n");

            for (int i = 0; i < n; i++)
            {
                sr.Write("{0, 15}\t{1, 15}\t{2, 15}\n", A_array[i], phi_proc[i], frec[i]);
            }
            /*
            for (int i = 0; i < n; i++)
            {
                sr.Write("{0}\n", p[i]);
            }*/
            sr.Close();
        }

        public static double[] PeakDetection(double[] data)
        {
            var peekTime = SavitzkyGolayFilter(data, 5);

            double maxPeek = 0.0;

            for (int i = 0; i < peekTime.Length - 1; i++)
            {
                if (peekTime[i] > 0 && peekTime[i + 1] < 0 || peekTime[i] < 0 && peekTime[i + 1] > 0)
                {
                    if (maxPeek < peekTime[i]) maxPeek = peekTime[i];
                    peekTime[i] = peekTime[i] / maxPeek;
                }
                else peekTime[i] = 0.0;
            }
            return peekTime;
        }

        public static double[] SavitzkyGolayFilter(double[] data, int smoothingNumber)
        {
            double[] newData;
            newData = new double[data.Length];

            int Nomalization = 0;
            int[] W5 = { -3, 12, 17, 12, -3 };
            int[] W7 = { -2, 3, 6, 7, 6, 3, -2 };
            int[] W9 = { -21, 14, 39, 54, 59, 54, 39, 14, -21 };
            int[] W11 = { -36, 9, 44, 69, 84, 89, 84, 69, 44, 9, -36 };
            int[] W13 = { -11, 0, 9, 16, 21, 24, 25, 24, 21, 16, 9, 0, -11 };
            int[] W15 = { -78, -13, 42, 87, 122, 147, 162, 167, 162, 147, 122, 87, 42, -13, -78 };
            //            int[] W17 = { -105, -30, 35, 90, 135, 170, 195, 210, 215, 210, 195, 170, 135, 90, 35, -30, -105};
            int[] W17 = { -21, -6, 7, 18, 27, 34, 39, 42, 43, 42, 39, 34, 27, 18, 7, -6, -21 };
            int[] W25 = { -253, -138, -33, 62, 147, 222, 287, 342, 387, 422, 447, 462, 467, 462, 447, 422, 387, 342, 287, 222, 147, 62, -33, -138, -253 };

            switch (smoothingNumber)
            {
                case 5:
                    Nomalization = 35;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W5, Nomalization);
                    break;

                case 7:
                    //Nomalization = 21;
                    Nomalization = 105;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W7, Nomalization);
                    break;

                case 9:
                    Nomalization = 231;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W9, Nomalization);
                    break;

                case 11:
                    Nomalization = 429;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W11, Nomalization);
                    break;

                case 13:
                    //Nomalization = 143;
                    Nomalization = 715;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W13, Nomalization);
                    break;

                case 15:
                    Nomalization = 1105;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W15, Nomalization);
                    break;

                case 17:
                    Nomalization = 1615;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W17, Nomalization);
                    break;

                case 25:
                    Nomalization = 5175;
                    newData = SavitzkyGolayCalc(data, smoothingNumber, W25, Nomalization);
                    break;
            }
            return newData;
        }
        public static double[] SavitzkyGolayCalc(double[] data, int n, int[] W, int normal)
        {
            double[] newData;
            newData = new double[data.Length];

            int smoothingN = (n - 1) / 2;

            for (int i = 0; i < data.Length; i++)
            {
                for (int j = -smoothingN; j < smoothingN; j++)
                {
                    if (i + j < 0 || i + j >= data.Length) newData[i] = data[i];
                    else newData[i] = newData[i] + W[smoothingN + j] * data[i + j];
                }
                newData[i] = newData[i] / normal;
            }
            return newData;
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
            IntPtr plan = fftw.dft_1d(n / 2, ptr, ptr, fftw.fftw_direction.Forward, fftw.fftw_flags.Estimate);
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
            IntPtr plan = fftw.dft_1d(n / 2, ptr, ptr, fftw.fftw_direction.Backward, fftw.fftw_flags.Estimate);
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

    internal class SampleAggregator
    {
        // volume
        public event EventHandler<MaxSampleEventArgs> MaximumCalculated;
        private float maxValue;
        private float minValue;
        public int NotificationCount { get; set; }
        int count;

        // FFT
        public event EventHandler<FftEventArgs> FftCalculated;
        public bool PerformFFT { get; set; }
        private Complex[] fftBuffer;
        private FftEventArgs fftArgs;
        private int fftPos;
        private int fftLength;
        private int m;

        public SampleAggregator(int fftLength = 1024)
        {
            if (!IsPowerOfTwo(fftLength))
            {
                throw new ArgumentException("FFT Length must be a power of two");
            }
            this.m = (int)Math.Log(fftLength, 2.0);
            this.fftLength = fftLength;
            this.fftBuffer = new Complex[fftLength];
            this.fftArgs = new FftEventArgs(fftBuffer);
        }

        bool IsPowerOfTwo(int x)
        {
            return (x & (x - 1)) == 0;
        }


        public void Reset()
        {
            count = 0;
            maxValue = minValue = 0;
        }

        public void Add(float value)
        {
            if (PerformFFT && FftCalculated != null)
            {
                fftBuffer[fftPos].X = (float)(value * FastFourierTransform.HammingWindow(fftPos, fftBuffer.Length));
                fftBuffer[fftPos].Y = 0;
                fftPos++;
                if (fftPos >= fftBuffer.Length)
                {
                    fftPos = 0;
                    // 1024 = 2^10
                    FastFourierTransform.FFT(true, m, fftBuffer);
                    FftCalculated(this, fftArgs);
                }
            }

            maxValue = Math.Max(maxValue, value);
            minValue = Math.Min(minValue, value);
            count++;
            if (count >= NotificationCount && NotificationCount > 0)
            {
                if (MaximumCalculated != null)
                {
                    MaximumCalculated(this, new MaxSampleEventArgs(minValue, maxValue));
                }
                Reset();
            }
        }
    }

    internal class fftw
    {
        public enum fftw_flags : uint
        {
            /// <summary>
            /// Tells FFTW to find an optimized plan by actually computing several FFTs and measuring their execution time. 
            /// Depending on your machine, this can take some time (often a few seconds). Default (0x0). 
            /// </summary>
            Measure = 0,
            /// <summary>
            /// Specifies that an out-of-place transform is allowed to overwrite its 
            /// input array with arbitrary data; this can sometimes allow more efficient algorithms to be employed.
            /// </summary>
            DestroyInput = 1,
            /// <summary>
            /// Rarely used. Specifies that the algorithm may not impose any unusual alignment requirements on the input/output 
            /// arrays (i.e. no SIMD). This flag is normally not necessary, since the planner automatically detects 
            /// misaligned arrays. The only use for this flag is if you want to use the guru interface to execute a given 
            /// plan on a different array that may not be aligned like the original. 
            /// </summary>
            Unaligned = 2,
            /// <summary>
            /// Not used.
            /// </summary>
            ConserveMemory = 4,
            /// <summary>
            /// Like Patient, but considers an even wider range of algorithms, including many that we think are 
            /// unlikely to be fast, to produce the most optimal plan but with a substantially increased planning time. 
            /// </summary>
            Exhaustive = 8,
            /// <summary>
            /// Specifies that an out-of-place transform must not change its input array. 
            /// </summary>
            /// <remarks>
            /// This is ordinarily the default, 
            /// except for c2r and hc2r (i.e. complex-to-real) transforms for which DestroyInput is the default. 
            /// In the latter cases, passing PreserveInput will attempt to use algorithms that do not destroy the 
            /// input, at the expense of worse performance; for multi-dimensional c2r transforms, however, no 
            /// input-preserving algorithms are implemented and the planner will return null if one is requested.
            /// </remarks>
            PreserveInput = 16,
            /// <summary>
            /// Like Measure, but considers a wider range of algorithms and often produces a “more optimal” plan 
            /// (especially for large transforms), but at the expense of several times longer planning time 
            /// (especially for large transforms).
            /// </summary>
            Patient = 32,
            /// <summary>
            /// Specifies that, instead of actual measurements of different algorithms, a simple heuristic is 
            /// used to pick a (probably sub-optimal) plan quickly. With this flag, the input/output arrays 
            /// are not overwritten during planning. 
            /// </summary>
            Estimate = 64
        }

        /// <summary>
        /// Defines direction of operation
        /// </summary>
        public enum fftw_direction : int
        {
            /// <summary>
            /// Computes a regular DFT
            /// </summary>
            Forward = -1,
            /// <summary>
            /// Computes the inverse DFT
            /// </summary>
            Backward = 1
        }

        /// <summary>
        /// Kinds of real-to-real transforms
        /// </summary>
        public enum fftw_kind : uint
        {
            R2HC = 0,
            HC2R = 1,
            DHT = 2,
            REDFT00 = 3,
            REDFT01 = 4,
            REDFT10 = 5,
            REDFT11 = 6,
            RODFT00 = 7,
            RODFT01 = 8,
            RODFT10 = 9,
            RODFT11 = 10
        }

        /// <summary>
        /// Allocates FFTW-optimized unmanaged memory
        /// </summary>
        /// <param name="length">Amount to allocate, in bytes</param>
        /// <returns>Pointer to allocated memory</returns>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_malloc",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr malloc(int length);

        /// <summary>
        /// Deallocates memory allocated by FFTW malloc
        /// </summary>
        /// <param name="mem">Pointer to memory to release</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_free",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void free(IntPtr mem);

        /// <summary>
        /// Deallocates an FFTW plan and all associated resources
        /// </summary>
        /// <param name="plan">Pointer to the plan to release</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_destroy_plan",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void destroy_plan(IntPtr plan);

        /// <summary>
        /// Clears all memory used by FFTW, resets it to initial state. Does not replace destroy_plan and free
        /// </summary>
        /// <remarks>After calling fftw_cleanup, all existing plans become undefined, and you should not 
        /// attempt to execute them nor to destroy them. You can however create and execute/destroy new plans, 
        /// in which case FFTW starts accumulating wisdom information again. 
        /// fftw_cleanup does not deallocate your plans; you should still call fftw_destroy_plan for this purpose.</remarks>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_cleanup",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void cleanup();

        /// <summary>
        /// Sets the maximum time that can be used by the planner.
        /// </summary>
        /// <param name="seconds">Maximum time, in seconds.</param>
        /// <remarks>This function instructs FFTW to spend at most seconds seconds (approximately) in the planner. 
        /// If seconds == -1.0 (the default value), then planning time is unbounded. 
        /// Otherwise, FFTW plans with a progressively wider range of algorithms until the the given time limit is 
        /// reached or the given range of algorithms is explored, returning the best available plan. For example, 
        /// specifying fftw_flags.Patient first plans in Estimate mode, then in Measure mode, then finally (time 
        /// permitting) in Patient. If fftw_flags.Exhaustive is specified instead, the planner will further progress to 
        /// Exhaustive mode. 
        /// </remarks>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_set_timelimit",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void set_timelimit(double seconds);

        /// <summary>
        /// Executes an FFTW plan, provided that the input and output arrays still exist
        /// </summary>
        /// <param name="plan">Pointer to the plan to execute</param>
        /// <remarks>execute (and equivalents) is the only function in FFTW guaranteed to be thread-safe.</remarks>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_execute",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void execute(IntPtr plan);

        /// <summary>
        /// Creates a plan for a 1-dimensional complex-to-complex DFT
        /// </summary>
        /// <param name="n">The logical size of the transform</param>
        /// <param name="direction">Specifies the direction of the transform</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_1d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_1d(int n, IntPtr input, IntPtr output,
            fftw_direction direction, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 2-dimensional complex-to-complex DFT
        /// </summary>
        /// <param name="nx">The logical size of the transform along the first dimension</param>
        /// <param name="ny">The logical size of the transform along the second dimension</param>
        /// <param name="direction">Specifies the direction of the transform</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_2d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_2d(int nx, int ny, IntPtr input, IntPtr output,
            fftw_direction direction, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 3-dimensional complex-to-complex DFT
        /// </summary>
        /// <param name="nx">The logical size of the transform along the first dimension</param>
        /// <param name="ny">The logical size of the transform along the second dimension</param>
        /// <param name="nz">The logical size of the transform along the third dimension</param>
        /// <param name="direction">Specifies the direction of the transform</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_3d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_3d(int nx, int ny, int nz, IntPtr input, IntPtr output,
            fftw_direction direction, fftw_flags flags);

        /// <summary>
        /// Creates a plan for an n-dimensional complex-to-complex DFT
        /// </summary>
        /// <param name="rank">Number of dimensions</param>
        /// <param name="n">Array containing the logical size along each dimension</param>
        /// <param name="direction">Specifies the direction of the transform</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft(int rank, int[] n, IntPtr input, IntPtr output,
            fftw_direction direction, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 1-dimensional real-to-complex DFT
        /// </summary>
        /// <param name="n">Number of REAL (input) elements in the transform</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_r2c_1d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_r2c_1d(int n, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 2-dimensional real-to-complex DFT
        /// </summary>
        /// <param name="nx">Number of REAL (input) elements in the transform along the first dimension</param>
        /// <param name="ny">Number of REAL (input) elements in the transform along the second dimension</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_r2c_2d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_r2c_2d(int nx, int ny, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 3-dimensional real-to-complex DFT
        /// </summary>
        /// <param name="nx">Number of REAL (input) elements in the transform along the first dimension</param>
        /// <param name="ny">Number of REAL (input) elements in the transform along the second dimension</param>
        /// <param name="nz">Number of REAL (input) elements in the transform along the third dimension</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_r2c_3d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_r2c_3d(int nx, int ny, int nz, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for an n-dimensional real-to-complex DFT
        /// </summary>
        /// <param name="rank">Number of dimensions</param>
        /// <param name="n">Array containing the number of REAL (input) elements along each dimension</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_r2c",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_r2c(int rank, int[] n, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 1-dimensional complex-to-real DFT
        /// </summary>
        /// <param name="n">Number of REAL (output) elements in the transform</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_c2r_1d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_c2r_1d(int n, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 2-dimensional complex-to-real DFT
        /// </summary>
        /// <param name="nx">Number of REAL (output) elements in the transform along the first dimension</param>
        /// <param name="ny">Number of REAL (output) elements in the transform along the second dimension</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_c2r_2d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_c2r_2d(int nx, int ny, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 3-dimensional complex-to-real DFT
        /// </summary>
        /// <param name="nx">Number of REAL (output) elements in the transform along the first dimension</param>
        /// <param name="ny">Number of REAL (output) elements in the transform along the second dimension</param>
        /// <param name="nz">Number of REAL (output) elements in the transform along the third dimension</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_c2r_3d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_c2r_3d(int nx, int ny, int nz, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for an n-dimensional complex-to-real DFT
        /// </summary>
        /// <param name="rank">Number of dimensions</param>
        /// <param name="n">Array containing the number of REAL (output) elements along each dimension</param>
        /// <param name="input">Pointer to an array of 16-byte complex numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_dft_c2r",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr dft_c2r(int rank, int[] n, IntPtr input, IntPtr output, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 1-dimensional real-to-real DFT
        /// </summary>
        /// <param name="n">Number of elements in the transform</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="kind">The kind of real-to-real transform to compute</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_r2r_1d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr r2r_1d(int n, IntPtr input, IntPtr output, fftw_kind kind, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 2-dimensional real-to-real DFT
        /// </summary>
        /// <param name="nx">Number of elements in the transform along the first dimension</param>
        /// <param name="ny">Number of elements in the transform along the second dimension</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="kindx">The kind of real-to-real transform to compute along the first dimension</param>
        /// <param name="kindy">The kind of real-to-real transform to compute along the second dimension</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_r2r_2d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr r2r_2d(int nx, int ny, IntPtr input, IntPtr output,
            fftw_kind kindx, fftw_kind kindy, fftw_flags flags);

        /// <summary>
        /// Creates a plan for a 3-dimensional real-to-real DFT
        /// </summary>
        /// <param name="nx">Number of elements in the transform along the first dimension</param>
        /// <param name="ny">Number of elements in the transform along the second dimension</param>
        /// <param name="nz">Number of elements in the transform along the third dimension</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="kindx">The kind of real-to-real transform to compute along the first dimension</param>
        /// <param name="kindy">The kind of real-to-real transform to compute along the second dimension</param>
        /// <param name="kindz">The kind of real-to-real transform to compute along the third dimension</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_r2r_3d",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr r2r_3d(int nx, int ny, int nz, IntPtr input, IntPtr output,
            fftw_kind kindx, fftw_kind kindy, fftw_kind kindz, fftw_flags flags);

        /// <summary>
        /// Creates a plan for an n-dimensional real-to-real DFT
        /// </summary>
        /// <param name="rank">Number of dimensions</param>
        /// <param name="n">Array containing the number of elements in the transform along each dimension</param>
        /// <param name="input">Pointer to an array of 8-byte real numbers</param>
        /// <param name="output">Pointer to an array of 8-byte real numbers</param>
        /// <param name="kind">An array containing the kind of real-to-real transform to compute along each dimension</param>
        /// <param name="flags">Flags that specify the behavior of the planner</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_plan_r2r",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr r2r(int rank, int[] n, IntPtr input, IntPtr output,
            fftw_kind[] kind, fftw_flags flags);

        /// <summary>
        /// Returns (approximately) the number of flops used by a certain plan
        /// </summary>
        /// <param name="plan">The plan to measure</param>
        /// <param name="add">Reference to double to hold number of adds</param>
        /// <param name="mul">Reference to double to hold number of muls</param>
        /// <param name="fma">Reference to double to hold number of fmas (fused multiply-add)</param>
        /// <remarks>Total flops ~= add+mul+2*fma or add+mul+fma if fma is supported</remarks>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_flops",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void flops(IntPtr plan, ref double add, ref double mul, ref double fma);

        /// <summary>
        /// Outputs a "nerd-readable" version of the specified plan to stdout
        /// </summary>
        /// <param name="plan">The plan to output</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_print_plan",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void print_plan(IntPtr plan);

        /// <summary>
        /// Exports the accumulated Wisdom to the provided filename
        /// </summary>
        /// <param name="filename">The target filename</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_export_wisdom_to_filename",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void export_wisdom_to_filename(string filename);


        /// <summary>
        /// Imports Wisdom from provided filename
        /// </summary>
        /// <param name="filename">The filename to read from</param>
        [DllImport("libfftw3-3-x64.dll",
             EntryPoint = "fftw_import_wisdom_from_filename",
             ExactSpelling = true,
             CallingConvention = CallingConvention.Cdecl)]
        public static extern void import_wisdom_from_filename(string filename);
    }

    public class MaxSampleEventArgs : EventArgs
    {
        [DebuggerStepThrough]
        public MaxSampleEventArgs(float minValue, float maxValue)
        {
            this.MaxSample = maxValue;
            this.MinSample = minValue;
        }
        public float MaxSample { get; private set; }
        public float MinSample { get; private set; }
    }

    public class FftEventArgs : EventArgs
    {
        [DebuggerStepThrough]
        public FftEventArgs(Complex[] result)
        {
            this.Result = result;
        }
        public Complex[] Result { get; private set; }
    }
}
