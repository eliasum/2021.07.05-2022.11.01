using System.Drawing;
using System.Security.Permissions;
using System.Windows.Forms;

namespace WinForm_ReceiveMessage_TEST
{
    public partial class ReceiveForm : Form
    {
        string message = "void";

        string other = null;
        private int gain = 0;
        private long exposition = 0;

        // параметр 'усиление'
        //private int[] gain = new int[2] { 0, 0 };
        private int WParam = 0;

        // параметр 'экспозиция'
        //private long[] exposition = new long[2] { 0, 0 };
        private long LParam = 0;

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
        private const int CM_SET_CAM_SETTINGS_IMAGEPROG = WM_USER + 21; // 1045

        // конструктор формы
        public ReceiveForm()
        {
            InitializeComponent();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.DrawString(string.Format("message = {0}", this.message),
                this.Font, SystemBrushes.ActiveCaptionText, 20, 20);

            //if (this.gain[0] != this.gain[1])
            {
                //this.gain[0] = this.gain[1];
                //e.Graphics.DrawString(string.Format("Gain = {0}", this.gain[0]),
                e.Graphics.DrawString(string.Format("Gain = {0}", this.gain),
                    this.Font, SystemBrushes.ActiveCaptionText, 400, 20);
            }

            //if (this.exposition[0] != this.exposition[1])
            {
                //MessageBox.Show("OnPaint");
                //this.exposition[0] = this.exposition[1];
                //e.Graphics.DrawString(string.Format("Exposition = {0}", this.exposition[0]),
                e.Graphics.DrawString(string.Format("Exposition = {0}", this.exposition),
                    this.Font, SystemBrushes.ActiveCaptionText, 200, 20);
            }

            e.Graphics.DrawString(string.Format("other = {0}", this.other),
                this.Font, SystemBrushes.ActiveCaptionText, 20, 40);

            e.Graphics.DrawString(string.Format("WParam = {0}", this.WParam),
                this.Font, SystemBrushes.ActiveCaptionText, 200, 40);

            e.Graphics.DrawString(string.Format("LParam = {0}", this.LParam),
                this.Font, SystemBrushes.ActiveCaptionText, 400, 40);

        }

        /*
            Переопределение метода WndProc для обработки сообщений операционной 
            системы, указанных в структуре Message.
        */
        [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
        protected override void WndProc(ref Message msg)
        {
            switch (msg.Msg)
            {
                case CM_SET_CAM_SETTINGS_IMAGEPROG:
                    message = msg.Msg.ToString();
                    this.gain = (int)msg.WParam;
                    this.exposition = (long)msg.LParam;
                    this.Invalidate();
                    MessageBox.Show("Обработано сообщение CM_SET_CAM_SETTINGS_IMAGEPROG");
                    break;
                default:
                    other = msg.Msg.ToString();
                    this.WParam = (int)msg.WParam;
                    this.LParam = (long)msg.LParam;
                    break;
            }
            base.WndProc(ref msg);
        }
    }
}
