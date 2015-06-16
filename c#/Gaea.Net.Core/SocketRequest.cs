using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

namespace Gaea.Net.Core
{
    public class SocketRequest
    {
        private SocketAsyncEventArgs socketEventArg = new SocketAsyncEventArgs();

        public SocketAsyncEventArgs SocketEventArg { get { return socketEventArg; } }


        public SocketRequest()
        {
            socketEventArg.UserToken = this;
            SocketEventArg.Completed += new EventHandler<SocketAsyncEventArgs>(SocketEventArg_Completed);
        }


        public void SocketEventArg_Completed(object sender, SocketAsyncEventArgs e)
        {
            DoResponse();
        }
        
        public virtual void DoResponse()
        {

        }       
    }

}
