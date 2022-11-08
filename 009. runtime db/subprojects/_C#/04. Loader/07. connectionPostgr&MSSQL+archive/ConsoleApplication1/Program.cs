/*2022.07.21 15:21 IMM*/
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
        /*
            объект динамической строки builder для генерации файлов логов с сообщениями 
            об ошибках
        */
        static StringBuilder builderEx = new StringBuilder();

        /*
            объект динамической строки builder для генериции файлов 
            "configurationXpathsFromPostgresql.txt" и "configurationXpathsFromXML.txt"
        */
        static StringBuilder builderFile = new StringBuilder();

        static void Main(string[] args)
        {
            // создать папку "Logs" если не существует
            if (!Directory.Exists("Logs")) Directory.CreateDirectory("Logs");

            /*
                если принят 1 аргумент - путь ко входному файлу config.xml, а также
                что этот файл существует
            */
#if DEBUG
            string args0 = args[0];
#else
            string args0 = "config.xml";
#endif
            if (File.Exists(args0))
            {
                // переменная для нового Xml документа config.xml
                XmlDocument xDoc = new XmlDocument();

                // загрузить в переменную Xml документ config.xml из корневой директории
                xDoc.Load(args0);

                // получим корневой элемент файла config.xml
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
                XmlNodeList nodes = xRoot.SelectNodes("//Amperage | //Voltage | //Item/Temperature | //Timespan | //Rate");

                XmlNodeList nodesA = xRoot.SelectNodes("//Amperage");
                XmlNodeList nodesV = xRoot.SelectNodes("//Voltage");
                XmlNodeList nodesT = xRoot.SelectNodes("//Item/Temperature");
                XmlNodeList nodesTs = xRoot.SelectNodes("//Timespan");
                XmlNodeList nodesR = xRoot.SelectNodes("//Rate");

                // XPath пути к тегам Amperage или Voltage столбца configuration таблицы glossary
                string[] configurationXpaths = new string[nodes.Count];

                // путь к файлу со списком XPath`ов из файла XML
                string pathToXMLFile = "configurationXpathsFromXML.txt";

                // путь к файлу со списком XPath`ов из PostgreSQL
                string pathToPostgresqlFile = "configurationXpathsFromPostgresql.txt";

                // если контекст данных не пустой
                if (nodes != null)
                {
                    // узлы Amperage, Voltage, Item/Temperature, Timespan и Rate
                    node = null;

                    // индекс массива xpaths[]
                    int i = 0;

                    // имя текущего узла Amperage или Voltage
                    string nodeName = null;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in nodes)
                    {
                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // имя узла Amperage, Voltage, Item/Temperature, Timespan и Rate
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

                        /*
                            заполнение массива configurationXpaths[] путями Xpaths к узлам Amperage, Voltage, Item/Temperature, 
                            Timespan и Rate ИМЕННО В ТОЙ последовательности, которая во входном XML файле
                        */
                        configurationXpaths[i] = ancestorsPath;
                        if (i != configurationXpaths.Length - 1) i++;

                        // сохранить массив configurationXpaths[] в файл "configurationXpathsFromXML.txt"
                        System.IO.File.WriteAllLines(pathToXMLFile, configurationXpaths);
                    }
                }

                /*************************************************configurationXpathsFromPostgresql***********************************************************/

                // число полных совпадений строк файлов "configurationXpathsFromPostgresql.txt" и "configurationXpathsFromXML.txt"
                var count = 0;

                // число строк файла путей XPath
                int length = System.IO.File.ReadAllLines(pathToXMLFile).Length;

                // параметр наличия данных в таблице integer_actual
                string int_act_notNull = null;

                // параметр наличия данных в таблице float_actual
                string float_act_notNull = null;

                // значения параметров Amperage, Voltage, Item/Temperature, Timespan и Rate из PostgreSQL
                var valuesPostgres = new string[length];

                //Создание объекта для генерации чисел
                Random rnd = new Random();

                /*
                    j - индекс при заполнении массива valuesPostgres[]
                    _float_ - количество значений float в массиве valuesPostgres[]
                    _int_ - количество значений int в массиве valuesPostgres[]
                */
                int j = 0; int _float_ = 0; int _int_ = 0;

                // контекст данных
                node = xRoot.SelectSingleNode("//MSSQL/Item");

                // значения атрибутов текущего узла Item
                key = node.SelectSingleNode("@key").Value.Split(new char[] { ':' }, 2);

                // строка подключения к MSSQL
                string connectionString = @"Data Source=" + key[0] + ";Initial Catalog=" + key[1] + ";Integrated Security=True";

                // Создание подключения
                SqlConnection connectionMSSQL = new SqlConnection(connectionString);

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

                    // сравнение файла XPath`ов из БД с файлом XPath`ов из входного XML
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

                    // если длина файла XPath`ов из БД совпадает с длиной файлом XPath`ов из входного XML
                    if (count == length)
                    {
                        using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                        {
                            // открыть соединение
                            connectionPostgr.Open();

                            /********************************Проверка наличия данных actual и INSERT случайных чисел в случае NULL*********************************/

                            /*
                                вычисление _int_ и _float_
                            */
                            // обход всех узлов в элементах nodes
                            foreach (XmlElement xnode in nodes)
                            {
                                if (xnode.Name == "Amperage" || xnode.Name == "Temperature" && xnode.ParentNode.Name == "Item" || xnode.Name == "Rate")
                                {
                                    if (j == valuesPostgres.Length) break;
                                    j++; _float_++;
                                }
                                if (xnode.Name == "Voltage" || xnode.Name == "Timespan")
                                {
                                    if (j == valuesPostgres.Length) break;
                                    j++; _int_++; 
                                }
                            }

                            // запрос к integer_actual для проверки наличия данных в integer_actual
                            // INTEGER
                            using (NpgsqlCommand command = new NpgsqlCommand("select value from public.integer_actual where key = 1", connectionPostgr))
                            {
                                // выполнить запрос
                                using (NpgsqlDataReader reader = command.ExecuteReader())
                                {
                                    // cчитать все строки и вывести все записи второго столбца communication
                                    while (reader.Read())
                                    {
                                        Console.Write("{0}\n", reader[0]);

                                        int_act_notNull = reader[0].ToString();
                                        break;
                                    }
                                }
                            }

                            // если данные в integer_actual отсутствуют
                            if (int_act_notNull == null)
                            {
                                // в PostgreSQL в таблицу integer_actual добавить НОВЫЕ случайные данные 
                                for (int i = 1; i < _int_ + 1; i++)
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

                            // FLOAT
                            using (NpgsqlCommand command = new NpgsqlCommand("select value from public.float_actual where key = 1", connectionPostgr))
                            {
                                // выполнить запрос
                                using (NpgsqlDataReader reader = command.ExecuteReader())
                                {
                                    // cчитать все строки и вывести все записи второго столбца communication
                                    while (reader.Read())
                                    {
                                        Console.Write("{0}\n", reader[0]);

                                        float_act_notNull = reader[0].ToString();
                                        break;
                                    }
                                }
                            }

                            // если данные в float_actual отсутствуют
                            if (float_act_notNull == null)
                            {
                                // в PostgreSQL в таблицу float_actual добавить НОВЫЕ случайные данные 
                                for (int i = 1; i < _float_ + 1; i++)
                                {
                                    // определить запрос
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "INSERT INTO public.float_actual(key, fix, value) VALUES(" + i + ", NOW(), " + ((float)rnd.NextDouble() * 60).ToString().Replace(",", ".") + ");", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }
                                }
                            }

                            // закрыть соединение
                            connectionPostgr.Close();
                        }

                        // в ∞ цикле
                        do
                        {
                            using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                            {
                                // открыть соединение
                                connectionPostgr.Open(); int intRand = 0; float floatRand = 0;

                                /******************************Обновление данных actual случайными числами и добавление данных в archive***************************/
                                  
                                for (int i = 1; i < nodesV.Count + nodesTs.Count + 1; i++)
                                {
                                    intRand = rnd.Next(0, 60);

                                    // в PostgreSQL в таблице integer_actual обновить данные случайными числами 
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "UPDATE public.integer_actual SET fix = NOW(), value = " + intRand + " WHERE key = " + i + ";", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }

                                    // в PostgreSQL в таблицу integer_archive добавить случайные числа 
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "INSERT INTO public.integer_archive(key, fix, value) VALUES(" + i + ", NOW(), " + intRand + ");", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }
                                }

                                for (int i = 1; i < nodesA.Count + nodesT.Count + nodesR.Count + 1; i++)
                                {
                                    floatRand = ((float)rnd.NextDouble() * 60);

                                    // в PostgreSQL в таблице float_actual обновить данные случайными числами   
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "UPDATE public.float_actual SET fix = NOW(), value = " + floatRand.ToString().Replace(",", ".") + " WHERE key = " + i + ";", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }

                                    // в PostgreSQL в таблицу float_archive добавить случайные числа 
                                    using (NpgsqlCommand command = new NpgsqlCommand(
                                        "INSERT INTO public.float_archive(key, fix, value) VALUES(" + i + ", NOW(), " + floatRand.ToString().Replace(",", ".") + ");", connectionPostgr))
                                    {
                                        // выполнить запрос
                                        using (command.ExecuteReader()) { }
                                    }
                                }

                                /*******************************Заполнение массива valuesPostgres[], который будет записан в MS SQL********************************/
                                /*
                                    заполнение массива valuesPostgres[] значениями Amperage из таблицы float_actual и Voltage 
                                    из таблицы integer_actual в соответствии с путями Xpaths к узлам Amperage или Voltage 
                                    ИМЕННО В ТОЙ последовательности, которая во входном XML файле
                                */
                                j = 0; _int_ = 1; _float_ = 1;

                                // обход всех узлов в элементах nodes
                                foreach (XmlElement xnode in nodes)
                                {
                                    // присвоить переменную цикла foreach переменной node
                                    node = xnode;

                                    if (node.Name == "Amperage" || node.Name == "Temperature" && node.ParentNode.Name == "Item" || node.Name == "Rate")
                                    {
                                        using (NpgsqlCommand command = new NpgsqlCommand("select value from public.float_actual where key = " + _float_, connectionPostgr))
                                        {
                                            // выполнить запрос
                                            using (NpgsqlDataReader reader = command.ExecuteReader())
                                            {
                                                // cчитать все строки и вывести все записи второго столбца communication
                                                while (reader.Read())
                                                {
                                                    Console.Write("{0}\n", reader[0]);

                                                    if (j == valuesPostgres.Length + 1) break;

                                                    valuesPostgres[j] = reader[0].ToString();
                                                    j++; _float_++; break;
                                                }
                                            }
                                        }
                                    }
                                    if (node.Name == "Voltage" || node.Name == "Timespan")
                                    {
                                        using (NpgsqlCommand command = new NpgsqlCommand("select value from public.integer_actual where key = " + _int_, connectionPostgr))
                                        {
                                            // выполнить запрос
                                            using (NpgsqlDataReader reader = command.ExecuteReader())
                                            {
                                                // cчитать все строки и вывести все записи второго столбца communication
                                                while (reader.Read())
                                                {
                                                    Console.Write("{0}\n", reader[0]);

                                                    if (j == valuesPostgres.Length + 1) break;

                                                    valuesPostgres[j] = reader[0].ToString();
                                                    j++; _int_++; break;
                                                }
                                            }
                                        }
                                    }
                                }

                                // закрыть соединение
                                connectionPostgr.Close();
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

                                    command.CommandText = "INSERT [scada].[dbo].[trends_data] VALUES (" + i + ", CURRENT_TIMESTAMP, " + valuesPostgres[i].Replace(",", ".") + ", 1)";

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
                                    File.WriteAllText(string.Format("Logs\\{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));
                                }

                                // закрыть соединение
                                connectionMSSQL.Close();
                            }
                            
                                catch (Exception ex)
                                {
                                    // вывести сообщение об ошибке
                                    Console.WriteLine(ex.Message);

                                    // добавить в builderEx сообщение об ошибке
                                    builderEx.AppendLine(ex.Message);

                                    // создать лог-файл и записать в него результирующую динамическую строку builder
                                    File.WriteAllText(string.Format("Logs\\{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));

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

                    // создать лог-файл и записать в него результирующую динамическую строку builder
                    File.WriteAllText(string.Format("Logs\\{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));

                    Environment.Exit(-1);
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