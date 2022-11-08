namespace SimpleScadaTrend
{
    using System;
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

        static void Main(string[] args)
        {
            Trend[] trends = new Trend[3];

            for (int i = 0; i < 3; i++)
            {
                trends[i] = new Trend();
                trends[i].Position1m = i;                               // при копировании (дублировании) тренда в новой группе +1
                trends[i].LengthName = 6;
                trends[i].Name = string.Format("Trend{0}", i + 1);      // при копировании (дублировании) тренда изменить имя
                trends[i].LengthCaption = 6;
                trends[i].Caption = string.Format("Тренд{0}", i + 1);   // при копировании (дублировании) тренда изменить название
                trends[i].Color = HexToByte("00 00 ff");                // при копировании (дублировании) тренда изменить цвет
                trends[i].ID = (ulong)i;                                // при копировании (дублировании) тренда изменить ID переменной
                trends[i].numbVarTrendNumber = HexToByte("b0 21");      // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                trends[i].setPosition = HexToByte("00");
                trends[i].showScale = HexToByte("01");
            }

            Settings settings = new Settings()
            {
                CountTrend = 1,
                CountGroup1p = 2,                                                   // default = 01, при добавлении группы число удваивается
                CountSection1p = 2,                                                 // default = 01, при добавлении раздела число удваивается
                CountSection = 1,                                                   // при добавлении раздела +1                

                section = new Section[]
                {
                    new Section()
                    {
                        Position = 1,
                        Length = 8,
                        Name = "Section1",
                        CountGroup = 1,                                             // при добавлении группы +1

                        group = new Group[]
                        {
                            new Group()
                            {
                                Length = 6,
                                Name = "Group1",
                                Position = 1,                                       // при копировании (дублировании) группы в новом разделе +1
                                CountTrends = 3,                                    // при добавлении тренда +1

                                trend = trends

                            }
                        }
                    }
                }
            };

            try
            {
                if (File.Exists(file)) File.Delete(file);   // удалить файл если существует

                // создаем объект BinaryWriter
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
