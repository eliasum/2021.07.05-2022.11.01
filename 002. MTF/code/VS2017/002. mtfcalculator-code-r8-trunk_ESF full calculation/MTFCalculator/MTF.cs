using System;
using System.Drawing;

namespace MTFCalculator
{
    public static class MTF
    {
        /// <summary>
        /// Compute the Modulation Transfer Function.
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

            fft.Compute(real, imag);

            for (int i = 0; i < real.Length; i++)
            {
                real[i] = Math.Sqrt(real[i] * real[i] + imag[i] * imag[i]);
            }
        }

        public static double[] ZeroPad(double[] real)
        {
            int n = (int)Math.Pow(2.0, Math.Ceiling(Math.Log(real.Length, 2)));
            
            if (real.Length < n)
            {
                double[] padded = new double[n];

                int a = (int)Math.Floor((double)(n - real.Length) / 2);
                
                int b = a + real.Length;

                for (int i = 0; i < a; i++)
                {
                    padded[i] = 0.0;
                }

                for (int i = a; i < b; i++)
                {
                    padded[i] = real[i - a];
                }

                for (int i = b; i < n; i++)
                {
                    padded[i] = 0.0;
                }

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
