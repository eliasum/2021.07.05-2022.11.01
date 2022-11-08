/*2022.03.30 17:36 IMM*/
/*2022.06.30 18:58 IMM*/
/*2022.07.25 11:11 IMM*/

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace INSERT
{
    class Program
    {
        static double GetRandomNumber(Random random, double minimum, double maximum)
        {
            return random.NextDouble() * (maximum - minimum) + minimum;
        }

        static void Main(string[] args)
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("en-US");

            string[] tableNames = { "float_actual", "float_archive", "integer_actual", "integer_archive" };

            Random random = new Random();

            const int count = 254;

            if (!Directory.Exists("sql")) Directory.CreateDirectory("sql");

            for (int j = 0; j < tableNames.Length; j++)
            {
                using (StreamWriter w = new StreamWriter(@"sql\" + tableNames[j] + ".sql", false, Encoding.GetEncoding(1251)))
                {
                    int type=1;
                    if (tableNames[j].Contains("archive")) type = 2; 

                    for (int k = 0; k < type; k++)
                    {
                        for (int i = 1; i < count + 1; i++)
                        {
                            /*
                            w.Write("INSERT INTO " +
                                        tableNames[j] + "(key, fix, value) VALUES(" +
                                        i.ToString() + ", NOW()::TIMESTAMP WITH TIME ZONE + interval '" +
                                        (i* Math.Round(GetRandomNumber(random, 1.2144, 14.34213), 0)).ToString() + " millisecond', " +
                                        Math.Round(GetRandomNumber(random, 1.2144, 145.34213), 2) + ");\n");
                            */
                            w.Write("INSERT INTO " +
                                     tableNames[j] + "(key, fix, value) VALUES(" +
                                      i.ToString() + ", NOW() + interval '" +
                                      (i * Math.Round(GetRandomNumber(random, 1.2144, 14.34213), 0)).ToString() + " millisecond', " +
                                      Math.Round(GetRandomNumber(random, 1.2144, 99.34213), 2) + ");\n");
                        }
                    }
                }
            }

            using (var output = File.Create(@"sql\INSERT to tables.sql"))
            {
                foreach (var file in new[] { @"sql\float_actual.sql", @"sql\float_archive.sql", @"sql\integer_actual.sql", @"sql\integer_archive.sql" })
                {
                    using (var input = File.OpenRead(file))
                    {
                        input.CopyTo(output);
                    }
                }
            }

            Console.WriteLine("Ok");
            Console.ReadKey();
        }
    }
}
