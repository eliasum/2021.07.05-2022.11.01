using NAudio.Wave;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace f
{
    class Program
    {
        struct WavHeader
        {
            public byte[] riffID;
            public uint size;
            public byte[] wavID;
            public byte[] fmtID;
            public uint fmtSize;
            public ushort format;
            public ushort channels;
            public uint sampleRate;
            public uint bytePerSec;
            public ushort blockSize;
            public ushort bit;
            public byte[] dataID;
            public uint dataSize;
        }

        static void Main(string[] args)
        {
            WavHeader Header = new WavHeader();
            List<Int16> lDataList = new List<Int16>();

            byte[] buffer = null;
            int read = 0;
            short[] sampleBuffer = null;

            using (FileStream fs = new FileStream(@"d:\source.wav", FileMode.Open, FileAccess.Read))
            using (BinaryReader br = new BinaryReader(fs))
            {
                Header.riffID = br.ReadBytes(4);//1
                Header.size = br.ReadUInt32();//2
                Header.wavID = br.ReadBytes(4);//3
                Header.fmtID = br.ReadBytes(4);//4
                Header.fmtSize = br.ReadUInt32();//5
                Header.format = br.ReadUInt16();//6
                Header.channels = br.ReadUInt16();//7
                Header.sampleRate = br.ReadUInt32();//8
                Header.bytePerSec = br.ReadUInt32();//9
                Header.blockSize = br.ReadUInt16();//10
                Header.bit = br.ReadUInt16();//11
                Header.dataID = br.ReadBytes(6);//12
                Header.dataSize = br.ReadUInt32();//13
            }

            using (WaveFileReader reader = new WaveFileReader(@"d:\source.wav"))
            {
                buffer = new byte[reader.Length];
                read = reader.Read(buffer, 0, buffer.Length);
                sampleBuffer = new short[read / 1];
                Buffer.BlockCopy(buffer, 0, sampleBuffer, 0, read);
            }

            byte[] bsampleBuffer = new byte[sampleBuffer.Length];

            for (int i = 0; i < sampleBuffer.Length / 2; i++)
                bsampleBuffer[i] = (byte)sampleBuffer[i];

            // вывод байтов аудио
            StreamWriter sr = new StreamWriter(@"d:\out1.txt");

            for (int i = 0; i < bsampleBuffer.Length / 2; i++)
                sr.Write(bsampleBuffer[i] + "\n");

            sr.Close();

            using (FileStream fs = new FileStream(@"d:\source1.wav", FileMode.Create, FileAccess.Write))
            using (BinaryWriter bw = new BinaryWriter(fs))
            {
                try
                {
                    bw.Write(Header.riffID);//1
                    bw.Write(Header.size);//2
                    bw.Write(Header.wavID);//3
                    bw.Write(Header.fmtID);//4
                    bw.Write(Header.fmtSize);//5
                    bw.Write(Header.format);//6
                    bw.Write(Header.channels);//7
                    bw.Write(Header.sampleRate);//8
                    bw.Write(Header.bytePerSec);//9
                    bw.Write(Header.blockSize);//10
                    bw.Write(Header.bit);//11
                    bw.Write(Header.dataID);//12
                    bw.Write(Header.dataSize);//13

                    /*
                    int i = 0;
                    while (bw.BaseStream.Position != br_BaseStream_Length)
                    {
                        Int16 tmp = bsampleBuffer[i];
                        bw.Write(tmp);
                        i++;
                    }
                    */

                    for (int i = 0; i < bsampleBuffer.Length; i++)
                    {
                        Int16 tmp = bsampleBuffer[i];
                        bw.Write(tmp);
                    }
                }
                finally
                {
                    if (bw != null)
                    {
                        bw.Close();
                    }
                    if (fs != null)
                    {
                        fs.Close();
                    }
                }
            }
        }
    }
}
