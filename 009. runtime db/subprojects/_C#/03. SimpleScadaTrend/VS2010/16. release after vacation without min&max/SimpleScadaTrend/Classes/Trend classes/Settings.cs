using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SimpleScadaTrend
{
    class Settings
    {
        /// <summary> ОБЩЕЕ количество трендов </summary>
        public int CountTrend { get; set; }

        /// <summary> Количество групп + 1 (default 01), при добавлении группы число удваивается </summary>
        public int CountGroup1p { get; set; }  

        /// <summary> Неизвестная команда </summary>
        readonly int Unknown;

        /// <summary> Количество разделов (Sections) + 1 (default 01), при добавлении раздела число удваивается </summary>
        public int CountSection1p { get; set; }

        /// <summary> Количество разделов (Sections) (default 00), при добавлении раздела +1 </summary>
        public int CountSection { get; set; }

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

        public Settings(int CountTrend, int CountGroup1p, int CountSection1p, int CountSection, Section[] section)
        {
            Unknown = 0;
            this.CountTrend = CountTrend;
            this.CountGroup1p = CountGroup1p;
            this.CountSection1p = CountSection1p;
            this.CountSection = CountSection;
            this.section = section;
        }
    }
}
