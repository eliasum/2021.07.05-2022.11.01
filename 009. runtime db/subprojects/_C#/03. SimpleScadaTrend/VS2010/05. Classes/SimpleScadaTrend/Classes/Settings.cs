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

        /// <summary> Количество групп + 1 (default 01) </summary>
        public int CountGroup1p { get; set; }

        /// <summary> Неизвестная команда </summary>
        readonly int Unknown;

        /// <summary> Количество разделов (Sections) + 1 (default 01) </summary>
        public int CountSection1p { get; set; }

        /// <summary> Количество разделов (Sections) (default 00) </summary>
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

        public Settings()
        {
            Unknown = 0;
        }
    }
}
