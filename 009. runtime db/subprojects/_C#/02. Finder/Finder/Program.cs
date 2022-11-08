using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Finder
{
    class Program
    {
        private class Finder
        {
            private struct Entity
            {
                public byte[] Value;
                public byte Fraction;

                public Entity(int value, byte divider)          // value = 5
                {
                    this.Fraction = (byte)(value % divider);    // остаток от деления 1, 2
                    /*
                         массив [количество/делитель, делитель]
                                 5/2=2,                   2
                                 5/3=1,                   3
                    */
                    this.Value = new byte[] { Convert.ToByte(Math.Truncate(
                    (double)value / divider)), divider };
                }
            }

            private List<Entity> list;

            private int value; public int Value { get { return this.value; } }

            private int column; public int Column { get { return this.column; } }

            private int row; public int Row { get { return this.row; } }

            public Finder(int value)
            {
                this.value = value;
                this.list = new List<Entity>();
                for (byte i = 2; i < value - 1; i++)
                    list.Add(new Entity(value, i));
                foreach (var item in list)
                {
                    Console.WriteLine("item.Fraction = " + item.Fraction + ", item.Value[0] = " + item.Value[0] + ", item.Value[1] = " + item.Value[1]);
                }
            }
        }

        static void Main(string[] args)
        {
            int value = 24;

            Finder finder = new Finder(value);

            Console.ReadKey();
        }
    }
}
