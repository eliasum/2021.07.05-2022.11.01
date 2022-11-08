using System;

namespace _IMM.Library
{
    public class FFT
    {
        public static int FORWARD = 1;
        public static int INVERSE = -1;

        private int direction = FORWARD;

        public int Direction
        {
            get
            {
                return direction;
            }
            set
            {
                direction = value;
            }
        }

        public FFT()
        {
        }

        /// <summary>
        /// Compute the FFT. 
        /// Расчёт БПФ. 
        /// </summary>
        /// <param name="real"></param>
        /// <param name="imag"></param>
        public void Compute(double[] real, double[] imag)
        {
            double[] data = new double[2 * real.Length];

            int k = 0;

            // заполнение входного для метода four1() массива комплексных данных
            for (int i = 0; i < real.Length; i++)
            {
                data[k    ] = real[i];
                data[k + 1] = imag[i];

                k += 2;
            }

            // выполнение БПФ над массивом комплексных данных data[]
            four1(data, Direction);

            k = 0;

            // заполнение массивов real[] и imag[] результатами БПФ
            for (int i = 0; i < real.Length; i++)
            {
                real[i] = data[k    ];
                imag[i] = data[k + 1];

                k += 2;
            }
        }

        /// <summary>
        /// Цифровая реализация алгоритма Быстрого Преобразования Фурье (БПФ)
        /// </summary>
        /// <param name="data"></param>
        /// <param name="isign"></param>
        /// <returns></returns>
        public void four1(double[] data, int direction)
        {
            int nn = data.Length / 2;

            int n = nn << 1;

            double temp;

            for (int i = 1, j = 1; i < n; i += 2)
            {
                if (j > i)
                {
                    temp = data[i - 1];

                    data[i - 1] = data[j - 1];
                    data[j - 1] = temp;

                    temp = data[i];

                    data[i] = data[j];
                    data[j] = temp;
                }

                int m = nn;

                while (m >= 2 && j > m)
                {
                    j -= m;

                    m >>= 1;
                }

                j += m;
            }

            int mmax = 2;

            while (n > mmax)
            {
                int istep = mmax << 1;

                double tempr;
                double tempi;
                double theta    = direction * (2 * Math.PI / mmax);
                double wtemp    = Math.Sin(0.5 * theta);
                double wpr      = -2.0 * wtemp * wtemp;
                double wpi      = Math.Sin(theta);
                double wr       = 1.0;
                double wi       = 0.0;

                for (int m = 1; m < mmax; m += 2)
                {
                    for (int i = m; i <= n; i += istep)
                    {
                        int j = i + mmax;

                        tempr = wr * data[j - 1] - wi * data[j];
                        tempi = wr * data[j] + wi * data[j - 1];

                        data[j - 1] = data[i - 1] - tempr;
                        data[j    ] = data[i    ] - tempi;
                        
                        data[i - 1] += tempr;
                        data[i    ] += tempi;
                    }

                    wr = (wtemp = wr) * wpr - wi * wpi + wr;
                    wi = wi * wpr + wtemp * wpi + wi;
                }

                mmax = istep;
            }
        }
    }
}