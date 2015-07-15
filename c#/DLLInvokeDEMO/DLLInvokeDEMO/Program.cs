using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DLLInvokeDEMO
{
    class Program
    {
        static void Main(string[] args)
        {
            string value = GNSSLibrary.DoInvoke("gps,001,001");
            Console.WriteLine(value);
            Console.ReadLine();
        }
    }
}
