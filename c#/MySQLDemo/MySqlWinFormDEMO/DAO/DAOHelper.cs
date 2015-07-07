using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MySqlWinFormDEMO.DAO
{
    public static class DAOHelper
    {
        public static MySqlConnection GetConnection()
        {            
            string connStr = "server=localhost;user id=root;password=;database=mysql"; //根据自己的设置
            MySqlConnection rvalue = new MySqlConnection(connStr);
            return rvalue;
        }

        public static DataSet Query(string sql, MySqlConnection conn)
        {
            DataSet rvalue = new DataSet();
            MySqlDataAdapter adapter = new MySqlDataAdapter(sql, conn);
            adapter.Fill(rvalue);
            return rvalue;
        }

        public static IDataReader QueryReader(string sql, MySqlConnection conn)
        {
            MySqlCommand cmd = new MySqlCommand(sql, conn);
            return cmd.ExecuteReader();
        }

        public static int ExecuteSQL(string sql, MySqlConnection conn)
        {
            MySqlCommand cmd = new MySqlCommand(sql, conn);
            return cmd.ExecuteNonQuery();
        }
    }
}
