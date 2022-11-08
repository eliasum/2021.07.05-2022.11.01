using System;
using System.Data;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Npgsql;

namespace npgsql
{
    class Program
    {
        static void Main(string[] args)
        {
            var connString = "Host=localhost;Username=postgres;Password=11010;Database=runtime";

            try
            {
                NpgsqlConnection nc = new NpgsqlConnection(connString);

                //Открываем соединение.
                nc.Open();

                if (nc.FullState == ConnectionState.Broken || nc.FullState == ConnectionState.Closed)
                {
                    Console.WriteLine("not Open");
                }
                else
                {
                    Console.WriteLine("Open");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }

            Console.ReadKey();
        }
    }
}
