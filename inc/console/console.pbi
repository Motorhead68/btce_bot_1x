; BTC-E BOT (version 1.2.x.x)
; Author: explode48 (explode48@gmail.com)
; ULR: http://proapi.ru/btce_bot/
; License: GNU General Public License v2


XIncludeFile "inc/console/Xtended-Console.pbi"

Procedure ConsoleText(Text.s)
  If Configs\logf <> ""
    Log = OpenFile(#PB_Any, Configs\logf, #PB_File_SharedRead|#PB_File_SharedWrite|#PB_File_Append)
    If Log
      WriteStringN(Log, Text)
      CloseFile(Log)
    EndIf
  EndIf
  PrintNEx(LSet("", 395))
  ConsoleLocateEx(0, GetCursorY()-5)
  PrintNEx(Text)
EndProcedure

Procedure ConsoleBalance()
  PrintNEx(LSet("", 79))
  PrintNEx(LSet("", 79))
  ConsoleLocateEx(0, GetCursorY()-1)
  PrintNEx("> [BALANCE: "+Double2String(getCurrentBalance(1), 3)+" "+UCase(StringField(Configs\curpair, 1, "_"))+", "+Double2String(getCurrentBalance(2), 3)+" "+UCase(StringField(Configs\curpair, 2, "_"))+"] [ORDERS: "+Str(Exchange\getInfo\open_orders)+"] [PRICE: 1 "+UCase(StringField(Configs\curpair, 1, "_"))+" = "+Double2String(Exchange\getTicker\last, 3)+" "+UCase(StringField(Configs\curpair, 2, "_"))+"]")
  If Exit = #False
    PrintNEx("> [PRESS ESC KEY TO STOP THE BTC-E BOT]")
  Else
    PrintNEx("> [WAITING FOR EXIT]")
  EndIf
  ConsoleLocateEx(0, GetCursorY()-3)
EndProcedure

Procedure ConsoleDateText(Text.s, Verbose.b)
  If (Configs\verb = #True And Verbose = #True) Or (Verbose = #False)
    ConsoleText("* "+FormatDate("[%dd.%mm.%yy %hh:%ii:%ss]: ", Date())+Text)
    ConsoleBalance()
  EndIf
EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; UseMainFile = ..\..\main.pb
