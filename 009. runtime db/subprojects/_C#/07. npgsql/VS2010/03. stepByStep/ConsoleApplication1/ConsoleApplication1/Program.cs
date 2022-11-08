namespace ConsoleApplication1
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;

    using Npgsql;
    using NpgsqlTypes;

    class Program
    {
        static void Main(string[] args)
        {
            using (NpgsqlConnection connection = new NpgsqlConnection(
            "Server=localhost;Port=5432;User=postgres;Password=postgres;Database=runtime;"))
            {
                connection.Open();
                using (NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM public.Glossary", connection))
                {
                    using (NpgsqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                        }
                    }
                }
            }
        }
    }
}
