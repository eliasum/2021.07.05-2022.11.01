/*2022.07.07 11:01 IMM*/
namespace ConsoleApplication1
{
    using System;
    using System.Xml;
    using System.IO;
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
        // объект динамической строки builder
        static StringBuilder builderEx = new StringBuilder();
        static StringBuilder builderFile = new StringBuilder();

        static void Main(string[] args)
        {
            /*
                если принято 2 аргумента - пути ко входным файлам xml и XPath, а также
                что эти файлы существуют
            */
            if (args.Length == 2 && File.Exists(args[0]) && File.Exists(args[1]))
            {
                // переменная для нового Xml документа
                XmlDocument xDoc = new XmlDocument();

                // загрузить в переменную Xml документ из корневой директории
                xDoc.Load(args[0]);

                // получим корневой элемент
                XmlNode xRoot = xDoc.DocumentElement;

                // контекст данных
                XmlNode node = xRoot.SelectSingleNode("//Postgres/Item");

                // значения атрибутов текущего узла Item
                var key = node.SelectSingleNode("@key").Value.Split(new char[] { ':' }, 3);
                string login = node.SelectSingleNode("@login").Value;
                string password = node.SelectSingleNode("@password").Value;

                // строка подключения к PostgreSQL
                string connPostgrStr = "Server=" + key[0] + ";Port=" + key[1] + ";User=" + login + ";Password=" + password + ";Database=" + key[2];

                /********************************************************PostgreSQL*********************************************************************/

                // путь к файлу со списком XPath`ов
                string pathToFile = args[1];

                // число полных совпадений строк
                var count = 0;

                // число строк файла путей XPath
                int length = System.IO.File.ReadAllLines(pathToFile).Length;

                var valuesPostgres = new string[length];

                try
                {
                    using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                    {
                        // открыть соединение
                        connectionPostgr.Open();

                        // определить запрос
                        using (NpgsqlCommand command = new NpgsqlCommand("select * from public.glossary order by key asc", connectionPostgr))
                        {
                            // выполнить запрос
                            using (NpgsqlDataReader reader = command.ExecuteReader())
                            {
                                // cчитать все строки и вывести все записи второго столбца communication
                                while (reader.Read())
                                {
                                    Console.Write("{0}\n", reader[1]);

                                    // добавить в builderFile очередную строку
                                    builderFile.AppendLine(reader[1].ToString());
                                }
                            }

                            // сохранить данные БД на диск
                            File.WriteAllText("postgresql.txt", builderFile.ToString(), Encoding.GetEncoding(65001));
                        }

                        // закрыть соединение
                        connectionPostgr.Close();
                    }

                    // сравнение файла БД с исходным
                    using (var sr1 = new StreamReader(pathToFile))
                    using (var sr2 = new StreamReader("postgresql.txt"))
                    {
                        var w1 = sr1.ReadLine();
                        var w2 = sr2.ReadLine();

                        while (w1 != null && w2 != null)
                        {
                            var comp = w1.CompareTo(w2);

                            if (comp == 0)
                            {
                                Console.WriteLine(w1);
                                count++;
                            }

                            if (comp <= 0) w1 = sr1.ReadLine();
                            if (comp >= 0) w2 = sr2.ReadLine();
                        }
                    }

                    if (count == length)
                    {
                        using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                        {
                            // открыть соединение
                            connectionPostgr.Open();

                            // контекст данных
                            node = xRoot.SelectSingleNode("//MSSQL/Item");

                            // значения атрибутов текущего узла Item
                            key = node.SelectSingleNode("@key").Value.Split(new char[] { ':' }, 2);

                            // строка подключения к MSSQL
                            string connectionString = @"Data Source=" + key[0] + ";Initial Catalog=" + key[1] + ";Integrated Security=True";

                            // Создание подключения
                            SqlConnection connectionMSSQL = new SqlConnection(connectionString);

                            //Создание объекта для генерации чисел
                            Random rnd = new Random();

                            do
                            {

                                for (int i = 0; i < valuesPostgres.Length; i++)
                                {
                                    // определить запрос
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "UPDATE public.integer_actual SET fix = NOW(), value = " + rnd.Next(0, 100) + " WHERE key = " + i + ";", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }

                                }

                                // определить запрос
                                using (NpgsqlCommand command = new NpgsqlCommand("select * from public.integer_actual order by key asc", connectionPostgr))
                                {
                                    // выполнить запрос
                                    using (NpgsqlDataReader reader = command.ExecuteReader())
                                    {
                                        int i = 0;

                                        // cчитать все строки и вывести все записи второго столбца communication
                                        while (reader.Read())
                                        {
                                            Console.Write("{0}\n", reader[2]);

                                            valuesPostgres[i] = reader[2].ToString();
                                            i++;
                                        }
                                    }
                                }

                                /***********************************************************MS SQL**********************************************************************/
                                try
                                {
                                    // Открываем подключение
                                    connectionMSSQL.Open();

                                    Console.WriteLine("Подключение открыто");

                                    for (int i = 0; i < valuesPostgres.Length; i++)
                                    {
                                        SqlCommand command = new SqlCommand();

                                        command.CommandText = "INSERT [scada].[dbo].[trends_data] VALUES (" + i + ", CURRENT_TIMESTAMP, " + valuesPostgres[i] + ", 1)";

                                        command.Connection = connectionMSSQL;

                                        // выполнить запрос
                                        using (SqlDataReader reader = command.ExecuteReader()) { }

                                        // задержка 20с
                                        System.Threading.Thread.Sleep(200);
                                    }

                                    /*
                                        если в разделе PostgreSQL была ошибка, записанная в динамическую строку builder, то
                                        создать лог-файл и записать в него результирующую динамическую строку builder
                                    */
                                    if (builderEx != null)
                                        File.WriteAllText(string.Format("{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));
                                }

                                catch (Exception ex)
                                {
                                    // вывести сообщение об ошибке
                                    Console.WriteLine(ex.Message);

                                    // добавить в builderEx сообщение об ошибке
                                    builderEx.AppendLine(ex.Message);

                                    // создать лог-файл и записать в него результирующую динамическую строку builder
                                    File.WriteAllText(string.Format("{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));

                                    Environment.Exit(-1);
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
                            }

                            while (true);

                            // закрыть соединение
                            // connectionPostgr.Close();
                        }
                    }
                    else
                        if (count != length)
                        {
                            // добавить в builderEx сообщение об ошибке
                            builderEx.AppendLine("Файл БД не совпадает с исходным!");
                        }
                }

                catch (Exception ex)
                {
                    // вывести сообщение об ошибке
                    Console.WriteLine(ex.Message);

                    // добавить в builderEx сообщение об ошибке
                    builderEx.AppendLine(ex.Message);
                }
            }
            else
            {
                Console.WriteLine("Нет xml и/или xpath файла!");
                Console.ReadKey();
            }
        }
    }
}