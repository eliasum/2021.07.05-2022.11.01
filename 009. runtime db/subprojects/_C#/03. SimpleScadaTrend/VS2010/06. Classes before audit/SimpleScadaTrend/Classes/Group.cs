using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SimpleScadaTrend
{
    class Group
    {
        /// <summary>Длина имени</summary>
        public int Length { get; set; }

        /// <summary> Имя группы </summary>
        public string Name { get; set; }

        /// <summary> Позиция группы </summary>
        public int Position { get; set; }

        /// <summary> Неизвестная команда </summary>
        readonly byte[] Unknown;

        /// <summary> Количество трендов группы (max = 10) </summary>
        public int CountTrends { get; set; }

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

        public Group()
        {
            Unknown = Program.HexToByte("00");
        }
    }
}
