using System;
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

        private int WParam = 0;

        private long LParam = 0;

        private const int WM_USER = 0x0400;

        private const int CM_SET_CAM_SETTINGS_IMAGEPROG = WM_USER + 21; // 1045

        public ReceiveForm()
        {
            InitializeComponent();
        }

        [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
        protected override void WndProc(ref Message msg)
        {
            switch (msg.Msg)
            {
                case CM_SET_CAM_SETTINGS_IMAGEPROG:
                    message = msg.Msg.ToString();
                    this.gain = (int)msg.WParam;
                    this.exposition = (long)msg.LParam;
                    messageListBox.Items.Add("Сообщение: " + message + "; gain: " + gain.ToString() + "; exposition: " + exposition.ToString());
                    this.Invalidate();
                    break;
                default:
                    other = msg.Msg.ToString();
                    this.WParam = (int)msg.WParam;
                    this.LParam = (long)msg.LParam;
                    otherListBox.Items.Add("Сообщение: " + other + "; WParam: " + WParam.ToString() + "; LParam: " + LParam.ToString());
                    break;
            }
            base.WndProc(ref msg);
        }

        private void OtherSaveButton_Click(object sender, System.EventArgs e)
        {
            using (System.IO.StreamWriter sw = new System.IO.StreamWriter("OtherMessages.txt"))
            {
                for (int i = 0; i < otherListBox.Items.Count; i++)
                    sw.WriteLine(otherListBox.Items[i].ToString());
            }
        }

        private void MessagesSaveButton_Click(object sender, EventArgs e)
        {
            using (System.IO.StreamWriter sw = new System.IO.StreamWriter("MKPMessages.txt"))
            {
                for (int i = 0; i < messageListBox.Items.Count; i++)
                    sw.WriteLine(messageListBox.Items[i].ToString());
            }
        }
    }
}
