SuperStrict

Framework brl.blitz
Import vertex.bnetex

Const REMOTE_PORT : Short = 1234

Global Stream : TUDPStream

Try

Stream = New TUDPStream
If Not Stream.Init() Then Throw("Can't create socket")
Stream.SetRemoteIP(TNetwork.IntIP("127.0.0.1"))
Stream.SetLocalPort()
Stream.SetRemotePort(REMOTE_PORT)

Stream.WriteLine("Hello World!")
WriteStdout(Stream.SendMsg() + " Bytes sended~n")

Catch Exception:Object
	WriteStdout("Error~n " + Exception.ToString())
End Try

If Stream Then Stream.Close()
WriteStdout("~n- ready -~n")
End