using System;
using System.Collections.Generic;
using System.IO;

namespace ConsoleApplication1
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
            long br_BaseStream_Length = 0;
            long lDataList_count = 0;

            using (FileStream fs = new FileStream(@"d:\source.wav", FileMode.Open, FileAccess.Read))
            using (BinaryReader br = new BinaryReader(fs))
            {
                try
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

                    /*
                    int n = (int)(Header.dataSize / Header.channels * 8 / Header.bit);

                    for (int i = 0; i < 193535; i++)
                    {
                        Int16 tmp = 0;
                        tmp = br.ReadInt16();
                        lDataList.Add(tmp);
                    }
                    */

                    while (br.BaseStream.Position != br.BaseStream.Length)
                    {
                        Int16 tmp = 0;
                        tmp = br.ReadInt16();
                        lDataList.Add(tmp);
                        lDataList_count++;
                    }

                    br_BaseStream_Length = br.BaseStream.Length;

                    // вывод байтов аудио
                    StreamWriter sr = new StreamWriter(@"d:\out.txt");

                    for (int i = 0; i < lDataList_count; i++)
                        sr.Write(lDataList[i] + "\n");

                    sr.Close();
                }
                finally
                {
                    if (br != null)
                    {
                        br.Close();
                    }
                    if (fs != null)
                    {
                        fs.Close();
                    }
                }
            }
            Console.WriteLine("Открыт");

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
                    int n = (int)(Header.dataSize / Header.channels * 8 / Header.size);

                    for (int i = 0; i < n; i++)
                    {
                        Int16 tmp = lDataList[i];
                        bw.Write(tmp);
                    }
                    */

                    int i = 0;
                    while (bw.BaseStream.Position != br_BaseStream_Length)
                    {
                        Int16 tmp = lDataList[i];
                        bw.Write(tmp);
                        i++;
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

            return;
        }
    }
}