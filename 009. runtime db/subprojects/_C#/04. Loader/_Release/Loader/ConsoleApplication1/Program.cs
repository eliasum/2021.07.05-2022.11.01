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
        static StringBuilder builderEx = new StringBuilder();

        static StringBuilder builderFile = new StringBuilder();

        const string IP_036CE062 = "192.168.3.89";              // ip компа во внутр. сети с именем "036CE062", где стоит БД postgreSQL
        const string WORK_SQLEXPRESS = "NO01\\SQLEXPRESS";      // экземпляр MS SQL Express на рабочем компе  
        static string DB_NAME;                                  // имя рабочей БД

        static void Main(string[] args)
        {
            if (!Directory.Exists("Logs")) Directory.CreateDirectory("Logs");
#if DEBUG
            string args0 = args[0];
#else
            string args0 = "config.xml";
#endif
            if (File.Exists(args0))
            {
                XmlDocument xDoc = new XmlDocument();

                xDoc.Load(args0);

                XmlNode xRoot = xDoc.DocumentElement;

                XmlNode node = xRoot.SelectSingleNode("//Postgres/Item");

                var key = node.SelectSingleNode("@key").Value.Split(new char[] { ':' }, 3);
                string login = node.SelectSingleNode("@login").Value;
                string password = node.SelectSingleNode("@password").Value;

                key[0] = IP_036CE062;   

                DB_NAME = key[2];

                string connPostgrStr = "Server=" + key[0] + ";Port=" + key[1] + ";User=" + login + ";Password=" + password + ";Database=" + key[2];

                /*************************************************configurationXpathsFromXML************************************************************/

                XmlNodeList nodes = xRoot.SelectNodes("//*[@type and not(@title='Команда')]");

                string[] configurationXpaths = new string[nodes.Count];

                string pathToXMLFile = "configurationXpathsFromXML.txt";

                string pathToPostgresqlFile = "configurationXpathsFromPostgresql.txt";

                if (nodes != null)
                {
                    node = null;

                    int i = 0;

                    string nodeName = null;

                    foreach (XmlElement xnode in nodes)
                    {
                        node = xnode;

                        nodeName = node.Name;

                        string ancestorsPath = nodeName;

                        while (node.Name != "Configuration")
                        {
                            if (node.ParentNode != null)
                            {
                                node = node.ParentNode;

                                nodeName = node.Name;

                                if (node.SelectSingleNode("@key") != null)

                                    ancestorsPath = nodeName + "[@key='" + node.SelectSingleNode("@key").Value + "']" + "/" + ancestorsPath;
                                else
                                    ancestorsPath = nodeName + "/" + ancestorsPath;
                            }
                        }

                        configurationXpaths[i] = ancestorsPath;
                        if (i != configurationXpaths.Length - 1) i++;

                        System.IO.File.WriteAllLines(pathToXMLFile, configurationXpaths);
                    }
                }

                /*************************************************configurationXpathsFromPostgresql***********************************************************/

                var count = 0;

                int length = System.IO.File.ReadAllLines(pathToXMLFile).Length;

                var valuesPostgres = new string[length];

                Random rnd = new Random();

                int j = 0; int _float_ = 0; int _int_ = 0; int _bool_ = 0;

                node = xRoot.SelectSingleNode("//MSSQL/Item");

                key = node.SelectSingleNode("@key").Value.Split(new char[] { ':' }, 2);

                //key[0] = WORK_SQLEXPRESS;       // экземпляр MS SQL Express на рабочем компе

                string connectionString = @"Data Source=" + key[0] + ";Initial Catalog=" + key[1] + ";Integrated Security=True";

                SqlConnection connectionMSSQL = new SqlConnection(connectionString);

                try
                {
                    using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                    {
                        connectionPostgr.Open();

                        using (NpgsqlCommand command = new NpgsqlCommand("select * from public.glossary order by key asc", connectionPostgr))
                        {
                            using (NpgsqlDataReader reader = command.ExecuteReader())
                            {
                                while (reader.Read())
                                {
                                    Console.Write("{0}\n", reader[1]);

                                    builderFile.AppendLine(reader[1].ToString());
                                }
                            }

                            File.WriteAllText(pathToPostgresqlFile, builderFile.ToString(), Encoding.GetEncoding(65001));
                        }

                        connectionPostgr.Close();
                    }

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
                            connectionPostgr.Open();

                            /********************************Проверка наличия данных actual*********************************/

                            foreach (XmlElement xnode in nodes)
                            {
                                if (xnode.Name == "Amperage" || xnode.Name == "Temperature" || xnode.Name == "Rate")
                                {
                                    if (j == valuesPostgres.Length) break;
                                    j++; _float_++;
                                }
                                if (xnode.Name == "Voltage" || xnode.Name == "Time")
                                {
                                    if (j == valuesPostgres.Length) break;
                                    j++; _int_++;
                                }
                                if (xnode.Name == "State")
                                {
                                    if (j == valuesPostgres.Length) break;
                                    j++; _bool_++;
                                }
                            }

                            connectionPostgr.Close();
                        }

                        do
                        {
                            using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                            {
                                connectionPostgr.Open();

                                /*******************************Заполнение массива valuesPostgres[], который будет записан в MS SQL********************************/

                                j = 0; _int_ = 1; _float_ = 1; _bool_ = 1;

                                foreach (XmlElement xnode in nodes)
                                {
                                    node = xnode;

                                    if (node.Name == "Amperage" || node.Name == "Temperature" || node.Name == "Rate")
                                    {
                                        using (NpgsqlCommand command = new NpgsqlCommand("SELECT xpath('//@value', entity)::TEXT FROM value_actual where key = " + _float_, connectionPostgr))
                                        {
                                            using (NpgsqlDataReader reader = command.ExecuteReader())
                                            {
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
                                    if (node.Name == "Voltage" || node.Name == "Time")
                                    {
                                        using (NpgsqlCommand command = new NpgsqlCommand("SELECT xpath('//@value', entity)::TEXT FROM value_actual where key = " + _int_, connectionPostgr))
                                        {
                                            using (NpgsqlDataReader reader = command.ExecuteReader())
                                            {
                                                while (reader.Read())
                                                {
                                                    Console.Write("{0}\n", reader[0]);

                                                    if (j == valuesPostgres.Length + 1) break;

                                                    valuesPostgres[j] = string.Join("+",reader[0].ToString());
                                                    j++; _int_++; break;
                                                }
                                            }
                                        }
                                    }
                                    if (node.Name == "State")
                                    {
                                        using (NpgsqlCommand command = new NpgsqlCommand("SELECT xpath('//@value', entity)::TEXT FROM value_actual where key = " + _bool_, connectionPostgr))
                                        {
                                            using (NpgsqlDataReader reader = command.ExecuteReader())
                                            {
                                                while (reader.Read())
                                                {
                                                    Console.Write("{0}\n", reader[0]);

                                                    if (j == valuesPostgres.Length + 1) break;

                                                    valuesPostgres[j] = reader[0].ToString();
                                                    j++; _bool_++; break;
                                                }
                                            }
                                        }
                                    }
                                }

                                connectionPostgr.Close();
                            }

                            /***********************************************************MS SQL**********************************************************************/
                            try
                            {
                                connectionMSSQL.Open();

                                Console.WriteLine("Подключение открыто");

                                for (int i = 0; i < valuesPostgres.Length; i++)
                                {
                                    SqlCommand command = new SqlCommand();

                                    valuesPostgres[i] = (string.Join("", valuesPostgres[i].Split('{', '+', '}','"'))).Replace(",", ".");

                                    //bool
                                    if (valuesPostgres[i] == "True" || valuesPostgres[i] == "true") valuesPostgres[i] = "1";
                                    if (valuesPostgres[i] == "False" || valuesPostgres[i] == "false") valuesPostgres[i] = "0";

                                    command.CommandText = "INSERT [" + DB_NAME + "].[dbo].[trends_data] VALUES (" + i + ", CURRENT_TIMESTAMP, " + valuesPostgres[i] + ", 1)";

                                    command.Connection = connectionMSSQL;

                                    using (SqlDataReader reader = command.ExecuteReader()) { }

                                    System.Threading.Thread.Sleep(100);
                                }

                                if (builderEx.Length != 0)
                                {
                                    File.WriteAllText(string.Format("Logs\\{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));
                                }

                                connectionMSSQL.Close();
                            }
                            catch (Exception ex)
                            {
                                Console.WriteLine(ex.Message);

                                builderEx.AppendLine(ex.Message);

                                File.WriteAllText(string.Format("Logs\\{0}.Log.txt", DateTime.Now.ToString("dd.MM.yyyy_HH.mm.ss")), builderEx.ToString(), Encoding.GetEncoding(65001));

                                Environment.Exit(-1);
                            }

                            finally
                            {
                                if (connectionMSSQL.State == ConnectionState.Open)
                                {
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
                            builderEx.AppendLine("Файл БД не совпадает с исходным!");
                        }
                }
                
                catch (Exception ex)
                {
                    Console.WriteLine(ex.Message);

                    builderEx.AppendLine(ex.Message);

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