; BTC-E BOT (version 1.2.x.x)
; Author: explode48 (explode48@gmail.com)
; ULR: http://proapi.ru/btce_bot/
; License: GNU General Public License v2


PROGRAM_FILENAME$ = ProgramFilename()
PROGRAM_VERSION$ = GetFileVersion(PROGRAM_FILENAME$, #GFVI_FileVersion, 0) ; Compiler -> Compiler Options... -> Version Info

SetCurrentDirectory(GetPathPart(PROGRAM_FILENAME$)) ; ������������� ���� �� ������� �����������

Global Exit.b = #False
Structure CFG
  file.s      ; ���� ��������
  curpair.s   ; �������� ����
  mins.d      ; ����������� ����� ������ �� �������
  minb.d      ; ����������� ����� ������ �� �������
  maxs.d      ; ������������ ����� ������ �� �������
  maxb.d      ; ������������ ����� ������ �� �������
  diff.d      ; ������� ����� ��������/��������
  bttl.l      ; ����� ����� ������� �� ������� (���, 0 - ����)
  delay.l     ; �������� � �������� ����� (���)
  verb.b      ; ����� ������������ ������
  logf.s      ; ��������� ��� � ����
  update.b    ; �������� ����������
EndStructure
Global Configs.CFG

; ��������� ���� ������
Procedure.b IfNewVersion(NewVersion.s, OldVersion.s)
  If (Val(StringField(NewVersion, 1, "."))>Val(StringField(OldVersion, 1, "."))) Or ((Val(StringField(NewVersion, 1, "."))=Val(StringField(OldVersion, 1, "."))) And (Val(StringField(NewVersion, 2, "."))>Val(StringField(OldVersion, 2, ".")))) Or ((Val(StringField(NewVersion, 1, "."))=Val(StringField(OldVersion, 1, "."))) And (Val(StringField(NewVersion, 2, "."))=Val(StringField(OldVersion, 2, "."))) And (Val(StringField(NewVersion, 3, "."))>Val(StringField(OldVersion, 3, ".")))) Or ((Val(StringField(NewVersion, 1, "."))=Val(StringField(OldVersion, 1, "."))) And (Val(StringField(NewVersion, 2, "."))=Val(StringField(OldVersion, 2, "."))) And (Val(StringField(NewVersion, 3, "."))=Val(StringField(OldVersion, 3, "."))) And (Val(StringField(NewVersion, 4, "."))>Val(StringField(OldVersion, 4, "."))))
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf
EndProcedure

; ������ StrD(), ������ ��� ����������
Procedure.s Double2String(value.d, nb.l)
  If nb<0 : nb = 0 : EndIf
  result.s = StrD(value, nb+1)
  If nb>0 : dLeft = 1 : Else : dLeft = 2 :EndIf
  result = Left(result, Len(result)-dLeft)
  ProcedureReturn result
EndProcedure

; ������� ������ � ��������� � ���������
Procedure.s GetNormalSize(Size.l)
  result.s = ""
  If Size<1024
    result = Str(Size)+" Bytes"
  ElseIf Size>=1024 And Size<1048576
    result = Str(Round(Size/1024, #PB_Round_Nearest))+" Kb"
  Else
    result = StrF(Size/1048576, 2)+" Mb"
  EndIf
  ProcedureReturn result
EndProcedure

; ���������� �������������� ����������
XIncludeFile "inc/quickhash/QuickHash.pbi"    ; QuickHash library (HMAC-SHA512)
XIncludeFile "inc/libcurl/RW_LibCurl_Inc.pbi" ; LibCurl (������ � �����)
XIncludeFile "inc/json/json.pbi"              ; JSON
XIncludeFile "inc/btce/btce_api.pbi"          ; API ��� btc-e.com
XIncludeFile "inc/console/console.pbi" ; ������ � ��������

;- ������������� �������
OpenConsoleEx() ; ��������� �������
ClearConsoleEx() ; ������� �������
ConsoleCursorEx(0) ; �������� ������
ConsoleTitleEx("BTC-E BOT (version "+PROGRAM_VERSION$+")") ; ������������� ���������
ConsoleText("=============================================")
ConsoleText("=="+Space(Round((21-Len(PROGRAM_VERSION$))/2, #PB_Round_Down))+"BTC-E BOT (version "+PROGRAM_VERSION$+")"+Space(Round((21-Len(PROGRAM_VERSION$))/2, #PB_Round_Up))+"==")
ConsoleText("== URL: http://proapi.ru/btce_bot          ==")
ConsoleText("== BTC: 1EPN3YTsfxPrJ8sfoGHLi2mt73Ex4xEwvk ==")
ConsoleText("== LTC: LYXZmq6hXa79KytU3bdrZZNJ93QV9uLqsT ==")
ConsoleText("=============================================")
ConsoleText("")

;- ��������� �� ���������
Configs\file      = "config.ini"
Configs\curpair   = "btc_usd"
Configs\mins      = 0.01
Configs\minb      = 0.01
Configs\maxs      = 0.01
Configs\maxb      = 0.01
Configs\diff      = 0.5
Configs\bttl      = 360
Configs\delay     = 60
Configs\verb      = #False
Configs\logf      = ""
Configs\update    = #True
BTCE_API\key = "XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX"
BTCE_API\secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
BTCE_API\nonce = Date()

;- ��������� �������� �� ��������� ������
For I=0 To CountProgramParameters()-1
  Select ProgramParameter(I)
    Case "-c", "--config" ; �������� ����
      Configs\file = ProgramParameter(I+1)
    Case "-h", "--help" ; ������
      ConsoleText(" Usage: btce_bot.exe [OPTIONS]")
      ConsoleText("")
      ConsoleText(" Options:")
      ConsoleText("  -c, --config <FILE>  - Use a specified configuration file.")
      ConsoleText("  -h, --help           - Display this help text and exit.")
      ConsoleText("")
      ConsoleText(" Attention! You use this software at your own risk. The developer is not")
      ConsoleText(" responsible for the financial and other damage caused as a result of using")
      ConsoleText(" this program.")
      ConsoleText("")
      ConsoleText("Press ENTER key to exit...")
      Repeat
        Delay(100)
      Until InkeyEx()= Chr(13)
      CloseConsoleEx()
      End
  EndSelect
Next I

;- ��������� �������� �� �����
InitConfig:
If OpenPreferences(Configs\file)
  PreferenceGroup("api")
  BTCE_API\key    = ReadPreferenceString("akey", BTCE_API\key)
  BTCE_API\secret = ReadPreferenceString("asec", BTCE_API\secret)
  PreferenceGroup("bot")
  Configs\curpair = ReadPreferenceString("curpair", Configs\curpair)
  Configs\mins    = ReadPreferenceDouble("mins", Configs\mins)
  Configs\minb    = ReadPreferenceDouble("minb", Configs\minb)
  Configs\maxs    = ReadPreferenceDouble("maxs", Configs\maxs)
  Configs\maxb    = ReadPreferenceDouble("maxb", Configs\maxb)
  Configs\diff    = ReadPreferenceDouble("diff", Configs\diff)
  Configs\bttl    = ReadPreferenceLong("bttl", Configs\bttl)
  Configs\delay   = ReadPreferenceLong("delay", Configs\delay)
  Configs\verb    = ReadPreferenceLong("verb", Configs\verb)
  Configs\update  = ReadPreferenceLong("update", Configs\update)
  Configs\logf    = ReadPreferenceString("logf", Configs\logf)
  ClosePreferences()
ElseIf CreatePreferences(Configs\file)
  PreferenceGroup("api")
  WritePreferenceString("akey", BTCE_API\key)
  WritePreferenceString("asec", BTCE_API\secret)
  PreferenceGroup("bot")
  WritePreferenceString("curpair", Configs\curpair)
  WritePreferenceDouble("mins", Configs\mins)
  WritePreferenceDouble("minb", Configs\minb)
  WritePreferenceDouble("maxs", Configs\maxs)
  WritePreferenceDouble("maxb", Configs\maxb)
  WritePreferenceDouble("diff", Configs\diff)
  WritePreferenceLong("bttl", Configs\bttl)
  WritePreferenceLong("delay", Configs\delay)
  WritePreferenceLong("verb", Configs\verb)
  WritePreferenceLong("update", Configs\update)
  WritePreferenceString("logf", Configs\logf)
  ClosePreferences()
  Goto InitConfig
EndIf

; ����� �� ����� ������� ���������� ������
NewList PendingOrders.trce_trade3()

; ��������� ����
If Configs\verb = #True : VERB$ = " [VERB]" : Else : VERB$ = "" : EndIf
ConsoleText("> [CURPAIR: "+UCase(StringField(Configs\curpair, 1, "_"))+"/"+UCase(StringField(Configs\curpair, 2, "_"))+"] [DIFF: "+Double2String(Configs\diff, 2)+"] [DELAY: "+Str(Configs\delay)+"]"+VERB$)
ConsoleText("> [MINS: "+Double2String(Configs\mins, 2)+"] [MINB: "+Double2String(Configs\minb, 2)+"] [MAXS: "+Double2String(Configs\maxs, 2)+"] [MAXB: "+Double2String(Configs\maxb, 2)+"]")
ConsoleText("> [AKEY: "+BTCE_API\key+"]")
ConsoleText("> [ASEC: "+BTCE_API\secret+"]")

ConsoleText("")
ConsoleDateText("BTC-E BOT is running.", #False)

;- ��������� �� ����� ����� ����������
If FileSize(GetTemporaryDirectory()+"btce_bot_update\")=-2 And FileSize(GetTemporaryDirectory()+"btce_bot_update\updater.exe")>0 ; ���� ���������� ������ ��� �����������
  If DeleteDirectory(GetTemporaryDirectory()+"btce_bot_update\", "", #PB_FileSystem_Recursive|#PB_FileSystem_Force)
    ConsoleDateText("Update was successful!", #False)
  EndIf
EndIf  

;- �������� ����������
If Configs\update=#True ; ���� �������� ���������� �������� � ����������
  ConsoleDateText("Check for program updates...", #False)
  UpdateInProgress.b = #False
  hCurl = curl_easy_init() : UData$ = ""

  If hCurl
    UUrl$ = "http://update.proapi.ru/btce_bot/latest.php?v="+PROGRAM_VERSION$
    curl_easy_setopt(hCurl, #CURLOPT_URL, @UUrl$)
    curl_easy_setopt(hCurl, #CURLOPT_HEADER, #False)
    curl_easy_setopt(hCurl, #CURLOPT_TIMEOUT, 30)
    curl_easy_setopt(hCurl, #CURLOPT_WRITEFUNCTION, @RW_LibCurl_WriteFunction())
    curl_easy_perform(hCurl)
    UData$ = RW_LibCurl_GetData()
    ReceivedData = ""
    curl_easy_cleanup(hCurl)
  EndIf
  UData$ = Trim(UData$)
  If UData$<>""
    UInfo$ = StringField(UData$, 1, Chr(13)+Chr(10)) ; ������ ������ ������ �� �����
    UInfo$ = Trim(UInfo$)
    ; ������ ��
    UVers$    = StringField(UInfo$, 1, ":")      ; ����� ����� ������
    UVers$    = Right(UVers$, Len(UVers$)-1)
    USize.l   = Val(StringField(UInfo$, 2, ":")) ; ������
    UCrs$     = StringField(UInfo$, 3, ":")      ; ����������� �����
    UCrs$     = Left(UCrs$, Len(UCrs$)-1)
    UDesc$ = ""                                  ; �������� ����������
    For i=2 To CountString(UData$, Chr(13)+Chr(10))
      UDesc$ + StringField(UData$, i, Chr(13)+Chr(10))+Chr(10)
    Next i
    UDesc$ = Trim(UDesc$)
    If IfNewVersion(UVers$, PROGRAM_VERSION$) ; ���� ������ ������ �������
      ConsoleDateText("New version, v"+UVers$+", is available.", #False)
      If UDesc$<>""
        ConsoleDateText("Changes:", #False)
        For i=1 To CountString(UDesc$, Chr(10))
          ConsoleDateText(Chr(9)+StringField(UDesc$, i, Chr(10)), #False)
        Next i
      EndIf
      UpdateConfirm:
      SetConsoleCtrlHandler_(#Null, #True)
      ConsoleDateText("Install this update? (Yes or No):", #False)
      ConsoleLocateEx(57, GetCursorY()-1)
      InputText$ = InputEx()
      If UCase(InputText$)="YES"
        PrintNEx("")
        ConsoleDateText("Download the updates (size "+GetNormalSize(USize)+"), please wait...", #False)
        InitNetwork()
        If ReceiveHTTPFile("http://update.proapi.ru/btce_bot/latest.zip", GetTemporaryDirectory()+"btce_bot_update.dat")
          ; �������� CRC
          If LCase(Right(Hex(CRC32FileFingerprint(GetTemporaryDirectory()+"btce_bot_update.dat")), Len(UCrs$)))=UCrs$
            ConsoleDateText("All files are uploaded. Update in progress...", #False)
            If PureZIP_Archive_Read(GetTemporaryDirectory()+"btce_bot_update.dat") ; ��������� ����� � �����������
              ; ������������� ��� �� ��������� �����.
              CreateDirectory(GetTemporaryDirectory()+"btce_bot_update")
              UpdateUnzip.l = PureZIP_Archive_FindFirst()
              While UpdateUnzip = #UNZ_OK 
                PureZIP_Archive_Extract(GetTemporaryDirectory()+"btce_bot_update\", #True)
                UpdateUnzip.l = PureZIP_Archive_FindNext()
              Wend
              PureZIP_Archive_Close()
              ; �������� ����������
              If RunProgram(GetTemporaryDirectory()+"btce_bot_update\updater.exe", Chr(34)+GetPathPart(PROGRAM_FILENAME$)+Chr(34)+Chr(32)+Chr(34)+"-c "+Chr(39)+Configs\file+Chr(39)+Chr(34), GetTemporaryDirectory()+"btce_bot_update\")
                UpdateInProgress = #True
              Else
                ConsoleDateText("An error occurred while installing the update!", #False)
              EndIf
            Else
              ConsoleDateText("An error occurred while installing the update!", #False)
            EndIf
          Else
            ConsoleDateText("The downloaded files are corrupted. Update aborted!", #False)
          EndIf
          DeleteFile(GetTemporaryDirectory()+"btce_bot_update.dat")
        Else
          ConsoleDateText("An error occurred while downloading the update!", #False)
        EndIf
      ElseIf UCase(InputText$)="NO"
        PrintNEx("")
        ConsoleDateText("Installing the update has been canceled.", #False)
      Else
        PrintNEx("")
        Goto UpdateConfirm
      EndIf
    Else
      ConsoleDateText("You are using the latest version of the program.", #False)
    EndIf
  Else
    ConsoleDateText("Failed to check for program updates!", #False)
  EndIf
  If UpdateInProgress=#True
    ConsoleDateText("Closing the program to complete the update.", #False)
    curl_global_cleanup()
    CloseConsoleEx()
    End
  EndIf
EndIf

; ��������� ������� Ctrl+C
SetConsoleCtrlHandler_(#Null, #False)
SetConsoleCtrlHandler_(?ExitLabel, #True)

Repeat ; �������� ����
  ;- TODO: ����������� � ���������� �������
  ;- TODO: �������� �����������
  ;- �������� ����� ������ � �����
  ConsoleDateText("Receives new data from the stock exchange.", #True)
  If Not BTCE_OrderList() ; ������ �������� �������
    ConsoleDateText("`OrderList` method error ("+Exchange\OrderList\error+")!", #False)
  Else
    ConsoleDateText("`OrderList` method ok (there are no errors).", #True)
    ConsoleBalance()
  EndIf
  If Not BTCE_getInfo() ; �������� getInfo
    ConsoleDateText("`getInfo` method error ("+Exchange\getInfo\error+")!", #False)
  Else
    ConsoleDateText("`getInfo` method ok (there are no errors).", #True)
    ConsoleBalance()
  EndIf
  If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
    ConsoleDateText("`getTicker` method error ("+Exchange\getTicker\error+")!", #False)
  Else
    ConsoleDateText("`getTicker` method ok (there are no errors).", #True)
    ConsoleBalance()
  EndIf
  ConsoleDateText("The new data is received. Analyzing further action.", #True)
  ;- ��������� ����� �������
  If Exchange\getInfo\success = #True
    If Exchange\getInfo\rights\info=0 Or Exchange\getInfo\rights\trade=0
      ConsoleDateText("Not enough permissions for this API key!", #False)
      Break
    EndIf
  EndIf
  ;- TODO: ������ ������ �� ��������� �����
  ;- TODO: ������ diff ��� sell � buy
  ;- �������� ������� �� �������
  If getCurrentBalance(2)/(Exchange\getTicker\buy-Configs\diff) >= Configs\minb ; ���� ���-�� ������, ������� �� ����� ������ >= minb
    ;- TODO: ���������� Exchange\LastsOrders\sell_price � ���� ��� ��������� ���������� �������
    If Exchange\LastsOrders\sell_price-(Exchange\getTicker\buy-Configs\diff)>=Configs\diff/2 Or Exchange\LastsOrders\sell_price=0 ; ������ ���� ���� ������
      If getCurrentBalance(2)/(Exchange\getTicker\buy-Configs\diff) > Configs\maxb ; ���� ���-�� ������, ������� �� ����� ������ > maxb
        Amount.d = Configs\maxb
      Else
        Amount.d = getCurrentBalance(2)/(Exchange\getTicker\buy-Configs\diff)
      EndIf
      Error.s = BTCE_Trade(Configs\curpair, "buy", Exchange\getTicker\buy-Configs\diff, Amount) ; ������� �����
      If Error = "" ; ���� ����� ������
        ConsoleDateText("Created a new buy order ("+Double2String(Amount, 3)+" "+UCase(StringField(Configs\curpair, 1, "_"))+"/"+Double2String(Exchange\getTicker\buy-Configs\diff, 3)+" "+UCase(StringField(Configs\curpair, 2, "_"))+").", #False)
        ; �������� ����� ������ � �����
        ConsoleDateText("Receives new data from the stock exchange.", #True)
        If Not BTCE_OrderList() ; ������ �������� �������
          ConsoleDateText("`OrderList` method error ("+Exchange\OrderList\error+")!", #False)
        Else
          ConsoleDateText("`OrderList` method ok (there are no errors).", #True)
          ConsoleBalance()
        EndIf
        If Not BTCE_getInfo() ; �������� getInfo
          ConsoleDateText("`getInfo` method error ("+Exchange\getInfo\error+")!", #False)
        Else
          ConsoleDateText("`getInfo` method ok (there are no errors).", #True)
          ConsoleBalance()
        EndIf
        If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
          ConsoleDateText("`getTicker` method error ("+Exchange\getTicker\error+")!", #False)
        Else
          ConsoleDateText("`getTicker` method ok (there are no errors).", #True)
          ConsoleBalance()
        EndIf
        ConsoleDateText("The new data is received. Analyzing further action.", #True)
        ; �������� �� ����������� ����� �������
        If Exchange\LastsOrders\buy_amount < Configs\mins
          Exchange\LastsOrders\buy_amount = Configs\mins
        EndIf
        ; ���� � ��� ���� ������ ��� �������� ������ �� �������
        If getCurrentBalance(1) >= Exchange\LastsOrders\buy_amount
          If Exchange\LastsOrders\buy_amount > Configs\maxs ; ���� ���-�� ������, ������� �� ����� ������� > maxs
            Amount.d = Configs\maxs
          Else
            Amount.d = Exchange\LastsOrders\buy_amount
          EndIf
          Error.s = BTCE_Trade(Configs\curpair, "sell", Exchange\LastsOrders\buy_price+(Configs\diff*2), Amount) ; ������� �����
          If Error = "" ; ���� ����� ������
            ConsoleDateText("Created a new sell order ("+Double2String(Amount, 3)+" "+UCase(StringField(Configs\curpair, 1, "_"))+"/"+Double2String(Exchange\LastsOrders\buy_price+(Configs\diff*2), 3)+" "+UCase(StringField(Configs\curpair, 2, "_"))+").", #False)
            ; �������� ����� ������ � �����
            ConsoleDateText("Receives new data from the stock exchange.", #True)
            If Not BTCE_OrderList() ; ������ �������� �������
              ConsoleDateText("`OrderList` method error ("+Exchange\OrderList\error+")!", #False)
            Else
              ConsoleDateText("`OrderList` method ok (there are no errors).", #True)
              ConsoleBalance()
            EndIf
            If Not BTCE_getInfo() ; �������� getInfo
              ConsoleDateText("`getInfo` method error ("+Exchange\getInfo\error+")!", #False)
            Else
              ConsoleDateText("`getInfo` method ok (there are no errors).", #True)
              ConsoleBalance()
            EndIf
            ConsoleDateText("The new data is received. Analyzing further action.", #True)
          Else ; ���� �� ������� ������� �����
            ConsoleDateText("Error creating sell order ("+Error+")!", #False)
            ; ����������� �����
            AddElement(PendingOrders())
            PendingOrders()\price  = Exchange\LastsOrders\buy_price+(Configs\diff*2)
            PendingOrders()\amount = Amount
          EndIf
        Else ; ���� ������ ������� �� ������ �� �����
          ; ����������� �����
          AddElement(PendingOrders())
          PendingOrders()\price  = Exchange\LastsOrders\buy_price+(Configs\diff*2)
          PendingOrders()\amount = Exchange\LastsOrders\buy_amount
        EndIf
      Else ; ���� �� ������� ������� �����
        ConsoleDateText("Error creating buy order ("+Error+")!", #False)
      EndIf
    EndIf
  EndIf
  ;- ���������� ������ �� �������
  If ListSize(PendingOrders()) > 0
    ; �������� ����� ������ � �����
    ConsoleDateText("Receives new data from the stock exchange.", #True)
    If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
      ConsoleDateText("`getTicker` method error ("+Exchange\getTicker\error+")!", #False)
    Else
      ConsoleDateText("`getTicker` method ok (there are no errors).", #True)
      ConsoleBalance()
    EndIf
    ConsoleDateText("The new data is received. Analyzing further action.", #True)    
    PendingOrdersAmount.d = 0
    ResetList(PendingOrders())
    While NextElement(PendingOrders())
      If PendingOrders()\amount > Configs\maxs ; ���� ���-�� ������, ������� �� ����� ������� > maxs
        PendingOrders()\amount = Configs\maxs
      EndIf
      PendingOrdersAmount + PendingOrders()\amount
      ; ����  � ��� ���������� ������ ��� �������� ������
      If getCurrentBalance(1) >= PendingOrders()\amount
        Error.s = BTCE_Trade(Configs\curpair, "sell", PendingOrders()\price, PendingOrders()\amount) ; ������� �����
        If Error = "" ; ���� ����� ������
          ConsoleDateText("Created a new sell order ("+Double2String(PendingOrders()\amount, 3)+" "+UCase(StringField(Configs\curpair, 1, "_"))+"/"+Double2String(PendingOrders()\price, 3)+" "+UCase(StringField(Configs\curpair, 2, "_"))+").", #False)
          PendingOrdersAmount - PendingOrders()\amount
          DeleteElement(PendingOrders()) ; ������� ��� �� ����������
          ; �������� ����� ������ � �����
          ConsoleDateText("Receives new data from the stock exchange.", #True)
          If Not BTCE_OrderList() ; ������ �������� �������
            ConsoleDateText("`OrderList` method error ("+Exchange\OrderList\error+")!", #False)
          Else
            ConsoleDateText("`OrderList` method ok (there are no errors).", #True)
            ConsoleBalance()
          EndIf
          If Not BTCE_getInfo() ; �������� getInfo
            ConsoleDateText("`getInfo` method error ("+Exchange\getInfo\error+")!", #False)
          Else
            ConsoleDateText("`getInfo` method ok (there are no errors).", #True)
            ConsoleBalance()
          EndIf
          If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
            ConsoleDateText("`getTicker` method error ("+Exchange\getTicker\error+")!", #False)
          Else
            ConsoleDateText("`getTicker` method ok (there are no errors).", #True)
            ConsoleBalance()
          EndIf
          ConsoleDateText("The new data is received. Analyzing further action.", #True)
        Else
          ConsoleDateText("Error creating sell order ("+Error+")!", #False)
        EndIf
      EndIf
    Wend
  EndIf
  ;- ��������� ������ �� �������
  If getCurrentBalance(1)-PendingOrdersAmount >= Configs\mins ; ���� ���� ��������� ������ ��� �������
    ; �������� ����� ������ � �����
    ConsoleDateText("Receives new data from the stock exchange.", #True)
    If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
      ConsoleDateText("`getTicker` method error ("+Exchange\getTicker\error+")!", #False)
    Else
      ConsoleDateText("`getTicker` method ok (there are no errors).", #True)
      ConsoleBalance()
    EndIf
    ConsoleDateText("The new data is received. Analyzing further action.", #True)
    If getCurrentBalance(1)-PendingOrdersAmount > Configs\maxs ; ���� ���-�� ������, ������� �� ����� ������� > maxs
      Amount.d = Configs\maxs
    Else
      Amount.d = getCurrentBalance(1)-PendingOrdersAmount
    EndIf
    Error.s = BTCE_Trade(Configs\curpair, "sell", Exchange\getTicker\sell+Configs\diff, Amount) ; ������� �����    
    If Error = "" ; ���� ����� ������
      ConsoleDateText("Created a new sell order ("+Double2String(Amount, 3)+" "+UCase(StringField(Configs\curpair, 1, "_"))+"/"+Double2String(Exchange\getTicker\sell+Configs\diff, 3)+" "+UCase(StringField(Configs\curpair, 2, "_"))+").", #False)
      ; �������� ����� ������ � �����
      ConsoleDateText("Receives new data from the stock exchange.", #True)
      If Not BTCE_OrderList() ; ������ �������� �������
        ConsoleDateText("`OrderList` method error ("+Exchange\OrderList\error+")!", #False)
      Else
        ConsoleDateText("`OrderList` method ok (there are no errors).", #True)
        ConsoleBalance()
      EndIf
      If Not BTCE_getInfo() ; �������� getInfo
        ConsoleDateText("`getInfo` method error ("+Exchange\getInfo\error+")!", #False)
      Else
        ConsoleDateText("`getInfo` method ok (there are no errors).", #True)
        ConsoleBalance()
      EndIf
      If Not BTCE_getTicker() ; �������� ������� ���������� � ��������� �����
        ConsoleDateText("`getTicker` method error ("+Exchange\getTicker\error+")!", #False)
      Else
        ConsoleDateText("`getTicker` method ok (there are no errors).", #True)
        ConsoleBalance()
      EndIf
      ConsoleDateText("The new data is received. Analyzing further action.", #True)
    Else
      ConsoleDateText("Error creating sell order ("+Error+")!", #False)
    EndIf
  EndIf
  ;- ������ BUY ������� � �������� TTL
  If Configs\bttl<>0
    ResetList(Exchange\OrderList\orders())
    While NextElement(Exchange\OrderList\orders())
      If Exchange\OrderList\orders()\type = "buy" And Exchange\OrderList\orders()\status = 0
        ;- FIXME: ������ ������ �� ����������� ����� ����� �������� ������
        If Exchange\getInfo\server_time - Exchange\OrderList\orders()\timestamp_created >= 60*Configs\bttl
          Error.s = BTCE_CancelOrder(Exchange\OrderList\orders()\id)
          If Error = "" ; ���� ����� �������
            ;- FIXME: ������ ������ �� �������, ������� � ��� ������
            ConsoleDateText("A buy order is successfully canceled (ID="+Str(Exchange\OrderList\orders()\id)+").", #False)
          Else
            ConsoleDateText("Error when canceling buy order ("+Error+")!", #False)
          EndIf
        EndIf
      EndIf
    Wend
    ; �������� ����� ������ � �����
    ConsoleDateText("Receives new data from the stock exchange.", #True)
    If Not BTCE_OrderList() ; ������ �������� �������
      ConsoleDateText("`OrderList` method error ("+Exchange\OrderList\error+")!", #False)
    Else
      ConsoleDateText("`OrderList` method ok (there are no errors).", #True)
      ConsoleBalance()
    EndIf
    If Not BTCE_getInfo() ; �������� getInfo
      ConsoleDateText("`getInfo` method error ("+Exchange\getInfo\error+")!", #False)
    Else
      ConsoleDateText("`getInfo` method ok (there are no errors).", #True)
      ConsoleBalance()
    EndIf
    ConsoleDateText("The new data is received. Analyzing further action.", #True)
  EndIf
  ;- ��������� ��������
  If Configs\delay>0 And Exit=#False
    ConsoleDateText("No more action. Wait for "+Str(Configs\delay)+" seconds...", #True)
    For i=0 To Configs\delay-1
      If Exit=#False
        Delay(1000)
      Else
        Break
      EndIf
    Next i
  EndIf
Until Exit = #True

ExitLabel:
SetConsoleCtrlHandler_(#Null, #True)

;- ������ ������� �� �������
If Exchange\getInfo\rights\info=1 Or Exchange\getInfo\rights\trade=1
  ConsoleDateText("Cancel all buy orders...", #False)
  ; �������� ������ �������� �������
  If Not BTCE_OrderList() ; �������� OrderList
    ConsoleDateText("`OrderList` method error ("+Exchange\OrderList\error+")!", #False)
  Else
    ConsoleDateText("`OrderList` method ok (there are no errors).", #True)
  EndIf
  ; ���� ����� ��� ������ �� �������
  ResetList(Exchange\OrderList\orders())
  While NextElement(Exchange\OrderList\orders())
    If Exchange\OrderList\orders()\type = "buy" ; ���� ����� �� �������
      If Exchange\OrderList\orders()\status = 0 ; � �� ��� �� ��������
        Error.s = BTCE_CancelOrder(Exchange\OrderList\orders()\id)
        If Error = "" ; ���� ����� �������
          ConsoleDateText("A buy order is successfully canceled (ID="+Str(Exchange\OrderList\orders()\id)+").", #False)
        Else
          ConsoleDateText("Error when canceling buy order ("+Error+")!", #False)
        EndIf
      EndIf
    EndIf
  Wend
EndIf

ConsoleDateText("BTC-E BOT is stopped.", #False)
ConsoleLocateEx(0, GetCursorY()+2)
PrintNEx(LSet("", 79))
ConsoleLocateEx(0, GetCursorY()-1)
CloseConsoleEx()

; ����������� ������� CURL
curl_global_cleanup()

End

; IDE Options = PureBasic 5.11 (Windows - x86)
; ExecutableFormat = Console
; EnableThread
; EnableXP
; UseIcon = icons\btce_bot\icon.ico
; Executable = btce_bot.exe
; SubSystem = UserLibThreadSafe
; EnableCompileCount = 13
; EnableBuildCount = 8
; IncludeVersionInfo
; VersionField0 = 1.2.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.2.%BUILDCOUNT.%COMPILECOUNT
; VersionField2 = PROAPI.RU
; VersionField3 = BTC-E BOT
; VersionField4 = 1.2.%BUILDCOUNT.%COMPILECOUNT
; VersionField5 = 1.2.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = BTC-E BOT
; VersionField7 = btce_bot
; VersionField8 = btce_bot.exe
; VersionField9 = � PROAPI.RU, 2013
; VersionField14 = http://proapi.ru/btce_bot
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
; VersionField17 = 0409 English (United States)
; VersionField18 = BTC
; VersionField19 = LTC
; VersionField21 = 1EPN3YTsfxPrJ8sfoGHLi2mt73Ex4xEwvk
; VersionField22 = LYXZmq6hXa79KytU3bdrZZNJ93QV9uLqsT
