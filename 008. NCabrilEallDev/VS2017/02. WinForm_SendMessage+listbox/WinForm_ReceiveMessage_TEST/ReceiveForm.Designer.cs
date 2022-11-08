namespace WinForm_ReceiveMessage_TEST
{
    partial class ReceiveForm
    {
        /// <summary>
        /// Обязательная переменная конструктора.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Освободить все используемые ресурсы.
        /// </summary>
        /// <param name="disposing">истинно, если управляемый ресурс должен быть удален; иначе ложно.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Код, автоматически созданный конструктором форм Windows

        /// <summary>
        /// Требуемый метод для поддержки конструктора — не изменяйте 
        /// содержимое этого метода с помощью редактора кода.
        /// </summary>
        private void InitializeComponent()
        {
            this.otherListBox = new System.Windows.Forms.ListBox();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.otherSaveButton = new System.Windows.Forms.Button();
            this.messageListBox = new System.Windows.Forms.ListBox();
            this.messagesSaveButton = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // otherListBox
            // 
            this.otherListBox.FormattingEnabled = true;
            this.otherListBox.ItemHeight = 25;
            this.otherListBox.Location = new System.Drawing.Point(17, 302);
            this.otherListBox.Name = "otherListBox";
            this.otherListBox.Size = new System.Drawing.Size(611, 204);
            this.otherListBox.TabIndex = 0;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(12, 274);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(206, 25);
            this.label1.TabIndex = 1;
            this.label1.Text = "Другие сообщения:";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(12, 9);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(214, 25);
            this.label2.TabIndex = 2;
            this.label2.Text = "Сообщение от MKP:";
            // 
            // otherSaveButton
            // 
            this.otherSaveButton.Location = new System.Drawing.Point(634, 302);
            this.otherSaveButton.Name = "otherSaveButton";
            this.otherSaveButton.Size = new System.Drawing.Size(227, 50);
            this.otherSaveButton.TabIndex = 6;
            this.otherSaveButton.Text = "Сохранить в файл";
            this.otherSaveButton.UseVisualStyleBackColor = true;
            this.otherSaveButton.Click += new System.EventHandler(this.OtherSaveButton_Click);
            // 
            // messageListBox
            // 
            this.messageListBox.FormattingEnabled = true;
            this.messageListBox.ItemHeight = 25;
            this.messageListBox.Location = new System.Drawing.Point(17, 37);
            this.messageListBox.Name = "messageListBox";
            this.messageListBox.Size = new System.Drawing.Size(611, 204);
            this.messageListBox.TabIndex = 7;
            // 
            // messagesSaveButton
            // 
            this.messagesSaveButton.Location = new System.Drawing.Point(634, 37);
            this.messagesSaveButton.Name = "messagesSaveButton";
            this.messagesSaveButton.Size = new System.Drawing.Size(227, 50);
            this.messagesSaveButton.TabIndex = 8;
            this.messagesSaveButton.Text = "Сохранить в файл";
            this.messagesSaveButton.UseVisualStyleBackColor = true;
            this.messagesSaveButton.Click += new System.EventHandler(this.MessagesSaveButton_Click);
            // 
            // ReceiveForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(12F, 25F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(874, 529);
            this.Controls.Add(this.messagesSaveButton);
            this.Controls.Add(this.messageListBox);
            this.Controls.Add(this.otherSaveButton);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.otherListBox);
            this.Name = "ReceiveForm";
            this.Text = "UeyeWindow";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.ListBox otherListBox;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Button otherSaveButton;
        private System.Windows.Forms.ListBox messageListBox;
        private System.Windows.Forms.Button messagesSaveButton;
    }
}

