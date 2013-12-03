; BTC-E BOT (version 1.4.x.x)
; Author: explode48 (explode48@gmail.com)
; ULR: http://proapi.ru/btce_bot/
; License: GNU General Public License v2


; Official library documentation:
; http://curl.haxx.se/libcurl/

;- Constants
#CURL_GLOBAL_ALL    = $00000003
#CURLOPT_TIMEOUT        = 00013
#CURLOPT_HEADER         = 00042
#CURLOPT_POST           = 00047
#CURLOPT_SSL_VERIFYPEER = 00064
#CURLOPT_SSL_VERIFYHOST = 00081
#CURLOPT_URL            = 10002
#CURLOPT_PROXY          = 10004
#CURLOPT_PROXYUSERPWD   = 10006
#CURLOPT_POSTFIELDS     = 10015
#CURLOPT_HTTPHEADER     = 10023
#CURLOPT_WRITEFUNCTION  = 20011

;- Structures
Structure Curl_Slist
  *Data
  *Next_.curl_slist
EndStructure

;- Imports
ImportC "inc/libcurl.lib"
	curl_easy_cleanup(handle.l) As "_curl_easy_cleanup"
	curl_easy_init() As "_curl_easy_init"
	curl_easy_perform(handle.l) As "_curl_easy_perform"
	curl_easy_setopt(handle.l, option.l, parameter.l) As "_curl_easy_setopt"
	curl_global_cleanup() As "_curl_global_cleanup"
	curl_global_init(flags.l) As "_curl_global_init"
	curl_slist_append(slist.l, string.p-utf8) As "_curl_slist_append"
	curl_slist_free_all(slist.l) As "_curl_slist_free_all"
EndImport

;- Procedures
ProcedureC  RW_LibCurl_WriteFunction(*ptr, Size, NMemB, *Stream)
  Protected SizeProper.l  = Size & 255
  Protected NMemBProper.l = NMemB
  Protected MyDataS.s
  Shared ReceivedData.s
  MyDataS = PeekS(*ptr, SizeProper * NMemBProper)
  ReceivedData + MyDataS
  ProcedureReturn SizeProper * NMemBProper
EndProcedure

Procedure.s RW_LibCurl_GetData()
  Shared ReceivedData.s
  ProcedureReturn ReceivedData
EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; UseMainFile = ..\main.pb
