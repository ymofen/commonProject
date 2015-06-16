using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Gaea.Net.Core
{
    public class GaeaTcpServer:SocketServer
    {
        TcpListener defaultListener = null;

        public GaeaTcpServer():base()
        {
            defaultListener = new TcpListener();
            defaultListener.TcpServer = this;
            defaultListener.RegisterContextClass(typeof(SocketContext));
        }



        public void Open()
        {
            defaultListener.Start();
            defaultListener.CheckPostRequest();
            
        }

        public int DefaultPort { 
            set
            {
                defaultListener.Port = value;
            }
            get
            {
                return defaultListener.Port;
            }
        }

        public TcpListener DefaultListener { get { return defaultListener; } }



    }
}
