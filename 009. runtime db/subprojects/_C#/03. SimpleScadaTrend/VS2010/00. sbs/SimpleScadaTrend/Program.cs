namespace SimpleScadaTrend
{
    using System;
    using System.IO;
    using System.Runtime.Serialization.Formatters.Binary;

    [Serializable]
    struct Section
    {
        /// <summary>Количество </summary>
        public int Count;
        public string Name;
        public Group[] Group;
    }

    [Serializable]
    struct Group
    {
        /// <summary>Количество тендов</summary>
        public int Count;
        /// <summary>неизвесно 8 байт</summary>
        public byte[] Data;
        public Trend[] Trend;
    }

    [Serializable]
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
        static void Main(string[] args)
        {
            Section[] section = new Section[]
            {
                new Section()
                {   Count = 1,
                    Group = new Group[]
                    {
                        new Group()
                        {
                            Count = 1,
                            Trend = new Trend[]
                            {
                                new Trend()
                                {
                                    Data = new byte[23]
                                }
                            }
                        }
                    }
                }
            };
            BinaryFormatter formatter = new BinaryFormatter();
            using (FileStream stream = new FileStream("Trends.str",
                FileMode.OpenOrCreate)) { formatter.Serialize(stream, section); }

        }
    }
}
