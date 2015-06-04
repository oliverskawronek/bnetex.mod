SuperStrict

Framework brl.blitz
Import vertex.bnetex

Global Info:TAdapterInfo

If Not TNetwork.GetAdapterInfo(Info) Then
	WriteStdout("Faield to get network adapter information.~n" + ..
	            " Maybe there is no network adapter or~n" + ..
	            " no network driver installed.")
	End
EndIf

WriteStdout("Device: " + Info.Device + "~n" + ..
            " MAC Address:       " + TNetwork.StringMAC(Info.MAC) + "~n" + ..
            " IP Address:        " + TNetwork.StringIP(Info.Address) + "~n" + ..
            " Broadcast Address: " + TNetwork.StringIP(Info.Broadcast) + "~n" + ..
            " Netmask:           " + Tnetwork.StringIP(Info.Netmask) + "~n")
End