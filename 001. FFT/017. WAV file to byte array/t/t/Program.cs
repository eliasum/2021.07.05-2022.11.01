using NAudio.Wave;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace t
{
    class Program
    {
        static void Main(string[] args)
        {
            using (WaveFileReader reader = new WaveFileReader(@"d:\1.wav"))
            {

                IWaveProvider stream32 = new Wave16ToFloatProvider(reader);

                using (WaveFileWriter converted = new WaveFileWriter(@"d:\source1.wav", stream32.WaveFormat))
                {
                    byte[] buffer = new byte[1024];
                    int bytesRead;

                    do
                    {
                        bytesRead = stream32.Read(buffer, 0, buffer.Length);
                        converted.Write(buffer, 0, bytesRead);
                    } while (bytesRead != 0 && converted.Length < reader.Length);
                }
            }
        }
    }
}
