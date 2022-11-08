using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SimpleScadaTrend
{
    class Variable
    {
        public static string[] DataTypes = 
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

        public static string[] TagTypes = 
        {
            "внешн.",
            "внутрен."
        };

        public static string[] VariablesUpdateRates = 
        {
            "20 ms",
            "50 ms",
            "100 ms",
            "300 ms",
            "500 ms",
            "1 sec",
            "2 sec",
            "3 sec",
            "5 sec",
            "10 sec",
            "15 sec",
            "20 sec",
            "30 sec",
            "40 sec",
            "50 sec",
            "1 min",
            "2 min",
            "3 min",
            "5 min",
            "10 min",
            "15 min",
            "30 min",
            "1 hour"

        };

        public static string[] RetentiveTypes =  
        {
            "вкл.",
            "выкл."
        };

        public static string[] ArchiveTypes =  
        {
            "не архивировать",
            "по изменению",
            "по времени",
            "комбинированный"
        };

        public static string[] TrendDrawTypes =  
        {
            "обычный",
            "ступенчатый"
        };

        public static string[] ArchiveIntervals =  
        {
            "как в настр.",
            "100 ms",
            "300 ms",
            "500 ms",
            "1 sec",
            "2 sec",
            "3 sec",
            "5 sec",
            "10 sec",
            "15 sec",
            "20 sec",
            "30 sec",
            "40 sec",
            "50 sec",
            "1 min",
            "2 min",
            "3 min",
            "5 min",
            "10 min",
            "30 min",
            "1 hour"
        };

        public static string[] MessagesByLimits =  
        {
            "по-умолчанию",
            "для всех границ",
            "только для авар.",
            "без сообщений"
        };

        public static string[] FilterTypes =  
        {
            "без фильтра",
            "фильтр Калмана",
            "скользящее среднее",
            "медианный фильтр",
            "фильтр отклонений",
            "фильтр мин. макс."

        };

        /// <summary> Имя переменной </summary>
        public string Name { get; set; }

        /// <summary> Тип данных </summary>
        public string DataType { get; set; }

        /// <summary> Тип тега </summary>
        public string TagType { get; set; }

        /// <summary> Частота опроса </summary>
        public string VariablesUpdateRate { get; set; }

        /// <summary> Начальное значение </summary> 
        public string InitialValue { get; set; }

        /// <summary> Авто восстановление </summary> 
        public string RetentiveType { get; set; }    

        /// <summary> Описание переменной </summary> 
        public string Description { get; set; }

        /// <summary> Формат </summary> 
        public string Format { get; set; }

        /// <summary> Сдвиг запятой </summary> 
        public string CommaShift { get; set; }

        /// <summary> Тип архивации </summary> 
        public string ArchiveType { get; set; }

        /// <summary> Тип отрисовки тренда </summary> 
        public string TrendDrawType { get; set; }

        /// <summary> Зона нечувствительности архива </summary> 
        public string ArchiveDeadZone { get; set; }

        /// <summary> Интервал архивации </summary> 
        public string ArchiveInterval { get; set; }

        /// <summary> Сообщение о нарушении границ </summary> 
        public string MessageByLimits { get; set; }

        /// <summary> Зона нечувствительности сообщений</summary> 
        public string MessageDeadZone { get; set; }

        /// <summary> Тип фильтра </summary> 
        public string FilterType { get; set; }

        /// <summary> ID переменной </summary> 
        public string ID { get; set; }
    }
}
