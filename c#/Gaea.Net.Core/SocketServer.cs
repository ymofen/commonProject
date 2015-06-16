using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Gaea.Net.Core
{
    public class SocketServer
    {
        Hashtable onlineMap = new Hashtable();

        public void AddContext(SocketContext context)
        {
            context.OwnerServer = this;
            lock (onlineMap)
            {
                onlineMap.Add(context.RawSocket.Handle, context);
            }
        }

        public void RemoveContext(SocketContext context)
        {
            lock (onlineMap)
            {
                onlineMap.Remove(context.RawSocket.Handle);
            }
        }
    }
}
