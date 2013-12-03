; BTC-E BOT (version 1.4.x.x)
; Author: explode48 (explode48@gmail.com)
; ULR: http://proapi.ru/btce_bot/
; License: GNU General Public License v2


;- ���������� ����������
Global Run.b = #False
Global Exit.b = #False
Global Thread.l = #Null
Global PROGRAM_FILENAME$ = ProgramFilename()
Global PROGRAM_VERSION$ = GetFileVersion(PROGRAM_FILENAME$, #GFVI_FileVersion, 0) ; Compiler -> Compiler Options... -> Version Info
SetCurrentDirectory(GetPathPart(PROGRAM_FILENAME$)) ; ������������� ���� �� ������� �����������

;- ��������� ��������
Structure CFG
  file.s           ; ���� �� ����� ��������
  ; ��������� API
  api_key.s        ; ��� ����
  api_secret.s     ; ��������� ������
  api_nonce.l      ; ������������ ��������
  ; ��������� ������
  proxy_host.s     ; ����� ����� (host:port)
  proxy_login.s    ; ��� ������������
  proxy_pass.s     ; ������
  ; ��� �������
  log_file.s       ; ��� ����� ��� ���������� �����
  log_scroll.b     ; ������������� �����
  log_verbose.b    ; ����� ������������ ������
  ; ��������� ��������� ����
  bot_curpair.s    ; �������� ����
  bot_min_sell.d   ; ����������� ����� ������ �� �������
  bot_min_buy.d    ; ����������� ����� ������ �� �������
  bot_max_sell.d   ; ������������ ����� ������ �� �������
  bot_max_buy.d    ; ������������ ����� ������ �� �������
  bot_difference.d ; ������� ����� ��������/��������
  bot_buy_ttl.l    ; ����� ����� ������� �� ������� (���, 0 - ����)
  bot_delay.l      ; �������� � �������� ����� (���)
  bot_fall_def.b   ; ������ �� ������� �����
  ; ��������� ����������
  app_autorun.b    ; �������������� ������ ��� ������ ����������
EndStructure
Global Configs.CFG

; ������ StrD(), ������ ��� ����������
Procedure.s Double2String(value.d, nb.l)
  If nb<0 : nb = 0 : EndIf
  result.s = StrD(value, nb+1)
  If nb>0 : dLeft = 1 : Else : dLeft = 2 :EndIf
  result = Left(result, Len(result)-dLeft)
  ProcedureReturn result
EndProcedure

; FormatStr("This %1 is %2", "text", "formatted") ; This text is formatted
Procedure.s FormatStr(Text.s, s1.s="", s2.s="", s3.s="", s4.s="", s5.s="", s6.s="", s7.s="", s8.s="", s9.s="", s10.s="")
  Text = ReplaceString(Text, "%1",  s1)
  Text = ReplaceString(Text, "%2",  s2)
  Text = ReplaceString(Text, "%3",  s3)
  Text = ReplaceString(Text, "%4",  s4)
  Text = ReplaceString(Text, "%5",  s5)
  Text = ReplaceString(Text, "%6",  s6)
  Text = ReplaceString(Text, "%7",  s7)
  Text = ReplaceString(Text, "%8",  s8)
  Text = ReplaceString(Text, "%9",  s9)
  Text = ReplaceString(Text, "%10", s10)
	ProcedureReturn Text
EndProcedure

;- �������������� ����������
XIncludeFile "inc/translator.pbi"; ��������������
XIncludeFile "inc/QuickHash.pbi" ; QuickHash library (HMAC-SHA512)
XIncludeFile "inc/LibCurl.pbi"   ; LibCurl (������ � �����)
XIncludeFile "inc/Json.pbi"      ; JSON
XIncludeFile "inc/BtceApi.pbi"   ; API ��� btc-e.com

; ������������� ��������������
Translator_init("./", "")

;- ��������� �� ���������
Configs\file           = "config.ini"
; ��������� API
Configs\api_key        = ""
Configs\api_secret     = ""
Configs\api_nonce      = Date()
; ��������� ������
Configs\proxy_host     = ""
Configs\proxy_login    = ""
Configs\proxy_pass     = ""
; ��� �������
Configs\log_file       = ""
Configs\log_scroll     = #True
Configs\log_verbose    = #False
; ��������� ��������� ����
Configs\bot_curpair    = "btc_usd"
Configs\bot_min_sell   = 0.01
Configs\bot_min_buy    = 0.01
Configs\bot_max_sell   = 0.01
Configs\bot_max_buy    = 0.01
Configs\bot_difference = 0.5
Configs\bot_buy_ttl    = 360
Configs\bot_delay      = 60
Configs\bot_fall_def   = #True
; ��������� ����������
Configs\app_autorun    = #False

;- ��������� ��������� ������
For I=0 To CountProgramParameters()-1
  Select ProgramParameter(I)
    Case "-c", "--config" ; �������� ����
      Configs\file = ProgramParameter(I+1)
    Case "-h", "--help" ; ������
      MessageRequester(__("BTC-E BOT: Help"), __("Usage: btce_bot.exe [OPTIONS]"+Chr(13)+Chr(13)+"Options:"+Chr(13)+"-c, --config <FILE>"+Chr(9)+" - Use a specified configuration file."+Chr(13)+"-h, --help"+Chr(9)+Chr(9)+" - Display this help message And exit."+Chr(13)+Chr(13)+"Attention! You use this software at your own risk. The developer is Not responsible For the financial And other damage caused As a result of using this program."), #MB_ICONINFORMATION)
      End
  EndSelect
Next I

;- ��������� �������� �� �����
InitCount.l = 0
InitConfig:
If OpenPreferences(Configs\file)
  PreferenceGroup("api")
  Configs\api_key        = ReadPreferenceString("key",        Configs\api_key)
  Configs\api_secret     = ReadPreferenceString("secret",     Configs\api_secret)
  PreferenceGroup("proxy")
  Configs\proxy_host     = ReadPreferenceString("host",       Configs\proxy_host)
  Configs\proxy_login    = ReadPreferenceString("login",      Configs\proxy_login)
  Configs\proxy_pass     = ReadPreferenceString("pass",       Configs\proxy_pass)
  PreferenceGroup("log")
  Configs\log_file       = ReadPreferenceString("file",       Configs\log_file)
  Configs\log_scroll     = ReadPreferenceLong(  "scroll",     Configs\log_scroll)
  Configs\log_verbose    = ReadPreferenceLong(  "verbose",    Configs\log_verbose)
  PreferenceGroup("bot")
  Configs\bot_curpair    = ReadPreferenceString("curpair",    Configs\bot_curpair)
  Configs\bot_min_sell   = ReadPreferenceDouble("min_sell",   Configs\bot_min_sell)
  Configs\bot_min_buy    = ReadPreferenceDouble("min_buy",    Configs\bot_min_buy)
  Configs\bot_max_sell   = ReadPreferenceDouble("max_sell",   Configs\bot_max_sell)
  Configs\bot_max_buy    = ReadPreferenceDouble("max_buy",    Configs\bot_max_buy)
  Configs\bot_difference = ReadPreferenceDouble("difference", Configs\bot_difference)
  Configs\bot_buy_ttl    = ReadPreferenceLong(  "buy_ttl",    Configs\bot_buy_ttl)
  Configs\bot_delay      = ReadPreferenceLong(  "delay",      Configs\bot_delay)
  Configs\bot_fall_def   = ReadPreferenceLong(  "fall_def",   Configs\bot_fall_def)
  PreferenceGroup("application")
  Configs\app_autorun    = ReadPreferenceLong(  "autorun",    Configs\app_autorun)
  ClosePreferences()
ElseIf CreatePreferences(Configs\file)
  PreferenceGroup("api")
  WritePreferenceString("key",        Configs\api_key)
  WritePreferenceString("secret",     Configs\api_secret)
  PreferenceGroup("proxy")
  WritePreferenceString("host",       Configs\proxy_host)
  WritePreferenceString("login",      Configs\proxy_login)
  WritePreferenceString("pass",       Configs\proxy_pass)
  PreferenceGroup("log")
  WritePreferenceString("file",       Configs\log_file)
  WritePreferenceLong(  "scroll",     Configs\log_scroll)
  WritePreferenceLong(  "verbose",    Configs\log_verbose)
  PreferenceGroup("bot")
  WritePreferenceString("curpair",    Configs\bot_curpair)
  WritePreferenceString("min_sell",   Double2String(Configs\bot_min_sell, 6))
  WritePreferenceString("min_buy",    Double2String(Configs\bot_min_buy, 6))
  WritePreferenceString("max_sell",   Double2String(Configs\bot_max_sell, 6))
  WritePreferenceString("max_buy",    Double2String(Configs\bot_max_buy, 6))
  WritePreferenceString("difference", Double2String(Configs\bot_difference, 6))
  WritePreferenceLong(  "buy_ttl",    Configs\bot_buy_ttl)
  WritePreferenceLong(  "delay",      Configs\bot_delay)
  WritePreferenceLong(  "fall_def",   Configs\bot_fall_def)
  PreferenceGroup("application")
  WritePreferenceLong(  "autorun",    Configs\app_autorun)
  ClosePreferences()
  InitCount + 1
  If InitCount>5
    MessageRequester(__("Error!"), __("Error reading or creating configuration file!"), #MB_ICONERROR)
    End
  Else
    Goto InitConfig
  EndIf
EndIf

; ��������� ���������� �������� ������� �� ������ ����
Procedure UpdateBalance()
  StatusBarText(0, 0, FormatStr(__("Balance: %1 %2, %3 %4"), Double2String(getCurrentBalance(1), 3), UCase(StringField(Configs\bot_curpair, 1, "_")), Double2String(getCurrentBalance(2), 3), UCase(StringField(Configs\bot_curpair, 2, "_"))))
  StatusBarText(0, 1, FormatStr(__("Orders: %1"), Str(Exchange\getInfo\open_orders)))
  StatusBarText(0, 2, FormatStr(__("Price: 1 %1 = %2 %3"), UCase(StringField(Configs\bot_curpair, 1, "_")), Double2String(Exchange\getTicker\last, 3), UCase(StringField(Configs\bot_curpair, 2, "_"))))
EndProcedure

; ��������� ���������� ������ � ��� ������ ����
Procedure AddToLog(Text.s, Verbose.b, Dated.b=#True)
  ; ���� ������ ���������� �������
  If (Configs\log_verbose = #True And Verbose = #True) Or (Verbose = #False)
    ; ��������� ��������� ������ ��� ������ � ���
    If Dated=#True
      Text = FormatDate("* [%dd.%mm.%yy %hh:%ii:%ss]: ", Date())+Text
    EndIf
    ; ����� � ����, ���� ����������
    If Configs\log_file <> ""
      Log = OpenFile(#PB_Any, Configs\log_file, #PB_File_SharedRead|#PB_File_SharedWrite|#PB_File_Append)
      If Log
        WriteStringN(Log, Text)
        CloseFile(Log)
      EndIf
    EndIf
    ; ������� � ��� �������
    AddGadgetItem(0, -1, Text)
    ; ����������
    If Configs\log_scroll=#True
      SendMessage_(GadgetID(0), #EM_SCROLLCARET, 0, 0)
    EndIf
  EndIf
  ; ��������� ��������� �������
  UpdateBalance()
EndProcedure

; ���������� ���������� � ������������ � ���
Procedure AuthorInformation()
  AddToLog("=============================================", #False, #False)
  AddToLog(" "+FormatStr(__("BTC-E BOT (version %1)"), PROGRAM_VERSION$), #False, #False)
  AddToLog(" URL: http://proapi.ru/btce_bot/", #False, #False)
  AddToLog(" BTC: 1EPN3YTsfxPrJ8sfoGHLi2mt73Ex4xEwvk", #False, #False)
  AddToLog(" LTC: LYXZmq6hXa79KytU3bdrZZNJ93QV9uLqsT", #False, #False)
  AddToLog("=============================================", #False, #False)
  AddToLog("", #False, #False)
EndProcedure

;- �������� �������� ���� ����
OpenWindow(0, #PB_Ignore, #PB_Ignore, 600, 385, FormatStr(__("BTC-E BOT (version %1)"), PROGRAM_VERSION$), #PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
WebGadget(100, 5, 5, 590, 80, "http://proapi.ru/api/frame.php?w=590&h=80&a=btce_bot&v="+PROGRAM_VERSION$, #PB_Web_Mozilla)
SetGadgetAttribute(100, #PB_Web_BlockPopups, #True)
SetGadgetAttribute(100, #PB_Web_BlockPopupMenu, #True)
EditorGadget(0, 5, 90, 400, 290, #PB_Editor_ReadOnly)
Frame3DGadget(1, 415, 90, 175, 165, __("Trade options"))
TextGadget(2, 425, 110, 80, 20, __("Curpair:"))      : TextGadget(3, 510, 110, 75, 20, UCase(StringField(Configs\bot_curpair, 1, "_"))+"/"+UCase(StringField(Configs\bot_curpair, 2, "_")))
TextGadget(4, 425, 130, 80, 20, __("Difference:"))   : TextGadget(5, 510, 130, 75, 20, Double2String(Configs\bot_difference, 6))
TextGadget(6, 425, 150, 80, 20, __("BUY min:"))      : TextGadget(7, 510, 150, 75, 20, Double2String(Configs\bot_min_buy, 6))
TextGadget(8, 425, 170, 80, 20, __("BUY max:"))      : TextGadget(9, 510, 170, 75, 20, Double2String(Configs\bot_max_buy, 6))
TextGadget(10, 425, 190, 80, 20, __("SELL min:"))   : TextGadget(11, 510, 190, 75, 20, Double2String(Configs\bot_min_sell, 6))
TextGadget(12, 425, 210, 80, 20, __("SELL max:"))   : TextGadget(13, 510, 210, 75, 20, Double2String(Configs\bot_max_sell, 6))
If Configs\bot_buy_ttl>0 : BTTL$ = FormatStr(__("%1 min"), Str(Configs\bot_buy_ttl)) : Else : BTTL$ = __("DISABLE") : EndIf
TextGadget(14, 425, 230, 80, 20, __("Buy TTL:"))    : TextGadget(15, 510, 230, 75, 20, BTTL$)
Frame3DGadget(16, 415, 260, 175, 85, __("Other options"))
If Configs\bot_delay>0 : DELAY$ = FormatStr(__("%1 sec"), Str(Configs\bot_delay)) : Else : DELAY$ = __("DISABLE") : EndIf
TextGadget(17, 425, 280, 80, 20, __("Delay:"))        : TextGadget(18, 510, 280, 75, 20, DELAY$)
If Configs\log_verbose=#True : VERB$ = __("ENABLE") : Else : VERB$ = __("DISABLE") : EndIf
TextGadget(19, 425, 300, 80, 20, __("Verbose mode:")) : TextGadget(20, 510, 300, 75, 20, VERB$)
If Configs\log_file<>"" : LOGF$ = __("ENABLE") : Else : LOGF$ = __("DISABLE") : EndIf
TextGadget(21, 425, 320, 80, 20, __("Log file:"))   : TextGadget(22, 510, 320, 75, 20, LOGF$)
UsePNGImageDecoder() 
ButtonImageGadget(23, 415, 355, 30, 25, ImageID(CatchImage(#PB_Any, ?HelpIcon)))
ButtonImageGadget(24, 450, 355, 30, 25, ImageID(CatchImage(#PB_Any, ?ConfIcon)))
ButtonGadget(25, 485, 355, 110, 25, __("Run BOT"))
CreateStatusBar(0, WindowID(0))
AddStatusBarField(#PB_Ignore)
AddStatusBarField(#PB_Ignore)
AddStatusBarField(#PB_Ignore)
AuthorInformation()
ResizeWindow(0, #PB_Ignore, #PB_Ignore, WindowWidth(0), WindowHeight(0)+StatusBarHeight(0))

; ����� �� ����� ������� ���������� ������
Global NewList PendingOrders.trce_trade3()

; ��������� ������� ����
Procedure StartBtceBot(*Null)
  Run = #True
  ClearStructure(@Exchange, TradeInfo)
  InitializeStructure(@Exchange, TradeInfo)
  DisableGadget(23, #True)
  DisableGadget(24, #True)
  SetGadgetText(25, __("Stop BOT"))
  WindowTitle$ = GetWindowTitle(0)
  SetWindowTitle(0, FormatStr(__("%1 [RUN]"), WindowTitle$))
  ClearGadgetItems(0)
  AuthorInformation()
  AddToLog(__("Bot started."), #False)
  ; �������� ������ ����
  Repeat
    ;- TODO: ����������� � ���������� �������
    ;- TODO: �������� �����������
    ;- �������� ����� ������ � �����
    AddToLog(__("Receives new data from the stock exchange."), #True)
    If Not BTCE_OrderList() ; ������ �������� �������
      AddToLog(FormatStr(__("`%1` method error (%2)!"), "OrderList", __(Exchange\OrderList\error)), #False)
    Else
      AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "OrderList"), #True)
    EndIf
    If Not BTCE_getInfo() ; �������� getInfo
      AddToLog(FormatStr(__("`%1` method error (%2)!"), "getInfo", __(Exchange\getInfo\error)), #False)
    Else
      AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getInfo"), #True)
    EndIf
    If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
      AddToLog(FormatStr(__("`%1` method error (%2)!"), "getTicker", __(Exchange\getTicker\error)), #False)
    Else
      AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getTicker"), #True)
    EndIf
    AddToLog(__("The new data is received. Analyzing further action."), #True)
    ;- ��������� ����� �������
    If Exchange\getInfo\success = #True
      If Exchange\getInfo\rights\info=0 Or Exchange\getInfo\rights\trade=0
        AddToLog(__("Not enough permissions for this API key!"), #False)
        Break
      EndIf
    EndIf
    ;- TODO: ������ ������ �� ��������� �����
    ;- TODO: ������ diff ��� sell � buy
    ;- �������� ������� �� �������
    If getCurrentBalance(2)/(Exchange\getTicker\buy-Configs\bot_difference) >= Configs\bot_min_buy ; ���� ���-�� ������, ������� �� ����� ������ >= minb
      If Configs\bot_fall_def=#False Or Exchange\LastsOrders\sell_price=0 Or Exchange\LastsOrders\sell_price-(Exchange\getTicker\buy-Configs\bot_difference)>=Configs\bot_difference/2 ; ������ ���� ���� ������
        If getCurrentBalance(2)/(Exchange\getTicker\buy-Configs\bot_difference) > Configs\bot_max_buy ; ���� ���-�� ������, ������� �� ����� ������ > maxb
          Amount.d = Configs\bot_max_buy
        Else
          Amount.d = getCurrentBalance(2)/(Exchange\getTicker\buy-Configs\bot_difference)
        EndIf
        Error.s = BTCE_Trade(Configs\bot_curpair, "buy", Exchange\getTicker\buy-Configs\bot_difference, Amount) ; ������� �����
        If Error = "" ; ���� ����� ������
          AddToLog(FormatStr(__("Created a new buy order (%1 %2/%3 %4)."), Double2String(Amount, 3), UCase(StringField(Configs\bot_curpair, 1, "_")), Double2String(Exchange\getTicker\buy-Configs\bot_difference, 3), UCase(StringField(Configs\bot_curpair, 2, "_"))), #False)
          ; �������� ����� ������ � �����
          AddToLog(__("Receives new data from the stock exchange."), #True)
          If Not BTCE_OrderList() ; ������ �������� �������
            AddToLog(FormatStr(__("`%1` method error (%2)!"), "OrderList", __(Exchange\OrderList\error)), #False)
          Else
            AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "OrderList"), #True)
          EndIf
          If Not BTCE_getInfo() ; �������� getInfo
            AddToLog(FormatStr(__("`%1` method error (%2)!"), "getInfo", __(Exchange\getInfo\error)), #False)
          Else
            AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getInfo"), #True)
          EndIf
          If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
            AddToLog(FormatStr(__("`%1` method error (%2)!"), "getTicker", __(Exchange\getTicker\error)), #False)
          Else
            AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getTicker"), #True)
          EndIf
          AddToLog(__("The new data is received. Analyzing further action."), #True)
          ; �������� �� ����������� ����� �������
          If Exchange\LastsOrders\buy_amount < Configs\bot_min_sell
            Exchange\LastsOrders\buy_amount = Configs\bot_min_sell
          EndIf
          ; ���� � ��� ���� ������ ��� �������� ������ �� �������
          If getCurrentBalance(1) >= Exchange\LastsOrders\buy_amount
            If Exchange\LastsOrders\buy_amount > Configs\bot_max_sell ; ���� ���-�� ������, ������� �� ����� ������� > maxs
              Amount.d = Configs\bot_max_sell
            Else
              Amount.d = Exchange\LastsOrders\buy_amount
            EndIf
            Error.s = BTCE_Trade(Configs\bot_curpair, "sell", Exchange\LastsOrders\buy_price+(Configs\bot_difference*2), Amount) ; ������� �����
            If Error = "" ; ���� ����� ������
              AddToLog(FormatStr(__("Created a new sell order (%1 %2/%3 %4)."), Double2String(Amount, 3), UCase(StringField(Configs\bot_curpair, 1, "_")), Double2String(Exchange\LastsOrders\buy_price+(Configs\bot_difference*2), 3), UCase(StringField(Configs\bot_curpair, 2, "_"))), #False)
              ; �������� ����� ������ � �����
              AddToLog(__("Receives new data from the stock exchange."), #True)
              If Not BTCE_OrderList() ; ������ �������� �������
                AddToLog(FormatStr(__("`%1` method error (%2)!"), "OrderList", __(Exchange\OrderList\error)), #False)
              Else
                AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "OrderList"), #True)
              EndIf
              If Not BTCE_getInfo() ; �������� getInfo
                AddToLog(FormatStr(__("`%1` method error (%2)!"), "getInfo", __(Exchange\getInfo\error)), #False)
              Else
                AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getInfo"), #True)
              EndIf
              AddToLog(__("The new data is received. Analyzing further action."), #True)
            Else ; ���� �� ������� ������� �����
              AddToLog(FormatStr(__("Error creating sell order (%1)!"), Error), #False)
              ; ����������� �����
              AddElement(PendingOrders())
              PendingOrders()\price  = Exchange\LastsOrders\buy_price+(Configs\bot_difference*2)
              PendingOrders()\amount = Amount
            EndIf
          Else ; ���� ������ ������� �� ������ �� �����
            ; ����������� �����
            AddElement(PendingOrders())
            PendingOrders()\price  = Exchange\LastsOrders\buy_price+(Configs\bot_difference*2)
            PendingOrders()\amount = Exchange\LastsOrders\buy_amount
          EndIf
        Else ; ���� �� ������� ������� �����
          AddToLog(FormatStr(__("Error creating buy order (%1)!"), Error), #False)
        EndIf
      EndIf
    EndIf
    ;- ���������� ������ �� �������
    If ListSize(PendingOrders()) > 0
      ; �������� ����� ������ � �����
      AddToLog(__("Receives new data from the stock exchange."), #True)
      If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
        AddToLog(FormatStr(__("`%1` method error (%2)!"), "getTicker", __(Exchange\getTicker\error)), #False)
      Else
        AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getTicker"), #True)
      EndIf
      AddToLog(__("The new data is received. Analyzing further action."), #True)    
      PendingOrdersAmount.d = 0
      ResetList(PendingOrders())
      While NextElement(PendingOrders())
        If PendingOrders()\amount > Configs\bot_max_sell ; ���� ���-�� ������, ������� �� ����� ������� > maxs
          PendingOrders()\amount = Configs\bot_max_sell
        EndIf
        PendingOrdersAmount + PendingOrders()\amount
        ; ����  � ��� ���������� ������ ��� �������� ������
        If getCurrentBalance(1) >= PendingOrders()\amount
          Error.s = BTCE_Trade(Configs\bot_curpair, "sell", PendingOrders()\price, PendingOrders()\amount) ; ������� �����
          If Error = "" ; ���� ����� ������
            AddToLog(FormatStr(__("Created a new sell order (%1 %2/%3 %4)."), Double2String(PendingOrders()\amount, 3), UCase(StringField(Configs\bot_curpair, 1, "_")), Double2String(PendingOrders()\price, 3), UCase(StringField(Configs\bot_curpair, 2, "_"))), #False)
            PendingOrdersAmount - PendingOrders()\amount
            DeleteElement(PendingOrders()) ; ������� ��� �� ����������
            ; �������� ����� ������ � �����
            AddToLog(__("Receives new data from the stock exchange."), #True)
            If Not BTCE_OrderList() ; ������ �������� �������
              AddToLog(FormatStr(__("`%1` method error (%2)!"), "OrderList", __(Exchange\OrderList\error)), #False)
            Else
              AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "OrderList"), #True)
            EndIf
            If Not BTCE_getInfo() ; �������� getInfo
              AddToLog(FormatStr(__("`%1` method error (%2)!"), "getInfo", __(Exchange\getInfo\error)), #False)
            Else
              AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getInfo"), #True)
            EndIf
            If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
              AddToLog(FormatStr(__("`%1` method error (%2)!"), "getTicker", __(Exchange\getTicker\error)), #False)
            Else
              AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getTicker"), #True)
            EndIf
            AddToLog(__("The new data is received. Analyzing further action."), #True)
          Else
            AddToLog(FormatStr(__("Error creating sell order (%1)!"), Error), #False)
          EndIf
        EndIf
      Wend
    EndIf
    ;- ��������� ������ �� �������
    If getCurrentBalance(1)-PendingOrdersAmount >= Configs\bot_min_sell ; ���� ���� ��������� ������ ��� �������
      ; �������� ����� ������ � �����
      AddToLog(__("Receives new data from the stock exchange."), #True)
      If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
        AddToLog(FormatStr(__("`%1` method error (%2)!"), "getTicker", __(Exchange\getTicker\error)), #False)
      Else
        AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getTicker"), #True)
      EndIf
      AddToLog(__("The new data is received. Analyzing further action."), #True)
      If getCurrentBalance(1)-PendingOrdersAmount > Configs\bot_max_sell ; ���� ���-�� ������, ������� �� ����� ������� > maxs
        Amount.d = Configs\bot_max_sell
      Else
        Amount.d = getCurrentBalance(1)-PendingOrdersAmount
      EndIf
      Error.s = BTCE_Trade(Configs\bot_curpair, "sell", Exchange\getTicker\sell+Configs\bot_difference, Amount) ; ������� �����    
      If Error = "" ; ���� ����� ������
        AddToLog(FormatStr(__("Created a new sell order (%1 %2/%3 %4)."), Double2String(Amount, 3), UCase(StringField(Configs\bot_curpair, 1, "_")), Double2String(Exchange\getTicker\sell+Configs\bot_difference, 3), UCase(StringField(Configs\bot_curpair, 2, "_"))), #False)
        ; �������� ����� ������ � �����
        AddToLog(__("Receives new data from the stock exchange."), #True)
        If Not BTCE_OrderList() ; ������ �������� �������
          AddToLog(FormatStr(__("`%1` method error (%2)!"), "OrderList", __(Exchange\OrderList\error)), #False)
        Else
          AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "OrderList"), #True)
        EndIf
        If Not BTCE_getInfo() ; �������� getInfo
          AddToLog(FormatStr(__("`%1` method error (%2)!"), "getInfo", __(Exchange\getInfo\error)), #False)
        Else
          AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getInfo"), #True)
        EndIf
        If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
          AddToLog(FormatStr(__("`%1` method error (%2)!"), "getTicker", __(Exchange\getTicker\error)), #False)
        Else
          AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getTicker"), #True)
        EndIf
        AddToLog(__("The new data is received. Analyzing further action."), #True)
      Else
        AddToLog(FormatStr(__("Error creating sell order (%1)!"), Error), #False)
      EndIf
    EndIf
    ;- ������ BUY ������� � �������� TTL
    If Configs\bot_buy_ttl<>0
      ResetList(Exchange\OrderList\orders())
      While NextElement(Exchange\OrderList\orders())
        If Exchange\OrderList\orders()\type = "buy" And Exchange\OrderList\orders()\status = 0
          ;- FIXME: ������ ������ �� ����������� ����� ����� �������� ������
          If Exchange\getInfo\server_time - Exchange\OrderList\orders()\timestamp_created >= 60*Configs\bot_buy_ttl
            Error.s = BTCE_CancelOrder(Exchange\OrderList\orders()\id)
            If Error = "" ; ���� ����� �������
              ;- FIXME: ������ ������ �� �������, ������� � ��� ������
              AddToLog(FormatStr(__("A buy order is successfully canceled (ID=%1)."), Str(Exchange\OrderList\orders()\id)), #False)
            Else
              AddToLog(FormatStr(__("Error when canceling buy order (%1)!"), Error), #False)
            EndIf
          EndIf
        EndIf
      Wend
      ; �������� ����� ������ � �����
      AddToLog(__("Receives new data from the stock exchange."), #True)
      If Not BTCE_OrderList() ; ������ �������� �������
        AddToLog(FormatStr(__("`%1` method error (%2)!"), "OrderList", __(Exchange\OrderList\error)), #False)
      Else
        AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "OrderList"), #True)
      EndIf
      If Not BTCE_getInfo() ; �������� getInfo
        AddToLog(FormatStr(__("`%1` method error (%2)!"), "getInfo", __(Exchange\getInfo\error)), #False)
      Else
        AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "getInfo"), #True)
      EndIf
      AddToLog(__("The new data is received. Analyzing further action."), #True)
    EndIf
    ;- ��������� ��������
    If Configs\bot_delay>0 And Run=#True
      AddToLog(FormatStr(__("No more action. Wait for %1 seconds..."), Str(Configs\bot_delay)), #True)
      For i=0 To Configs\bot_delay-1
        If Run=#True
          Delay(1000)
        Else
          Break
        EndIf
      Next i
    EndIf    
  Until Run = #False
  ;- ������ ������� �� �������
  If Exchange\getInfo\rights\info=1 Or Exchange\getInfo\rights\trade=1
    AddToLog(__("Cancel all buy orders..."), #False)
    ; �������� ������ �������� �������
    If Not BTCE_OrderList() ; �������� OrderList
      AddToLog(FormatStr(__("`%1` method error (%2)!"), "OrderList", __(Exchange\OrderList\error)), #False)
    Else
      AddToLog(FormatStr(__("`%1` method ok (there are no errors)."), "OrderList"), #True)
    EndIf
    ; ���� ����� ��� ������ �� �������
    ResetList(Exchange\OrderList\orders())
    While NextElement(Exchange\OrderList\orders())
      If Exchange\OrderList\orders()\type = "buy" ; ���� ����� �� �������
        If Exchange\OrderList\orders()\status = 0 ; � �� ��� �� ��������
          Error.s = BTCE_CancelOrder(Exchange\OrderList\orders()\id)
          If Error = "" ; ���� ����� �������
            AddToLog(FormatStr(__("A buy order is successfully canceled (ID=%1)."), Str(Exchange\OrderList\orders()\id)), #False)
          Else
            AddToLog(FormatStr(__("Error when canceling buy order (%1)!"), Error), #False)
          EndIf
        EndIf
      EndIf
    Wend
  EndIf
  ; ����� �������� ������ ����
  AddToLog(__("Bot stopped."), #False)
  AddToLog("", #False, #False)
  DisableGadget(23, #False)
  DisableGadget(24, #False)
  SetGadgetText(25, __("Run BOT"))
  DisableGadget(25, #False)
  SetWindowTitle(0, WindowTitle$)
EndProcedure

; ���� �������� �������������� ������
If Configs\app_autorun=#True
  Thread = CreateThread(@StartBtceBot(), #Null)
EndIf

; �������� ����
Repeat
  Select WaitWindowEvent(100)
    Case #PB_Event_Gadget
      Select EventGadget() ; �������
        Case 23 ; �������
          RunProgram(PROGRAM_FILENAME$, "--help", GetPathPart(PROGRAM_FILENAME$))
        Case 24 ; ���������
          ;- TODO: �������� ���� �������������� ��������
          MessageRequester(__("Information"), __("This feature is not available in the current version of the program!"), #MB_ICONINFORMATION)
        Case 25 ; �����/����
          If IsThread(Thread) Or Run=#True ; ���� ��� �������
            DisableGadget(25, #True)
            SetGadgetText(25, __("Stops..."))
            AddToLog(__("Bot stops. Please wait..."), #False)
            Run = #False ; �������������
          Else ; ���� �� �������
            Thread = CreateThread(@StartBtceBot(), #Null) ; �� ���������
          EndIf
      EndSelect
    Case #PB_Event_CloseWindow ; �������� ��������� ����
      If IsThread(Thread) Or Run=#True ; ���� ��� �������
        If Exit = #False
          If MessageRequester(__("Question"), __("Stop bot and exit?"), #MB_ICONQUESTION|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes
            DisableGadget(25, #True)
            SetGadgetText(25, __("Stops..."))
            AddToLog(__("Bot stops. Please wait..."), #False)
            Run = #False ; �������������
            Exit = #True
          EndIf
        Else
          MessageRequester(__("Information"), __("Please wait until stop the bot!"), #MB_ICONINFORMATION)
        EndIf
      Else ; ���� ��� �� �������
        Exit = #True ; ��������� ���������
      EndIf
  EndSelect
Until (Exit = #True And Run=#False And Not IsThread(Thread))

; ����������� �������
curl_global_cleanup()
Translator_destroy()

End

;- �������� �������
DataSection
  HelpIcon: IncludeBinary "inc/help.png"
  ConfIcon: IncludeBinary "inc/conf.png"
EndDataSection

; IDE Options = PureBasic 5.11 (Windows - x86)
; EnableThread
; EnableXP
; UseIcon = inc/icon.ico
; Executable = btce_bot.exe
; EnableCompileCount = 1
; EnableBuildCount = 1
; IncludeVersionInfo
; VersionField0 = 1.4.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.4.%BUILDCOUNT.%COMPILECOUNT
; VersionField2 = PROAPI.RU
; VersionField3 = BTC-E BOT
; VersionField4 = 1.4.%BUILDCOUNT.%COMPILECOUNT
; VersionField5 = 1.4.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = BTC-E BOT
; VersionField7 = btce_bot
; VersionField8 = btce_bot.exe
; VersionField9 = � PROAPI.RU, 2013
; VersionField14 = http://proapi.ru/btce_bot/
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
; VersionField17 = 0409 English (United States)
; VersionField18 = BTC
; VersionField19 = LTC
; VersionField21 = 1EPN3YTsfxPrJ8sfoGHLi2mt73Ex4xEwvk
; VersionField22 = LYXZmq6hXa79KytU3bdrZZNJ93QV9uLqsT
