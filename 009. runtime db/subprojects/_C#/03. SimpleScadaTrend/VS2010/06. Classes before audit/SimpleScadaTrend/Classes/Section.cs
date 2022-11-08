using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SimpleScadaTrend
{
    class Section
    {
        /// <summary> Позиция раздела </summary>
        public int Position { get; set; }

        /// <summary> Длина имени раздела </summary>
        public int Length { get; set; }

        /// <summary> Неизвестная команда </summary>
        readonly int Unknown;

        /// <summary> Количество групп </summary>
        public int CountGroup { get; set; }

        /// <summary> Имя раздела </summary>
        public string Name { get; set; }

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

        public Section()
        {
            Unknown = 0;
        }
    }
}
