using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

namespace Gaea.Net.Core
{


    public class AcceptRequest : SocketRequest
    {
        public override void DoResponse()
        {
            base.DoResponse();
            Owner.DoAfterAccept(this);
        }
        public TcpListener Owner { set; get; }
    }


    public class TcpListener
    {
        private Socket socket = null;


        Type socketContextClassType = null;

        public SocketContext GetSocketContext()
        {
            SocketContext context = (SocketContext)System.Activator.CreateInstance(socketContextClassType);            
            return context;
        }

        public void RegisterContextClass(Type classType)
        {
            socketContextClassType = classType;
        }


        private AcceptRequest GetAcceptRequest()
        {
            AcceptRequest req = new AcceptRequest();
            req.Owner = this;
            return req;
        }

        private void ReleaseAcceptRequest(AcceptRequest req)
        {
            req.Owner = null;
            return;
        }  


        public void CheckPostRequest()
        {
            AcceptRequest req = GetAcceptRequest();
            PostAcceptRequest(req);
        }


        public void DoAfterAccept(AcceptRequest req)
        {
            SocketContext context = GetSocketContext();
            context.RawSocket = req.SocketEventArg.AcceptSocket;
            TcpServer.AddContext(context);
            context.DoAfterAccept();
            context.PostReceiveRequest();

            // 投递另外的接收请求
            CheckPostRequest();
        }
        

        /// <summary>
        ///   开始侦听
        /// </summary>
        /// <param name="localEndPoint"></param>
        public void Start(IPEndPoint localEndPoint)
        {
            socket = new Socket(localEndPoint.AddressFamily, SocketType.Stream, ProtocolType.Tcp);
            socket.Bind(localEndPoint);
            socket.Listen(0);

            Debug.WriteLine(String.Format("服务已经开启,侦听端口:{0}", localEndPoint.Port));
        }

        public void Start(int port)
        {
            IPEndPoint ip = new IPEndPoint(IPAddress.Any, port);
            Start(ip);
        }

        public void Start()
        {
            Start(Port);
        }

        private void PostAcceptRequest(SocketRequest request)
        {
            request.SocketEventArg.AcceptSocket = null;
            bool iodepending = socket.AcceptAsync(request.SocketEventArg);
            if (!iodepending)
            {   // returns false if the I/O operation completed synchronously
                request.DoResponse();
            }
        }

        public GaeaTcpServer TcpServer { set; get; }


        public int Port { get; set; }

    }
}
