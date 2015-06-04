SuperStrict

Framework brl.blitz
Import vertex.bnetex

Global RemoteIP : Int, ..
       Message  : String, ..
       Data     : Byte Ptr, ..
       Result   : Int

RemoteIP = TNetwork.GetHostIP("google.com")
If Not RemoteIP Then
	WriteStdout("Host not found~n")
	End
EndIf

Message = "Hello, world!"
Data = Message.ToCString()

Result = TNetwork.Ping(RemoteIP, Data, Message.Length)

If Result = -1 Then
	WriteStdout("Ping failed~n" + ..
	            " Maybe you have to run it with administrator rights,~n" + ..
	            " the network/host is unreachable or~n" + ..
	            " timeout has exceeded.")
	MemFree(Data)
	End
EndIf

WriteStdout("Ping tooks " + Result + "ms~n")
MemFree(Data)
End