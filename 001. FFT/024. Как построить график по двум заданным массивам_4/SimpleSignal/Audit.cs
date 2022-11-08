namespace FFTW
{
    using NAudio.Wave;
    using System;
    using System.Numerics;

    //using System.Numerics;

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
            Complex[] buffer = new Complex[value.Length];
            for (int i = 0; i < value.Length; i++)
            {
                buffer[i] = new Complex(value[i], 0);
                buffer[i] *= 1;
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
                // Check if it is splitted enough
                if (value != null && value.Length <= 1) { return value; }
                int n = value.Length >> 1;
                // Split even and odd
                Complex[] odd = new Complex[n];
                Complex[] even = new Complex[n];
                for (int i = 0; i < n; i++)
                {
                    even[i] = value[i * 2];
                    odd[i] = value[i * 2 + 1];
                }
                // Split on tasks
                even = Calculate(even);
                odd = Calculate(odd);
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
