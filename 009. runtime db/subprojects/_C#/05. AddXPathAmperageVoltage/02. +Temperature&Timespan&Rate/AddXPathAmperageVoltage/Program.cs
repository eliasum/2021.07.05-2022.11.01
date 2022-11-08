/*2022.07.22 18:09 IMM*/
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

namespace AddXPathAmperageVoltage
{
    class Program
    {
        static void Main(string[] args)
        {
            /*
            ПРОГРАММА РАБОТАЕТ ТОЛЬКО ПОСЛЕ ПРИМЕНЕНИЯ СКРИПТА UPDATE К СООТВЕТСТВУЮЩЕЙ БД!
            */
            /****************************************************configurationXpaths****************************************************************/
            /*
                если принято 2 аргумента - пути ко входному и выходному файлам, а также
                что эти файлы существуют
            */
#if DEBUG
            string args0 = args[0];
#else
            string args0 = "config.xml";
#endif
            if (File.Exists(args0))
            {
                // переменная для нового Xml документа
                XmlDocument xDoc = new XmlDocument();

                // загрузить в переменную Xml документ из директории Resources
                xDoc.Load(args0);

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
                XmlNodeList nodes = xRoot.SelectNodes("//Amperage | //Voltage | //Item/Temperature | //Timespan | //Rate");

                XmlNodeList nodesA = xRoot.SelectNodes("//Amperage");
                XmlNodeList nodesV = xRoot.SelectNodes("//Voltage");
                XmlNodeList nodesT = xRoot.SelectNodes("//Item/Temperature");
                XmlNodeList nodesTs = xRoot.SelectNodes("//Timespan");
                XmlNodeList nodesR = xRoot.SelectNodes("//Rate");

                // XPath пути к тегам Amperage или Voltage столбца configuration таблицы glossary
                string[] configurationXpaths = new string[nodes.Count];

                // если контекст данных не пустой
                if (nodes != null)
                {
                    // узлы Amperage, Voltage, Item/Temperature, Timespan и Rate
                    node = null;

                    // индекс массива xpaths[]
                    int i = 0;

                    // имя текущего узла Amperage, Voltage, Item/Temperature, Timespan и Rate
                    string nodeName = null;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in nodes)
                    {
                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

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
                                    ancestorsPath = nodeName + "[@key=''" + node.SelectSingleNode("@key").Value + "'']" + "/" + ancestorsPath;
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
                    }
                }

                /****************************************************communicationXpaths****************************************************************/

                // XPath пути к тегам Amperage или Voltage столбца configuration таблицы glossary
                string[] communicationXpaths = new string[nodes.Count];

                // подключение в PostgreSQL
                using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                {
                    // открыть соединение
                    connectionPostgr.Open();

                    for (int i = 0; i < communicationXpaths.Length; i++)
                    {
                        // определить запрос
                        using (NpgsqlCommand command = new NpgsqlCommand("select communication from public.glossary where configuration = '" + configurationXpaths[i] + "'", connectionPostgr))
                        {
                            // выполнить запрос
                            using (NpgsqlDataReader reader = command.ExecuteReader())
                            {
                                // cчитать все строки и вывести все записи второго столбца communication
                                while (reader.Read())
                                {
                                    Console.Write("{0}\n", reader[0]);
                                    communicationXpaths[i] = reader[0].ToString();
                                }
                            }
                        }
                    }

                    // закрыть соединение
                    connectionPostgr.Close();
                }

                /*******************************************************Файл конфигурации БД************************************************************/

                // переменная для нового Xml документа
                XmlDocument Doc = new XmlDocument();

                // загрузить в переменную Xml документ из корневой директории
                Doc.Load(args0);

                // получим корневой элемент
                XmlNode Root = Doc.DocumentElement;

                // контекст данных
                XmlNodeList nodeList = Root.SelectNodes("//Amperage | //Voltage | //Item/Temperature | //Timespan | //Rate");

                if (nodeList != null)
                {
                    // индекс массива xpaths[]
                    int i = 0;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in nodeList)
                    {
                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // создаем новый элемент Communicator
                        XmlElement CommunicatorElem = Doc.CreateElement("Communicator");

                        node.AppendChild(CommunicatorElem);

                        // создаем атрибут XPath
                        XmlAttribute XPath = Doc.CreateAttribute("XPath");

                        CommunicatorElem.Attributes.Append(XPath);

                        // создаем текстовые значения для элементов и атрибута
                        XmlText XPathText = Doc.CreateTextNode(communicationXpaths[i]);

                        if (i != communicationXpaths.Length - 1) i++;

                        XPath.AppendChild(XPathText);
                    }

                    // сохранить в выходной файл
                    Doc.Save("config+Communicator.xml");
                }
            }
            else
            {
                Console.WriteLine("Нет входного и/или выходного файла!");
                Console.ReadKey();
            }
        }
    }
}