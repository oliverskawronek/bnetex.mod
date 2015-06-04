SuperStrict

Framework Vertex.BNetEx

Import Brl.LinkedList

Global Server  : TTCPStream, ..
       Clients : TList, ..
       Client  : TTCPStream

Try

Server = New TTCPStream
If Not Server.Init() Then Throw("Can't create socket")
If Not Server.SetLocalPort(80) Then Throw("Can't set local port")
If Not Server.Listen() Then Throw("Can't set to listen")

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
				While Not Client.EoF()
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