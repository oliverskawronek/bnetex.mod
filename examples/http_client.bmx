SuperStrict

Framework brl.blitz
Import vertex.bnetex

Const HOST    : String = "www.google.de"
Const PATH    : String = "/"
Const TIMEOUT : Int    = 5000 ' in ms

Global IP     : Int, ..
       Client : TTCPStream, ..
       Start  : Int

Try

IP = TNetwork.GetHostIP(HOST)
If Not IP Then Throw("Host not found")

Client = New TTCPStream
If Not Client.Init() Then Throw("Can't create socket")
Client.SetTimeouts(TIMEOUT, TIMEOUT)
If Not Client.SetLocalPort() Then Throw("Can't set local port")
Client.SetRemoteIP(IP)
Client.SetRemotePort(80)
If Not Client.Connect() Then Throw("Can't connect to host")

Client.WriteLine("GET " + PATH + " HTTP/1.0")
Client.WriteLine("Host: " + HOST)
Client.WriteLine("User-Agent: BNetEx Client")
Client.WriteLine("Accept: application/xhtml+xml,text/html")
Client.WriteLine("Connection: close")
Client.WriteLine("")
While Client.SendMsg() ; Wend

Start = MilliSecs()
Repeat
	Local Result:Int

	If MilliSecs() - Start > TIMEOUT Then Throw("Timeout")

	Result = Client.RecvAvail()
	If Result = -1 Then
		Throw("Socket Error")
	ElseIf Result > 0 Then
		Exit
	EndIf
Forever

While Client.RecvMsg() ; Wend

While Not Client.Eof()
	WriteStdout(Client.ReadLine() + "~n")
Wend

Catch Exception:Object
	WriteStdout("Error:~n " + Exception.ToString())
End Try

If Client Then Client.Close()
WriteStdout("~n- ready -~n")
End