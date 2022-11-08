/*2022.07.12 09:54 IMM*/
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
                если принят 1 аргумент - путь ко входному файлу xml, а также
                что этот файл существует
            */
            if (args.Length == 1 && File.Exists(args[0]))
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

                /*************************************************configurationXpathsFromXML************************************************************/

                // контекст данных
                XmlNodeList nodes = xRoot.SelectNodes("//Supply/Item");

                // XPath пути к тегам Amperage или Voltage столбца configuration таблицы glossary
                string[] configurationXpaths = new string[nodes.Count * 2];

                // путь к файлу со списком XPath`ов из файла XML
                string pathToXMLFile = "configurationXpathsFromXML.txt";

                // путь к файлу со списком XPath`ов из PostgreSQL
                string pathToPostgresqlFile = "configurationXpathsFromPostgresql.txt";

                if (nodes != null)
                {
                    // узлы Item
                    node = null;

                    // индекс массива xpaths[]
                    int i = 0;

                    // узлы Amperage или Voltage
                    XmlNodeList ChildNodes = null;

                    // имя текущего узла Amperage или Voltage
                    string nodeName = null;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in nodes)
                    {
                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // если текущий узел это Item
                        if (node.Name == "Item")
                        {
                            // дочерние узлы
                            ChildNodes = node.ChildNodes;

                            foreach (XmlElement сnode in ChildNodes)
                            {
                                // присвоить переменную цикла foreach переменной node
                                node = сnode;

                                // имя дочернего узла Amperage или Voltage
                                nodeName = node.Name;

                                // строка для записи названий всех предков (с учётом атрибута @key если есть) через символ "/"
                                string ancestorsPath = nodeName;

                                /*
                                    1й цикл while используется для вычисления строки пути XPath - последовательности имен узлов через "/",
                                    пока имя текущего узла не равно "Configuration" - корневому узлу xml документа
                                */
                                while (node.Name != "Configuration")
                                {
                                    // если текущий узел имеет родителя
                                    if (node.ParentNode != null)
                                    {
                                        // переходим на родителя текущего узла 
                                        node = node.ParentNode;

                                        // имя родителя текущего узла
                                        nodeName = node.Name;

                                        // если текущий узел имеет атрибуты @key
                                        if (node.SelectSingleNode("@key") != null)
                                            /*
                                                записать в строку ancestorsPath значение атрибута @key и "/" впереди 
                                                предыдущего значения ancestorsPath
                                            */
                                            ancestorsPath = nodeName + "[@key='" + node.SelectSingleNode("@key").Value + "']" + "/" + ancestorsPath;
                                        else
                                            ancestorsPath = nodeName + "/" + ancestorsPath;
                                    }
                                }
                                configurationXpaths[i] = ancestorsPath;
                                if (i != configurationXpaths.Length - 1) i++;
                            }

                            System.IO.File.WriteAllLines(pathToXMLFile, configurationXpaths);
                        }
                    }
                }

                /*************************************************configurationXpathsFromPostgresql***********************************************************/

                // число полных совпадений строк
                var count = 0;

                // число строк файла путей XPath
                int length = System.IO.File.ReadAllLines(pathToXMLFile).Length;

                var integer_actual = new string[length];
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
                            File.WriteAllText(pathToPostgresqlFile, builderFile.ToString(), Encoding.GetEncoding(65001));
                        }

                        // закрыть соединение
                        connectionPostgr.Close();
                    }

                    // сравнение файла БД с исходным
                    using (var sr1 = new StreamReader(pathToXMLFile))
                    using (var sr2 = new StreamReader(pathToPostgresqlFile))
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

                            // запрос к integer_actual для проверки наличия данных в integer_actual
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

                                        integer_actual[i] = reader[2].ToString();
                                        i++;

                                        if (i == valuesPostgres.Length)
                                            break;
                                    }
                                }
                            }

                            // если данные в integer_actual отсутствуют
                            if (integer_actual[0] == null)
                            {
                                // в PostgreSQL в таблицу integer_actual добавить НОВЫЕ случайные данные 
                                for (int i = 1; i < valuesPostgres.Length + 1; i++)
                                {
                                    // определить запрос
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "INSERT INTO public.integer_actual(key, fix, value) VALUES(" + i + ", NOW(), " + rnd.Next(0, 60) + ");", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }
                                }
                            }

                            // в ∞ цикле
                            do
                            {
                                // в PostgreSQL в таблице integer_actual обновить данные случайными числами   
                                for (int i = 0; i < valuesPostgres.Length; i++)
                                {
                                    // определить запрос
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "UPDATE public.integer_actual SET fix = NOW(), value = " + rnd.Next(0, 60) + " WHERE key = " + i + ";", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }

                                }

                                // считать из таблицы integer_actual данные и записать их в массив valuesPostgres[]
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

                                            if (i == valuesPostgres.Length)
                                                break;
                                        }
                                    }
                                }

                                /***********************************************************MS SQL**********************************************************************/
                                try
                                {
                                    // Открываем подключение
                                    connectionMSSQL.Open();

                                    Console.WriteLine("Подключение открыто");

                                    // записать в таблицу данных трендов массив valuesPostgres[]
                                    for (int i = 0; i < valuesPostgres.Length; i++)
                                    {
                                        SqlCommand command = new SqlCommand();

                                        command.CommandText = "INSERT [scada].[dbo].[trends_data] VALUES (" + i + ", CURRENT_TIMESTAMP, " + valuesPostgres[i] + ", 1)";

                                        command.Connection = connectionMSSQL;

                                        // выполнить запрос
                                        using (SqlDataReader reader = command.ExecuteReader()) { }

                                        // задержка 10с
                                        System.Threading.Thread.Sleep(100);
                                    }

                                    /*
                                        если в разделе PostgreSQL была ошибка, записанная в динамическую строку builder, то
                                        создать лог-файл и записать в него результирующую динамическую строку builder
                                    */
                                    if (builderEx != null)
                                    {
                                        // создать папку "Logs" если не существует
                                        if (!Directory.Exists("Logs")) Directory.CreateDirectory("Logs");

                                        File.WriteAllText(string.Format("Logs\\{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));
                                    }
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