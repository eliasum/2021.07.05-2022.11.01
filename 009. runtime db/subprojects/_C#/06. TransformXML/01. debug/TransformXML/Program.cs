/*2022.07.15 15:27 IMM*/
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Xsl;
using System.Xml;
using System.IO;
using System.Diagnostics;

namespace TransformXML
{
    class Program
    {
        // xslt трансформация xml файла
        public static string TransformXMLToHTML(string inputXml, string xsltString)
        {
            XslCompiledTransform transform = GetAndCacheTransform(xsltString);

            StringWriter results = new StringWriter();

            using (XmlReader reader = XmlReader.Create(new StringReader(inputXml)))
            {
                transform.Transform(reader, null, results);
            }

            return results.ToString();
        }

        private static Dictionary<String, XslCompiledTransform> cachedTransforms = new Dictionary<string, XslCompiledTransform>();

        private static XslCompiledTransform GetAndCacheTransform(String xslt)
        {
            XslCompiledTransform transform;

            if (!cachedTransforms.TryGetValue(xslt, out transform))
            {
                transform = new XslCompiledTransform();

                using (XmlReader reader = XmlReader.Create(new StringReader(xslt)))
                {
                    transform.Load(reader);
                }

                cachedTransforms.Add(xslt, transform);
            }

            return transform;
        }

        // перекодировка файла
        static bool ChangeFileEncoding(string _fileFullName, Encoding _oldEncoding, Encoding _newEncoding)
        {
            try
            {
                File.WriteAllText(_fileFullName, File.ReadAllText(_fileFullName, _oldEncoding), _newEncoding);
                return true;
            }
            catch { }

            return false;
        }

        /*
            args[0] = "config.xml"
            args[1] = "stylesheet.xsl"
        */
        static void Main(string[] args)
        {
            /*
                если принято 2 аргумента - путь ко входному файлу @"config.xml", путь к файлу xslt
                трансформации @"stylesheet.xsl", а также что эти файлы существуют
            */
            if (args.Length == 2 && File.Exists(args[0]) && File.Exists(args[1]))
            {
                // строка пути к скрипту БД
                string database = @"database.sql";

                // строка пути к скрипту генерации БД
                string createdb = @"createdb.bat";

                // новый xml документ
                XmlDocument xDoc = new XmlDocument();

                // загрузить в новый xml документ входной файл "config.xml"
                xDoc.Load(args[0]);

                // загрузить в строку входной файл "stylesheet.xsl"
                string stylesheet = File.ReadAllText(args[1]);

                // загрузить в строку результат xslt трансформации
                string results = TransformXMLToHTML(xDoc.OuterXml, stylesheet);

                // записать строку результата xslt трансформации в файл
                File.WriteAllText(database, results, Encoding.GetEncoding(65001));

                // кодировка UTF8 без BOM
                Encoding utf8WithoutBom = new UTF8Encoding(false);

                // установить кодировку файла UTF8 без BOM
                ChangeFileEncoding(database, Encoding.GetEncoding(65001), utf8WithoutBom);

                // запуск файла .bat генерации БД
                if (File.Exists(createdb))
                    Process.Start(createdb);
                else
                    Console.WriteLine(string.Format("Файл {0} не найден!", createdb));
            }
            else
            {
                Console.WriteLine("Нет xml и/или xslt файла!");
                Console.ReadKey();
            }
        }
    }
}
