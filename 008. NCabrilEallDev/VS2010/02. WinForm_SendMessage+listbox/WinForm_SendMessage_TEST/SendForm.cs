namespace WinForm_SendMessage_TEST
{
    using System;
    using System.Windows.Forms;
    using System.Runtime.InteropServices;

    public partial class SendForm : Form
    {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        public static extern int PostMessage(IntPtr hWnd, int uMsg, int wParam, long lParam);

        private int gain = 10;      // тестовое значение

        private long expo = 100;    // тестовое значение

        private const int WM_USER = 0x0400;

        private const int CM_SET_CAM_SETTINGS_IMAGEPROG = WM_USER + 21;

        public SendForm()
        {
            InitializeComponent();
        }

        private void SendButton_Click(object sender, EventArgs e)
        {
            IntPtr ptr = FindWindow(null, "UeyeWindow");

            if (ptr != IntPtr.Zero)
                PostMessage(ptr, CM_SET_CAM_SETTINGS_IMAGEPROG, gain, expo);   // функция для отправки сообщения
            else
                MessageBox.Show("Окно не найдено");
        }
    }
}
