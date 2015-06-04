SuperStrict

Framework brl.blitz
Import vertex.bnetex

Const HOST : String = "www.google.com"

Global IPs : Int[], ..
       IP  : Int

WriteStdout("Host: " + HOST + "~n")
IPs = TNetwork.GetHostIPs(HOST)
WriteStdout("Found " + IPs.Length + " ip address(es)~n")
For IP = EachIn IPs
	WriteStdout(" - " + Tnetwork.StringIP(IP) + "~n")
Next

WriteStdout("~n- ready -~n")
End