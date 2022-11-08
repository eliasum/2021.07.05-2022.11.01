namespace SimpleScadaTrend
{
    using System;
    using System.IO;
    using System.Text;
    using System.Linq;

    struct Settings
    {
        /// <summary> ОБЩЕЕ количество трендов </summary>
        public int CountTrend;

        /// <summary> Количество групп + 1 (default 01) </summary>
        public int CountGroup1p;

        /// <summary> Неизвестная команда </summary>
        public int Unknown;

        /// <summary> Количество разделов (Sections) + 1 (default 01) </summary>
        public int CountSection1p;

        /// <summary> Количество разделов (Sections) (default 00) </summary>
        public int CountSection;

        public Section[] section;
    }

    struct Section
    {
        /// <summary> Позиция раздела </summary>
        public int Position;

        /// <summary> Длина имени раздела </summary>
        public int Length;

        /// <summary> Неизвестная команда </summary>
        public int Unknown;

        /// <summary> Количество групп </summary>
        public int CountGroup;

        /// <summary> Имя раздела </summary>
        public string Name;

        public Group[] group;
    }

    struct Group
    {
        /// <summary>Длина имени</summary>
        public int Length;

        /// <summary> Имя группы </summary>
        public string Name;

        /// <summary> Позиция группы </summary>
        public int Position;

        /// <summary> Неизвестная команда </summary>
        public byte Unknown;

        /// <summary> Количество трендов группы (max = 10) </summary>
        public int CountTrends;

        public Trend[] trend;
    }

    struct Trend
    {
        /// <summary> Длина имени </summary>
        public int LengthName;

        /// <summary> Имя </summary>
        public string Name;

        /// <summary> Позиция тренда минус 1, т.е. 0, 1, 2... (default = 00) </summary>
        public int Position1m;

        /// <summary> Неизвестная команда </summary>
        public int Unknown;

        /// <summary> Длина названия </summary>
        public int LengthCaption;

        /// <summary> Название </summary>
        public string Caption;

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData1;

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData2;

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData3;

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData4;

        /// <summary> Цвет тренда </summary>
        public byte[] Color;

        /// <summary> ID переменной </summary>
        public byte[] ID;

        /// <summary> Параметр, зависящий от количества переменных и № тренда </summary>
        public byte[] numbVarTrendNumber;

        /// <summary> Параметр "задать положение" </summary>
        public byte setPosition;

        /// <summary> Параметр "показать шкалу" </summary>
        public byte showScale;
    }

    class Program
    {
        static readonly string file = "Trends.str";

        /// <summary>
        /// Метод преобразования строки hex в массив байт dec
        /// </summary>
        /// <param name="str">Cтрока hex</param>
        /// <returns></returns>
        static byte[] HexToByte(string str)
        {
            return str.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).Select(i => byte.Parse(i, System.Globalization.NumberStyles.HexNumber)).ToArray();
        }

        static void Main(string[] args)
        {
            Settings settings = new Settings()
            {
                Unknown = 0,
                CountTrend = 1,
                CountGroup1p = 2,                                                   // default = 01, при добавлении группы число удваивается
                CountSection1p = 2,                                                 // default = 01, при добавлении раздела число удваивается
                CountSection = 1,                                                   // при добавлении раздела +1                

                section = new Section[]
                {
                    new Section()
                    {
                        Unknown = 0,
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
                                Unknown = 0,
                                Position = 1,                                       // при копировании (дублировании) группы в новом разделе +1
                                CountTrends = 1,                                    // при добавлении тренда +1

                                trend = new Trend[]
                                {
                                    new Trend()
                                    {
                                        Position1m = 0,                             // при копировании (дублировании) тренда в новой группе +1
                                        Unknown = 0,
                                        LengthName = 6,
                                        Name = "Trend1",                            // при копировании (дублировании) тренда изменить имя
                                        LengthCaption = 6,
                                        Caption = "Trend1",                         // при копировании (дублировании) тренда изменить название
                                        UnknownData1 = HexToByte("00 80 1d 44 00 00 c4 42 00 40 f0 44 00 00 00 42 ff 00 00 00 00 01 01 02 00 00 80 3f 00 00 00 00 ff ff ff 00 ff"),
                                        Color = HexToByte("00 00 ff"),              // при копировании (дублировании) тренда изменить цвет
                                        UnknownData2 = HexToByte("00 00 00 00 00 00 00 00 00 00"),
                                        ID = HexToByte("01 00 00 00 00 00 00 00"),  // при копировании (дублировании) тренда изменить ID переменной
                                        numbVarTrendNumber = HexToByte("b0 21"),    // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                                        UnknownData3 = HexToByte("00 00 01"),
                                        setPosition = 0,
                                        UnknownData4 = HexToByte("00 00 00 00 00 00 00 00 00 00 00 00 00 00 59 40"),
                                        showScale = 1,
                                    }
                                }
                            }
                        }
                    }
                }
            };

            if (File.Exists(file)) File.Delete(file);   // удалить файл если существует

            // создаем объект BinaryWriter
            using (BinaryWriter writer = new BinaryWriter(File.Open(file, FileMode.OpenOrCreate)))
            {
                writer.Write(settings.CountTrend);
                writer.Write(settings.Unknown);
                writer.Write(settings.CountGroup1p);
                writer.Write(settings.CountSection1p);
                writer.Write(settings.CountSection);

                // цикл по разделам
                for (int i = 0; i < settings.CountSection; i++)
                {
                    writer.Write(settings.section[i].Position);
                    writer.Write(settings.section[i].Length);
                    writer.Write(Encoding.GetEncoding(0).GetBytes(settings.section[i].Name));
                    writer.Write(settings.section[i].CountGroup);

                    // цикл по группам раздела
                    for (int j = 0; j < settings.section[i].CountGroup; j++)
                    {
                        writer.Write(settings.section[i].group[j].Position);
                        writer.Write(settings.section[i].group[j].Length);
                        writer.Write(Encoding.GetEncoding(0).GetBytes(settings.section[i].group[j].Name));                      // "Group1"
                        writer.Write(settings.section[i].group[j].Unknown);                                                     // "00"
                        writer.Write(settings.section[i].group[j].CountTrends);

                        // цикл по трендам группы
                        for (int k = 0; k < settings.section[i].group[j].CountTrends; k++)
                        {
                            writer.Write(settings.section[i].group[j].trend[k].Position1m);
                            writer.Write(settings.section[i].group[j].trend[k].Unknown);                                        // "00" "00" "00" "00"
                            writer.Write(settings.section[i].group[j].trend[k].LengthName);
                            writer.Write(Encoding.GetEncoding(0).GetBytes(settings.section[i].group[j].trend[k].Name));         // "Trend1"
                            writer.Write(settings.section[i].group[j].trend[k].Unknown);                                        // "00" "00" "00" "00"
                            writer.Write(settings.section[i].group[j].trend[k].LengthCaption);
                            writer.Write(Encoding.GetEncoding(0).GetBytes(settings.section[i].group[j].trend[k].Caption));      // "Trend1"
                            writer.Write(settings.section[i].group[j].trend[k].UnknownData1);
                            writer.Write(settings.section[i].group[j].trend[k].Color);
                            writer.Write(settings.section[i].group[j].trend[k].UnknownData2);
                            writer.Write(settings.section[i].group[j].trend[k].ID);
                            writer.Write(settings.section[i].group[j].trend[k].numbVarTrendNumber);
                            writer.Write(settings.section[i].group[j].trend[k].UnknownData3);
                            writer.Write(settings.section[i].group[j].trend[k].setPosition);
                            writer.Write(settings.section[i].group[j].trend[k].UnknownData4);
                            writer.Write(settings.section[i].group[j].trend[k].showScale);
                        }
                    }
                }
            }
        }
    }
}
