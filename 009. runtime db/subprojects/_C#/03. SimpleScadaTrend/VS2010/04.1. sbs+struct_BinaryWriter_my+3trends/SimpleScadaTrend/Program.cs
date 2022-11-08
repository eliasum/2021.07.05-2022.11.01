namespace SimpleScadaTrend
{
    using System;
    using System.IO;
    using System.Text;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
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

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();

            list.AddRange(BitConverter.GetBytes(this.CountTrend));
            list.AddRange(BitConverter.GetBytes(this.Unknown));
            list.AddRange(BitConverter.GetBytes(this.CountGroup1p));
            list.AddRange(BitConverter.GetBytes(this.CountSection1p));
            list.AddRange(BitConverter.GetBytes(this.CountSection));

            return list.ToArray();
        }
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

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();

            list.AddRange(BitConverter.GetBytes(this.Position));
            list.AddRange(BitConverter.GetBytes(this.Length));
            list.AddRange(Encoding.GetEncoding(0).GetBytes(this.Name));
            list.AddRange(BitConverter.GetBytes(this.CountGroup));

            return list.ToArray();
        }
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
        public byte[] Unknown;

        /// <summary> Количество трендов группы (max = 10) </summary>
        public int CountTrends;

        public Trend[] trend;

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();

            byte[] Unknown = new byte[1];

            list.AddRange(BitConverter.GetBytes(this.Position));
            list.AddRange(BitConverter.GetBytes(this.Length));
            list.AddRange(Encoding.GetEncoding(0).GetBytes(this.Name));
            list.AddRange(this.Unknown);
            list.AddRange(BitConverter.GetBytes(this.CountTrends));

            return list.ToArray();
        }
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
        public byte[] setPosition;

        /// <summary> Параметр "показать шкалу" </summary>
        public byte[] showScale;

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();

            byte[] UnknownData1 = new byte[37];
            byte[] Color = new byte[3];
            byte[] UnknownData2 = new byte[10];
            byte[] ID = new byte[8];
            byte[] numbVarTrendNumber = new byte[2];
            byte[] UnknownData3 = new byte[3];
            byte[] UnknownData4 = new byte[16];
            byte[] setPosition = new byte[1];
            byte[] showScale = new byte[1];

            list.AddRange(BitConverter.GetBytes(this.Position1m));
            list.AddRange(BitConverter.GetBytes(this.Unknown));
            list.AddRange(BitConverter.GetBytes(this.LengthName));
            list.AddRange(Encoding.GetEncoding(0).GetBytes(this.Name));
            list.AddRange(BitConverter.GetBytes(this.Unknown));
            list.AddRange(BitConverter.GetBytes(this.LengthCaption));
            list.AddRange(Encoding.GetEncoding(0).GetBytes(this.Caption));
            list.AddRange(this.UnknownData1);
            list.AddRange(this.Color);
            list.AddRange(this.UnknownData2);
            list.AddRange(this.ID);
            list.AddRange(this.numbVarTrendNumber);
            list.AddRange(this.UnknownData3);
            list.AddRange(this.setPosition);
            list.AddRange(this.UnknownData4);
            list.AddRange(this.showScale);

            return list.ToArray();
        }
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
                                Unknown = HexToByte("00"),
                                Position = 1,                                       // при копировании (дублировании) группы в новом разделе +1
                                CountTrends = 3,                                    // при добавлении тренда +1

                                trend = new Trend[]
                                {
                                    new Trend()
                                    {
                                        Position1m = 0,                             // при копировании (дублировании) тренда в новой группе +1
                                        Unknown = 0,
                                        LengthName = 6,
                                        Name = "Trend1",                            // при копировании (дублировании) тренда изменить имя
                                        LengthCaption = 6,
                                        Caption = "Тренд1",                         // при копировании (дублировании) тренда изменить название
                                        UnknownData1 = HexToByte("00 80 1d 44 00 00 c4 42 00 40 f0 44 00 00 00 42 ff 00 00 00 00 01 01 02 00 00 80 3f 00 00 00 00 ff ff ff 00 ff"),
                                        Color = HexToByte("00 00 ff"),              // при копировании (дублировании) тренда изменить цвет
                                        UnknownData2 = HexToByte("00 00 00 00 00 00 00 00 00 00"),
                                        ID = HexToByte("00 00 00 00 00 00 00 00"),  // при копировании (дублировании) тренда изменить ID переменной
                                        numbVarTrendNumber = HexToByte("b0 21"),    // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                                        UnknownData3 = HexToByte("00 00 01"),
                                        setPosition = HexToByte("00"),
                                        UnknownData4 = HexToByte("00 00 00 00 00 00 00 00 00 00 00 00 00 00 59 40"),
                                        showScale = HexToByte("01"),
                                    },
                                    new Trend()
                                    {
                                        Position1m = 1,                             // при копировании (дублировании) тренда в новой группе +1
                                        Unknown = 0,
                                        LengthName = 6,
                                        Name = "Trend2",                            // при копировании (дублировании) тренда изменить имя
                                        LengthCaption = 6,
                                        Caption = "Тренд2",                         // при копировании (дублировании) тренда изменить название
                                        UnknownData1 = HexToByte("00 80 1d 44 00 00 c4 42 00 40 f0 44 00 00 00 42 ff 00 00 00 00 01 01 02 00 00 80 3f 00 00 00 00 ff ff ff 00 ff"),
                                        Color = HexToByte("ff 00 ff"),              // при копировании (дублировании) тренда изменить цвет
                                        UnknownData2 = HexToByte("00 00 00 00 00 00 00 00 00 00"),
                                        ID = HexToByte("01 00 00 00 00 00 00 00"),  // при копировании (дублировании) тренда изменить ID переменной
                                        numbVarTrendNumber = HexToByte("b0 21"),    // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                                        UnknownData3 = HexToByte("00 00 01"),
                                        setPosition = HexToByte("00"),
                                        UnknownData4 = HexToByte("00 00 00 00 00 00 00 00 00 00 00 00 00 00 59 40"),
                                        showScale = HexToByte("01"),
                                    },
                                    new Trend()
                                    {
                                        Position1m = 2,                             // при копировании (дублировании) тренда в новой группе +1
                                        Unknown = 0,
                                        LengthName = 6,
                                        Name = "Trend3",                            // при копировании (дублировании) тренда изменить имя
                                        LengthCaption = 6,
                                        Caption = "Тренд3",                         // при копировании (дублировании) тренда изменить название
                                        UnknownData1 = HexToByte("00 80 1d 44 00 00 c4 42 00 40 f0 44 00 00 00 42 ff 00 00 00 00 01 01 02 00 00 80 3f 00 00 00 00 ff ff ff 00 ff"),
                                        Color = HexToByte("00 ff ff"),              // при копировании (дублировании) тренда изменить цвет
                                        UnknownData2 = HexToByte("00 00 00 00 00 00 00 00 00 00"),
                                        ID = HexToByte("02 00 00 00 00 00 00 00"),  // при копировании (дублировании) тренда изменить ID переменной
                                        numbVarTrendNumber = HexToByte("b0 21"),    // при копировании (дублировании) тренда изменить значение b0 21h+400*(число переменных)+400*(№ тренда)
                                        UnknownData3 = HexToByte("00 00 01"),
                                        setPosition = HexToByte("00"),
                                        UnknownData4 = HexToByte("00 00 00 00 00 00 00 00 00 00 00 00 00 00 59 40"),
                                        showScale = HexToByte("01"),
                                    }
                                }
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
