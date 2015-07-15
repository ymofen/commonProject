using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace DLLInvokeDEMO
{
    public class GNSSLibrary
    {
        /// <summary>
        ///  void indoor_navigation(char *se, char *res, int *resultlen);
        ///  procedure indoor_navigation(se:PAnsiChar; res:PAnsiChar;resultlen:PInteger); stdcall; external DLL_FILE;
        /// </summary>
        /// <param name="se"></param>
        /// <param name="res"></param>
        /// <param name="resLen"></param>
        [DllImport("IndoorNavigation.dll", CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Ansi)]
        public extern static void indoor_navigation(string se, IntPtr res, IntPtr resLen);
        

        public static string DoInvoke(string se)
        {
            int resLen = 2048;
            IntPtr pres = Marshal.AllocHGlobal(2048);
            IntPtr presLen = Marshal.AllocHGlobal(4);
            byte[] reslenBytes = BitConverter.GetBytes(resLen);
            Marshal.Copy(reslenBytes, 0, presLen, 4);


            indoor_navigation(se, pres, presLen);

            Marshal.Copy(presLen, reslenBytes, 0, 4);
            resLen = BitConverter.ToInt32(reslenBytes, 0);

            byte[] resBytes = new byte[resLen];
            Marshal.Copy(pres, resBytes, 0, resLen);

            Marshal.FreeHGlobal(pres);
            Marshal.FreeHGlobal(presLen);

            return Encoding.Default.GetString(resBytes);


        }
    }
}
