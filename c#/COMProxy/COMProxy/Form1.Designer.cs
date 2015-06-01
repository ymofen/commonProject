namespace COMProxy
{
    partial class frmMain
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.btnOpenCOM1 = new System.Windows.Forms.Button();
            this.comboBox1 = new System.Windows.Forms.ComboBox();
            this.sPort01 = new System.IO.Ports.SerialPort(this.components);
            this.textBox1 = new System.Windows.Forms.TextBox();
            this.cbbCOM02 = new System.Windows.Forms.ComboBox();
            this.sPort02 = new System.IO.Ports.SerialPort(this.components);
            this.txtPort2 = new System.Windows.Forms.TextBox();
            this.btnOpenCOM2 = new System.Windows.Forms.Button();
            this.button1 = new System.Windows.Forms.Button();
            this.btnClose = new System.Windows.Forms.Button();
            this.lstFilter = new System.Windows.Forms.CheckedListBox();
            this.label1 = new System.Windows.Forms.Label();
            this.txtCOMDATA_01 = new System.Windows.Forms.TextBox();
            this.SendCOM01 = new System.Windows.Forms.Button();
            this.btnSendCOM01Hex = new System.Windows.Forms.Button();
            this.btnHexToString = new System.Windows.Forms.Button();
            this.chkCOM02RecordToFile = new System.Windows.Forms.CheckBox();
            this.SuspendLayout();
            // 
            // btnOpenCOM1
            // 
            this.btnOpenCOM1.Location = new System.Drawing.Point(139, 20);
            this.btnOpenCOM1.Name = "btnOpenCOM1";
            this.btnOpenCOM1.Size = new System.Drawing.Size(87, 23);
            this.btnOpenCOM1.TabIndex = 0;
            this.btnOpenCOM1.Text = "打开COM接口";
            this.btnOpenCOM1.UseVisualStyleBackColor = true;
            this.btnOpenCOM1.Click += new System.EventHandler(this.button1_Click);
            // 
            // comboBox1
            // 
            this.comboBox1.FormattingEnabled = true;
            this.comboBox1.Location = new System.Drawing.Point(12, 22);
            this.comboBox1.Name = "comboBox1";
            this.comboBox1.Size = new System.Drawing.Size(121, 20);
            this.comboBox1.TabIndex = 1;
            // 
            // sPort01
            // 
            this.sPort01.DataReceived += new System.IO.Ports.SerialDataReceivedEventHandler(this.sPort01_DataReceived);
            // 
            // textBox1
            // 
            this.textBox1.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.textBox1.Location = new System.Drawing.Point(12, 84);
            this.textBox1.Multiline = true;
            this.textBox1.Name = "textBox1";
            this.textBox1.Size = new System.Drawing.Size(599, 213);
            this.textBox1.TabIndex = 2;
            // 
            // cbbCOM02
            // 
            this.cbbCOM02.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.cbbCOM02.FormattingEnabled = true;
            this.cbbCOM02.Location = new System.Drawing.Point(15, 323);
            this.cbbCOM02.Name = "cbbCOM02";
            this.cbbCOM02.Size = new System.Drawing.Size(121, 20);
            this.cbbCOM02.TabIndex = 3;
            // 
            // sPort02
            // 
            this.sPort02.DataReceived += new System.IO.Ports.SerialDataReceivedEventHandler(this.sPort02_DataReceived);
            // 
            // txtPort2
            // 
            this.txtPort2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtPort2.Location = new System.Drawing.Point(12, 350);
            this.txtPort2.Multiline = true;
            this.txtPort2.Name = "txtPort2";
            this.txtPort2.Size = new System.Drawing.Size(760, 164);
            this.txtPort2.TabIndex = 4;
            // 
            // btnOpenCOM2
            // 
            this.btnOpenCOM2.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnOpenCOM2.Location = new System.Drawing.Point(151, 321);
            this.btnOpenCOM2.Name = "btnOpenCOM2";
            this.btnOpenCOM2.Size = new System.Drawing.Size(75, 23);
            this.btnOpenCOM2.TabIndex = 5;
            this.btnOpenCOM2.Text = "打开COM接口";
            this.btnOpenCOM2.UseVisualStyleBackColor = true;
            this.btnOpenCOM2.Click += new System.EventHandler(this.btnOpenCOM2_Click);
            // 
            // button1
            // 
            this.button1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.button1.Location = new System.Drawing.Point(642, 320);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(75, 23);
            this.button1.TabIndex = 6;
            this.button1.Text = "测试";
            this.button1.UseVisualStyleBackColor = true;
            this.button1.Click += new System.EventHandler(this.button1_Click_1);
            // 
            // btnClose
            // 
            this.btnClose.Location = new System.Drawing.Point(621, 22);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(109, 23);
            this.btnClose.TabIndex = 7;
            this.btnClose.Text = "关闭所有端口";
            this.btnClose.UseVisualStyleBackColor = true;
            this.btnClose.Click += new System.EventHandler(this.btnClose_Click);
            // 
            // lstFilter
            // 
            this.lstFilter.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.lstFilter.FormattingEnabled = true;
            this.lstFilter.Items.AddRange(new object[] {
            "$GPGGA,",
            "$GNGST,",
            "$GPZDA,",
            "$GNGSA,",
            "$GPGSV,",
            "$GLGSV,",
            "$GBDGSV,",
            "$PTNL,BPQ,",
            "$$"});
            this.lstFilter.Location = new System.Drawing.Point(617, 84);
            this.lstFilter.Name = "lstFilter";
            this.lstFilter.Size = new System.Drawing.Size(155, 212);
            this.lstFilter.TabIndex = 8;
            // 
            // label1
            // 
            this.label1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(619, 59);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(53, 12);
            this.label1.TabIndex = 9;
            this.label1.Text = "过滤项目";
            this.label1.DoubleClick += new System.EventHandler(this.label1_DoubleClick);
            // 
            // txtCOMDATA_01
            // 
            this.txtCOMDATA_01.Location = new System.Drawing.Point(12, 57);
            this.txtCOMDATA_01.Name = "txtCOMDATA_01";
            this.txtCOMDATA_01.Size = new System.Drawing.Size(427, 21);
            this.txtCOMDATA_01.TabIndex = 10;
            // 
            // SendCOM01
            // 
            this.SendCOM01.Location = new System.Drawing.Point(445, 55);
            this.SendCOM01.Name = "SendCOM01";
            this.SendCOM01.Size = new System.Drawing.Size(86, 23);
            this.SendCOM01.TabIndex = 11;
            this.SendCOM01.Text = "发送到端口1";
            this.SendCOM01.UseVisualStyleBackColor = true;
            this.SendCOM01.Click += new System.EventHandler(this.SendCOM01_Click);
            // 
            // btnSendCOM01Hex
            // 
            this.btnSendCOM01Hex.Location = new System.Drawing.Point(536, 55);
            this.btnSendCOM01Hex.Name = "btnSendCOM01Hex";
            this.btnSendCOM01Hex.Size = new System.Drawing.Size(75, 23);
            this.btnSendCOM01Hex.TabIndex = 12;
            this.btnSendCOM01Hex.Text = "Hex发送";
            this.btnSendCOM01Hex.UseVisualStyleBackColor = true;
            this.btnSendCOM01Hex.Click += new System.EventHandler(this.btnSendCOM01Hex_Click);
            // 
            // btnHexToString
            // 
            this.btnHexToString.Location = new System.Drawing.Point(445, 26);
            this.btnHexToString.Name = "btnHexToString";
            this.btnHexToString.Size = new System.Drawing.Size(86, 23);
            this.btnHexToString.TabIndex = 13;
            this.btnHexToString.Text = "HexToString";
            this.btnHexToString.UseVisualStyleBackColor = true;
            this.btnHexToString.Click += new System.EventHandler(this.btnHexToString_Click);
            // 
            // chkCOM02RecordToFile
            // 
            this.chkCOM02RecordToFile.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.chkCOM02RecordToFile.AutoSize = true;
            this.chkCOM02RecordToFile.Location = new System.Drawing.Point(244, 325);
            this.chkCOM02RecordToFile.Name = "chkCOM02RecordToFile";
            this.chkCOM02RecordToFile.Size = new System.Drawing.Size(132, 16);
            this.chkCOM02RecordToFile.TabIndex = 14;
            this.chkCOM02RecordToFile.Text = "接收数据记录到文件";
            this.chkCOM02RecordToFile.UseVisualStyleBackColor = true;
            this.chkCOM02RecordToFile.CheckedChanged += new System.EventHandler(this.chkCOM02RecordToFile_CheckedChanged);
            // 
            // frmMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(784, 526);
            this.Controls.Add(this.chkCOM02RecordToFile);
            this.Controls.Add(this.btnHexToString);
            this.Controls.Add(this.btnSendCOM01Hex);
            this.Controls.Add(this.SendCOM01);
            this.Controls.Add(this.txtCOMDATA_01);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.lstFilter);
            this.Controls.Add(this.btnClose);
            this.Controls.Add(this.button1);
            this.Controls.Add(this.btnOpenCOM2);
            this.Controls.Add(this.txtPort2);
            this.Controls.Add(this.cbbCOM02);
            this.Controls.Add(this.textBox1);
            this.Controls.Add(this.comboBox1);
            this.Controls.Add(this.btnOpenCOM1);
            this.Name = "frmMain";
            this.Text = "COM端口转发";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnOpenCOM1;
        private System.Windows.Forms.ComboBox comboBox1;
        private System.IO.Ports.SerialPort sPort01;
        private System.Windows.Forms.TextBox textBox1;
        private System.Windows.Forms.ComboBox cbbCOM02;
        private System.IO.Ports.SerialPort sPort02;
        private System.Windows.Forms.TextBox txtPort2;
        private System.Windows.Forms.Button btnOpenCOM2;
        private System.Windows.Forms.Button button1;
        private System.Windows.Forms.Button btnClose;
        private System.Windows.Forms.CheckedListBox lstFilter;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox txtCOMDATA_01;
        private System.Windows.Forms.Button SendCOM01;
        private System.Windows.Forms.Button btnSendCOM01Hex;
        private System.Windows.Forms.Button btnHexToString;
        private System.Windows.Forms.CheckBox chkCOM02RecordToFile;

    }
}

