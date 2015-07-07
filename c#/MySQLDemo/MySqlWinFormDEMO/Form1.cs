using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MySqlWinFormDEMO
{
    public partial class Form1 : Form
    {
        private MySqlConnection conn = DAO.DAOHelper.GetConnection();

        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            string s = textBox1.Text;
            try
            {
                DataSet ds = DAO.DAOHelper.Query(s, conn);
                this.dataGridView1.DataSource = ds.Tables[0];
            }catch(Exception ex)
            {
                MessageBox.Show(ex.Message, "异常", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            this.dataGridView2.DataSource = dataGridView1.DataSource;
        }
    }
}
