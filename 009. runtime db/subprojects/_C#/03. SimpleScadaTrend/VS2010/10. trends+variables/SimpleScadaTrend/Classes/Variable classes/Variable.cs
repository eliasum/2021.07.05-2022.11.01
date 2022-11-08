using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SimpleScadaTrend
{
    class Variable
    {
        public string[] DataTypes = 
        {
            "Boolean",
            "Byte",
            "Word",
            "ShortInt",
            "SmallInt",
            "Integer",
            "LongWord",
            "Int64",
            "Single",
            "Double",
            "DateTime",
            "String",
            "Boolean Array",
            "Byte Array",
            "Word Array",
            "ShortInt Array",
            "SmallInt Array",
            "Integer Array",
            "LongWord Array",
            "Int64 Array",
            "Single Array",
            "Double Array",
            "DateTime Array",
            "String Array"
        };

        /// <summary> Имя переменной </summary>
        public string Name { get; set; }

        /// <summary> Тип данных </summary>
        readonly string DataType { get; set; }



        public Variable(string DataType)
        {
            this.DataType = DataType;
        }
    }
}
