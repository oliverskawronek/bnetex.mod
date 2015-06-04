SuperStrict

Framework brl.blitz
Import vertex.bnetex

Const LISTEN_PORT : Short = 1234

Global Stream : TUDPStream

' Please run udp_sender after
Try

Stream = New TUDPStream
If Not Stream.Init() Then Throw("Can't create socket")
Stream.SetLocalPort(LISTEN_PORT)

WriteStdout("UDP Receiver listining on port " + LISTEN_PORT + "~n")

Repeat
	If Stream.RecvAvail() Then
		While Stream.RecvMsg() ; Wend

		If Stream.Size() > 0 Then
			WriteStdout("Message from:~n" + ..
			            " - IP = " + TNetwork.StringIP(Stream.GetMsgIP()) + "~n" + ..
			            " - Port = " + Stream.GetMsgPort() + "~n")
	
			While Not Stream.Eof()
				WriteStdout(">" + Stream.ReadLine() + "~n")
			Wend
		EndIf
	EndIf
Forever

Catch Exception:Object
	WriteStdout("Error~n " + Exception.ToString())
End Try

If Stream Then Stream.Close()
WriteStdout("~n- ready -~n")
End