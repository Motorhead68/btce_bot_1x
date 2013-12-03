; BTC-E BOT (version 1.4.x.x)
; Author: explode48 (explode48@gmail.com)
; ULR: http://proapi.ru/btce_bot/
; License: GNU General Public License v2


; Official library documentation:
; http://www.slavasoft.com/quickhash/help-online/index.html

;- Imports
Import "inc/QuickHash.lib"
  SL_HMAC_CalculateHex(nAlgID, *pDest, *pSrc, nSrcLength, *pKey, nKeyLength, bUpper)
EndImport

;- Procedures
Procedure.s HMAC_SHA512(Message.s, Key.s)
  *Hash = AllocateMemory(129)
  SL_HMAC_CalculateHex(3, *Hash, @Message, Len(Message), @Key, Len(Key), 0)
  Result.s = PeekS(*Hash)
  FreeMemory(*Hash)
  ProcedureReturn Result
EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; UseMainFile = ..\main.pb
