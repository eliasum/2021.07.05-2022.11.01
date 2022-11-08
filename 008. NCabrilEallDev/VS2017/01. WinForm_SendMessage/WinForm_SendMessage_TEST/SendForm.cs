/*2021.10.26 17:29 IMM*/

namespace WinForm_SendMessage_TEST
{
    using System;
    using System.Windows.Forms;
    using System.Runtime.InteropServices;

    public partial class SendForm : Form
    {
        // Импорт метода FindWindow() из user32.dll
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        // Импорт метода SendMessage() из user32.dll
        [DllImport("user32.dll")]
        public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);

        // Импорт метода PostMessage() из user32.dll
        /*
            hWnd   - Дескриптор окна, оконная процедура которого должна принять сообщение.
            Msg    - Определяет сообщение, которое должно быть поставлено в очередь.
            wParam - Определяет дополнительную конкретизирующую сообщение информацию.
            lParam - Определяет дополнительную конкретизирующую сообщение информацию.
        */
        [DllImport("user32.dll")]
        public static extern int PostMessage(IntPtr hWnd, int uMsg, int wParam, long lParam);

        // параметр 'усиление'
        private int gain = 10;      // тестовое значение

        // параметр 'экспозиция'
        private long expo = 100;    // тестовое значение

        /*
            http://vsokovikov.narod.ru/New_MSDN_API/Message_queue/notify_wm_user.htm

            Константа WM_USER используется прикладными программами, чтобы помогать 
            определить нестандартные сообщения используемы нестандартными классами 
            окна, обычно в форме WM_USER+X, где X - целочисленное значение.
        */
        private const int WM_USER = 0x0400;

        /*
            пользовательская константа, входящая в диапазон:
            от WM_USER до 0x7FFF - Целочисленные сообщения для использования отдельными
            классами окна. 
        */
        private const int CM_SET_CAM_SETTINGS_IMAGEPROG = WM_USER + 21;

        // конструктор формы
        public SendForm()
        {
            InitializeComponent();
        }

        // прослушивание события загрузки класса формы
        private void SendForm_Load(object sender, EventArgs e)
        {
            // поиск дескриптора окна верхнего уровня с именем 'UeyeWindow'
            IntPtr ptr = FindWindow(null, "UeyeWindow");

            // если окно с именем 'UeyeWindow' открыто
            if (ptr != IntPtr.Zero)
                /*
                    отправка окну с именем 'UeyeWindow' сообщения 
                    'CM_SET_CAM_SETTINGS_IMAGEPROG' с параметрами gain и expo
                */
                PostMessage(ptr, CM_SET_CAM_SETTINGS_IMAGEPROG, gain, expo);   // функция для отправки сообщения
            else
                MessageBox.Show("Окно не найдено");
        }
    }
}
