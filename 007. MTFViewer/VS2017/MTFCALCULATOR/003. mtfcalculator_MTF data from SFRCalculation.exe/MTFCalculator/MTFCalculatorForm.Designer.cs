namespace MTFCalculator
{
    partial class MTFCalculatorForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MTFCalculatorForm));
            this.menuStrip = new System.Windows.Forms.MenuStrip();
            this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.openToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator = new System.Windows.Forms.ToolStripSeparator();
            this.saveToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveAsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator2 = new System.Windows.Forms.ToolStripSeparator();
            this.exitToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.editToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.copyToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.optionsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.helpToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.aboutToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.toolStripStatusLabel = new System.Windows.Forms.ToolStripStatusLabel();
            this.tabControl = new System.Windows.Forms.TabControl();
            this.tabImage = new System.Windows.Forms.TabPage();
            this.pB_Original_Image = new System.Windows.Forms.PictureBox();
            this.tabESF = new System.Windows.Forms.TabPage();
            this.zGC_MyESF = new ZedGraph.ZedGraphControl();
            this.tabLSF = new System.Windows.Forms.TabPage();
            this.tabLSF_My_Graph = new System.Windows.Forms.TabPage();
            this.zGC_MyLSF = new ZedGraph.ZedGraphControl();
            this.tabMTF = new System.Windows.Forms.TabPage();
            this.tabMTF_My_Graph = new System.Windows.Forms.TabPage();
            this.zGC_MyMTF = new ZedGraph.ZedGraphControl();
            this.tabTests = new System.Windows.Forms.TabPage();
            this.zGC_Tests = new ZedGraph.ZedGraphControl();
            this.menuStrip.SuspendLayout();
            this.statusStrip1.SuspendLayout();
            this.tabControl.SuspendLayout();
            this.tabImage.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pB_Original_Image)).BeginInit();
            this.tabESF.SuspendLayout();
            this.tabLSF_My_Graph.SuspendLayout();
            this.tabMTF_My_Graph.SuspendLayout();
            this.tabTests.SuspendLayout();
            this.SuspendLayout();
            // 
            // menuStrip
            // 
            this.menuStrip.ImageScalingSize = new System.Drawing.Size(32, 32);
            this.menuStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem,
            this.editToolStripMenuItem,
            this.toolsToolStripMenuItem,
            this.helpToolStripMenuItem});
            this.menuStrip.Location = new System.Drawing.Point(0, 0);
            this.menuStrip.Name = "menuStrip";
            this.menuStrip.Padding = new System.Windows.Forms.Padding(12, 4, 0, 4);
            this.menuStrip.Size = new System.Drawing.Size(1374, 44);
            this.menuStrip.TabIndex = 0;
            this.menuStrip.Text = "menuStrip1";
            // 
            // fileToolStripMenuItem
            // 
            this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.openToolStripMenuItem,
            this.toolStripSeparator,
            this.saveToolStripMenuItem,
            this.saveAsToolStripMenuItem,
            this.toolStripSeparator2,
            this.exitToolStripMenuItem});
            this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
            this.fileToolStripMenuItem.Size = new System.Drawing.Size(64, 36);
            this.fileToolStripMenuItem.Text = "&File";
            // 
            // openToolStripMenuItem
            // 
            this.openToolStripMenuItem.Image = ((System.Drawing.Image)(resources.GetObject("openToolStripMenuItem.Image")));
            this.openToolStripMenuItem.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.openToolStripMenuItem.Name = "openToolStripMenuItem";
            this.openToolStripMenuItem.ShortcutKeys = ((System.Windows.Forms.Keys)((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.O)));
            this.openToolStripMenuItem.Size = new System.Drawing.Size(324, 38);
            this.openToolStripMenuItem.Text = "&Open";
            this.openToolStripMenuItem.Click += new System.EventHandler(this.openToolStripMenuItem_Click);
            // 
            // toolStripSeparator
            // 
            this.toolStripSeparator.Name = "toolStripSeparator";
            this.toolStripSeparator.Size = new System.Drawing.Size(321, 6);
            // 
            // saveToolStripMenuItem
            // 
            this.saveToolStripMenuItem.Image = ((System.Drawing.Image)(resources.GetObject("saveToolStripMenuItem.Image")));
            this.saveToolStripMenuItem.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.saveToolStripMenuItem.Name = "saveToolStripMenuItem";
            this.saveToolStripMenuItem.ShortcutKeys = ((System.Windows.Forms.Keys)((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.S)));
            this.saveToolStripMenuItem.Size = new System.Drawing.Size(324, 38);
            this.saveToolStripMenuItem.Text = "&Save";
            this.saveToolStripMenuItem.Click += new System.EventHandler(this.saveToolStripMenuItem_Click);
            // 
            // saveAsToolStripMenuItem
            // 
            this.saveAsToolStripMenuItem.Name = "saveAsToolStripMenuItem";
            this.saveAsToolStripMenuItem.Size = new System.Drawing.Size(324, 38);
            this.saveAsToolStripMenuItem.Text = "Save &As";
            this.saveAsToolStripMenuItem.Click += new System.EventHandler(this.saveAsToolStripMenuItem_Click);
            // 
            // toolStripSeparator2
            // 
            this.toolStripSeparator2.Name = "toolStripSeparator2";
            this.toolStripSeparator2.Size = new System.Drawing.Size(321, 6);
            // 
            // exitToolStripMenuItem
            // 
            this.exitToolStripMenuItem.Name = "exitToolStripMenuItem";
            this.exitToolStripMenuItem.Size = new System.Drawing.Size(324, 38);
            this.exitToolStripMenuItem.Text = "E&xit";
            this.exitToolStripMenuItem.Click += new System.EventHandler(this.exitToolStripMenuItem_Click);
            // 
            // editToolStripMenuItem
            // 
            this.editToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.copyToolStripMenuItem});
            this.editToolStripMenuItem.Name = "editToolStripMenuItem";
            this.editToolStripMenuItem.Size = new System.Drawing.Size(67, 36);
            this.editToolStripMenuItem.Text = "&Edit";
            // 
            // copyToolStripMenuItem
            // 
            this.copyToolStripMenuItem.Image = ((System.Drawing.Image)(resources.GetObject("copyToolStripMenuItem.Image")));
            this.copyToolStripMenuItem.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.copyToolStripMenuItem.Name = "copyToolStripMenuItem";
            this.copyToolStripMenuItem.ShortcutKeys = ((System.Windows.Forms.Keys)((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.C)));
            this.copyToolStripMenuItem.Size = new System.Drawing.Size(252, 38);
            this.copyToolStripMenuItem.Text = "&Copy";
            this.copyToolStripMenuItem.Click += new System.EventHandler(this.copyToolStripMenuItem_Click);
            // 
            // toolsToolStripMenuItem
            // 
            this.toolsToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.optionsToolStripMenuItem});
            this.toolsToolStripMenuItem.Name = "toolsToolStripMenuItem";
            this.toolsToolStripMenuItem.Size = new System.Drawing.Size(82, 36);
            this.toolsToolStripMenuItem.Text = "&Tools";
            // 
            // optionsToolStripMenuItem
            // 
            this.optionsToolStripMenuItem.Name = "optionsToolStripMenuItem";
            this.optionsToolStripMenuItem.Size = new System.Drawing.Size(198, 38);
            this.optionsToolStripMenuItem.Text = "&Options";
            this.optionsToolStripMenuItem.Click += new System.EventHandler(this.optionsToolStripMenuItem_Click);
            // 
            // helpToolStripMenuItem
            // 
            this.helpToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.aboutToolStripMenuItem});
            this.helpToolStripMenuItem.Name = "helpToolStripMenuItem";
            this.helpToolStripMenuItem.Size = new System.Drawing.Size(77, 36);
            this.helpToolStripMenuItem.Text = "&Help";
            // 
            // aboutToolStripMenuItem
            // 
            this.aboutToolStripMenuItem.Name = "aboutToolStripMenuItem";
            this.aboutToolStripMenuItem.Size = new System.Drawing.Size(194, 38);
            this.aboutToolStripMenuItem.Text = "&About...";
            this.aboutToolStripMenuItem.Click += new System.EventHandler(this.aboutToolStripMenuItem_Click);
            // 
            // statusStrip1
            // 
            this.statusStrip1.ImageScalingSize = new System.Drawing.Size(32, 32);
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripStatusLabel});
            this.statusStrip1.Location = new System.Drawing.Point(0, 792);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Padding = new System.Windows.Forms.Padding(2, 0, 28, 0);
            this.statusStrip1.Size = new System.Drawing.Size(1374, 37);
            this.statusStrip1.TabIndex = 1;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // toolStripStatusLabel
            // 
            this.toolStripStatusLabel.Name = "toolStripStatusLabel";
            this.toolStripStatusLabel.Size = new System.Drawing.Size(225, 32);
            this.toolStripStatusLabel.Text = "toolStripStatusLabel";
            // 
            // tabControl
            // 
            this.tabControl.Controls.Add(this.tabImage);
            this.tabControl.Controls.Add(this.tabESF);
            this.tabControl.Controls.Add(this.tabLSF);
            this.tabControl.Controls.Add(this.tabLSF_My_Graph);
            this.tabControl.Controls.Add(this.tabMTF);
            this.tabControl.Controls.Add(this.tabMTF_My_Graph);
            this.tabControl.Controls.Add(this.tabTests);
            this.tabControl.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl.Location = new System.Drawing.Point(0, 44);
            this.tabControl.Margin = new System.Windows.Forms.Padding(6);
            this.tabControl.Multiline = true;
            this.tabControl.Name = "tabControl";
            this.tabControl.SelectedIndex = 0;
            this.tabControl.Size = new System.Drawing.Size(1374, 748);
            this.tabControl.TabIndex = 2;
            // 
            // tabImage
            // 
            this.tabImage.Controls.Add(this.pB_Original_Image);
            this.tabImage.Location = new System.Drawing.Point(8, 39);
            this.tabImage.Margin = new System.Windows.Forms.Padding(6);
            this.tabImage.Name = "tabImage";
            this.tabImage.Padding = new System.Windows.Forms.Padding(6);
            this.tabImage.Size = new System.Drawing.Size(1358, 701);
            this.tabImage.TabIndex = 3;
            this.tabImage.Text = "Original Image";
            this.tabImage.UseVisualStyleBackColor = true;
            // 
            // pB_Original_Image
            // 
            this.pB_Original_Image.Location = new System.Drawing.Point(9, 9);
            this.pB_Original_Image.Name = "pB_Original_Image";
            this.pB_Original_Image.Size = new System.Drawing.Size(1214, 708);
            this.pB_Original_Image.TabIndex = 0;
            this.pB_Original_Image.TabStop = false;
            // 
            // tabESF
            // 
            this.tabESF.Controls.Add(this.zGC_MyESF);
            this.tabESF.Location = new System.Drawing.Point(8, 39);
            this.tabESF.Name = "tabESF";
            this.tabESF.Size = new System.Drawing.Size(1358, 701);
            this.tabESF.TabIndex = 4;
            this.tabESF.Text = "Edge Spread Function ";
            this.tabESF.UseVisualStyleBackColor = true;
            // 
            // zGC_MyESF
            // 
            this.zGC_MyESF.Dock = System.Windows.Forms.DockStyle.Fill;
            this.zGC_MyESF.Location = new System.Drawing.Point(0, 0);
            this.zGC_MyESF.Margin = new System.Windows.Forms.Padding(12);
            this.zGC_MyESF.Name = "zGC_MyESF";
            this.zGC_MyESF.ScrollGrace = 0D;
            this.zGC_MyESF.ScrollMaxX = 0D;
            this.zGC_MyESF.ScrollMaxY = 0D;
            this.zGC_MyESF.ScrollMaxY2 = 0D;
            this.zGC_MyESF.ScrollMinX = 0D;
            this.zGC_MyESF.ScrollMinY = 0D;
            this.zGC_MyESF.ScrollMinY2 = 0D;
            this.zGC_MyESF.Size = new System.Drawing.Size(1358, 701);
            this.zGC_MyESF.TabIndex = 1;
            // 
            // tabLSF
            // 
            this.tabLSF.Location = new System.Drawing.Point(8, 39);
            this.tabLSF.Margin = new System.Windows.Forms.Padding(6);
            this.tabLSF.Name = "tabLSF";
            this.tabLSF.Padding = new System.Windows.Forms.Padding(6);
            this.tabLSF.Size = new System.Drawing.Size(1358, 701);
            this.tabLSF.TabIndex = 0;
            this.tabLSF.Text = "Line Spread Function";
            this.tabLSF.UseVisualStyleBackColor = true;
            // 
            // tabLSF_My_Graph
            // 
            this.tabLSF_My_Graph.Controls.Add(this.zGC_MyLSF);
            this.tabLSF_My_Graph.Location = new System.Drawing.Point(8, 39);
            this.tabLSF_My_Graph.Name = "tabLSF_My_Graph";
            this.tabLSF_My_Graph.Size = new System.Drawing.Size(1358, 701);
            this.tabLSF_My_Graph.TabIndex = 5;
            this.tabLSF_My_Graph.Text = "LSF My Graph";
            this.tabLSF_My_Graph.UseVisualStyleBackColor = true;
            // 
            // zGC_MyLSF
            // 
            this.zGC_MyLSF.Dock = System.Windows.Forms.DockStyle.Fill;
            this.zGC_MyLSF.Location = new System.Drawing.Point(0, 0);
            this.zGC_MyLSF.Margin = new System.Windows.Forms.Padding(12);
            this.zGC_MyLSF.Name = "zGC_MyLSF";
            this.zGC_MyLSF.ScrollGrace = 0D;
            this.zGC_MyLSF.ScrollMaxX = 0D;
            this.zGC_MyLSF.ScrollMaxY = 0D;
            this.zGC_MyLSF.ScrollMaxY2 = 0D;
            this.zGC_MyLSF.ScrollMinX = 0D;
            this.zGC_MyLSF.ScrollMinY = 0D;
            this.zGC_MyLSF.ScrollMinY2 = 0D;
            this.zGC_MyLSF.Size = new System.Drawing.Size(1358, 701);
            this.zGC_MyLSF.TabIndex = 2;
            // 
            // tabMTF
            // 
            this.tabMTF.Location = new System.Drawing.Point(8, 39);
            this.tabMTF.Margin = new System.Windows.Forms.Padding(6);
            this.tabMTF.Name = "tabMTF";
            this.tabMTF.Padding = new System.Windows.Forms.Padding(6);
            this.tabMTF.Size = new System.Drawing.Size(1358, 701);
            this.tabMTF.TabIndex = 1;
            this.tabMTF.Text = "Modulation Transfer Function";
            this.tabMTF.UseVisualStyleBackColor = true;
            // 
            // tabMTF_My_Graph
            // 
            this.tabMTF_My_Graph.Controls.Add(this.zGC_MyMTF);
            this.tabMTF_My_Graph.Location = new System.Drawing.Point(8, 39);
            this.tabMTF_My_Graph.Name = "tabMTF_My_Graph";
            this.tabMTF_My_Graph.Size = new System.Drawing.Size(1358, 701);
            this.tabMTF_My_Graph.TabIndex = 6;
            this.tabMTF_My_Graph.Text = "MTF My Graph";
            this.tabMTF_My_Graph.UseVisualStyleBackColor = true;
            // 
            // zGC_MyMTF
            // 
            this.zGC_MyMTF.Dock = System.Windows.Forms.DockStyle.Fill;
            this.zGC_MyMTF.Location = new System.Drawing.Point(0, 0);
            this.zGC_MyMTF.Margin = new System.Windows.Forms.Padding(12);
            this.zGC_MyMTF.Name = "zGC_MyMTF";
            this.zGC_MyMTF.ScrollGrace = 0D;
            this.zGC_MyMTF.ScrollMaxX = 0D;
            this.zGC_MyMTF.ScrollMaxY = 0D;
            this.zGC_MyMTF.ScrollMaxY2 = 0D;
            this.zGC_MyMTF.ScrollMinX = 0D;
            this.zGC_MyMTF.ScrollMinY = 0D;
            this.zGC_MyMTF.ScrollMinY2 = 0D;
            this.zGC_MyMTF.Size = new System.Drawing.Size(1358, 701);
            this.zGC_MyMTF.TabIndex = 3;
            // 
            // tabTests
            // 
            this.tabTests.Controls.Add(this.zGC_Tests);
            this.tabTests.Location = new System.Drawing.Point(8, 39);
            this.tabTests.Name = "tabTests";
            this.tabTests.Size = new System.Drawing.Size(1358, 701);
            this.tabTests.TabIndex = 7;
            this.tabTests.Text = "Tests";
            this.tabTests.UseVisualStyleBackColor = true;
            // 
            // zGC_Tests
            // 
            this.zGC_Tests.Dock = System.Windows.Forms.DockStyle.Fill;
            this.zGC_Tests.Location = new System.Drawing.Point(0, 0);
            this.zGC_Tests.Margin = new System.Windows.Forms.Padding(12);
            this.zGC_Tests.Name = "zGC_Tests";
            this.zGC_Tests.ScrollGrace = 0D;
            this.zGC_Tests.ScrollMaxX = 0D;
            this.zGC_Tests.ScrollMaxY = 0D;
            this.zGC_Tests.ScrollMaxY2 = 0D;
            this.zGC_Tests.ScrollMinX = 0D;
            this.zGC_Tests.ScrollMinY = 0D;
            this.zGC_Tests.ScrollMinY2 = 0D;
            this.zGC_Tests.Size = new System.Drawing.Size(1358, 701);
            this.zGC_Tests.TabIndex = 4;
            // 
            // MTFCalculatorForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(12F, 25F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1374, 829);
            this.Controls.Add(this.tabControl);
            this.Controls.Add(this.statusStrip1);
            this.Controls.Add(this.menuStrip);
            this.MainMenuStrip = this.menuStrip;
            this.Margin = new System.Windows.Forms.Padding(6);
            this.Name = "MTFCalculatorForm";
            this.Text = "Modulation Transfer Function Calculator";
            this.menuStrip.ResumeLayout(false);
            this.menuStrip.PerformLayout();
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.tabControl.ResumeLayout(false);
            this.tabImage.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pB_Original_Image)).EndInit();
            this.tabESF.ResumeLayout(false);
            this.tabLSF_My_Graph.ResumeLayout(false);
            this.tabMTF_My_Graph.ResumeLayout(false);
            this.tabTests.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.MenuStrip menuStrip;
        private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem openToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator;
        private System.Windows.Forms.ToolStripMenuItem saveAsToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator2;
        private System.Windows.Forms.ToolStripMenuItem exitToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem editToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem copyToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem toolsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem optionsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem helpToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem aboutToolStripMenuItem;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel;
        private System.Windows.Forms.ToolStripMenuItem saveToolStripMenuItem;
        private System.Windows.Forms.TabControl tabControl;
        private System.Windows.Forms.TabPage tabLSF;
        private System.Windows.Forms.TabPage tabMTF;
        private System.Windows.Forms.TabPage tabImage;
        private System.Windows.Forms.TabPage tabESF;
        private ZedGraph.ZedGraphControl zGC_MyESF;
        private System.Windows.Forms.PictureBox pB_Original_Image;
        private System.Windows.Forms.TabPage tabLSF_My_Graph;
        private ZedGraph.ZedGraphControl zGC_MyLSF;
        private System.Windows.Forms.TabPage tabMTF_My_Graph;
        private ZedGraph.ZedGraphControl zGC_MyMTF;
        private System.Windows.Forms.TabPage tabTests;
        private ZedGraph.ZedGraphControl zGC_Tests;
    }
}

