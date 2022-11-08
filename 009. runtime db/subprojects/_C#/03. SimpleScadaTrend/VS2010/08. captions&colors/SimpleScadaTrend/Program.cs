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
            XmlDocument xDoc = new XmlDocument();
            xDoc.Load("..\\..\\_036CE061.xml");

            // получим корневой элемент
            XmlNode xRoot = xDoc.DocumentElement;

            XmlNodeList nodes = xRoot.SelectNodes("//Pen/*");

            // список названий трендов
            List<string> captions = new List<string>();

            // список цветов перьев трендов
            List<byte[]> arrcolors = new List<byte[]>();

            if (nodes != null)
            {
                XmlNode node = null;

                // обход всех узлов в элементах nodes xnode.Attributes["key"].Value
                foreach (XmlElement xnode in nodes)
                {
                    string xpath = null;
                    string strcolor;
                    Color color;
                    node = xnode;

                    if (node.Name == "Item")
                    {
                        xpath = node.SelectSingleNode("@key").Value;

                        strcolor = node.FirstChild.SelectSingleNode("@value").Value;
                        color = Color.FromName(strcolor);
                        string hex = color.B.ToString("X2") + ' ' + color.G.ToString("X2") + ' ' + color.R.ToString("X2");
                        arrcolors.Add(HexToByte(hex));

                        string ancestorsPath = null;

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
                                captions.Add(str);
                                break;
                            }
                        }
                    }
                }
            }

            int trendsCount = captions.Count;
            
            /***************************************************************Тренды****************************************************************************/
            Trend[] trends = new Trend[trendsCount];

            for (int i = 0; i < trendsCount; i++)
            {
                trends[i] = new Trend();

                trends[i].Position1m = i;                                 // при копировании (дублировании) тренда в новой группе +1
                trends[i].LengthName = 6;
                trends[i].Name = string.Format("Trend{0}", i + 1);        // при копировании (дублировании) тренда изменить имя
                trends[i].LengthCaption = captions[i].Length;
                trends[i].Caption = string.Format(captions[i]);           // при копировании (дублировании) тренда изменить название            
                trends[i].Color = arrcolors[i];                           // при копировании (дублировании) тренда изменить цвет
                trends[i].ID = (ulong)i;                                  // при копировании (дублировании) тренда изменить ID переменной
                trends[i].numbVarTrendNumber = 45089;                     // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                trends[i].setPosition = 0;
                trends[i].showScale = 1;
            }

            /***************************************************************Группы****************************************************************************/
            Group[] groups = new Group[1];

            groups[0] = new Group();

            groups[0].Length = 6;
            groups[0].Name = "Group1";
            groups[0].Position = 1;                                       // при копировании (дублировании) группы в новом разделе +1
            groups[0].TrendsCount = trendsCount;                          // при добавлении тренда +1
            groups[0].trend = trends;

            /***************************************************************Разделы****************************************************************************/
            Section[] sections = new Section[1];

            sections[0] = new Section();

            sections[0].Position = 1;
            sections[0].Length = 8;
            sections[0].Name = "Section1";
            sections[0].CountGroup = 1;                                   // при добавлении группы +1
            sections[0].group = groups;

            /**************************************************************Настройки***************************************************************************/
            Settings settings = new Settings(1, 2, 2, 1, sections);

            try
            {
                if (File.Exists(file)) File.Delete(file);   // удалить файл если существует

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
            }

            catch (Exception exception)
            {
                Console.WriteLine(exception.Message);
                Console.ReadKey();
            }
        }
    }
}
