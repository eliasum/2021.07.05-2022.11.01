namespace SimpleScadaTrend
{
    using System;
    using System.IO;
    using Microsoft.VisualBasic;
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 1)]
    struct Settings
    {
        /// <summary>ОБЩЕЕ количество трендов</summary>
        public long CountTrend;
        /// <summary>Количество групп</summary>
        public long CountGroup;
        /// <summary>Количество разделов (Sections) + 1 (default 01)</summary>
        public int CountSection1;
        /// <summary>Количество разделов (Sections) (default 00)</summary>
        public int CountSection2;
        public Section[] Section;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    struct Section
    {
        //public int PositionSection;
        /// <summary>Длина имени</summary>
        //public int Length;
        public string Name;
        //public Group[] Group;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 1)]
    struct Group
    {
        /// <summary>Длина имени</summary>
        public int Length;
        public string Name;
        /*/// <summary>Количество тендов</summary>
        public int Count;
        /// <summary>неизвесно 8 байт</summary>
        public byte[] Data;
        public Trend[] Trend;*/
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 1)]
    struct Trend
    {
        /// <summary>Длина имени</summary>
        public int LengthName;
        /// <summary>Имя</summary>
        public string Name;
        /// <summary>Длина </summary>
        public int LengthCaption;
        /// <summary></summary>
        public string Caption;
        public byte[] Data;
    }

    class Program
    {
        static string file = "Trends.str";

        static void Main(string[] args)
        {
            //Settings settings = new Settings()
            //{
                //CountTrend = 4,
                //CountGroup = 1,
                //CountSection1 = 4,
                //CountSection2 = 3,
            Section[] section = new Section[]
                {
                    new Section()
                    {
                        //Length = 8,
                        Name = "Секция1",
                        /*Group = new Group[]
                        {
                            new Group()
                            {
                                Length = Comform(6),
                                Name = "Group1",
                                Trend = new Trend[]
                                {
                                    new Trend()
                                    {
                                        Data = new byte[23]
                                    }
                                }
                            }
                        }*/
                    },
                    new Section()
                    {
                        //Length = Comform(8),
                        Name = "Section2",
                        /*Group = new Group[]
                        {
                            new Group()
                            {
                                Length = Comform(6),
                                Name = "Group2",
                                Trend = new Trend[]
                                {
                                    new Trend()
                                    {
                                        Data = new byte[23]
                                    }
                                }
                            }
                        }*/
                    }
                };
            //};
            if (File.Exists(file)) File.Delete(file);
            FileSystem.FileOpen(1, file, OpenMode.Random);
            for (int i = 0; i < section.Length; i++)
                FileSystem.FilePut(1, section[i]);
        }

        static int Comform(int value)
        {
            return (value << 16);
        }
    }
}
