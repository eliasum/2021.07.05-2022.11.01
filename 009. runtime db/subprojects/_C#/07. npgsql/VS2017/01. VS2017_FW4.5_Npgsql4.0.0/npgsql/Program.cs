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
                    Console.WriteLine("not Open\n");
                }
                else
                {
                    Console.WriteLine("Open\n");

                    // Define a query
                    NpgsqlCommand cmd = new NpgsqlCommand("select val from foo_test;", nc);

                    // Execute a query
                    NpgsqlDataReader dr = cmd.ExecuteReader();

                    // Read all rows and output the first column in each row
                    while (dr.Read())
                        Console.Write("{0}\n", dr[0]);

                    // Close connection
                    nc.Close();

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
