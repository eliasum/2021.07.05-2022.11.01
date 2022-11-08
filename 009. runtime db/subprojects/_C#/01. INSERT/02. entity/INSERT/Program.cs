/*2022.08.01 17:08 IMM*/
/*2022.08.03 19:36 IMM*/

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

            string[] tableNames = { "entity_actual", "entity_archive" };

            Random random = new Random();

            const int count = 340;

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
                            w.Write("INSERT INTO " +
                                     tableNames[j] + "(key, fix, entity) VALUES(" +
                                      i.ToString() + ", NOW() + interval '" +
                                      (i * Math.Round(GetRandomNumber(random, 1.2144, 14.34213), 0)).ToString() + " millisecond', '<a><b order=''" +
                                      Math.Round(GetRandomNumber(random, 1.2144, 99.34213), 2) + "'' /></a> ');\n");
                        }
                    }
                }
            }

            using (var output = File.Create(@"sql\INSERT to entity tables.sql"))
            {
                foreach (var file in new[] { @"sql\entity_actual.sql", @"sql\entity_archive.sql" })
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
