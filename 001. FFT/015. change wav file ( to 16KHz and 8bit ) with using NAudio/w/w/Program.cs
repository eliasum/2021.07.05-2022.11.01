using NAudio.Wave;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace w
{
    class Program
    {
        static void Main(string[] args)
        {
            using (var reader = new WaveFileReader(@"d:\source.wav"))
            {
                var newFormat = new WaveFormat(8000, 16, 1);
                using (var conversionStream = new WaveFormatConversionStream(newFormat, reader))
                {
                    WaveFileWriter.CreateWaveFile(@"d:\source1.wav", conversionStream);
                }
            }
        }
    }
}
