namespace ConsoleApplication1
{
    using System;
    using System.Data;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using Npgsql;
    using NpgsqlTypes;
    using System.Data.SqlClient;
    using System.Threading.Tasks;

    class Program
    {
        static void Main(string[] args)
        {
            /********************************************************PostgreSQL*********************************************************************/
            using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(
            "Server=localhost;Port=5432;User=postgres;Password=11010;Database=_036ce061_runtime;"))
            {
                // открыть соединение
                connectionPostgr.Open();

                // определить запрос
                using (NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM public.glossary", connectionPostgr))
                {
                    // выполнить запрос
                    using (NpgsqlDataReader reader = command.ExecuteReader())
                    {
                        // cчитать все строки и вывести все записи второго столбца communication
                        while (reader.Read())
                        {
                            Console.Write("{0}: {1}\n", reader[0], reader[1]);
                        }
                    }
                }

                // закрыть соединение
                connectionPostgr.Close();
            }

            /***********************************************************MS SQL**********************************************************************/
            string connectionString = @"Data Source=NO01\SQLEXPRESS;Initial Catalog=scada;Integrated Security=True";

            // Создание подключения
            SqlConnection connectionMSSQL = new SqlConnection(connectionString);
            try
            {
                // Открываем подключение
                connectionMSSQL.Open();
                Console.WriteLine("Подключение открыто");

                SqlCommand command = new SqlCommand();
                command.CommandText = "SELECT * FROM [scada].[dbo].[trends_data]";
                command.Connection = connectionMSSQL;

                // выполнить запрос
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    // cчитать все строки и вывести все записи второго столбца communication
                    while (reader.Read())
                    {
                        Console.Write("{0}: {1}\n", reader[0], reader[1]);
                    }
                }

            }
            catch (SqlException ex)
            {
                Console.WriteLine(ex.Message);
            }

            finally
            {
                // если подключение открыто
                if (connectionMSSQL.State == ConnectionState.Open)
                {
                    // закрываем подключение
                    connectionMSSQL.Close();
                    Console.WriteLine("Подключение закрыто...");
                }
            }
            Console.WriteLine("Программа завершила работу.");

            Console.ReadKey();
        }
    }
}
