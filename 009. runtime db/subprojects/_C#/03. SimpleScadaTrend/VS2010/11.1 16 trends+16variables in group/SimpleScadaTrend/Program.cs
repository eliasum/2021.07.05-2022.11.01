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

    public static class SplitExtension
    {
        /// <summary>
        /// Splits an array into several smaller arrays.
        /// </summary>
        /// <typeparam name="T">The type of the array.</typeparam>
        /// <param name="array">The array to split.</param>
        /// <param name="size">The size of the smaller arrays.</param>
        /// <returns>An array containing smaller arrays.</returns>
        public static IEnumerable<IEnumerable<T>> Split<T>(this T[] array, int size)
        {
            for (var i = 0; i < (float)array.Length / size; i++)
            {
                yield return array.Skip(i * size).Take(size);
            }
        }
    }

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
            // переменная для нового Xml документа
            XmlDocument xDoc = new XmlDocument();

            // загрузить в переменную Xml документ из корневой директории
            xDoc.Load("..\\..\\_036CE061.xml");

            // получим корневой элемент
            XmlNode xRoot = xDoc.DocumentElement;

            // контекст данных
            XmlNodeList nodes = xRoot.SelectNodes("//Pen/*");

            // список названий трендов
            List<string> captions = new List<string>();

            // список цветов перьев трендов
            List<byte[]> arrcolors = new List<byte[]>();

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
                        // значение атрибута @key тега Item
                        xpath = node.SelectSingleNode("@key").Value;

                        // значение атрибута @value тега Color, дочернего для Item
                        strcolor = node.FirstChild.SelectSingleNode("@value").Value;

                        // получить цвет RGB из строки системного названия цвета 
                        color = Color.FromName(strcolor);

                        // преобразовать цвет в hex
                        string hex = color.B.ToString("X2") + ' ' + color.G.ToString("X2") + ' ' + color.R.ToString("X2");

                        // преобразовать hex значение цвета в массив байт и добавить в список
                        arrcolors.Add(HexToByte(hex));

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
                            атрибута @title, указанного во 2м входном параметре - значении атрибута @key текущего узла Item, 
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
                }
            }

            // количество:

            // трендов
            int trendsCount = captions.Count;

            // групп
            int groupsCount = 1;

            // разделов
            int sectionsCount = 1;

            const double trendCountPerGroup = 8.0;
            int subTrendCount = (int)Math.Ceiling((double)trendsCount / trendCountPerGroup);

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

            Trend[] subTrend1 = new Trend[trendCountPerGroup];
            Trend[] subTrend2 = new Trend[trendCountPerGroup];

            for (int i = 0; i < 8; i++)
            {
                subTrend1[i] = trends[i];
            }

            for (int i = 8; i < 16; i++)
            {
                subTrend2[i-8] = trends[i];
            }




            /***************************************************************Группы****************************************************************************/
            Group[] groups = new Group[groupsCount];

            groups[0] = new Group();
            {
                groups[0].Position = 1;                              // при копировании (дублировании) группы в новом разделе +1
                groups[0].Name = "Group1";                           // при копировании (дублировании) группы изменить имя
                groups[0].Length = groups[0].Name.Length;
                groups[0].TrendsCount = trendsCount;
                groups[0].trend = trends;
            }
            /*
            groups[1] = new Group();
            {
                groups[1].Position = 2;                              // при копировании (дублировании) группы в новом разделе +1
                groups[1].Name = "Group2";                           // при копировании (дублировании) группы изменить имя
                groups[1].Length = groups[1].Name.Length;
                groups[1].TrendsCount = trendsCount;
                groups[1].trend = subTrend2;
            }
            /*
            groups[2] = new Group();
            {
                groups[2].Position = 3;                              // при копировании (дублировании) группы в новом разделе +1
                groups[2].Name = "Group3";                           // при копировании (дублировании) группы изменить имя
                groups[2].Length = groups[2].Name.Length;
                groups[2].TrendsCount = trendsCount;
                groups[2].trend = subTrend2;
            }
            */
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
            /*
            sections[1] = new Section();
            {
                sections[1].Position = 2;                            // при копировании (дублировании) группы в новом разделе +1
                sections[1].Name = "Section2";                       // при копировании (дублировании) группы изменить имя
                sections[1].Length = sections[0].Name.Length;
                sections[1].CountGroup = groupsCount;                 
                sections[1].group = groups;
            }

            sections[2] = new Section();
            {
                sections[2].Position = 3;                            // при копировании (дублировании) группы в новом разделе +1
                sections[2].Name = "Section3";                       // при копировании (дублировании) группы изменить имя
                sections[2].Length = sections[0].Name.Length;
                sections[2].CountGroup = groupsCount;                           
                sections[2].group = groups;
            }
            */
            /**************************************************************Настройки***************************************************************************/
            Settings settings = new Settings(1, 2, 2, sectionsCount, sections);

            //try
            {
                if (File.Exists(file)) File.Delete(file);   // удалить файл если существует

                /*******************************************************Генерация файла трендов********************************************************************/
                // создать объект BinaryWriter
                using (BinaryWriter writer = new BinaryWriter(File.Open(file, FileMode.OpenOrCreate)))
                {
                    writer.Write(settings.GetBytes());

                    // цикл по разделам
                    for (int i = 0; i < settings.CountSection; i++)
                    {
                        writer.Write(settings.section[i].GetBytes());

                        // цикл по группам раздела
                        for (int j = 0; j < settings.section[i].CountGroup; j++)
                        {
                            writer.Write(settings.section[i].group[j].GetBytes());

                            // цикл по трендам группы
                            for (int k = 0; k < settings.section[i].group[j].TrendsCount; k++)
                            {
                                writer.Write(settings.section[i].group[j].trend[k].GetBytes());
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
                        variables[i].InitialValue = Convert.ToString(1);
                        variables[i].RetentiveType = Variable.RetentiveTypes[1];
                        variables[i].Description = string.Format("Описание переменной {0}", i + 1);
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
                                         + variables[i].Description + ";;;;;"
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
            /*
        catch (Exception exception)
        {
            Console.WriteLine(exception.Message);
            Console.ReadKey();
        }*/
        }
    }
}
