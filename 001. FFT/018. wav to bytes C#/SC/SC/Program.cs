/*
 * Created by SharpDevelop.
 * User: 
 * Date: 24.11.2012
 * Time: 7:48
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */

using System;
using System.Collections;
using System.IO;
using System.Runtime.InteropServices;

namespace Stego_Console
{
    class Program
    {
        public static void Main(string[] args)
        {
            bool flag = true;
            do
            {
                Console.WriteLine("What ddo you want to do with audio file? (Hide - 1 or Recover - 2 a text)");
                string action = Console.ReadLine();
                switch (action)
                {
                    case "1":
                        try
                        {
                            Console.WriteLine("Please, enter path to audio file:");
                            F_H_For_In.setSound("1.wav");
                            Console.WriteLine("Now enter path to text file:");
                            F_H_For_In.setText(Console.ReadLine());
                            try
                            {
                                F_H_For_In.step();
                                Stego_In si = new Stego_In();
                                si.hiderLength();
                                si.hiderText();
                                F_H_For_In.soundReWriter(si.b_snd);
                                Console.WriteLine("Stegofile is created.");
                            }
                            catch (LengthException l)
                            {
                                Console.WriteLine(l.MessageIn);
                            }
                        }
                        catch (FileException f)
                        {
                            Console.WriteLine(f.Message);
                        }
                        break;
                    case "2":
                        try
                        {
                            Console.WriteLine("Please, enter path to audio file:");
                            F_H_For_Out.setSound(Console.ReadLine());
                            try
                            {
                                Stego_Out so = new Stego_Out();
                                so.textRecover();
                                F_H_For_Out.textWriter(so.txt);
                                Console.WriteLine("Text recover.");
                            }
                            catch (LengthException l)
                            {
                                Console.WriteLine(l.MessageOut);
                            }
                        }
                        catch (FileException f)
                        {
                            Console.WriteLine(f.Message);
                        }
                        break;
                    default:
                        Console.WriteLine("Incorrect enter!");
                        break;
                }
                Console.WriteLine("Continue? (1 - Yes or 2 - No)");
                string s = Console.ReadLine();
                switch (s)
                {
                    case "1":
                        flag = true;
                        break;
                    case "2":
                        flag = false;
                        break;
                    default:
                        Console.WriteLine("Incorrect enter!");
                        flag = true;
                        break;
                }
            } while (flag);
        }
    }
}
 
 
/*
 * Created by SharpDevelop.
 * User: 
 * Date: 11.12.2012
 * Time: 19:07
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */

 
namespace Stego_Console
{
    // Overrides FileNotFound Exception

    public class FileException : System.Exception
    {
        public FileException() { }

        public override string Message
        {
            get
            {
                return "File not Found!";
            }
        }
    }
}
 
 
/*
 * Created by SharpDevelop.
 * User: 
 * Date: 11.12.2012
 * Time: 19:02
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */

 
namespace Stego_Console
{
    // Exception of lenghth of step

    public class LengthException : System.Exception
    {
        public LengthException() { }

        public string MessageIn
        {
            get
            {
                return "Text is too long!";
            }
        }

        public string MessageOut
        {
            get
            {
                return "This action is meaningless!";
            }
        }
    }
} 
/*
 * Created by SharpDevelop.
 * User: 
 * Date: 24.11.2012
 * Time: 7:51
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
 

 
namespace Stego_Console
{
    // Operate header of WAV-file; get information about encoding

    [StructLayout(LayoutKind.Sequential)]

    // Struct describing header of WAV-file

    internal class WavHeader
    {
        // WAV-format starts with RIFF-header: contains ASCII-character "RIFF"
        // (0x52494646 in big-endian form)

        public UInt32 ChunkId;

        // 36 + subchunk2Size, or more exactly: 4 + (8 + subchunk1Size) + (8 + subchunk2Size)

        public UInt32 ChunkSize;

        // Contains characters "WAVE" (0x57415645 in big-endian form)

        public UInt32 Format;

        // Format "WAVE" consists of two subchains: "fmt " and "data":
        // Subchain "fmt " describe format of audio data: contains characters "fmt "
        // (0x666d7420 in big-endian form)

        public UInt32 Subchunk1Id;

        // 16 for PCM-format

        public UInt32 Subchunk1Size;

        // Audio-format
        // For PCM = 1 (linear quantization)

        public UInt16 AudioFormat;

        // Number of channels

        public UInt16 NumChannels;

        // Sampling rate

        public UInt32 SampleRate;

        // sampleRate * numChannels * bitsPerSample/8

        public UInt32 ByteRate;

        // numChannels * bitsPerSample/8
        // Number of bytes for one sample; includong all channels

        public UInt16 BlockAlign;

        // Bits per sample

        public UInt16 BitsPerSample;

        // Subchain "data" contains audio-data and its size
        // Contains characters "data" (0x64617461 in big-endian form)

        public UInt32 Subchunk2Id;

        // numSamples * numChannels * bitsPerSample/8
        // Number of bytes in data realm

        public UInt32 Subchunk2Size;

        // Audio-data
    }

    static class Audio_Info
    {
        public static int info(string name)
        {
            var header = new WavHeader();                   //  Size of header
            var headerSize = Marshal.SizeOf(header);
            var fileStream = new FileStream(name, FileMode.Open, FileAccess.Read);
            var buffer = new byte[headerSize];
            fileStream.Read(buffer, 0, headerSize);
            var headerPtr = Marshal.AllocHGlobal(headerSize);
            Marshal.Copy(buffer, 0, headerPtr, headerSize);
            Marshal.PtrToStructure(headerPtr, header);
            return header.BitsPerSample;
        }
    }
}
 
/*
 * Created by SharpDevelop.
 * User: 
 * Date: 11.12.2012
 * Time: 18:32
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
 
 
namespace Stego_Console
{
    // Primary handler for stego_in operation

    public static class F_H_For_In
    {
        public static string snd_name;
        public static string txt_name;

        public static void setSound(string path)
        {
            snd_name = path;
            if (!File.Exists(snd_name))
            {
                throw new FileException();
            }
        }

        public static void setText(string path)
        {
            txt_name = path;
            if (!File.Exists(txt_name))
            {
                throw new FileException();
            }
        }

        public static byte[] textReader()
        {
            return File.ReadAllBytes(txt_name);
        }

        public static byte[] soundReader()
        {
            return File.ReadAllBytes(snd_name);
        }

        public static void soundReWriter(byte[] snd)
        {
            String n_path = snd_name.Replace(".wav", "_stego.wav");
            File.WriteAllBytes(n_path, snd);
        }

        public static int step()
        {
            long p;
            int k = Audio_Info.info(snd_name);
            p = (F_H_For_In.soundReader().LongLength - 174) / (F_H_For_In.textReader().LongLength * k);
            if (p < 4)
            {
                throw new LengthException();
            }
            return (int)p;
        }
    }
}
 
 
/*
 * Created by SharpDevelop.
 * User: 
 * Date: 24.11.2012
 * Time: 7:53
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */

 
namespace Stego_Console
{
    // Primary operation of files

    public static class F_H_For_Out
    {
        public static string snd_name;

        public static void setSound(string path)
        {
            snd_name = path;
            if (!File.Exists(snd_name))
            {
                throw new FileException();
            }
        }

        public static byte[] soundReader()
        {
            return File.ReadAllBytes(snd_name);
        }

        public static void textWriter(byte[] txt)
        {
            string n_path = snd_name.Replace(".wav", "_from_stego.txt");
            File.WriteAllBytes(n_path, txt);
        }

        public static int step(int l)
        {
            long p;
            int k = Audio_Info.info(snd_name);
            p = (F_H_For_Out.soundReader().LongLength - 174) / (l * k);
            if (p < 4)
            {
                throw new LengthException();
            }
            return (int)p;
        }
    }
}
 
 
/*
 * Created by SharpDevelop.
 * User: 
 * Date: 24.11.2012
 * Time: 7:56
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
 

namespace Stego_Console
{
    // Hide text in audiofile
    public class Stego_In
    {
        public Stego_In() { }
        private readonly int step = F_H_For_In.step();
        private BitArray length = new BitArray(codeLength());
        private BitArray b_txt = new BitArray(F_H_For_In.textReader());
        public byte[] b_snd = F_H_For_In.soundReader();

        public void hiderLength()
        {
            int j = 46;
            for (int i = 0; i < length.Count; i++)
            {
                byteChange(b_snd[j], length[i]);
                j += 4;
            }
        }

        public void hiderText()
        {
            long j = 180;
            for (int i = 0; i < b_txt.Count; i++)
            {
                byteChange(b_snd[j], b_txt[i]);
                j += step;
            }
        }

        private static byte[] codeLength()
        {
            byte[] b = new byte[4];
            int l = F_H_For_In.textReader().Length;
            for (int i = 0; i <= 3; i++)
            {
                b[i] = (byte)((l >> (8 * i)) & 0x000F);
            }
            return b;
        }

        private byte byteChange(byte b, bool curr)
        {
            byte[] nb = new byte[1] { b };
            BitArray ba = new BitArray(nb);
            ba.Set(0, curr);
            b = 0;
            for (int i = 0; i < 8; i++)
            {
                if (ba[i] == true)
                {
                    b += (byte)Math.Pow(2, i);
                }
            }
            return nb[0];
        }
    }
}
/*
 * Created by SharpDevelop.
 * User: 
 * Date: 24.11.2012
 * Time: 7:57
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */

 
namespace Stego_Console
{
    // Recover text from audio file 
    public class Stego_Out
    {
        public Stego_Out() { }

        private readonly int step = F_H_For_Out.step(lengthReader());
        private static BitArray length = new BitArray(32);
        private BitArray b_txt = new BitArray(lengthReader() * 8);
        private static byte[] b_snd = F_H_For_Out.soundReader();
        public byte[] txt = new byte[lengthReader()];

        public static int lengthReader()
        {
            int j = 46;
            for (int i = 0; i < 32; i++)
            {
                length.Set(i, bitRead(b_snd[j]));
                j += 4;
            }
            byte[] l = bitsToBytes(length);
            int ln = BitConverter.ToInt32(l, 0);
            if (ln <= 0)
            {
                throw new LengthException();
            }
            return ln;
        }

        public void textRecover()
        {
            long j = 180;
            for (int i = 0; i < b_txt.Count; i++)
            {
                b_txt[i] = bitRead(b_snd[j]);
                j += step;
            }
            txt = bitsToBytes(b_txt);
        }

        private static byte[] bitsToBytes(BitArray ba)
        {
            const int bb = 8;
            byte[] b = new byte[(ba.Count + (bb - 1)) / bb];
            ba.CopyTo(b, 0);
            return b;
        }

        private static bool bitRead(byte b)
        {
            byte[] nb = new byte[1] { b };
            BitArray ba = new BitArray(nb);
            bool bo = ba.Get(0);
            return bo;
        }
    }
}