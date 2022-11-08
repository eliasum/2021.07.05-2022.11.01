namespace WinForm_SendMessage_TEST
{
    using System;
    using System.Drawing;
    using System.Windows.Forms;
    using System.Security.Permissions;
    using System.Runtime.InteropServices;

    public partial class Form1 : Form
    {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);

         private double[] exposition = new double[2] { .0, .0 };
        private uint[] gain = new uint[2] { 0, 0 };

        private const int WM_COPYDATA = 0x004Af;

        public Form1() { InitializeComponent(); }

        private void Form1_Load(object sender, EventArgs e)
        {
            IntPtr ptr = FindWindow(null, "здесь должен быть заголовок Татьяниной програииы");
            if (ptr != IntPtr.Zero)
                SendMessage(ptr, WM_COPYDATA, 0, string.Empty); // функция для отправки сообщкния
            else MessageBox.Show("Окно не найдено");
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            if (this.exposition[0] != this.exposition[1])
            {
                this.exposition[0] = this.exposition[1];
                e.Graphics.DrawString(string.Format("Exposition = {0}", this.exposition[0]),
                    this.Font, SystemBrushes.ActiveCaptionText, 20, 20);
            }
            if (this.gain[0] != this.gain[1])
            {
                this.gain[0] = this.gain[1];
                e.Graphics.DrawString(string.Format("Gain = {0}", this.gain[0]),
                    this.Font, SystemBrushes.ActiveCaptionText, 200, 20);
            }
        }

        [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
        protected override void WndProc(ref Message msg)
        {
            switch (msg.Msg)
            {
                case WM_COPYDATA:
                    this.exposition[1] = (double)msg.LParam;
                    this.gain[1] = (uint)msg.WParam;
                    this.Invalidate();
                    break;
            }
            base.WndProc(ref msg);
        }
    }
}
