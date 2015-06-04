SuperStrict

Import brl.blitz
import brl.stream
import brl.random

Public

Type CRC16
	Const CCITT : Short = $8408, ..
	      IBM   : Short = $A001
	
	Global table : Short[256]
	
	Function Init(polynomial:Short = IBM)
		Local i     : Int, ..
		      j     : Int, ..
		      value : Short, ..
		      temp  : Short
		
		For i = 0 To 255
			value = 0
			temp  = i
			For j = 0 To 7
				If ((value ~ temp) & $0001) <> 0 Then
					value = (value Shr 1) ~ polynomial
				Else
					value :Shr 1
				EndIf
				temp :Shr 1
			Next
			table[i] = value
		Next
	End Function
	
	Function FromString:Short(value:String)
		Local crc   : Short, ..
		      i     : Int
		
		crc = $FFFF
		For i = 0 Until value.Length
			crc = (crc Shr 8) ~ table[(crc ~ value[i]) & $FF]
		Next
		
		Return crc
	End Function
	
	Function FromBuffer:Short(buffer:Byte Ptr, length:Int)
		Local crc   : Short, ..
		      i     : Int
		
		If (Not buffer) Or length < 0 Then Throw("failed")
		
		crc = $FFFF
		While length > 0
			crc = (crc Shr 8) ~ table[(crc ~ buffer[0]) & $FF]
			buffer :+ 1
			length :- 1
		Wend
		
		Return crc
	End Function

	Function FromStream:Short(stream:TStream)
		Local crc   : Short, ..
		      i     : Int
		
		If Not stream Then Throw("failed")
		
		crc = $FFFF
		While Not stream.Eof()
			crc = (crc Shr 8) ~ table[(crc ~ stream.ReadByte()) & $FF]
		Wend
		
		Return crc
	End Function
End Type

Type CRC32
	Const IEEE8023   : Int = $04C11DB7, ..
	      CASTAGNOLI : Int = $1EDC6F41, ..
	      KOOPMAN    : Int = $741B8CD7
	
	Global table : Int[]
	
	Function Init(polynomial:Int = IEEE8023)
		Local i : Int, ..
		      j : Int
		
		table = New Int[256]
		For i = 0 To 255
			table[i] = reflect(i, 8) Shl 24
			
			For j = 0 To 7
				If table[i] & $80000000 Then
					table[i] = (table[i] Shl 1) ~ polynomial
				Else
					table[i] :Shl 1
				EndIf
			Next
			
			table[i] = reflect(table[i], 32)
		Next
		
		Function reflect:Int(value:Int, count:Byte)
			Local out : Int, ..
			      i   : Int
			
			For i = 1 To count + 1
				If value & 1 Then out :| 1 Shl (count - i)
				value :Shr 1
			Next
			
			Return out
		End Function
	End Function
	
	Function FromString:Int(value:String)
		Local crc : Int, ..
		      i   : Int

		crc = $FFFFFFFF
		For i = 0 Until value.Length
			crc = (crc Shr 8) ~ table[(crc & $FF) ~ value[i]]
		Next
		
		Return crc ~ $FFFFFFFF
	End Function

	Function FromBuffer:Int(buffer:Byte Ptr, length:Int)
		Local crc : Int, ..
		      i   : Int
		
		If (Not buffer) Or length < 0 Then Throw("failed")

		crc = $FFFFFFFF
		While length > 0
			crc = (crc Shr 8) ~ table[(crc & $FF) ~ buffer[0]]
			buffer :+ 1
			length :- 1
		Wend
		
		Return crc ~ $FFFFFFFF
	End Function

	Function FromStream:Int(stream:TStream)
		Local crc : Int, ..
		      i   : Int
		
		If Not stream Then Throw("failed")
		
		crc = $FFFFFFFF
		While Not stream.Eof()
			crc = (crc Shr 8) ~ table[(crc & $FF) ~ stream.ReadByte()]
		Wend
		
		Return crc ~ $FFFFFFFF
	End Function
End Type

Type MD5
	Const K0 : Int = $5A827999, ..
	      K1 : Int = $6ED9EBA1, ..
	      K2 : Int = $8F1BBCDC, ..
	      K3 : Int = $CA62C1D6
	
	Global block : Byte[64]
	Global h0 : Int, h1 : Int, h2 : Int, h3 : Int
	
	Global k : Int[] = ..
				[$D76AA478, $E8C7B756, $242070DB, $C1BDCEEE, $F57C0FAF, $4787C62A, ..
				 $A8304613, $FD469501, $698098D8, $8B44F7AF, $FFFF5BB1, $895CD7BE, ..
				 $6B901122, $FD987193, $A679438E, $49B40821, $F61E2562, $C040B340, ..
				 $265E5A51, $E9B6C7AA, $D62F105D, $02441453, $D8A1E681, $E7D3FBC8, ..
				 $21E1CDE6, $C33707D6, $F4D50D87, $455A14ED, $A9E3E905, $FCEFA3F8, ..
				 $676F02D9, $8D2A4C8A, $FFFA3942, $8771F681, $6D9D6122, $FDE5380C, ..
				 $A4BEEA44, $4BDECFA9, $F6BB4B60, $BEBFBC70, $289B7EC6, $EAA127FA, ..
				 $D4EF3085, $04881D05, $D9D4D039, $E6DB99E5, $1FA27CF8, $C4AC5665, ..
				 $F4292244, $432AFF97, $AB9423A7, $FC93A039, $655B59C3, $8F0CCC92, ..
				 $FFEFF47D, $85845DD1, $6FA87E4F, $FE2CE6E0, $A3014314, $4E0811A1, ..
				 $F7537E82, $BD3AF235, $2AD7D2BB, $EB86D391]
				
	Global r : Int[] = ..
				[7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22, ..
				 5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20, ..
				 4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23, ..
				 6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21]

	Function reset()
		h0 = $67452301
		h1 = $EFCDAB89
		h2 = $98BADCFE
		h3 = $10325476
	End Function

	Function FromString(value:String)
		Local length    : Int, ..
		      bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		reset()
		
		length = value.Length
		bitLength = length*8
		
		' divide data into 512 bit blocks
		i = 0
		index = 0
		Repeat
			block[index] = value[i]
			i     :+ 1
			index :+ 1
			
			If index = 64 Then
				transform()
				index = 0
			EndIf
		Until i = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		(Long Ptr(Byte Ptr(block) + SizeOf(block) - 8))[0] = bitLength
		transform()
	End Function

	Function FromBuffer(buffer:Byte Ptr, length:Int)
		Local bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		If (Not buffer) Or length < 0 Then Throw("failed")
		reset()

		bitLength = length Shl 3
		
		' divide data into 512 bit blocks
		i = 0
		While length >= SizeOf(block)
			MemCopy(block, buffer, SizeOf(block))
			buffer :+ SizeOf(block)
			length :- SizeOf(block)
			transform()
		Wend
		If length > 0 Then MemCopy(block, buffer, length)
		index = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		(Long Ptr(Byte Ptr(block) + SizeOf(block) - 8))[0] = bitLength
		transform()
	End Function
	
	Function FromStream(stream:TStream)
		Local length    : Int, ..
		      bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		If Not stream Then Throw("failed")
		reset()
		
		' divide data into 512 bit blocks
		While Not stream.Eof()
			length = stream.Read(block, SizeOf(block))
			bitLength :+ length Shl 3
			If length < SizeOf(block) Then Exit
			transform()
		Wend
		If length = 64 Then
			index = 0
		Else
			index = length
		EndIf
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		(Long Ptr(Byte Ptr(block) + SizeOf(block) - 8))[0] = bitLength
		transform()
	End Function
	
	Function ToStr:String()
		Return hexadecimal(bigEndian(h0)) + ..
		       hexadecimal(bigEndian(h1)) + ..
		       hexadecimal(bigEndian(h2)) + ..
		       hexadecimal(bigEndian(h3))
		
		Function bigEndian:Int(value:Int)
			Return (value & $FF) Shl 24 ..
			       | (value Shr 8 & $FF) Shl 16 ..
			       | (value Shr 16 & $FF) Shl 8 ..
			       | (value Shr 24 & $FF)
		End Function
	End Function
	
	Function transform()
		Global t    : Int, ..
		       w    : Int[64], ..
		       temp : Int
		Global f : Int
		Global a : Int, b : Int, c : Int, d : Int
		
		a = h0 ; b = h1 ; c = h2 ; d = h3
		
		MemCopy(w, block, SizeOf(block))
		
		For t = 0 To 15
			temp = d
			f = d ~ (b & (c ~ d))
			d = c
			c = b
			b = rol((a + f + k[t] + w[t]), r[t]) + b
			a = temp
		Next
	
		For t = 16 To 31
			temp = d
			f = c ~ (d & (b ~ c))			
			d = c
			c = b
			b = rol((a + f + k[t] + w[(((5*t) + 1) & 15)]), r[t]) + b
			a = temp
		Next
		
		For t = 32 To 47
			temp = d
			f = b ~ c ~ d
			d = c
			c = b
			b = rol((a + f + k[t] + w[(((3*t) + 5) & 15)]), r[t]) + b
			a = temp
		Next
		
		For t = 48 To 63
			temp = d
			f = c ~ (b | ~d)
			d = c
			c = b
			b = rol((a + f + k[t] + w[((7*t) & 15)]), r[t]) + b
			a = temp
		Next
		
		h0 :+ a ; h1 :+ b ; h2 :+ c ; h3 :+ d
	End Function
End Type

Type SHA1
	Const K0 : Int = $5A827999, ..
	      K1 : Int = $6ED9EBA1, ..
	      K2 : Int = $8F1BBCDC, ..
	      K3 : Int = $CA62C1D6

	Global block : Byte[64]
	Global h0 : Int, h1 : Int, h2 : Int, h3 : Int, h4 : Int

	Function reset()
		h0 = $67452301
		h1 = $EFCDAB89
		h2 = $98BADCFE
		h3 = $10325476
		h4 = $C3D2E1F0
	End Function
	
	Function FromString(value:String)
		Local length    : Int, ..
		      bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		reset()
		
		length = value.Length
		bitLength = length*8
		
		' divide data into 512 bit blocks
		i = 0
		index = 0
		Repeat
			block[index] = value[i]
			i     :+ 1
			index :+ 1
			
			If index = 64 Then
				transform()
				index = 0
			EndIf
		Until i = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		block[56] = bitLength Shr 56
		block[57] = bitLength Shr 48
		block[58] = bitLength Shr 40
		block[59] = bitLength Shr 32
		block[60] = bitlength Shr 24
		block[61] = bitlength Shr 16
		block[62] = bitlength Shr 8
		block[63] = bitlength
		transform()
	End Function
	
	Function FromBuffer(buffer:Byte Ptr, length:Int)
		Local bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		If (Not buffer) Or length < 0 Then Throw("failed")
		reset()

		bitLength = length Shl 3
		
		' divide data into 512 bit blocks
		i = 0
		While length >= SizeOf(block)
			MemCopy(block, buffer, SizeOf(block))
			buffer :+ SizeOf(block)
			length :- SizeOf(block)
			transform()
		Wend
		If length > 0 Then MemCopy(block, buffer, length)
		index = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		block[56] = bitLength Shr 56
		block[57] = bitLength Shr 48
		block[58] = bitLength Shr 40
		block[59] = bitLength Shr 32
		block[60] = bitlength Shr 24
		block[61] = bitlength Shr 16
		block[62] = bitlength Shr 8
		block[63] = bitlength
		transform()
	End Function
	
	Function FromStream(stream:TStream)
		Local length    : Int, ..
		      bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		If Not stream Then Throw("failed")
		reset()
		
		' divide data into 512 bit blocks
		While Not stream.Eof()
			length = stream.Read(block, SizeOf(block))
			bitLength :+ length Shl 3
			If length = SizeOf(block) Then transform()
		Wend
		index = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		block[56] = bitLength Shr 56
		block[57] = bitLength Shr 48
		block[58] = bitLength Shr 40
		block[59] = bitLength Shr 32
		block[60] = bitlength Shr 24
		block[61] = bitlength Shr 16
		block[62] = bitlength Shr 8
		block[63] = bitlength
		transform()
	End Function
	
	Function ToStr:String()
		Return hexadecimal(h0) + hexadecimal(h1) + hexadecimal(h2) + hexadecimal(h3) + hexadecimal(h4)
	End Function
	
	Function transform()
		Global t    : Int, ..
		       temp : Int, ..
		       w    : Int[80]
		Global a : Int, b : Int, c : Int, d : Int, e : Int
		
		' little- to big endian
		For t = 0 To 15
			temp = t Shl 2
			w[t] = block[temp] Shl 24 ..
			       | block[temp + 1] Shl 16 ..
			       | block[temp + 2] Shl 8 ..
			       | block[temp + 3]
		Next
		
		For t = 16 To 79
			w[t] = rol(w[t - 3] ~ w[t - 8] ~ w[t - 14] ~ w[t - 16], 1)
		Next
		
		a = h0 ; b = h1 ; c = h2 ; d = h3 ; e = h4
		
		' Round 1
		For t = 0 To 19
			temp = rol(a, 5) + (d ~ (b & (c ~ d))) + e + K0 + w[t]
			e = d
			d = c
			c = rol(b, 30)
			b = a
			a = temp
		Next
		
		' Round 2
		For t = 20 To 39
			temp = rol(a, 5) + (b ~ c ~ d) + e + K1 + w[t]	      
			e = d
			d = c
			c = rol(b, 30)
			b = a
			a = temp
		Next
		
		' Round 3
		For t = 40 To 59
			temp = rol(a, 5) + ((b & c) | (d & (b | c))) + e + K2 + w[t]  
			e = d
			d = c
			c = rol(b, 30)
			b = a
			a = temp
		Next
		
		' Round 4
		For t = 60 To 79
			temp = rol(a, 5) + (b ~ c ~ d) + e + K3 + w[t]  
			e = d
			d = c
			c = rol(b, 30)
			b = a
			a = temp
		Next
		
		h0 :+ a ; h1 :+ b ; h2 :+ c ; h3 :+ d ; h4 :+ e
	End Function
End Type

Type SHA256
	Global block : Byte[64]
	Global h0 : Int, h1 : Int, h2 : Int, h3 : Int, ..
	       h4 : Int, h5 : Int, h6 : Int, h7 : Int
	
	Global k : Int[] = ..
		[$428A2F98, $71374491, $B5C0FBCF, $E9B5DBA5, $3956C25B, $59F111F1, ..
		 $923F82A4, $AB1C5ED5, $D807AA98, $12835B01, $243185BE, $550C7DC3, ..
		 $72BE5D74, $80DEB1FE, $9BDC06A7, $C19BF174, $E49B69C1, $EFBE4786, ..
		 $0FC19DC6, $240CA1CC, $2DE92C6F, $4A7484AA, $5CB0A9DC, $76F988DA, ..
		 $983E5152, $A831C66D, $B00327C8, $BF597FC7, $C6E00BF3, $D5A79147, ..
		 $06CA6351, $14292967, $27B70A85, $2E1B2138, $4D2C6DFC, $53380D13, ..
		 $650A7354, $766A0ABB, $81C2C92E, $92722C85, $A2BFE8A1, $A81A664B, ..
		 $C24B8B70, $C76C51A3, $D192E819, $D6990624, $F40E3585, $106AA070, ..
		 $19A4C116, $1E376C08, $2748774C, $34B0BCB5, $391C0CB3, $4ED8AA4A, ..
		 $5B9CCA4F, $682E6FF3, $748F82EE, $78A5636F, $84C87814, $8CC70208, ..
		 $90BEFFFA, $A4506CEB, $BEF9A3F7, $C67178F2]

	Function reset()
		h0 = $6A09E667
		h1 = $BB67AE85
		h2 = $3C6EF372
		h3 = $A54FF53A
		h4 = $510E527F
		h5 = $9B05688C
		h6 = $1F83D9AB
		h7 = $5BE0CD19
	End Function
	
	Function FromBuffer(buffer:Byte Ptr, length:Int)
		Local bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		If (Not buffer) Or length < 0 Then Throw("failed")
		reset()

		bitLength = length Shl 3
		
		' divide data into 512 bit blocks
		i = 0
		While length >= SizeOf(block)
			MemCopy(block, buffer, SizeOf(block))
			buffer :+ SizeOf(block)
			length :- SizeOf(block)
			transform()
		Wend
		If length > 0 Then MemCopy(block, buffer, length)
		index = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		block[56] = bitLength Shr 56
		block[57] = bitLength Shr 48
		block[58] = bitLength Shr 40
		block[59] = bitLength Shr 32
		block[60] = bitlength Shr 24
		block[61] = bitlength Shr 16
		block[62] = bitlength Shr 8
		block[63] = bitlength
		transform()
	End Function
	
	Function FromStream(stream:TStream)
		Local length    : Int, ..
		      bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		If Not stream Then Throw("failed")
		reset()
		
		' divide data into 512 bit blocks
		While Not stream.Eof()
			length = stream.Read(block, SizeOf(block))
			bitLength :+ length Shl 3
			If length = SizeOf(block) Then transform()
		Wend
		index = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		block[56] = bitLength Shr 56
		block[57] = bitLength Shr 48
		block[58] = bitLength Shr 40
		block[59] = bitLength Shr 32
		block[60] = bitlength Shr 24
		block[61] = bitlength Shr 16
		block[62] = bitlength Shr 8
		block[63] = bitlength
		transform()
	End Function
	
	Function FromString(value:String)
		Local length    : Int, ..
		      bitLength : Long, ..
		      i         : Int, ..
		      index     : Int
		
		reset()
		
		length = value.Length
		bitLength = length*8
		
		' divide data into 512 bit blocks
		i = 0
		index = 0
		Repeat
			block[index] = value[i]
			i     :+ 1
			index :+ 1
			
			If index = 64 Then
				transform()
				index = 0
			EndIf
		Until i = length
		
		' append one
		block[index] = $80
		index :+ 1
		
		If index = 64 Then
			transform()
			index = 0
		EndIf
		
		' fill with zeros
		MemClear(Byte Ptr(block) + index, 56 - index)
		
		' append length in bits at the end of block
		block[56] = bitLength Shr 56
		block[57] = bitLength Shr 48
		block[58] = bitLength Shr 40
		block[59] = bitLength Shr 32
		block[60] = bitlength Shr 24
		block[61] = bitlength Shr 16
		block[62] = bitlength Shr 8
		block[63] = bitlength
		transform()
	End Function
	
	Function ToStr:String()
		Return hexadecimal(h0) + hexadecimal(h1) + hexadecimal(h2) + hexadecimal(h3) + ..
		       hexadecimal(h4) + hexadecimal(h5) + hexadecimal(h6) + hexadecimal(h7)
	End Function

	Function transform()
		Global i    : Int, ..
		       t0   : Int, ..
		       t1   : Int, ..
		       temp : Int, ..
		       w    : Int[64]
		Global a : Int, b : Int, c : Int, d : Int, e : Int, f : Int, g : Int, h : Int
		
		' little- to big endian
		For i = 0 To 15
			temp = i Shl 2
			w[i] = block[temp] Shl 24 ..
			       | block[temp + 1] Shl 16 ..
			       | block[temp + 2] Shl 8 ..
			       | block[temp + 3]
		Next
		
		For i = 16 To 63
			w[i] = w[i - 16] + (ror(w[i - 15], 7) ~ ror(w[i - 15], 18) ~ (w[i - 15] Shr 3))..
			       + w[i - 7] + (ror(w[i - 2], 17) ~ rOr(w[i - 2], 19) ~ (w[i - 2] Shr 10))
		Next
		
		a = h0 ; b = h1 ; c = h2 ; d = h3
		e = h4 ; f = h5 ; g = h6 ; h = h7
		
		For i=0 To 63
			t0 = (ror(a, 2) ~ ror(a, 13) ~ ror(a, 22)) + ((a & b) | (b & c) | (c & a))
			t1 = h + (ror(e, 6) ~ ror(e, 11) ~ ror(e, 25)) + ((e & f) | (~e & g)) + k[i] + w[i]
				      
			h = g
			g = f
			f = e
			e = d + t1
			d = c
			c = b
			b = a
			a = t0 + t1  
		Next

		h0 :+ a ; h1 :+ b ; h2 :+ c ; h3 :+ d
		h4 :+ e ; h5 :+ f ; h6 :+ g ; h7 :+ h
	End Function
End Type

Type RC4
	Global s : Byte[256], ..
	       k : Byte[256]
	
	Function FromString:String(value:String, key:String)
		Local i     : Int, ..
		      j     : Int, ..
		      temp  : Int, ..
		      index : Int, ..
		      out   : Byte[]
		
		If key.Length = 0 Then Throw("failed")
		prepareKey(key)
		
		out = New Byte[value.length]
		
		i = 0
		j = 0
		For index = 0 Until value.length
			i = (i + 1) Mod 256
			j = (j + s[i]) Mod 256
			
			' Swap
	        temp = s[i]
	        s[i] = s[j]
	        s[j] = temp
	
			out[index] = value[index] ~ s[(s[i] + s[j]) Mod 256]
		Next
		
		Return String.FromBytes(out, value.length)
	End Function
	
	Function FromStream(in:TStream, out:TStream, key:String)
		Local i      : Int, ..
		      j      : Int, ..
		      temp   : Int
		
		If key.Length = 0 Then Throw("failed")
		prepareKey(key)
		
		i = 0
		j = 0
		While Not in.Eof()
			i = (i + 1) Mod 256
			j = (j + s[i]) Mod 256
			
			' Swap
	        temp = s[i]
	        s[i] = s[j]
	        s[j] = temp
			
			out.WriteByte(in.ReadByte() ~ s[(s[i] + s[j]) Mod 256])
		Wend
	End Function

	Function FromBuffer(in:Byte Ptr, out:Byte Ptr, length:Int, key:String)
		Local i     : Int, ..
		      j     : Int, ..
		      temp  : Int
		
		If key.Length = 0 Then Throw("failed")
		prepareKey(key)
		
		i = 0
		j = 0
		While length > 0
			i = (i + 1) Mod 256
			j = (j + s[i]) Mod 256
			
			' Swap
	        	temp = s[i]
	        	s[i] = s[j]
	        	s[j] = temp
	
			out[0] = in[0] ~ s[(s[i] + s[j]) Mod 256]
			in  :+ 1
			out :+ 1
			
			length :- 1
		Wend
	End Function
	
	Function prepareKey(key : String)
		Local i     : Int, ..
		      j     : Int, ..
		      temp  : Int
		
		For i = 0 To 255
			s[i] = i
			k[i] = key[i Mod key.length]
		Next
		
		' Swap
		j = 0
		For i = 0 To 255
	        j = (j + s[i] + k[i]) Mod 256
	        temp = s[i]
	        s[i] = s[j]
	        s[j] = temp
		Next
	End Function
End Type

Private

' circular rotate left
Function rol:Int(value:Int, shift:Int)
	Return (value Shl shift) | (value Shr (32 - shift))
End Function

' circular rotate right
Function ror:Int(value:Int, shift:Int)
  Return (value Shr shift) | (value Shl (32 - shift))
End Function

Function hexadecimal:String(value:Int)
	Local buffer : Byte[8], ..
	      i      : Int, ..
	      char   : Byte
	
	For i = 7 To 0 Step -1
		char = (value & $0F)
		If char > 9 Then
			char :+ Asc("a") - 10
		Else
			char :+ Asc("0")
		EndIf
		
		buffer[i] = char
		value :Shr 4
	Next
	
	Return String.FromBytes(buffer, 8)
End Function

Function binary:String(value:Int)
	Local buffer : Byte[32], ..
	      i      : Int
	
	For i = 31 To 0 Step -1
		buffer[i] = (value & %1) + Asc("0")
		value :Shr 1
	Next
	
	Return String.FromBytes(buffer, 32)
End Function

Function rightString:String(value:String, count:Int)
	Return value[(value.length - count)..(value.length)]
End Function
