SuperStrict

Module vertex.bnetex

ModuleInfo "Version: 1.80"
ModuleInfo "Author:  Oliver Skawronek"
ModuleInfo "License: GNU Lesser General Public License, Version 3"

Import "utils.bmx"
Import brl.stream
Import pub.stdc
?Win32
	Import "windows.c"
	Import "libiphlpapi.a"
?Linux
	Import "linux.c"
	Import "bsd.c"
?MacOS
	Import "bsd.c"
?

Private
Type TSockAddr
	Field SinFamily : Short
	Field SinPort   : Short
	Field SinAddr   : Int
	Field SinZero   : Long
End Type

Type TICMP
	Field _Type    : Byte
	Field Code     : Byte
	Field Checksum : Short
	Field ID       : Short
	Field Sequence : Short

	Function BuildChecksum:Short(buffer:Short Ptr, size:Int)
		Local checksum:Long

		While size > 1
			checksum :+ buffer[0]
			buffer :+ 1
			size :- 2
		Wend
		If size Then checksum :+ (Byte Ptr(buffer))[0]

		checksum = (checksum Shr 16) + (checksum & $FFFF)
		checksum :+ checksum Shr 16
		Return htons_(~checksum)
	End Function
End Type

Extern "OS"
	Const INVALID_SOCKET_ : Int = -1
	Const SOCK_RAW_       : Int = 3
	Const IPPROTO_ICMP    : Int = 1

	Const ICMP_ECHOREPLY   : Byte = 0
	Const ICMP_UNREACHABLE : Byte = 3
	Const ICMP_ECHO        : Byte = 8
	
	Const ICMP_CODE_NETWORK_UNREACHABLE : Byte = 0
	Const ICMP_CODE_HOST_UNREACHABLE    : Byte = 1
	
	?Win32
		Const FIONREAD      : Int   = $4004667F
		Const FIONBIO       : Int   = $8004667E 
		Const SOL_SOCKET_   : Int   = $FFFF
		Const SO_BROADCAST_ : Short = $20
		Const SO_SNDBUF_    : Short = $1001
		Const SO_RCVBUF_    : Short = $1002
		
		Const WSAEBASE       : Int = 10000
		Const WSAEWOULDBLOCK : Int = WSAEBASE + 35
	
	?MacOS
		Const FIONREAD      : Int   = $4004667F
		Const SOL_SOCKET_   : Int   = $FFFF
		Const SO_BROADCAST_ : Short = $20
		Const SO_SNDBUF_    : Short = $1001
		Const SO_RCVBUF_    : Short = $1002
	
	?Linux
		Const FIONREAD      : Int   = $0000541B
		Const SOL_SOCKET_   : Int   = 1
		Const SO_BROADCAST_ : Short = 6
		Const SO_SNDBUF_    : Short = 7
		Const SO_RCVBUF_    : Short = 8
	?
	
	?Win32
		Function ioctl_:Int(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctlsocket@12"
		Function inet_addr_:Int(Address$z) = "inet_addr@4"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa@4"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname@12"
		Function GetCurrentProcessId:Int() = "GetCurrentProcessId@0"
		
		Function WSAGetLastError:Int() = "WSAGetLastError@0"

	?Not Win32
		Function ioctl_(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctl"
		Function inet_addr_:Int(Address$z) = "inet_addr"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname"
		Function GetCurrentProcessId:Int() = "getpid"
	?
End Extern

Extern "C"
	?Linux
		Function selectex_:Int(ReadCount:Int, ReadSockets:Int Ptr, ..
		                       WriteCount:Int, WriteSockets:Int Ptr, ..
		                       ExceptCount:Int, ExceptSockets:Int Ptr, ..
		                       Milliseconds:Int) = "pselect_"
	?

	Function GetNetworkAdapter(Device:Byte Ptr, MAC:Byte Ptr, ..
	                           Address:Int Ptr, Netmask:Int Ptr, ..
	                           Broadcast:Int Ptr) = "GetNetworkAdapter"
End Extern

?Not Linux
	Global selectex_:Int(ReadCount:Int, ReadSockets:Int Ptr, ..
	                     WriteCount:Int, WriteSockets:Int Ptr, ..
	                     ExceptCount:Int, ExceptSockets:Int Ptr, ..
	                     Milliseconds:Int) = select_
?

Public
Type TAdapterInfo
	Field Device    : String
	Field MAC       : Byte[6]
	Field Address   : Int
	Field Broadcast : Int
	Field Netmask   : Int
End Type

Type TNetwork
	Function GetHostIP:Int(HostName:String)
		Return GetHostIPs(HostName)[0]
	End Function
	
	Function GetHostIPs:Int[](HostName:String)
		Local addresses     : Byte Ptr Ptr, ..
		      addressType   : Int, ..
		      addressLength : Int, ..
		      count         : Int, ..
		      ips           : Int[], ..
		      index         : Int, ..
		      pAddress      : Byte Ptr, ..
		      address       : Int
		
		addresses = gethostbyname_(HostName, addressType, addressLength)
		If (Not addresses) Or addressType <> AF_INET_ Or addressLength <> 4 Then Return Null
		
		count = 0
		While addresses[count]
			count :+ 1
		Wend
		
		ips = New Int[count]
		For index = 0 Until count
			pAddress = addresses[Index]
			address = (pAddress[0] Shl 24) ..
			          | (pAddress[1] Shl 16) ..
			          | (pAddress[2] Shl 8) ..
			          | pAddress[3]
			ips[Index] = address
		Next
		
		Return ips
	End Function
	
	Function GetHostName:String(HostIp:Int)
		Local address : Int, ..
		      name    : Byte Ptr
		
		address = htonl_(HostIp)
		name    = gethostbyaddr_(Varptr(address), 4, AF_INET_)
		
		If name Then
			Return String.FromCString(name)
		Else
			Return ""
		EndIf
	End Function
	
	Function StringIP:String(ip:Int)
		Return String.FromCString(inet_ntoa_(htonl_(ip)))
	End Function
	
	Function StringMAC:String(mac:Byte[])
		Local out     : String, ..
		      index   : Int, ..
		      nibble1 : Byte, ..
		      nibble2 : Byte
		
		For index = 0 To 5
			nibble1 = (mac[index] & $F0) Shr 4
			nibble2 = mac[index] & $0F
			
			If(nibble1 < 10)
				out :+ Chr(nibble1 + 48)
			Else
				out :+ Chr(nibble1 + 55)
			EndIf
			
			If(nibble2 < 10)
				out :+ Chr(nibble2 + 48)
			Else
				out :+ Chr(nibble2 + 55)
			EndIf
			
			out :+ "-"
		Next
		
		Return out[..out.Length - 1]
	End Function
	
	Function IntIP:Int(ip:String)
		Return htonl_(inet_addr_(ip))
	End Function
	
	Function Ping:Int(remoteIP:Int, data:Byte Ptr, size:Int, sequence:Int = 0, ..
	                  timeout:Int = 5000)
		Local socket     : Int, ..
		      processID  : Int, ..
		      icmp       : TICMP, ..
		      buffer     : Byte Ptr, ..
		      temp       : Int, ..
		      start      : Int, ..
		      stop       : Int, ..
		      result     : Int, ..
		      senderIP   : Int, ..
		      senderPort : Int, ..
		      ipSize     : Int
		
		socket = socket_(AF_INET_, SOCK_RAW_, IPPROTO_ICMP)
		If socket = INVALID_SOCKET_ Then Return -1
		
		processID = GetCurrentProcessID()
		
		icmp = New TICMP
		icmp._Type     = ICMP_ECHO
		icmp.Code      = 0
		icmp.Checksum  = 0
		icmp.ID        = processID
		icmp.Sequence  = sequence
		
		buffer = MemAlloc(65536)
		MemCopy(buffer, icmp, 8)
		MemCopy(buffer + 8, data, size)
		Short Ptr(buffer)[1] = htons_(TICMP.BuildChecksum(Short Ptr(buffer), 8 + size))
		
		temp = socket
		If (selectex_(0, Null, 1, Varptr(temp), 0, Null, 0) <> 1) Or ..
		   (sendto_(socket, buffer, 8 + size, 0, remoteIP, 0) = SOCKET_ERROR_) Then
			MemFree(buffer)
			closesocket_(socket)
			Return -1
		EndIf
		
		start = MilliSecs()
		Repeat
			temp = socket
			If selectex_(1, Varptr(temp), 0, Null, 0, Null, timeout) <> 1 Then
				MemFree(buffer)
				closesocket_(socket)
				Return -1
			EndIf
			
			result = recvfrom_(socket, buffer, 65536, 0, senderIP, senderPort)
			stop = MilliSecs()
			If result = SOCKET_ERROR_ Then
				MemFree(buffer)
				closesocket_(socket)
				Return -1
			EndIf
			
			?X86
				ipSize = (Buffer[0] & $0F)*4
			?PPC
				ipSize = (Buffer[0] & $F0)*4
			?
			MemCopy(icmp, buffer + ipSize, 8)
			
			If icmp.ID <> processID Then
				Continue
			ElseIf icmp._Type = ICMP_UNREACHABLE Then
				If icmp.Code = ICMP_CODE_HOST_UNREACHABLE Or ..
				   icmp.Code = ICMP_CODE_NETWORK_UNREACHABLE Then
					MemFree(buffer)
					closesocket_(socket)
					Return -1
				EndIf
			ElseIf icmp.Code = ICMP_ECHOREPLY Then
				Exit
			EndIf
		Forever
		
		MemFree(buffer)
		closesocket_(socket)
		
		Return stop - start
	End Function
	
	Function GetAdapterInfo:Int(info:TAdapterInfo Var)
		Local device : Byte Ptr
		
		If Not info Then info = New TAdapterInfo
		
		device = MemAlloc(256)
		If Not GetNetworkAdapter(device, info.MAC, Varptr(info.Address), ..
			Varptr(info.Netmask), Varptr(info.Broadcast)) Then Return False
		info.Device = String.FromCString(device)
		
		Return True
	End Function
End Type

Private
Const BUFFER_CAPACITY : Int = 16

Public
Type TNetStream Extends TStream
	Field socket       : Int
	Field recvBuffer   : Byte Ptr
	Field sendBuffer   : Byte Ptr
	Field recvCapacity : Int
	Field sendCapacity : Int
	Field recvSize     : Int
	Field sendSize     : Int
	Field recvPosition : Int
	Field sendPosition : Int
	
	Method New()
		socket       = INVALID_SOCKET_
		recvBuffer   = MemAlloc(BUFFER_CAPACITY)
		sendBuffer   = MemAlloc(BUFFER_CAPACITY)
		recvCapacity = BUFFER_CAPACITY
		sendCapacity = BUFFER_CAPACITY
		recvSize     = 0
		sendSize     = 0
		recvPosition = 0
		sendPosition = 0
	End Method

	Method Delete()
		Close()
		If Self.recvBuffer Then
			MemFree(Self.recvBuffer)
			Self.recvBuffer = Null
		EndIf
		If Self.sendBuffer Then
			MemFree(Self.sendBuffer)
			Self.sendBuffer = Null
		EndIf
		recvCapacity = 0
		sendCapacity = 0
		recvSize     = 0
		sendSize     = 0
		recvPosition = 0
		sendPosition = 0
	End Method
	
	Method Init:Int() Abstract
	Method RecvMsg:Int() Abstract
	Method SendMsg:Int() Abstract
	
	Method Read:Int(buffer:Byte Ptr, size:Int)
		Local newCapacity : Int
		
		If Not recvBuffer Then Return 0
		If size > recvSize Then size = recvSize
		
		newCapacity = recvCapacity
		While newCapacity > recvSize - size And ..
		      newCapacity > BUFFER_CAPACITY
		   newCapacity :Shr 1
		Wend
		If newCapacity < recvSize - size Then newCapacity :Shl 1
		
		MemCopy(buffer, recvBuffer + recvPosition, size)
		recvSize     :- size
		recvPosition :+ size
		
		If newCapacity <> recvCapacity Then
			Local temp : Byte Ptr
			
			temp = MemAlloc(newCapacity)
			MemCopy(temp, recvBuffer + recvPosition, recvSize)
			MemFree(recvBuffer)
			recvBuffer   = temp
			recvCapacity = newCapacity
			recvPosition = 0
		EndIf
		
		Return size
	End Method
	
	Method Write:Int(buffer:Byte Ptr, size:Int)
		Local newCapacity : Int
		
		newCapacity = sendCapacity
		While newCapacity < sendSize + size
			newCapacity :Shl 1
		Wend
		If newCapacity <> sendCapacity Then
			sendBuffer   = MemExtend(sendBuffer, sendCapacity, newCapacity)
			sendCapacity = newCapacity
		EndIf
		
		MemCopy(sendBuffer + sendPosition + sendSize, buffer, size)
		sendSize :+ size
		
		Return size
	End Method
	
	Method Eof:Int()
		Return Size() = 0
	End Method
	
	Method Size:Int()
		Return recvSize
	End Method
	
	Method Flush()
		If recvCapacity <> BUFFER_CAPACITY Then
			If recvBuffer Then MemFree(recvBuffer)
			recvBuffer   = MemAlloc(BUFFER_CAPACITY)
			recvCapacity = BUFFER_CAPACITY
		EndIf
		If sendCapacity <> BUFFER_CAPACITY Then
			If sendBuffer Then MemFree(sendBuffer)
			sendBuffer   = MemAlloc(BUFFER_CAPACITY)
			sendCapacity = BUFFER_CAPACITY
		EndIf
		recvSize     = 0
		sendSize     = 0
		recvPosition = 0
		sendPosition = 0
	End Method
	
	Method Close()
		If socket = INVALID_SOCKET_ Then Return
		
		shutdown_(socket, SD_BOTH)
		closesocket_(socket)
		socket = INVALID_SOCKET_
	End Method

	Method RecvAvail:Int()
		Local size : Int

		If socket = INVALID_SOCKET_ Then Return -1
		
		If ioctl_(socket, FIONREAD, Varptr(size)) = SOCKET_ERROR_ Then
			Return -1
		Else
			Return size
		EndIf
	End Method
End Type

Public
Type TUDPStream Extends TNetStream
	Field localIP     : Int
	Field localPort   : Short
	Field remotePort  : Short
	Field remoteIP    : Int
	Field messageIP   : Int
	Field messagePort : Short
	Field recvTimeout : Int
	Field sendTimeout : Int
	
	Method New()
		localPort   = 0
		localIP     = 0
		remotePort  = 0
		remoteIP    = 0
		messageIP   = 0
		messagePort = 0
		recvTimeout = 0
		sendTimeout = 0
	End Method

	Method Init:Int()
		Local size : Int

		socket = socket_(AF_INET_, SOCK_DGRAM_, 0)
		If socket = INVALID_SOCKET_ Then Return False

		' 2^16 - 1 Byte - 8 Byte UDP Overhead
		size = 1% Shl 16 - 9
		If setsockopt_(socket, SOL_SOCKET_, SO_RCVBUF_, Varptr(size), 4) = SOCKET_ERROR_ Or ..
		   setsockopt_(socket, SOL_SOCKET_, SO_SNDBUF_, Varptr(size), 4) = SOCKET_ERROR_ Then
			Close()
			Return False
		EndIf

		Return True
	End Method
	
	Method SetLocalPort:Int(port:Short = 0)
		Local address : TSockAddr, ..
		      length  : Int
		
		If socket = INVALID_SOCKET_ Then Return False

		If bind_(socket, AF_INET_, port) = SOCKET_ERROR_ Then
			Return False
		Else
			address = New TSockAddr
			length  = 16
			If getsockname_(socket, address, Varptr(length)) = SOCKET_ERROR_ Then
				Return False
			Else
				localIP   = ntohl_(address.SinAddr)
				localPort = ntohs_(address.SinPort)
				
				Return True
			EndIf
		EndIf
	End Method
	
	Method GetLocalPort:Short()
		Return localPort
	End Method
	
	Method GetLocalIP:Int()
		Return localIP
	End Method
	
	Method SetRemotePort(port:Short)
		remotePort = port
	End Method
	
	Method GetRemotePort:Short()
		Return remotePort
	End Method
	
	Method SetRemoteIP(ip:Int)
		remoteIP = ip
	End Method
	
	Method GetRemoteIP:Int()
		Return remoteIP
	End Method
	
	Method SetBroadcast:Int(enable:Int)
		If Self.Socket = INVALID_SOCKET_ Then Return False
		
		If enable Then enable = True
		If setsockopt_(socket, SOL_SOCKET_, SO_BROADCAST_, Varptr(enable), 4) ..
			= SOCKET_ERROR_ Then Return False
		
		Return True
	End Method
	
	Method GetBroadcast:Int()
		Local enable:Int, ..
		      size:Int
		
		If socket = INVALID_SOCKET_ Then Return False
		
		size = 4
		If getsockopt_(socket, SOL_SOCKET_, SO_BROADCAST_, Varptr(enable), ..
		               size)= SOCKET_ERROR_ Then Return -1
		
		Return enable
	End Method
	
	Method GetMsgPort:Short()
		Return messagePort
	End Method
	
	Method GetMsgIP:Int()
		Return messageIP
	End Method
	
	Method SetTimeouts(recvMillisecs:Int, sendMillisecs:Int)
		recvTimeout = recvMillisecs
		sendTimeout = sendMillisecs
	End Method
	
	Method GetRecvTimeout:Int()
		Return recvTimeout
	End Method
	
	Method GetSendTimeout:Int()
		Return sendTimeout
	End Method
	
	Method RecvMsg:Int()
		Local read        : Int, ..
		      size        : Int, ..
		      newCapacity : Int, ..
		      result      : Int, ..
		      ip          : Int, ..
		      port        : Int
	
		If socket = INVALID_SOCKET_ Or ..
		   (Not recvBuffer) Then Return 0
		
		read = socket
		If selectex_(1, Varptr(read), 0, Null, 0, Null, recvTimeout) <> 1 ..
		   Then Return 0
		
		If ioctl_(socket, FIONREAD, Varptr(size)) = SOCKET_ERROR_ ..
		   Then Return 0
	
		If size <= 0 Then Return 0
		
		newCapacity = recvCapacity
		While newCapacity < recvSize + size
			newCapacity :Shl 1
		Wend
		If newCapacity <> recvCapacity Then
			recvBuffer   = MemExtend(recvBuffer, recvCapacity, newCapacity)
			recvCapacity = newCapacity
		EndIf
		
		result = recvfrom_(socket, recvBuffer + recvPosition + recvSize, ..
		                   size, 0, ip, port)
		recvSize :+ result
			
		If result = SOCKET_ERROR_ Or result = 0 Then
			Return 0
		Else
			messageIP   = ip
			messagePort = Short(port)
			Return result
		EndIf
	End Method
	
	Method SendMsg:Int()
		Local write  : Int, ..
		      result : Int
		
		If socket = INVALID_SOCKET_ Or ..
		   sendSize = 0 Or ..
		   (Not sendBuffer) Then Return 0
			
		write = socket
		If selectex_(0, Null, 1, Varptr(write), 0, Null, sendTimeout) <> 1 ..
		   Then Return 0

		result = sendto_(socket, sendBuffer + sendPosition, sendSize, ..
		                 0, remoteIP, remotePort)
			
		If result = SOCKET_ERROR_ Or result = 0 Then
			Return 0
		Else
			Local newCapacity : Int
			
			newCapacity = sendCapacity
			While newCapacity > sendSize - result And ..
			      newCapacity > BUFFER_CAPACITY
			   newCapacity :Shr 1
			Wend
			If newCapacity < sendSize - result Then newCapacity :Shl 1
			
			sendSize     :- result
			sendPosition :+ result
			
			If newCapacity <> sendCapacity Then
				Local temp : Byte Ptr
				
				temp = MemAlloc(newCapacity)
				MemCopy(temp, sendBuffer + sendPosition, sendSize)
				MemFree(sendBuffer)
				sendBuffer   = temp
				sendCapacity = newCapacity
				sendPosition = 0
			EndIf
			
			Return result
		EndIf
	End Method
End Type

Type TTCPStream Extends TNetStream
	Field localIP       : Int
	Field localPort     : Short
	Field remoteIP      : Int
	Field remotePort    : Short
	Field recvTimeout   : Int
	Field sendTimeout   : Int
	Field acceptTimeout : Int
	
	Method New()
		localIP       = 0
		localPort     = 0
		remoteIP      = 0
		remotePort    = 0
		recvTimeout   = 0
		sendTimeout   = 0
		acceptTimeout = 0
	End Method
	
	Method Init:Int()
		Local size : Int
		
		socket = socket_(AF_INET_, SOCK_STREAM_, 0)
		If socket = INVALID_SOCKET_ Then Return False
		
		' 2^16 - 1 Byte
		Size = 1% Shl 16 - 1
		If setsockopt_(socket, SOL_SOCKET_, SO_RCVBUF_, Varptr(size), 4) = SOCKET_ERROR_ Or ..
		   setsockopt_(socket, SOL_SOCKET_, SO_SNDBUF_, Varptr(size), 4) = SOCKET_ERROR_ Then
			Close()
			Return False
		EndIf
		
		Return True
	End Method
	
	Method SetLocalPort:Int(port:Short = 0)
		Local address : TSockAddr, ..
		      length  : Int
		
		If socket = INVALID_SOCKET_ Then Return False

		If bind_(socket, AF_INET_, port) = SOCKET_ERROR_ Then
			Return False
		Else
			address = New TSockAddr
			length  = 16
			If getsockname_(socket, address, Varptr(length)) = SOCKET_ERROR_ Then
				Return False
			Else
				localIP   = ntohl_(address.SinAddr)
				localPort = ntohs_(address.SinPort)
				
				Return True
			EndIf
		EndIf
	End Method
	
	Method GetLocalPort:Short()
		Return localPort
	End Method
	
	Method GetLocalIP:Int()
		Return localIP
	End Method
	
	Method SetRemotePort(port:Short)
		remotePort = port
	End Method
	
	Method GetRemotePort:Short()
		Return remotePort
	End Method

	Method SetRemoteIP(ip:Int)
		remoteIP = ip
	End Method
	
	Method GetRemoteIP:Int()
		Return remoteIP
	End Method
	
	Method SetTimeouts(recvMillisecs:Int, sendMillisecs:Int, acceptMillisecs:Int=0)
		recvTimeout   = recvMillisecs
		sendTimeout   = sendMillisecs
		acceptTimeout = acceptMillisecs
	End Method
	
	Method GetRecvTimeout:Int()
		Return recvTimeout
	End Method
	
	Method GetSendTimeout:Int()
		Return sendTimeout
	End Method
	
	Method GetAcceptTimeout:Int()
		Return acceptTimeout
	End Method
	
	Method Connect:Int(timeout:Int=0)
		Local address:Int
		
		If socket = INVALID_SOCKET_ Then Return False
		
		address = htonl_(remoteIP)
		If timeout <> 0 Then
			?Win32
				Local option : Int, ..
				      write  : Int, ..
				      result : Int
				
				option = True
				ioctl_(socket, FIONBIO, Varptr(option))
				If connect_(socket, Varptr(address), AF_INET_, 4, remotePort) = SOCKET_ERROR_ Then
					If WSAGetLastError() <> WSAEWOULDBLOCK Then
						option = False
						ioctl_(socket, FIONBIO, Varptr(option))
						Return False
					EndIf
				EndIf

				write = socket
				result = selectex_(0, Null, 1, Varptr(write), 0, Null, timeout)
				
				option = False
				ioctl_(socket, FIONBIO, Varptr(option))
				
				Select result
					Case SOCKET_ERROR_
						Return False
					Case 0
						Return False
					Default
						Return True
				End Select
			?
			?NoWin32
			?
		Else
			If connect_(socket, Varptr(address), AF_INET_, 4, remotePort) ..
			   = SOCKET_ERROR_ Then
				Return False
			Else
				Return True
			EndIf
		EndIf
	End Method
	
	Method Listen:Int(maxClients:Int = 32)
		If socket = INVALID_SOCKET_ Then Return False
		
		If listen_(socket, maxClients) = SOCKET_ERROR_ Then
			Return False
		Else
			Return True
		EndIf
	End Method
	
	Method Accept:TTCPStream()
		Local read    : Int, ..
		      result  : Int, ..
		      address : TSockAddr, ..
		      addrLen : Int, ..
		      client  : TTCPStream
		
		If socket = INVALID_SOCKET_ Then Return Null
		
		read = Self.Socket
		If selectex_(1, Varptr(read), 0, Null, 0, Null, acceptTimeout) <> 1 ..
		   Then Return Null
		
		address = New TSockAddr
		addrLen = SizeOf(address)
		
		result = accept_(socket, address, Varptr(addrLen))
		If result = SOCKET_ERROR_ Then Return Null
		
		client = New TTCPStream
		client.socket    = Result
		client.localIP   = ntohl_(address.SinAddr)
		client.localPort = ntohs_(address.SinPort)
		
		addrLen = SizeOf(address)
		If getsockname_(client.Socket, address, Varptr(addrLen)) = SOCKET_ERROR_ Then
			client.Close()
			Return Null
		EndIf
		
		client.remoteIP   = ntohl_(address.SinAddr)
		client.remotePort = ntohs_(address.SinPort)
		
		Return client 
	End Method
	
	Method RecvMsg:Int()
		Local read        : Int, ..
		      size        : Int, ..
		      newCapacity : Int, ..
		      result      : Int
	
		If socket = INVALID_SOCKET_ Or ..
		   (Not recvBuffer) Then Return 0
		
		read = socket
		If selectex_(1, Varptr(read), 0, Null, 0, Null, recvTimeout) <> 1 ..
		   Then Return 0
		
		If ioctl_(socket, FIONREAD, Varptr(size)) = SOCKET_ERROR_ ..
		   Then Return 0
	
		If size <= 0 Then Return 0
		
		newCapacity = recvCapacity
		While newCapacity < recvSize + size
			newCapacity :Shl 1
		Wend
		If newCapacity <> recvCapacity Then
			recvBuffer   = MemExtend(recvBuffer, recvCapacity, newCapacity)
			recvCapacity = newCapacity
		EndIf
		
		result = recv_(socket, recvBuffer + recvPosition + recvSize, size, 0)
		recvSize :+ result
			
		If result = SOCKET_ERROR_ Or result = 0 Then
			Return 0
		Else
			Return result
		EndIf
	End Method
	
	Method SendMsg:Int()
		Local write  : Int, ..
		      result : Int
		
		If socket = INVALID_SOCKET_ Or ..
		   sendSize = 0 Or ..
		   (Not sendBuffer) Then Return 0
			
		write = socket
		If selectex_(0, Null, 1, Varptr(write), 0, Null, sendTimeout) <> 1 ..
		   Then Return 0

		result = send_(socket, sendBuffer + sendPosition, sendSize, 0)
			
		If result = SOCKET_ERROR_ Or result = 0 Then
			Return 0
		Else
			Local newCapacity : Int
			
			newCapacity = sendCapacity
			While newCapacity > sendSize - result And ..
			      newCapacity > BUFFER_CAPACITY
			   newCapacity :Shr 1
			Wend
			If newCapacity < sendSize - result Then newCapacity :Shl 1
			
			sendSize     :- result
			sendPosition :+ result
			
			If newCapacity <> sendCapacity Then
				Local temp : Byte Ptr
				
				temp = MemAlloc(newCapacity)
				MemCopy(temp, sendBuffer + sendPosition, sendSize)
				MemFree(sendBuffer)
				sendBuffer   = temp
				sendCapacity = newCapacity
				sendPosition = 0
			EndIf
			
			Return result
		EndIf
	End Method
	
	Method GetState:Int()
		Local read   : Int, ..
		      result : Int, ..
		      size   : Int

		If socket = INVALID_SOCKET_ Then Return -1

		read   = Self.Socket
		result = selectex_(1, Varptr(read), 0, Null, 0, Null, 0)

		If result = SOCKET_ERROR_ Then
			Close()
			Return -1
		ElseIf Result = 1
			size = RecvAvail()
			If size = SOCKET_ERROR_ Then
				Close()
				Return -1
			ElseIf Size = 0 Then
				Close()
				Return 0
			Else
				Return 1
			EndIf
		Else
			Return 1
		EndIf
	End Method
End Type
