using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace SimpleScadaTrend
{
    class Trend
    {
        /// <summary> Длина имени </summary>
        public int LengthName { get; set; }

        /// <summary> Имя </summary>
        public string Name { get; set; }

        /// <summary> Позиция тренда минус 1, т.е. 0, 1, 2... (default = 00) </summary>
        public int Position1m { get; set; }

        /// <summary> Неизвестная команда </summary>
        public int Unknown { get; set; }

        /// <summary> Длина названия </summary>
        public int CaptionLenght { get; set; }

        /// <summary> Название </summary>
        public string Caption { get; set; }

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData1;

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData2 { get; set; }

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData3 { get; set; }

        /// <summary> Неизвестные данные </summary>
        public byte[] UnknownData4 { get; set; }

        /// <summary> Цвет тренда </summary>
        public byte[] Color { get; set; }

        /// <summary> ID переменной </summary>
        public ulong ID { get; set; }

        /// <summary> Параметр, зависящий от количества переменных и № тренда </summary>
        public ushort numbVarTrendNumber { get; set; }

        /// <summary> Параметр "задать положение" </summary>
        public byte setPosition { get; set; }

        /// <summary> Параметр "показать шкалу" </summary>
        public byte showScale { get; set; }

        public byte[] GetBytes()
        {
            List<byte> list = new List<byte>();

            byte[] UnknownData1 = new byte[37];
            byte[] Color = new byte[3];
            byte[] UnknownData2 = new byte[10];
            byte[] UnknownData3 = new byte[3];
            byte[] UnknownData4 = new byte[16];

            list.AddRange(BitConverter.GetBytes(this.Position1m));
            list.AddRange(BitConverter.GetBytes(this.Unknown));
            list.AddRange(BitConverter.GetBytes(this.LengthName));
            list.AddRange(Encoding.GetEncoding(65001).GetBytes(this.Name));
            list.AddRange(BitConverter.GetBytes(this.Unknown));
            list.AddRange(BitConverter.GetBytes(this.CaptionLenght));
            list.AddRange(Encoding.GetEncoding(65001).GetBytes(this.Caption));
            list.AddRange(this.UnknownData1);
            list.AddRange(this.Color);
            list.AddRange(this.UnknownData2);
            list.AddRange(BitConverter.GetBytes(this.ID));
            list.AddRange(BitConverter.GetBytes(this.numbVarTrendNumber));
            list.AddRange(this.UnknownData3);
            list.Add(this.setPosition);
            list.AddRange(this.UnknownData4);
            list.Add(this.showScale);

            return list.ToArray();
        }

        public int СalcCaptLength(string caption)
        {
            /*
                словарь шаблонов кириллических символов для regex расчёта количества 
                вхождений кириллических символов в строку
            */
            Dictionary<string, string> patterns = new Dictionary<string, string>();

            // шаблоны
            patterns.Add("russian", "[а-я]");
            patterns.Add("RUSSIANS", "[А-Я]");

            // количество кириллических символов
            int cyrillicCount = 0;

            // количество символов '№'
            int countN = caption.Count(x => x == '№');

            // рассчитать количество кириллических символов в строке в цикле
            foreach (var pattern in patterns)
            {
                // результат по каждому шаблону
                var results = Regex.Matches(caption, pattern.Value);

                cyrillicCount += results.Count;
            }

            // рассчитать количество некириллических символов в строке
            int notCyrillicCount = caption.Length - cyrillicCount;

            return notCyrillicCount + cyrillicCount * 2 + countN * 2;
        }

        public Trend()
        {
            Unknown = 0;
            UnknownData1 = Program.HexToByte("00 80 1d 44 00 00 c4 42 00 40 f0 44 00 00 00 42 ff 00 00 00 00 01 01 02 00 00 80 3f 00 00 00 00 ff ff ff 00 ff");
            UnknownData2 = Program.IntToBytes(0, 10);
            UnknownData3 = Program.IntToBytes(1, 3);
            UnknownData4 = Program.HexToByte("00 00 00 00 00 00 00 00 00 00 00 00 00 00 59 40");
        }
    }
}
