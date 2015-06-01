using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO.Ports;
using System.IO;
using System.Globalization;

namespace COMProxy
{
    public partial class frmMain : Form
    {
        delegate void ThreadWork(String s);

        
        ///  端口1收到的数据 
        private MemoryStream data1 = new MemoryStream();

        
        ///  端口2收到的数据         
        private MemoryStream data2 = new MemoryStream();

        /// <summary>
        ///  读取到的数据记录到COM
        /// </summary>
        private bool bCOM02Record2File = false;

        public frmMain()
        {
            InitializeComponent();
        }

        public void AppendBuffer(Stream streamData, byte[] buf, int len)
        {
            long prePosition = streamData.Position;
            streamData.Seek(0, SeekOrigin.End);
            streamData.Write(buf, 0, len);
            streamData.Position = prePosition;
        }

        /// <summary>
        ///   清理当前位置之前的buffer数据
        /// </summary>
        /// <param name="streamData"></param>
        public void ClearReadBuffer(Stream streamData)
        {
            byte[] buf = new byte[streamData.Length - streamData.Position];
            streamData.Read(buf, 0, buf.Length);
            streamData.SetLength(0);
            streamData.Write(buf, 0, buf.Length);
            streamData.Position = 0;
        }

        public String ReadStringFromStream(Stream streamData)
        {
            StringBuilder sb = new StringBuilder();

            byte b = 0;
            byte CRCount = 0;  // 13 计数 \r
            byte LFCount = 0;  // 10 计数 \b

            long prePosition = streamData.Position;

            while (streamData.Position < streamData.Length)
            {
                b = (byte)streamData.ReadByte();

                if (b == 10)
                {
                    LFCount++;
                    sb.Append((char)b);
                    if (CRCount == 1) break;
                }
                else if (b == 13)
                {
                    sb.Append((char)b);
                    CRCount++;                    
                }
                else
                {
                    CRCount = 0;
                    LFCount = 0;
                    sb.Append((char)b);
                }
            }

            if (LFCount >= 1 && CRCount >= 1)
            {  // 读取完成
                return sb.ToString();
            }
            else
            {
                // 没有完整的字符串
                streamData.Position = prePosition;
                return null;
            }
        }

        

        private void Form1_Load(object sender, EventArgs e)
        {
            comboBox1.Items.Clear();
            cbbCOM02.Items.Clear();
            String[] Portname = SerialPort.GetPortNames();
         

          //create a loop for each string in SerialPort.GetPortNames
           foreach (string str in Portname)
           {
             comboBox1.Items.Add(str);
             cbbCOM02.Items.Add(str);
           }
        }

        private bool CheckIsFilter(String s)
        {
            for (int i = 0; i < lstFilter.CheckedItems.Count; i++)
            {
                if (s.IndexOf(lstFilter.CheckedItems[i].ToString()) != -1)
                {
                    return true;
                }
            }
            return false;
        }

        public static String BytesAsHexString(byte[] bytes)
        {
            StringBuilder sb = new StringBuilder();
            foreach (byte b in bytes)
            {
                sb.Append(String.Format("{0:X2} ", b));
            }
            return sb.ToString();
        }

        public static byte[] HexStringToBytes(String s)
        {
            
            MemoryStream ms = new MemoryStream();
            s = s.Replace(" ", "");
            byte[] sbuf = System.Text.ASCIIEncoding.ASCII.GetBytes(s);
            String hex = "";
            for (int i = 0; i<= sbuf.Length-1; i++)
            {                
                hex = hex + (char)sbuf[i];
                if (hex.Length == 2)
                {
                    ms.WriteByte(Byte.Parse(hex, NumberStyles.HexNumber));
                    hex = "";
                }
            }

            byte[] rbuf = new byte[ms.Length];
            ms.Position = 0;
            ms.Read(rbuf, 0, (int)rbuf.Length);
            return rbuf;

        }

        private void showCOM01DataRecv(String s)
        {
            if (s.Length == 0) { return; }
            if (!CheckIsFilter(s))
            {
                textBox1.Text += System.DateTime.Now.ToString() + ":" +  s.ToString();
                textBox1.Select(textBox1.Text.Length, 0);
                textBox1.ScrollToCaret();
            }
        }

        private void showCOM02DataRecv(String s)
        {
            txtPort2.Text += s.ToString();
            txtPort2.Text += s.ToString();
            txtPort2.Select(txtPort2.Text.Length, 0);
            txtPort2.ScrollToCaret();
        }

        private void sPort01_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            byte[] recvBuf = new byte[1024];
            int l = 0;

            while (sPort01.BytesToRead > 0)
            {
                l = sPort01.Read(recvBuf, 0, 1024);
                if (l > 0)
                {
                    AppendBuffer(data1, recvBuf, l);
                }
            }

            while (true)
            {
                String s = ReadStringFromStream(data1);

                if (s == null) break;

                if (this.InvokeRequired)
                {
                    ThreadWork fc = new ThreadWork(showCOM01DataRecv);
                    this.Invoke(fc, s);
                }
                else
                {
                    showCOM01DataRecv(s);
                }

                lock (sPort02)
                {
                    if (sPort02.IsOpen)
                    {
                        sPort02.Write(s);
                    }
                }           
            }

            ClearReadBuffer(data1);

            
        }

        private void button1_Click(object sender, EventArgs e)
        {
            try
            {
                sPort01.BaudRate = 9600;
                sPort01.PortName = comboBox1.Text;
                sPort01.StopBits = StopBits.One;
                sPort01.DataBits = 8;
                sPort01.Parity = System.IO.Ports.Parity.None;
                sPort01.Open();
            }catch(Exception E)
            {
                MessageBox.Show(E.Message);
            }
            
        }

        private void sPort02_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {

            byte[] recvBuf = new byte[1024];
            int l = 0;

            FileStream fWrite = null;

            if (bCOM02Record2File)
            {
                String sFile = this.GetType().Assembly.Location;
                sFile = System.IO.Path.GetFullPath(sFile) + "COM_01.DAT";

                fWrite = new FileStream(sFile, FileMode.Append);
            }
            
            while (sPort02.BytesToRead > 0)
            {
                l = sPort02.Read(recvBuf, 0, 1024);
                if (l > 0)
                {
                    AppendBuffer(data2, recvBuf, l);
                    if (fWrite!=null)
                    {
                        fWrite.Write(recvBuf, 0, l);
                    }
                }
            }

            if (fWrite != null)
            {
                fWrite.Close();
            }

            

            

            while (true)
            {
                String s = ReadStringFromStream(data2);

                if (s == null) break;

                if (this.InvokeRequired)
                {
                    ThreadWork fc = new ThreadWork(showCOM02DataRecv);
                    this.Invoke(fc, s);
                }
                else
                {
                    showCOM02DataRecv(s);
                }

                lock (sPort01)
                {
                    if (sPort01.IsOpen)
                    {
                        sPort01.Write(s);
                    }
                }
            }

            ClearReadBuffer(data2);

            //MemoryStream ms = new MemoryStream();
            //byte b = 0;

            //while (sPort02.BytesToRead > 0)
            //{
            //    b = (byte)sPort02.ReadByte();
            //    ms.WriteByte(b);
            //}

            //if (ms.Length > 0)
            //{
            //    ms.Position = 0;
            //    byte[] buf = new byte[ms.Length];
            //    ms.Read(buf, 0, buf.Length);

            //    lock (sPort01)
            //    {
            //        if (sPort01.IsOpen)
            //        {
            //            sPort01.Write(buf, 0, buf.Length);
            //        }
            //    }


            //    String s = System.Text.Encoding.Default.GetString(buf);

            //    if (this.InvokeRequired)
            //    {
            //        ThreadWork fc = new ThreadWork(showCOM02DataRecv);
            //        this.Invoke(fc, s);
            //    }
            //    else
            //    {
            //        showCOM02DataRecv(s);
            //    }
            //}
        }

        private void btnOpenCOM2_Click(object sender, EventArgs e)
        {
            sPort02.BaudRate = 9600;
            sPort02.PortName = cbbCOM02.Text;
            sPort02.StopBits = StopBits.One;
            sPort02.DataBits = 8;
            sPort02.Parity = System.IO.Ports.Parity.None;
            sPort02.Open();
        }

        private void button1_Click_1(object sender, EventArgs e)
        {
            String hex = "10";


            byte b = Byte.Parse(hex, NumberStyles.HexNumber);

            MessageBox.Show(b.ToString());

            //MemoryStream ms = new MemoryStream();
            //byte[] buf = new byte[1024];
            //buf[0] = (byte)'a';
            //buf[1] = (byte)'b';
            //buf[2] = (byte)'c';

            //AppendBuffer(ms, buf, 3);
            //byte b =(byte)ms.ReadByte();
            //ClearReadBuffer(ms);

            //ms.Read(buf, 0, 1024);

            //buf[0] = 0;




        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            sPort01.Close();
            sPort02.Close();
        }

        private void SendCOM01_Click(object sender, EventArgs e)
        {
            String s = txtCOMDATA_01.Text + (char)13 + (char)10;
            lock (sPort01)
            {
                if (sPort01.IsOpen)
                {
                    sPort01.Write(s);
                }
            }
        }

        private void btnSendCOM01Hex_Click(object sender, EventArgs e)
        {
            String s = txtCOMDATA_01.Text;
            byte[] sBuf = HexStringToBytes(s);
            lock (sPort01)
            {
                if (sPort01.IsOpen)
                {
                    sPort01.Write(sBuf, 0, sBuf.Length);
                }
            }
        }

        private void btnHexToString_Click(object sender, EventArgs e)
        {
            String s = txtCOMDATA_01.Text;
            byte[] sBuf = HexStringToBytes(s);

            s = System.Text.ASCIIEncoding.ASCII.GetString(sBuf);
            showCOM01DataRecv(s);
        }

        private void chkCOM02RecordToFile_CheckedChanged(object sender, EventArgs e)
        {
            bCOM02Record2File = chkCOM02RecordToFile.Checked;
        }

        private void label1_DoubleClick(object sender, EventArgs e)
        {
            for (int i = 0; i < lstFilter.CheckedItems.Count; i++)
            {
                lstFilter.SetItemChecked(i, true);
            }
        }
    }
}
