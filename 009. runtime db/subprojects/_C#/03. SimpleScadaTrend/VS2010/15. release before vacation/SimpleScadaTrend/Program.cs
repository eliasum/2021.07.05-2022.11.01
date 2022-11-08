/*2022.07.20 17:59 IMM*/
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

        static void Main(string[] args)
        {
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
                // переменная для нового Xml документа
                XmlDocument xDoc = new XmlDocument();

                // загрузить в переменную Xml документ из корневой директории
                xDoc.Load(args0);

                // получим корневой элемент
                XmlNode xRoot = xDoc.DocumentElement;

                // список названий трендов
                List<string> captions = new List<string>();

                // список цветов перьев трендов
                List<byte[]> arrcolors = new List<byte[]>();

                /****************************************************************units****************************************************************************/
                // контекст данных
                XmlNodeList nodes = xRoot.SelectNodes("//Amperage | //Voltage");

                XmlNodeList nodesA = xRoot.SelectNodes("//Amperage"); // 147 в 036ce062
                XmlNodeList nodesV = xRoot.SelectNodes("//Voltage");  // 84 в 036ce062

                // единицы измерения трендов
                string[] Units = new string[nodes.Count];

                if (nodes != null)
                {
                    // узлы Amperage и Voltage
                    XmlNode node = null;

                    // имя текущего узла Amperage или Voltage
                    string nodeName = null;

                    // индекс массива Units[]
                    int u = 0;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in nodes)
                    {
                        // присвоить переменную цикла foreach переменной nodeSup
                        node = xnode;

                        // имя первого дочернего узла
                        nodeName = node.Name;

                        // значение атрибута @unit тега Voltage без символов '[' и ']'
                        Units[u] = node.SelectSingleNode("@unit").Value.Trim(new char[] { '[', ']' }); u++;
                    }
                }

                /****************************************************************min&max**************************************************************************/
                // контекст данных
                nodes = xRoot.SelectNodes("//Limit/*");

                // минимальное значение переменной (шкалы) тренда
                string[] Minimum = new string[nodes.Count];

                // максимальное значение переменной (шкалы) тренда
                string[] Maximum = new string[nodes.Count];

                if (nodes != null)
                {
                    // текущий узел контекста данных
                    XmlNode node = null;

                    // индексы массивов Minimum[] и Maximum[]
                    int min = 0, max = 0;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in nodes)
                    {
                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // если текущий узел это Item
                        if (node.Name == "Item")
                        {
                            // значение атрибута @unit тега Minimum без символов '[' и ']'
                            Minimum[min] = node.SelectSingleNode("Minimum").SelectSingleNode("@const").Value;

                            // значение атрибута @unit тега Maximum без символов '[' и ']'
                            Maximum[max] = node.SelectSingleNode("Maximum").SelectSingleNode("@const").Value;

                            min++; max++;
                        }
                    }
                }

                /**********************************************************************colors*************************************************************************/
                // контекст данных
                nodes = xRoot.SelectNodes("//Pen/*");

                if (nodes != null)
                {
                    /*
                        переменная node используется для вычисления родительских узлов текущего
                        атрибута Item, удовлетворяющих условию наличия атрибутов @key и @title
                    */
                    XmlNode node = null;

                    // обход всех узлов в элементах nodes
                    foreach (XmlElement xnode in nodes)
                    {
                        // значение атрибута @key текущего узла Item
                        string xpath = null;

                        // строковая переменная цвета
                        string strcolor;

                        // переменная цвета
                        Color color;

                        // присвоить переменную цикла foreach переменной node
                        node = xnode;

                        // если текущий узел это Item
                        if (node.Name == "Item")
                        {
                            // значение атрибута @value тега Color, дочернего для Item
                            strcolor = node.SelectSingleNode("Color").SelectSingleNode("@value").Value;

                            // получить цвет RGB из строки системного названия цвета 
                            color = Color.FromName(strcolor);

                            // преобразовать цвет в hex
                            string hex = color.B.ToString("X2") + ' ' + color.G.ToString("X2") + ' ' + color.R.ToString("X2");

                            // преобразовать hex значение цвета в массив байт и добавить в список
                            arrcolors.Add(HexToByte(hex));

                            /****************************************************************captions*************************************************************************/

                            // значение атрибута @key тега Item без символов '{' и '}'
                            xpath = node.SelectSingleNode("@key").Value.Trim(new char[] { '{', '}' });

                            if (xpath != null && xpath != "")
                            {
                                // строка для записи значений атрибута @title всех предков с атрибутами @key и @title через ": " - названия пера
                                string ancestorsPath = null;

                                /*
                                    1й цикл while используется для вычисления первой части строки названия текущего пера - последовательности 
                                    атрибутов @title через ":", например, "АРМ: СУБД: Установка {@key}: Поз.№ {@key}: ", пока имя текущего узла
                                    не равно "Configuration" - корневому узлу xml документа
                                */
                                while (node.Name != "Configuration")
                                {
                                    // если текущий узел имеет родителя
                                    if (node.ParentNode != null)
                                    {
                                        // переходим на родителя текущего узла 
                                        node = node.ParentNode;

                                        // если текущий узел имеет атрибуты @key и @title
                                        if (node.SelectSingleNode("@key") != null && node.SelectSingleNode("@title") != null)
                                            /*
                                                записать в строку ancestorsPath значение атрибута @title и ": " впереди 
                                                предыдущего значения ancestorsPath
                                            */
                                            ancestorsPath = node.SelectSingleNode("@title").Value + ": " + ancestorsPath;
                                    }
                                }

                                /*
                                    Восстановление первоначального значения переменной node - самого ближнего родительского 
                                    узла при первой итерации - Pen
                                */
                                node = xnode;

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
                                        string str = ancestorsPath + node.SelectSingleNode(xpath).Value; // "АРМ: СУБД: Установка {@key}: Поз.№ {@key}: Ток"

                                        // добавить название текущего тренда в список названий
                                        captions.Add(str);
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

                // количество:

                // трендов
                int trendsCount = captions.Count;

                // трендов на группу
                const int trendCountPerGroup = 10;

                // групп
                int groupsCount = (int)Math.Ceiling((double)trendsCount / (double)trendCountPerGroup);

                // разделов
                int sectionsCount = 1;

                /***************************************************************Тренды****************************************************************************/
                Trend[] trends = new Trend[trendsCount];

                for (int i = 0; i < trendsCount; i++)
                {
                    trends[i] = new Trend();

                    trends[i].Position1m = i;
                    trends[i].Name = string.Format("Trend{0}", i + 1);
                    trends[i].LengthName = trends[i].Name.Length;
                    trends[i].CaptionLenght = trends[i].СalcCaptLength(captions[i]);
                    trends[i].Caption = string.Format(captions[i]);
                    trends[i].Color = arrcolors[i];
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

                /***************************************************************Группы****************************************************************************/
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

                    /*******************************************************Генерация файла трендов********************************************************************/
                    // создать объект BinaryWriter
                    using (BinaryWriter writer = new BinaryWriter(File.Open(file, FileMode.OpenOrCreate)))
                    {
                        writer.Write(settings.GetBytes());

                        int count = 0;

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
                                    count++;
                                    if (count == trendsCount)
                                        break;
                                }
                            }
                        }
                    }

                    /******************************************************Генерация файла переменных******************************************************************/
                    Variable[] variables = new Variable[trendsCount];

                    for (int i = 0; i < trendsCount; i++)
                    {
                        variables[i] = new Variable();
                        {
                            variables[i].Name = string.Format("var{0}", i + 1);
                            variables[i].DataType = Variable.DataTypes[8];
                            variables[i].TagType = Variable.TagTypes[1];
                            variables[i].VariablesUpdateRate = Variable.VariablesUpdateRates[0];
                            variables[i].InitialValue = Convert.ToString(i * 5);
                            variables[i].RetentiveType = Variable.RetentiveTypes[1];
                            variables[i].Description = string.Format("Описание переменной {0}", i + 1);
                            variables[i].ScaleName = string.Format("Scale{0}", i + 1);
                            variables[i].Unit = Units[i];
                            variables[i].Minimum = Minimum[i];
                            variables[i].Maximum = Maximum[i];
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

                        //";var6;Single;внутрен.;;;как в настр.;25;выкл.;Описание переменной 6;Шкала4;%;-300;300;0.##;0;;;по изменению;обычный;0;как в настр.;;;;;по-умолчанию;-1;без фильтра;0;0;5"

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