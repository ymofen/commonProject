using MySql.Data.MySqlClient;
using MySQLDemo.DAO;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MySQLDemo
{
    public class Class1
    {

        static void Main(string[] args)
        {
            MySqlConnection conn = DAOHelper.GetConnection();
            IDataReader reader = DAOHelper.QueryReader("SELECT * FROM user", conn);
            while (reader.Read())
            {
                Console.WriteLine(reader["Host"]);	// 打印出每个用户的用户名
            }

            //DataTable table = ds.Tables[0];            
            //string user = table.Columns["User"].ToString();
            //Console.WriteLine("abcd");
            Console.ReadLine();
        }
    }
}
