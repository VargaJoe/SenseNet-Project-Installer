using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
public sealed class PlotHttpFixture : IDisposable {
    readonly TcpListener listener;
    readonly Thread thread;
    volatile bool stopped;
    int retries;
    public int Requests;
    public int Port { get; private set; }
    public PlotHttpFixture() {
        listener = new TcpListener(IPAddress.Loopback, 0); listener.Start();
        Port=((IPEndPoint)listener.LocalEndpoint).Port;
        thread=new Thread(Loop); thread.IsBackground=true; thread.Start();
    }
    void Loop() {
        while(!stopped) {
            try { var client=listener.AcceptTcpClient(); ThreadPool.QueueUserWorkItem(Respond, client); }
            catch(SocketException) { if(!stopped) throw; }
        }
    }
    void Respond(object state) {
        using(var client=(TcpClient)state) {
            client.ReceiveTimeout=2000; client.SendTimeout=2000;
            try {
                var stream=client.GetStream();
                var reader=new StreamReader(stream, Encoding.ASCII, false, 1024, true);
                string line=reader.ReadLine(); if(line==null) return;
                Interlocked.Increment(ref Requests);
                string path=line.Split(' ')[1];
                bool authorized=false;
                while(!String.IsNullOrEmpty(line=reader.ReadLine())) if(line=="X-Test-Key: local-secret") authorized=true;
                if(path=="/slow") Thread.Sleep(6000);
                int code=200;
                string body="abc";
                string extra="";
                if(path=="/fail" || (path=="/retry" && Interlocked.Increment(ref retries)<3)) code=503;
                if(path=="/auth" && !authorized) code=401;
                if(path=="/redirect") { code=302; extra="Location: /ok\r\n"; }
                var bytes=Encoding.UTF8.GetBytes(body);
                string headers="HTTP/1.1 "+code+" Test\r\nConnection: close\r\n"+extra;
                if(path!="/stream") headers+="Content-Length: "+bytes.Length+"\r\n";
                var header=Encoding.ASCII.GetBytes(headers+"\r\n"); stream.Write(header,0,header.Length);
                if(path=="/slowbody") Thread.Sleep(6000);
                stream.Write(bytes,0,bytes.Length); stream.Flush();
            } catch(IOException) {} catch(ObjectDisposedException) {}
        }
    }
    public void Dispose() { stopped=true; listener.Stop(); thread.Join(3000); }
}
