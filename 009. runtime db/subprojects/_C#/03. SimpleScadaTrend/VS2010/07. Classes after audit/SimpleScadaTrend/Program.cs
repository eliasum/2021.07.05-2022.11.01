namespace SimpleScadaTrend
{
    using System;
    using System.Xml;
    using System.IO;
    using System.Text;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
    using System.Linq;

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
            XmlElement xRoot = xDoc.DocumentElement;

            if (xRoot != null)
            {
                // обход всех узлов в корневом элементе
                foreach (XmlElement xnode in xRoot)
                {

                }
            }

            /***************************************************************Тренды****************************************************************************/
            Trend[] trends = new Trend[3];

            for (int i = 0; i < 3; i++)
            {
                trends[i] = new Trend();

                trends[i].Position1m = i;                               // при копировании (дублировании) тренда в новой группе +1
                trends[i].LengthName = 6;
                trends[i].Name = string.Format("Trend{0}", i + 1);      // при копировании (дублировании) тренда изменить имя
                trends[i].LengthCaption = 6;
                trends[i].Caption = string.Format("Тренд{0}", i + 1);   // при копировании (дублировании) тренда изменить название            
                trends[i].Color = IntToBytes(255 + 5000 * i,3);         // при копировании (дублировании) тренда изменить цвет
                trends[i].ID = (ulong)i;                                // при копировании (дублировании) тренда изменить ID переменной
                trends[i].numbVarTrendNumber = 45089;                   // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                trends[i].setPosition = 0;
                trends[i].showScale = 1;
            }

            /***************************************************************Группы****************************************************************************/
            Group[] groups = new Group[1];

            groups[0] = new Group();

            groups[0].Length = 6;
            groups[0].Name = "Group1";
            groups[0].Position = 1;                                       // при копировании (дублировании) группы в новом разделе +1
            groups[0].CountTrends = 3;                                    // при добавлении тренда +1
            groups[0].trend = trends;

            /***************************************************************Разделы****************************************************************************/
            Section[] sections = new Section[1];

            sections[0] = new Section();

            sections[0].Position = 1;
            sections[0].Length = 8;
            sections[0].Name = "Section1";
            sections[0].CountGroup = 1;                                             // при добавлении группы +1
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
                            for (int k = 0; k < settings.section[i].group[j].CountTrends; k++)
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
