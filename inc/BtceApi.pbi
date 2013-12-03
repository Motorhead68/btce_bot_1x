; BTC-E BOT (version 1.4.x.x)
; Author: explode48 (explode48@gmail.com)
; ULR: http://proapi.ru/btce_bot/
; License: GNU General Public License v2


; Official API documentation:
; https://btc-e.com/api/documentation

curl_global_init(#CURL_GLOBAL_ALL)

; Initialization
Procedure.l BTCE_Init()
  ProcedureReturn curl_easy_init()
EndProcedure

; HTTP request to the server (Trade API)
Procedure.s BTCE_Qwery(hBtce, Parametres.s)
  Shared ReceivedData
  Result$ = ""
  If hBtce
    If Configs\proxy_host<>""
      curl_easy_setopt(hBtce, #CURLOPT_PROXY, @Configs\proxy_host)
      If Configs\proxy_login<>"" Or Configs\proxy_pass<>""
        proxy_account.s = Configs\proxy_login
        If Configs\proxy_pass<>"" : proxy_account+":"+Configs\proxy_pass : EndIf
        curl_easy_setopt(hBtce, #CURLOPT_PROXYUSERPWD, @proxy_account)
      EndIf
    EndIf
    curl_easy_setopt(hBtce, #CURLOPT_URL, @"https://btc-e.com/tapi")
    curl_easy_setopt(hBtce, #CURLOPT_SSL_VERIFYPEER, #False)
    curl_easy_setopt(hBtce, #CURLOPT_SSL_VERIFYHOST, #False)
    curl_easy_setopt(hBtce, #CURLOPT_POST, #True)
    curl_easy_setopt(hBtce, #CURLOPT_HEADER, #False)
    curl_easy_setopt(hBtce, #CURLOPT_TIMEOUT, 30)
    Parametres = Parametres + "&nonce="+Str(Configs\api_nonce)
    HeaderSList.curl_slist
    *HeaderSList = curl_slist_append(*HeaderSList, "Key: "+Configs\api_key)
    *HeaderSList = curl_slist_append(*HeaderSList, "Sign: "+HMAC_SHA512(Parametres, Configs\api_secret))
    curl_easy_setopt(hBtce, #CURLOPT_HTTPHEADER, *HeaderSList)
    curl_easy_setopt(hBtce, #CURLOPT_POSTFIELDS, @Parametres)
    curl_easy_setopt(hBtce, #CURLOPT_WRITEFUNCTION, @RW_LibCurl_WriteFunction())
    curl_easy_perform(hBtce)
    Result$ = RW_LibCurl_GetData()
    curl_slist_free_all(*HeaderSList)
    Configs\api_nonce + 1
    ReceivedData = ""
  EndIf
  Result$ = Trim(Result$)
  ProcedureReturn Result$
EndProcedure

; HTTP request to the server (Public API)
Procedure.s BTCE_QweryPublic(hBtce, Adress.s)
  Shared ReceivedData
  Result$ = ""
  If hBtce
    If Configs\proxy_host<>""
      curl_easy_setopt(hBtce, #CURLOPT_PROXY, @Configs\proxy_host)
      If Configs\proxy_login<>"" Or Configs\proxy_pass<>""
        proxy_account.s = Configs\proxy_login
        If Configs\proxy_pass<>"" : proxy_account+":"+Configs\proxy_pass : EndIf
        curl_easy_setopt(hBtce, #CURLOPT_PROXYUSERPWD, @proxy_account)
      EndIf
    EndIf
    curl_easy_setopt(hBtce, #CURLOPT_URL, @Adress)
    curl_easy_setopt(hBtce, #CURLOPT_SSL_VERIFYPEER, #False)
    curl_easy_setopt(hBtce, #CURLOPT_SSL_VERIFYHOST, #False)
    curl_easy_setopt(hBtce, #CURLOPT_HEADER, #False)
    curl_easy_setopt(hBtce, #CURLOPT_TIMEOUT, 30)
    curl_easy_setopt(hBtce, #CURLOPT_WRITEFUNCTION, @RW_LibCurl_WriteFunction())
    curl_easy_perform(hBtce)
    Result$ = RW_LibCurl_GetData()
    ReceivedData = ""
  EndIf
  Result$ = Trim(Result$)
  ProcedureReturn Result$
EndProcedure

; Free cURL resources
Procedure.l BTCE_Free(hBtce)
  curl_easy_cleanup(hBtce)
EndProcedure

; Information of the balance
Structure btce_funds
  usd.d
  rur.d
  eur.d
  btc.d
  ltc.d
  nmc.d
  nvc.d
  trc.d
  ppc.d
EndStructure

; Permissions
Structure btce_rights
  info.b
  trade.b
  withdraw.b
EndStructure

; For getInfo method
Structure btce_info
  success.b
  error.s
  funds.btce_funds
  rights.btce_rights
  transaction_count.l
  open_orders.l
  server_time.l
EndStructure

; Information about the transaction
Structure btce_trans
  id.l
  type.b
  amount.d
  currency.s
  desc.s
  status.b
  timestamp.l
EndStructure

; Transaction data
Structure btce_trade
  id.l
  pair.s
  type.s
  amount.d
  rate.d
  order_id.l
  is_you_order.b
  timestamp.l
EndStructure

; Information about orders
Structure btce_order
  id.l
  pair.s
  type.s
  amount.d
  rate.d
  timestamp_created.l
  status.b
EndStructure

; Information on transactions
Structure btce_trade2
  date.l
  price.d
  amount.d
  tid.l
  price_currency.s
  item.s
  trade_type.s
EndStructure

; Available orders
Structure trce_trade3
  price.d
  amount.d
EndStructure

; For getFee method
Structure btce_fee
  success.b
  error.s
  value.d
EndStructure

; For getTicker method
Structure btce_ticker
  success.b
  error.s
  high.d
  low.d
  avg.d
  vol.d
  vol_cur.d
  last.d
  buy.d
  sell.d
  server_time.l
EndStructure

; For getTrades method
Structure btce_trades
  success.b
  error.s
  List trades.btce_trade2()
EndStructure

; For getTrades method
Structure btce_depth
  success.b
  error.s
  List asks.trce_trade3()
  List bids.trce_trade3()
EndStructure

; For TransHistory method
Structure btce_trans_history
  success.b
  error.s
  List history.btce_trans()
EndStructure

; For TradeHistory method
Structure btce_trade_history
  success.b
  error.s
  List history.btce_trade()
EndStructure

; For OrderList method
Structure btce_order_list
  success.b
  error.s
  List orders.btce_order()
EndStructure

; Information on recent orders created
Structure btce_lasts_orders
  sell_id.l
  sell_price.d
  sell_amount.d
  buy_id.l
  buy_price.d
  buy_amount.d
EndStructure

; Exchange information
Structure TradeInfo
  getFee.btce_fee
  getTicker.btce_ticker
  getTrades.btce_trades
  getDepth.btce_depth
  getInfo.btce_info
  TransHistory.btce_trans_history
  TradeHistory.btce_trade_history
  OrderList.btce_order_list
  LastsOrders.btce_lasts_orders
EndStructure
Global Exchange.TradeInfo

; getInfo method
Procedure BTCE_getInfo()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_Qwery(hBtce, "method=getInfo")
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("success")\i = 1
          Exchange\getInfo\success = #True
          Exchange\getInfo\error = ""
          Exchange\getInfo\funds\usd = *api_json\o("return")\o("funds")\o("usd")\f
          Exchange\getInfo\funds\rur = *api_json\o("return")\o("funds")\o("rur")\f
          Exchange\getInfo\funds\eur = *api_json\o("return")\o("funds")\o("eur")\f
          Exchange\getInfo\funds\btc = *api_json\o("return")\o("funds")\o("btc")\f
          Exchange\getInfo\funds\ltc = *api_json\o("return")\o("funds")\o("ltc")\f
          Exchange\getInfo\funds\nmc = *api_json\o("return")\o("funds")\o("nmc")\f
          Exchange\getInfo\funds\nvc = *api_json\o("return")\o("funds")\o("nvc")\f
          Exchange\getInfo\funds\trc = *api_json\o("return")\o("funds")\o("trc")\f
          Exchange\getInfo\funds\ppc = *api_json\o("return")\o("funds")\o("ppc")\f
          Exchange\getInfo\rights\info = *api_json\o("return")\o("rights")\o("info")\i
          Exchange\getInfo\rights\trade = *api_json\o("return")\o("rights")\o("trade")\i
          Exchange\getInfo\rights\withdraw = *api_json\o("return")\o("rights")\o("withdraw")\i
          Exchange\getInfo\transaction_count = *api_json\o("return")\o("transaction_count")\i
          ;Exchange\getInfo\open_orders = *api_json\o("return")\o("open_orders")\i
          Exchange\getInfo\open_orders = ListSize(Exchange\OrderList\orders())
          Exchange\getInfo\server_time = *api_json\o("return")\o("server_time")\i
        Else
          Exchange\getInfo\success = #False
          Exchange\getInfo\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\getInfo\success = #False
        Exchange\getInfo\error = "bad server response"
      EndIf
    Else
      Exchange\getInfo\success = #False
      Exchange\getInfo\error = "empty server response"
    EndIf
  Else
    Exchange\getInfo\success = #False
    Exchange\getInfo\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\getInfo\success
EndProcedure

; TransHistory method
Procedure BTCE_TransHistory()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_Qwery(hBtce, "method=TransHistory")
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("success")\i = 1
          Exchange\TransHistory\success = #True
          Exchange\TransHistory\error = ""
          ClearList(Exchange\TransHistory\history())
          ResetMap(*api_json\o("return")\o())
          While NextMapElement(*api_json\o("return")\o())
            If UCase(*api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("currency")\s)=UCase(StringField(Configs\bot_curpair, 1, "_")) Or UCase(*api_json\o("Return")\o(MapKey(*api_json\o("Return")\o()))\o("currency")\s)=UCase(StringField(Configs\bot_curpair, 2, "_"))
              AddElement(Exchange\TransHistory\history())
              Exchange\TransHistory\history()\id = Val(MapKey(*api_json\o("return")\o()))
              Exchange\TransHistory\history()\type = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("type")\i
              Exchange\TransHistory\history()\amount = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("amount")\f
              Exchange\TransHistory\history()\currency = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("currency")\s
              Exchange\TransHistory\history()\desc = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("desc")\s
              Exchange\TransHistory\history()\status = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("status")\i
              Exchange\TransHistory\history()\timestamp = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("timestamp")\i
            EndIf
          Wend
        Else
          Exchange\TransHistory\success = #False
          Exchange\TransHistory\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\TransHistory\success = #False
        Exchange\TransHistory\error = "bad server response"
      EndIf
    Else
      Exchange\TransHistory\success = #False
      Exchange\TransHistory\error = "empty server response"
    EndIf
  Else
    Exchange\TransHistory\success = #False
    Exchange\TransHistory\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\TransHistory\success
EndProcedure

; TradeHistory method
Procedure BTCE_TradeHistory()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_Qwery(hBtce, "method=TradeHistory&pair="+Configs\bot_curpair)
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("success")\i = 1
          Exchange\TradeHistory\success = #True
          Exchange\TradeHistory\error = ""
          ClearList(Exchange\TradeHistory\history())
          ResetMap(*api_json\o("return")\o())
          While NextMapElement(*api_json\o("return")\o())
            AddElement(Exchange\TradeHistory\history())
            Exchange\TradeHistory\history()\id = Val(MapKey(*api_json\o("return")\o()))
            Exchange\TradeHistory\history()\pair = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("pair")\s
            Exchange\TradeHistory\history()\type = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("type")\s
            Exchange\TradeHistory\history()\amount = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("amount")\f
            Exchange\TradeHistory\history()\rate = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("rate")\f
            Exchange\TradeHistory\history()\order_id = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("order_id")\i
            Exchange\TradeHistory\history()\is_you_order = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("is_you_order")\i
            Exchange\TradeHistory\history()\timestamp = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("timestamp")\i
          Wend
        Else
          Exchange\TradeHistory\success = #False
          Exchange\TradeHistory\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\TradeHistory\success = #False
        Exchange\TradeHistory\error = "bad server response"
      EndIf
    Else
      Exchange\TradeHistory\success = #False
      Exchange\TradeHistory\error = "empty server response"
    EndIf
  Else
    Exchange\TradeHistory\success = #False
    Exchange\TradeHistory\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\TradeHistory\success
EndProcedure

; ActiveOrders method (outdated OrderList)
Procedure BTCE_OrderList()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_Qwery(hBtce, "method=ActiveOrders&pair="+Configs\bot_curpair)
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("success")\i = 1
          Exchange\OrderList\success = #True
          Exchange\OrderList\error = ""
          ClearList(Exchange\OrderList\orders())
          ResetMap(*api_json\o("return")\o())
          While NextMapElement(*api_json\o("return")\o())
            AddElement(Exchange\OrderList\orders())
            Exchange\OrderList\orders()\id = Val(MapKey(*api_json\o("return")\o()))
            Exchange\OrderList\orders()\pair = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("pair")\s
            Exchange\OrderList\orders()\type = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("type")\s
            Exchange\OrderList\orders()\amount = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("amount")\f
            Exchange\OrderList\orders()\rate = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("rate")\f
            Exchange\OrderList\orders()\timestamp_created = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("timestamp_created")\i
            Exchange\OrderList\orders()\status = *api_json\o("return")\o(MapKey(*api_json\o("return")\o()))\o("status")\i
          Wend
        ElseIf *api_json\o("error")\s = "no orders"
          Exchange\OrderList\success = #True
          Exchange\OrderList\error = ""
          ClearList(Exchange\OrderList\orders())
        Else
          Exchange\OrderList\success = #False
          Exchange\OrderList\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\OrderList\success = #False
        Exchange\OrderList\error = "bad server response"
      EndIf
    Else
      Exchange\OrderList\success = #False
      Exchange\OrderList\error = "empty server response"
    EndIf
  Else
    Exchange\OrderList\success = #False
    Exchange\OrderList\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\OrderList\success
EndProcedure

Macro BTCE_ActiveOrders()
  BTCE_OrderList()
EndMacro

; Trade method
Procedure.s BTCE_Trade(pair.s, type.s, rate.d, amount.d)
  Error.s = ""
  hBtce = BTCE_Init()
  If hBtce
    ; Кол-во знаков после запятой
    nb1.l = 5 ; Для rate
    nb2.l = 8 ; Для amount
    ; Для некоторых пары кол-во знаков после запятой (только rate!) отличается
    Select pair
      Case "btc_usd" ; BTC/USD
        nb1 = 3
      Case "ltc_usd" ; LTC/USD
        nb1 = 6
      Case "ltc_eur" ; LTC/EUR
        nb1 = 3
      Case "nmc_usd" ; NMC/USD
        nb1 = 3
      Case "nvc_usd" ; NVC/USD
        nb1 = 3
    EndSelect
    api_data.s = BTCE_Qwery(hBtce, "method=Trade&pair="+pair+"&type="+type+"&rate="+Double2String(rate, nb1)+"&amount="+Double2String(amount, nb2))
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("success")\i = 0
          Error = *api_json\o("error")\s
        Else
          If LCase(type) = "buy"
            Exchange\LastsOrders\buy_id     = *api_json\o("return")\o("order_id")\i
            Exchange\LastsOrders\buy_price  = rate
            Exchange\LastsOrders\buy_amount = amount
          Else
            Exchange\LastsOrders\sell_id     = *api_json\o("return")\o("order_id")\i
            Exchange\LastsOrders\sell_price  = rate
            Exchange\LastsOrders\sell_amount = amount
          EndIf
        EndIf
        JSON_free(*api_json)
      Else
        Error = "bad server response"
      EndIf
    Else
      Error = "empty server response"
    EndIf
  Else
    Error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Error
EndProcedure

; CancelOrder method
Procedure.s BTCE_CancelOrder(order_id.l)
  Error.s = ""
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_Qwery(hBtce, "method=CancelOrder&order_id="+Str(order_id))
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("success")\i = 0
          Error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Error = "bad server response"
      EndIf
    Else
      Error = "empty server response"
    EndIf
  Else
    Error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Error
EndProcedure

; Get the size of the commission
Procedure BTCE_getFee()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_QweryPublic(hBtce, "https://btc-e.com/api/2/"+Configs\bot_curpair+"/fee")
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("error")\s = ""
          Exchange\getFee\success = #True
          Exchange\getFee\error = ""
          Exchange\getFee\value = *api_json\o("trade")\f
        Else
          Exchange\getFee\success = #False
          Exchange\getFee\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\getFee\success = #False
        Exchange\getFee\error = "bad server response"
      EndIf
    Else
      Exchange\getFee\success = #False
      Exchange\getFee\error = "empty server response"
    EndIf
  Else
    Exchange\getFee\success = #False
    Exchange\getFee\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\getFee\success
EndProcedure

; Get a summary of the state of the market
Procedure BTCE_getTicker()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_QweryPublic(hBtce, "https://btc-e.com/api/2/"+Configs\bot_curpair+"/ticker")
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("error")\s = ""
          Exchange\getTicker\success = #True
          Exchange\getTicker\error = ""
          Exchange\getTicker\high = *api_json\o("ticker")\o("high")\f
          Exchange\getTicker\low = *api_json\o("ticker")\o("low")\f
          Exchange\getTicker\avg = *api_json\o("ticker")\o("avg")\f
          Exchange\getTicker\vol = *api_json\o("ticker")\o("vol")\f
          Exchange\getTicker\vol_cur = *api_json\o("ticker")\o("vol_cur")\f
          Exchange\getTicker\last = *api_json\o("ticker")\o("last")\f
          Exchange\getTicker\buy = *api_json\o("ticker")\o("buy")\f
          Exchange\getTicker\sell = *api_json\o("ticker")\o("sell")\f
          Exchange\getTicker\server_time = *api_json\o("ticker")\o("server_time")\i
        Else
          Exchange\getFee\success = #False
          Exchange\getFee\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\getTicker\success = #False
        Exchange\getTicker\error = "bad server response"
      EndIf
    Else
      Exchange\getTicker\success = #False
      Exchange\getTicker\error = "empty server response"
    EndIf
  Else
    Exchange\getTicker\success = #False
    Exchange\getTicker\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\getTicker\success  
EndProcedure

; The history of all transactions
Procedure BTCE_getTrades()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_QweryPublic(hBtce, "https://btc-e.com/api/2/"+Configs\bot_curpair+"/trades")
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("error")\s = ""
          Exchange\getTrades\success = #True
          Exchange\getTrades\error = ""
          ClearList(Exchange\getTrades\trades())
          For I=0 To *api_json\length-1
            AddElement(Exchange\getTrades\trades())
            Exchange\getTrades\trades()\date = *api_json\a(I)\o("date")\i
            Exchange\getTrades\trades()\price = *api_json\a(I)\o("price")\f
            Exchange\getTrades\trades()\amount = *api_json\a(I)\o("amount")\f
            Exchange\getTrades\trades()\tid = *api_json\a(I)\o("tid")\i
            Exchange\getTrades\trades()\price_currency = *api_json\a(I)\o("price_currency")\s
            Exchange\getTrades\trades()\item = *api_json\a(I)\o("item")\s
            Exchange\getTrades\trades()\trade_type = *api_json\a(I)\o("trade_type")\s
          Next I
        Else
          Exchange\getTrades\success = #False
          Exchange\getTrades\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\getTrades\success = #False
        Exchange\getTrades\error = "bad server response"
      EndIf
    Else
      Exchange\getTrades\success = #False
      Exchange\getTrades\error = "empty server response"
    EndIf
  Else
    Exchange\getTrades\success = #False
    Exchange\getTrades\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\getTrades\success
EndProcedure

; Orders for sale/buy
Procedure BTCE_getDepth()
  hBtce = BTCE_Init()
  If hBtce
    api_data.s = BTCE_QweryPublic(hBtce, "https://btc-e.com/api/2/"+Configs\bot_curpair+"/depth")
    BTCE_Free(hBtce)
    If api_data
      *api_json.jsonObj = JSON_decode(api_data)
      If *api_json.jsonObj <> #False
        If *api_json\o("error")\s = ""
          Exchange\getDepth\success = #True
          Exchange\getDepth\error = ""
          ClearList(Exchange\getDepth\asks())
          For I=0 To *api_json\o("asks")\length-1
            AddElement(Exchange\getDepth\asks())
            Exchange\getDepth\asks()\price = *api_json\o("asks")\a(I)\a(0)\f
            Exchange\getDepth\asks()\amount = *api_json\o("asks")\a(I)\a(1)\f
          Next I
          ClearList(Exchange\getDepth\bids())
          For I=0 To *api_json\o("bids")\length-1
            AddElement(Exchange\getDepth\bids())
            Exchange\getDepth\bids()\price = *api_json\o("bids")\a(I)\a(0)\f
            Exchange\getDepth\bids()\amount = *api_json\o("bids")\a(I)\a(1)\f
          Next I
        Else
          Exchange\getDepth\success = #False
          Exchange\getDepth\error = *api_json\o("error")\s
        EndIf
        JSON_free(*api_json)
      Else
        Exchange\getDepth\success = #False
        Exchange\getDepth\error = "bad server response"
      EndIf
    Else
      Exchange\getDepth\success = #False
      Exchange\getDepth\error = "empty server response"
    EndIf
  Else
    Exchange\getDepth\success = #False
    Exchange\getDepth\error = "can`t init BTC-E API"
  EndIf
  ProcedureReturn Exchange\getDepth\success
EndProcedure

; Get balance
Procedure.d getCurrentBalance(Fund.b)
  Select LCase(StringField(Configs\bot_curpair, Fund, "_"))
    Case "usd"
      ProcedureReturn Exchange\getInfo\funds\usd
    Case "rur"
      ProcedureReturn Exchange\getInfo\funds\rur
    Case "eur"
      ProcedureReturn Exchange\getInfo\funds\eur
    Case "btc"
      ProcedureReturn Exchange\getInfo\funds\btc
    Case "ltc"
      ProcedureReturn Exchange\getInfo\funds\ltc
    Case "nmc"
      ProcedureReturn Exchange\getInfo\funds\nmc
    Case "nvc"
      ProcedureReturn Exchange\getInfo\funds\nvc
    Case "trc"
      ProcedureReturn Exchange\getInfo\funds\trc
    Case "ppc"
      ProcedureReturn Exchange\getInfo\funds\ppc
    Default
      ProcedureReturn 0
  EndSelect
EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; UseMainFile = ..\main.pb
