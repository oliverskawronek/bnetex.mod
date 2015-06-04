SuperStrict

Framework brl.blitz
Import vertex.bnetex
Import brl.linkedlist

Const HTTP_PORT : Short = 80

Global Server  : TTCPStream, ..
       Clients : TList, ..
       Client  : TTCPStream


' Type 127.0.0.1 in your browser
Try

Server = New TTCPStream
If Not Server.Init() Then Throw("Can't create socket")
If Not Server.SetLocalPort(HTTP_PORT) Then Throw("Can't set local port")
If Not Server.Listen() Then Throw("Can't set to listen")

WriteStdout("HTTP Server started successfully on port " + HTTP_PORT + "~n")

Clients = New TList

Repeat
	Client = Server.Accept()

	If Client Then
		WriteStdout("New Client:~n" + ..
		            " - IP:" + TNetwork.StringIP(Client.GetLocalIP()) + "~n" + ..
		            " - Port:" + Client.GetLocalPort() + "~n")
		Clients.AddLast(Client)
	EndIf

	For Client = EachIn Clients
		If Client.GetState() <> 1 Then
		WriteStdout("Client disconnected:~n" + ..
		            " - IP:" + TNetwork.StringIP(Client.GetLocalIP()) + "~n" + ..
		            " - Port:" + Client.GetLocalPort() + "~n")
			Client.Close()
			Clients.Remove(Client)
			Continue
		EndIf

		If Client.RecvAvail() Then
			While Client.RecvMsg() ; Wend

			If Client.Size() > 0 Then
				WriteStdout("Message from client:~n" + ..
				            " - IP:" + TNetwork.StringIP(Client.GetLocalIP()) + "~n" + ..
				            " - Port:" + Client.GetLocalPort() + "~n")
				While Not Client.Eof()
					WriteStdout(">"+Client.ReadLine() + "~n")
				Wend

				Client.WriteLine("OK")
				While Client.SendMsg() ; Wend
			EndIf
		EndIf
	Next
Forever

Catch Exception:Object
	WriteStdout("Error~n " + Exception.ToString())
End Try

If Server Then Server.Close()
WriteStdout("~n- ready -~n")
End