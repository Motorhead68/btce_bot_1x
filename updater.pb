; BTC-E BOT (version 1.2.x.x)
; Author: explode48 (explode48@gmail.com)
; ULR: http://proapi.ru/btce_bot/
; License: GNU General Public License v2


If CountProgramParameters()>0
  ; Получаем путь до каталога, куда установлен бот
  BotPath.s = ProgramParameter(0)
  ; Получаем параметры, с которыми был запущен бот
  BotParam.s = ProgramParameter(1)
  BotParam = ReplaceString(BotParam, Chr(39), Chr(34))
  ; Даем боту закрыться
  Delay(1000)
  ; Просмотриваем все файлы в папке с апдейтером
  If ExamineDirectory(0, GetPathPart(ProgramFilename()), "")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        FileName.s = DirectoryEntryName(0)
        If FileName<>"updater.exe"
          CopyFile(GetPathPart(ProgramFilename())+FileName, BotPath+FileName)
          DeleteFile(GetPathPart(ProgramFilename())+FileName)
        EndIf
      EndIf
    Wend
    FinishDirectory(0)
    MessageRequester("Information", "Update was successful!", #MB_ICONINFORMATION)
    RunProgram(BotPath+"btce_bot.exe", BotParam, BotPath)
  Else
    MessageRequester("Error", "An error occurred while installing the update!", #MB_ICONERROR)
  EndIf
Else
  MessageRequester("Warning", "Incorrect launch parameters!", #MB_ICONWARNING)
EndIf
End

; IDE Options = PureBasic 5.11 (Windows - x86)
; EnableXP
; UseIcon = icons\updater\icon.ico
; Executable = updater.exe
; EnableCompileCount = 19
; EnableBuildCount = 7
; IncludeVersionInfo
; VersionField0 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField2 = PROAPI.RU
; VersionField3 = BTC-E BOT
; VersionField4 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField5 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = BTC-E BOT Updater
; VersionField7 = updater
; VersionField8 = updater.exe
; VersionField9 = © PROAPI.RU, 2013
; VersionField14 = http://proapi.ru/btce_bot
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
; VersionField17 = 0409 English (United States)
; VersionField18 = BTC
; VersionField19 = LTC
; VersionField21 = 17dhqFobsbr8Fraj4d2c5D4VB1uqf58DMK
; VersionField22 = LRoS6D2X5sk3LcDq2o4PX6awpXYpEZt3Qk
