namespace SimpleScadaTrend
{
    using System;
    using System.Xml;
    using System.IO;
    using System.Text;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
    using System.Linq;
    using System.Drawing;
    using System.Text.RegularExpressions;
    using Npgsql;
    using NpgsqlTypes;

    public class Program
    {
        static readonly string file = "Trends.str";

        /// <summary>
        /// Метод преобразования строки hex в массив байт dec
        /// </summary>
        /// <param name="str">Cтрока hex</param>
        /// <returns></returns>
        public static byte[] HexToByte(string str)
        {
            return str.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).Select(i => byte.Parse(i, System.Globalization.NumberStyles.HexNumber)).ToArray();
        }

        /// <summary>
        /// Метод преобразования целого числа в массив байт
        /// </summary>
        /// <param name="value">значение числа</param>
        /// <param name="count">количество байт выходного массива</param>
        /// <returns></returns>
        public static byte[] IntToBytes(int value, int count)
        {
            var buffer = new byte[count];

            for (int i = 0; i < count; i++)
            {
                buffer[i] = (byte)((value >> 8 * (count - 1 - i)) & 0xff);
            }

            return buffer;
        }

        /*
            объект динамической строки builder для генериции файлов 
            "configurationXpathsFromPostgresql.txt" и "communicationXpathsFromPostgresql.txt"
        */
        static StringBuilder builderFile = new StringBuilder();

        static void Main(string[] args)
        {
            /*
                если принят 1 аргумент - путь ко входному файлу Configuration.xml, а также
                что этот файл существует
            */
#if DEBUG
            string configuration = args[0];
            string communication = args[1];
#else
            string configuration = "Configuration.xml";
            string communication = "Communication.xml";
#endif
            if (File.Exists(configuration) && File.Exists(communication))
            {
                // переменные для новых Xml документов
                XmlDocument configurationDoc = new XmlDocument();
                XmlDocument communicationDoc = new XmlDocument();

                // загрузить в переменную Xml документ из корневой директории
                configurationDoc.Load(configuration);
                communicationDoc.Load(communication);

                // получим корневой элемент
                XmlNode configurationRoot = configurationDoc.DocumentElement;
                XmlNode communicationRoot = communicationDoc.DocumentElement;

                // контекст данных
                XmlNode node = communicationRoot.SelectSingleNode("//Postgres/Item");

                // значения атрибутов текущего узла Item
                var key = node.SelectSingleNode("@key").Value.Split(new char[] { ':' }, 3);
                string login = node.SelectSingleNode("@login").Value;
                string password = node.SelectSingleNode("@password").Value;

                // строка подключения к PostgreSQL
                string connPostgrStr = "Server=" + key[0] + ";Port=" + key[1] + ";User=" + login + ";Password=" + password + ";Database=" + key[2];

                // контекст данных
                XmlNodeList communicationNodes = communicationRoot.SelectNodes("//*[@type]"); // "//*[@type and @unit]"
                //XmlNodeList configurationNodes = null;
                XmlNode[] configurationNodes = new XmlNode[communicationNodes.Count];

                // путь к файлу со списком XPath`ов из файла XML
                string pathToXMLFile = "communicationXpathsFromXML.txt";

                // путь к файлу со списком Configuration XPath`ов из PostgreSQL
                string pathToConfigurationPostgresqlFile = "configurationXpathsFromPostgresql.txt";

                // путь к файлу со списком Configuration узлов из PostgreSQL
                string сonfigurationNodesFile = "configurationNodesFile.txt";

                // путь к файлу со списком Communication XPath`ов из PostgreSQL
                string pathToCommunicationPostgresqlFile = "communicationXpathsFromPostgresql.txt";

                // путь к файлу со списком Captions
                string captionsFile = "captionsFile.txt";

                // XPath пути к тегам с атрибутом @type столбца configuration таблицы glossary
                string[] configurationXpaths = new string[communicationNodes.Count];

                // XPath пути к тегам с атрибутом @type столбца communication таблицы glossary
                string[] communicationXpaths = new string[communicationNodes.Count];

                // список названий трендов
                List<string> listCaptions = new List<string>();
                string[] arrCaptions = new string[communicationNodes.Count];
                string[] arrCaptionsNotNull = null;

                // список цветов перьев трендов
                List<byte[]> listColors = new List<byte[]>();
                byte[][] arrColors = new byte[communicationNodes.Count][];
                byte[][] arrColorsNotNull = null;

                // единицы измерения трендов
                List<string> listUnits = new List<string>();
                string[] arrUnits = new string[communicationNodes.Count];
                string[] arrUnitsNotNull = null;

                // минимальное значение переменной (шкалы) тренда
                List<string> listMinimum = new List<string>();
                string[] arrMinimum = new string[communicationNodes.Count];
                string[] arrMinimumNotNull = null;

                // максимальное значение переменной (шкалы) тренда
                List<string> listMaximum = new List<string>();
                string[] arrMaximum = new string[communicationNodes.Count];
                string[] arrMaximumNotNull = null;

                /*********************************************************communicationXpathsFromXML***************************************************************/

                // если контекст данных не пустой
                if (communicationNodes != null)
                {
                    // узлы с атрибутом @type
                    node = null;

                    // индекс массива xpaths[]
                    int i = 0;

                    // имя текущего узла с атрибутом @type
                    string nodeName = null;

                    // обход всех узлов в элементах communicationNodes
                    foreach (XmlElement xnode in communicationNodes)
                    {
                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // имя узла с атрибутом @type
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
                            заполнение массива configurationXpaths[] путями Xpaths к узлам с атрибутом @type
                            ИМЕННО В ТОЙ последовательности, которая во входном XML файле
                        */
                        communicationXpaths[i] = ancestorsPath;
                        if (i != communicationXpaths.Length - 1) i++;

                        // сохранить массив configurationXpaths[] в файл "configurationXpathsFromXML.txt"
                        System.IO.File.WriteAllLines(pathToXMLFile, communicationXpaths);
                    }
                }

                /******************************************************communicationXpathsFromPostgresql***********************************************************/

                // число полных совпадений строк файлов "communicationXpathsFromPostgresql.txt" и "communicationXpathsFromXML.txt"
                var count = 0;

                // число строк файла путей XPath
                int length = System.IO.File.ReadAllLines(pathToXMLFile).Length;

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
                        File.WriteAllText(pathToCommunicationPostgresqlFile, builderFile.ToString(), Encoding.GetEncoding(65001));
                    }

                    // очистить объект динамической строки builder
                    builderFile.Clear();

                    // закрыть соединение
                    connectionPostgr.Close();
                }

                // сравнение файла XPath`ов из БД с файлом XPath`ов из входного XML
                using (var sr1 = new StreamReader(pathToXMLFile))
                using (var sr2 = new StreamReader(pathToCommunicationPostgresqlFile))
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

                /******************************************************configurationXpathsFromPostgresql***********************************************************/

                // если длина файла XPath`ов из БД совпадает с длиной файлом XPath`ов из входного XML
                if (count == length)
                {
                    using (NpgsqlConnection connectionPostgr = new NpgsqlConnection(connPostgrStr))
                    {
                        // открыть соединение
                        connectionPostgr.Open();

                        for (int i = 0; i < communicationXpaths.Length; i++)
                        {
                            // определить запрос
                            using (NpgsqlCommand command = new NpgsqlCommand("select configuration from glossary where communication = '" + communicationXpaths[i].Replace("'", "''") + "'", connectionPostgr))
                            {
                                // выполнить запрос
                                using (NpgsqlDataReader reader = command.ExecuteReader())
                                {
                                    // cчитать все строки и вывести все записи второго столбца communication
                                    while (reader.Read())
                                    {
                                        Console.Write("{0}\n", reader[0]);

                                        configurationXpaths[i] = reader[0].ToString();

                                        // добавить в builderFile очередную строку
                                        builderFile.AppendLine(reader[0].ToString());
                                    }
                                }
                            }
                        }

                        // сохранить данные БД на диск
                        File.WriteAllText(pathToConfigurationPostgresqlFile, builderFile.ToString(), Encoding.GetEncoding(65001));

                        // очистить объект динамической строки builder
                        builderFile.Clear();

                        // закрыть соединение
                        connectionPostgr.Close();
                    }
                }
                /**********************************************************configurationNodes**********************************************************************/

                for (int i = 0; i < configurationXpaths.Length; i++)
                {
                    // если есть значение NULL - исправить файл _036CE062.UPDATE.sql
                    configurationNodes[i] = configurationRoot.SelectSingleNode("//" + configurationXpaths[i]);

                    if (configurationNodes[i] != null)
                    {
                        // добавить в builderFile очередную строку
                        builderFile.AppendLine(configurationNodes[i].ToString());
                    }
                    else
                    {
                        // добавить в builderFile очередную строку
                        builderFile.AppendLine("null");
                    }
                }

                // сохранить данные БД на диск
                File.WriteAllText(сonfigurationNodesFile, builderFile.ToString(), Encoding.GetEncoding(65001));

                // очистить объект динамической строки builder
                builderFile.Clear();

                /****************************************************************units*****************************************************************************/

                if (communicationNodes != null)
                {
                    // узлы с атрибутом @type
                    node = null;

                    // индекс массива Units[]
                    int u = 0;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in communicationNodes)
                    {
                        // присвоить переменную цикла foreach переменной nodeSup
                        node = xnode;

                        // значение атрибута @unit тега Voltage без символов '[' и ']'
                        arrUnits[u] = node.SelectSingleNode("@unit").Value.Trim(new char[] { '[', ']' }); u++;
                    }
                }

                /****************************************************************min&max***************************************************************************/

                if (communicationNodes != null)
                {
                    // текущий узел контекста данных
                    node = null;

                    // индексы массивов Minimum[] и Maximum[]
                    int min = 0, max = 0;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in communicationNodes)
                    {
                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // контекст данных
                        XmlNodeList limitNode = node.SelectNodes("Limit/*");

                        // если текущий узел это Item
                        if (limitNode != null)
                        {
                            // обход всех узлов в элементах limitNode
                            foreach (XmlElement ynode in limitNode)
                            {
                                // присвоить переменную цикла foreach переменной node
                                node = ynode;

                                // значение атрибута @const тега Minimum без символов '[' и ']'
                                arrMinimum[min] = node.SelectSingleNode("Minimum").SelectSingleNode("@const").Value;

                                // значение атрибута @const тега Maximum без символов '[' и ']'
                                arrMaximum[max] = node.SelectSingleNode("Maximum").SelectSingleNode("@const").Value;
                            }
                        }
                        // заполнение массивов Minimum[] и Maximum[] происходит в правильном порядке с учётом значений null
                        else
                        {
                            arrMinimum[min] = null;
                            arrMaximum[max] = null;
                        }

                        min++; max++;
                    }
                }

                /**********************************************************************colors**********************************************************************/

                // контекст данных
                XmlNodeList penNodes = configurationRoot.SelectNodes("//Pen/*");

                if (penNodes != null)
                {
                    /*
                        переменная node используется для вычисления родительских узлов текущего
                        атрибута Item, удовлетворяющих условию наличия атрибутов @key и @title
                    */
                    node = null;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in penNodes)
                    {
                        // значение атрибута @key текущего узла Item
                        string xpath = null;

                        // значение атрибута @title текущего узла Item
                        string caption = null;

                        // строковая переменная цвета
                        string strcolor;

                        // переменная цвета
                        Color color;

                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // если текущий узел это Item
                        if (node.Name == "Item")
                        {
                            /****************************************************************captions**************************************************************/
                            int indexOfCaption=0;

                            // значение атрибута @key тега Item
                            xpath = node.SelectSingleNode("@key").Value;

                            // значение атрибута @title тега Item
                            caption = node.SelectSingleNode("@title").Value;

                            // значение атрибута @value тега Color, дочернего для Item
                            strcolor = node.SelectSingleNode("Color").SelectSingleNode("@value").Value;

                            // получить цвет RGB из строки системного названия цвета 
                            color = Color.FromName(strcolor);

                            // преобразовать цвет в hex
                            string hex = color.B.ToString("X2") + ' ' + color.G.ToString("X2") + ' ' + color.R.ToString("X2");

                            if (xpath != null && xpath != "")
                            {
                                /*
                                    2й цикл while используется для вычисления второй части строки названия текущего пера - значения 
                                    атрибута @title узла, указанного в значении атрибута @key текущего узла Item, 
                                    который находится в переменной xpath, например, "Ток", пока первый выбранный узел не будет иметь 
                                    путь, указанный в переменной xpath, будем перемещаться к родительскому узлу.
                                    Тогда полная строка текущего пера, например, - "АРМ: СУБД: Установка {@key}: Поз.№ {@key}: Ток"
                                */
                                while (node != null)
                                {
                                    /*
                                        если первый выбранный узел не находится по пути xpath, тогда перемещаемся на родительский узел
                                    */
                                    if (node.SelectSingleNode(xpath) == null) node = node.ParentNode;

                                    /*
                                        иначе возвращаем полное значение строки названия текущего пера, где node.SelectSingleNode(xpath).Value - 
                                        значение первого выбранного узла ("Item[@key='photocathode']/Amperage/@title") по пути из переменной
                                        xpath, т.е. "Ток"
                                    */
                                    else
                                    {
                                        node = node.SelectSingleNode(xpath);

                                        for (int i = 0; i < configurationNodes.Length; i++)
                                        {
                                            if (configurationNodes[i] == node) indexOfCaption = i;
                                        }

                                        arrCaptions[indexOfCaption] = caption;
                                        arrColors[indexOfCaption] = HexToByte(hex);

                                        break;
                                    }
                                }
                            }
                            else
                            {
                                Console.WriteLine("XPath is not valid!");
                            }
                        }
                        else
                        {
                            Console.WriteLine("Element is not Item!");
                        }
                    }
                }

                // заполнение списков непустыми значениями и сохранение в файл списка arrCaptions
                for (int i = 0; i < arrCaptions.Length; i++)
                {
                    if (arrCaptions[i] != null && 
                        arrColors[i] != null && 
                        arrUnits[i] != null && 
                        arrMinimum[i] != null && 
                        arrMaximum[i] != null)
                    {
                        listCaptions.Add(arrCaptions[i]);
                        listColors.Add(arrColors[i]);
                        listUnits.Add(arrUnits[i]);
                        listMinimum.Add(arrMinimum[i]);
                        listMaximum.Add(arrMaximum[i]);

                        // добавить в builderFile очередную строку
                        builderFile.AppendLine(arrCaptions[i]);
                    }
                    else
                    {
                        // добавить в builderFile очередную строку
                        builderFile.AppendLine("null");
                    }
                }

                arrCaptionsNotNull = new string[listCaptions.Count];
                arrColorsNotNull = new byte[listColors.Count][];
                arrUnitsNotNull = new string[listUnits.Count];
                arrMinimumNotNull = new string[listMinimum.Count];
                arrMaximumNotNull = new string[listMaximum.Count];

                arrCaptionsNotNull = listCaptions.ToArray();
                arrColorsNotNull = listColors.ToArray();
                arrUnitsNotNull = listUnits.ToArray();
                arrMinimumNotNull = listMinimum.ToArray();
                arrMaximumNotNull = listMaximum.ToArray();

                // сохранить данные БД на диск
                File.WriteAllText(captionsFile, builderFile.ToString(), Encoding.GetEncoding(65001));

                // очистить объект динамической строки builder
                builderFile.Clear();

                // количество:

                // трендов
                int trendsCount = listCaptions.Count;

                // трендов на группу
                const int trendCountPerGroup = 10;

                // групп
                int groupsCount = (int)Math.Ceiling((double)trendsCount / (double)trendCountPerGroup);

                // разделов
                int sectionsCount = 1;

                /***************************************************************Тренды*****************************************************************************/
                Trend[] trends = new Trend[trendsCount];

                for (int i = 0; i < trendsCount; i++)
                {
                    trends[i] = new Trend();

                    trends[i].Position1m = i;
                    trends[i].Name = string.Format("Trend{0}", i + 1);
                    trends[i].LengthName = trends[i].Name.Length;
                    trends[i].CaptionLenght = trends[i].СalcCaptLength(arrCaptionsNotNull[i]);
                    trends[i].Caption = string.Format(arrCaptionsNotNull[i]);
                    trends[i].Color = arrColorsNotNull[i];
                    trends[i].ID = (ulong)i;
                    trends[i].numbVarTrendNumber = 45089;                // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                    trends[i].setPosition = 0;
                    trends[i].showScale = 1;
                }

                // список групп по trendCountPerGroup трендов
                List<Trend[]> groupsList = new List<Trend[]>();

                // заполнить список (разделить массив trends)
                for (int i = 0; i < trends.Length; i += trendCountPerGroup)
                    groupsList.Add(trends.Skip(i).Take(trendCountPerGroup).ToArray());

                /***************************************************************Группы*****************************************************************************/
                Group[] groups = new Group[groupsCount];

                for (int i = 0; i < groupsCount; i++)
                {
                    groups[i] = new Group();
                    {
                        groups[i].Position = i + 1;
                        groups[i].Name = string.Format("Group{0}", i + 1);
                        groups[i].Length = groups[i].Name.Length;
                        groups[i].trend = groupsList[i];

                        // количество трендов в последней группе
                        if (i == groupsCount - 1)
                            groups[i].TrendsCount = trendCountPerGroup - (groupsCount * trendCountPerGroup - trendsCount);
                        else
                            groups[i].TrendsCount = trendCountPerGroup;
                    }
                }

                /***************************************************************Разделы****************************************************************************/
                Section[] sections = new Section[sectionsCount];

                sections[0] = new Section();
                {
                    sections[0].Position = 1;                            // при копировании (дублировании) группы в новом разделе +1
                    sections[0].Name = "Section1";                       // при копировании (дублировании) группы изменить имя
                    sections[0].Length = sections[0].Name.Length;
                    sections[0].CountGroup = groupsCount;
                    sections[0].group = groups;
                }

                /**************************************************************Настройки***************************************************************************/
                Settings settings = new Settings(1, 2, 2, sectionsCount, sections);

                try
                {
                    if (File.Exists(file)) File.Delete(file);   // удалить файл если существует

                    /*******************************************************Генерация файла трендов****************************************************************/
                    // создать объект BinaryWriter
                    using (BinaryWriter writer = new BinaryWriter(File.Open(file, FileMode.OpenOrCreate)))
                    {
                        writer.Write(settings.GetBytes());

                        int countT = 0;

                        // цикл по разделам
                        for (int i = 0; i < settings.CountSection; i++)
                        {
                            writer.Write(settings.section[i].GetBytes());

                            // цикл по группам раздела
                            for (int j = 0; j < settings.section[i].CountGroup; j++)
                            {
                                writer.Write(settings.section[i].group[j].GetBytes());

                                // цикл по трендам группы
                                for (int k = 0; k < trendCountPerGroup; k++)
                                {
                                    writer.Write(settings.section[i].group[j].trend[k].GetBytes());

                                    // прекратить заполнение массива trend[k], если тренд был последний
                                    countT++;
                                    if (countT == trendsCount)
                                        break;
                                }
                            }
                        }
                    }

                    /******************************************************Генерация файла переменных**************************************************************/
                    Variable[] variables = new Variable[trendsCount];

                    for (int i = 0; i < trendsCount; i++)
                    {
                        variables[i] = new Variable();
                        {
                            variables[i].Name = string.Format("var{0}", i + 1);
                            variables[i].DataType = Variable.DataTypes[8];
                            variables[i].TagType = Variable.TagTypes[1];
                            variables[i].VariablesUpdateRate = Variable.VariablesUpdateRates[0];
                            variables[i].InitialValue = "0";
                            variables[i].RetentiveType = Variable.RetentiveTypes[1];
                            variables[i].Description = string.Format("Описание переменной {0}", i + 1);
                            variables[i].ScaleName = string.Format("Scale{0}", i + 1);
                            variables[i].Unit = arrUnitsNotNull[i];
                            variables[i].Minimum = arrMinimumNotNull[i];
                            variables[i].Maximum = arrMaximumNotNull[i];
                            variables[i].Format = "0.##";
                            variables[i].CommaShift = Convert.ToString(0);
                            variables[i].ArchiveType = Variable.ArchiveTypes[1];
                            variables[i].TrendDrawType = Variable.TrendDrawTypes[0];
                            variables[i].ArchiveDeadZone = Convert.ToString(0);
                            variables[i].ArchiveInterval = Variable.ArchiveIntervals[0];
                            variables[i].MessageByLimits = Variable.MessagesByLimits[0];
                            variables[i].MessageDeadZone = Convert.ToString(-1);
                            variables[i].FilterType = Variable.FilterTypes[0];
                            variables[i].ID = Convert.ToString(i);
                        }
                    }

                    using (var sw = new StreamWriter("Export.csv", false, Encoding.GetEncoding(65001)))
                    {
                        sw.WriteLine("ОСНОВНЫЕ;;;;;;;;;;ШКАЛА;;;;ЗНАЧЕНИЕ;;;;АРХИВ;;;;ГРАНИЦЫ;;;;СООБЩЕНИЯ;;ФИЛЬТР;;;ID");
                        sw.WriteLine("Имя группы;Имя переменной;Тип данных;Тип тега;Адрес;OPC сервер;Частота опроса;Начальное значение;Авто восстанов.;Описание;Имя шкалы;Ед. измерения;Минимум;Максимум;Формат;Сдвиг запятой;Виз. минимум;Виз. максимум;Тип архивации;Тип отрисовки тренда;Зона нечувствит.;Интервал архивации;ВА;ВП;НП;НА;Сообщения о нарушении границ;Зона нечувствит.;Тип фильтра;p1;p2;");
                        sw.WriteLine("..\\;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;");

                        for (int i = 0; i < trendsCount; i++)
                        {
                            sw.WriteLine(";" + variables[i].Name + ";"
                                             + variables[i].DataType + ";"
                                             + variables[i].TagType + ";;;"
                                             + variables[i].ArchiveInterval + ";"
                                             + variables[i].InitialValue + ";"
                                             + variables[i].RetentiveType + ";"
                                             + variables[i].Description + ";"
                                             + variables[i].ScaleName + ";"
                                             + variables[i].Unit + ";"
                                             + variables[i].Minimum + ";"
                                             + variables[i].Maximum + ";"
                                             + variables[i].Format + ";"
                                             + variables[i].CommaShift + ";;;"
                                             + variables[i].ArchiveType + ";"
                                             + variables[i].TrendDrawType + ";"
                                             + variables[i].ArchiveDeadZone + ";"
                                             + variables[i].ArchiveInterval + ";;;;;"
                                             + variables[i].MessageByLimits + ";"
                                             + variables[i].MessageDeadZone + ";"
                                             + variables[i].FilterType + ";NAN;NAN;"
                                             + variables[i].ID);
                        }
                    }
                }

                catch (Exception exception)
                {
                    Console.WriteLine(exception.Message);
                    Console.ReadKey();
                }
            }
            else
            {
                Console.WriteLine("Нет входного файла!");
                Console.ReadKey();
            }
        }
    }
}