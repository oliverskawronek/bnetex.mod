SuperStrict

Framework brl.blitz
Import vertex.bnetex

CRC16.Init() ' Default Polynom IBM 0xA001
' 51709 (decimal) = 0xC9FD (hex)
WriteStdout(CRC16.FromString("Foo") + "~n")

MD5.FromString("Foo")
' 1356c67d7ad1638d816bfb822dd2c25d
WriteStdout(MD5.ToStr() + "~n")

SHA256.FromString("Foo")
' 1cbec737f863e4922cee63cc2ebbfaafcd1cff8b790d8cfd2e6a5d550b648afa
WriteStdout(SHA256.ToStr() + "~n")

End
