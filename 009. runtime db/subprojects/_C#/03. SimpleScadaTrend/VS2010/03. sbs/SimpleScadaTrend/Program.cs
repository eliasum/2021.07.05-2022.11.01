namespace SimpleScadaTrend
{
    using System;
    using System.IO;
    using System.Text;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;

    struct Settings
    {
        /// <summary>Общее количество трендов</summary>
        public long CountTrend;
        /// <summary>Количество групп</summary>
        public long CountGroup;
        /// <summary>Количество разделов (Sections) + 1 (default 01)</summary>
        public int CountSection1;
        /// <summary>Количество разделов (Sections) (default 00)</summary>
        public int CountSection2;
        public Section[] Section;

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();
            list.AddRange(BitConverter.GetBytes(this.CountTrend));
            list.AddRange(BitConverter.GetBytes(this.CountGroup));
            list.AddRange(BitConverter.GetBytes(this.CountSection1));
            list.AddRange(BitConverter.GetBytes(this.CountSection2));
            foreach (var item in this.Section) list.AddRange(item.GetBytes());
            return list.ToArray();
        }
    }

    struct Section
    {
        //public int PositionSection;
        /// <summary>Длина имени контрола</summary>
        public int LengthName;
        /// <summary>Имя контрола</summary>
        public string Name;
        public Group[] Group;

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();
            list.AddRange(BitConverter.GetBytes(this.LengthName));
            list.AddRange(Encoding.ASCII.GetBytes(this.Name));
            foreach (var item in this.Group) list.AddRange(item.GetBytes());
            return list.ToArray();
        }
    }

    struct Group
    {
        /// <summary>Длина имени контрола</summary>
        public int LengthName;
        /// <summary>Имя контрола</summary>
        public string Name;
        /// <summary>Количество тендов</summary>
        public int Count;

        public Trend[] Trend;

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();
            list.AddRange(BitConverter.GetBytes(this.LengthName));
            list.AddRange(Encoding.ASCII.GetBytes(this.Name));
            list.AddRange(BitConverter.GetBytes(this.Count));
            list.AddRange(new byte[8]);// неизвесно 8 байт
            foreach (var item in this.Trend) list.AddRange(item.GetBytes());
            return list.ToArray();
        }
    }

    struct Trend
    {
        /// <summary>Длина имени контрола</summary>
        public int LengthName;
        /// <summary>Имя контрола</summary>
        public string Name;
        /// <summary>Длина заголовка</summary>
        public int LengthCaption;
        /// <summary>Эаголовок</summary>
        public string Caption;

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();
            list.AddRange(BitConverter.GetBytes(this.LengthName));
            list.AddRange(Encoding.ASCII.GetBytes(this.Name));
            list.AddRange(BitConverter.GetBytes(this.LengthCaption));
            list.AddRange(Encoding.ASCII.GetBytes(this.Caption));
            list.AddRange(new byte[8]);//неизвесно 8 байт<
            return list.ToArray();
        }
    }

    class Program
    {
        static string file = "Trends.str";

        static void Main(string[] args)
        {
            Settings settings = new Settings()
            {
                CountTrend = 4,
                CountGroup = 1,
                CountSection1 = 4,
                CountSection2 = 3,
                Section = new Section[]
                {
                    new Section()
                    {
                        LengthName = 8,
                        Name = "Section1",
                        Group = new Group[]
                        {
                            new Group()
                            {
                                LengthName = 6,
                                Name = "Group1",
                                Trend = new Trend[]
                                {
                                    new Trend()
                                    {
                                        LengthName = 6,
                                        Name = "Trend1",
                                        LengthCaption =10,
                                        Caption = "График №1"
                                    }
                                }
                            }
                        }
                    },
                    new Section()
                    {
                        LengthName = 8,
                        Name = "Section2",
                        Group = new Group[]
                        {
                            new Group()
                            {
                                LengthName = 6,
                                Name = "Group2",
                                Trend = new Trend[]
                                {
                                    new Trend()
                                    {
                                        LengthName = 6,
                                        Name = "Trend2",
                                        LengthCaption =10,
                                        Caption = "График №2"
                                    }
                                }
                            }
                        }
                    }
                }
            };
            try { File.WriteAllBytes(file, settings.GetBytes()); }
            catch (Exception exception)
            {
                Console.WriteLine(exception.Message);
                Console.ReadKey();
            }
        }

        //static int Comform(int value) { return (value << 24); }
    }
}
