; JSON decoder & encoder for PureBasic v4.51+
; Version: 0.7.0 (from 17.07.2012)
; (c) 2011+2012 by PMV 


#JSON_DefaultMapSlots  = 10
#JSON_parseArraySteps  = 10
#JSON_StringBufferSize = 256

Threaded *json_string_buffer
Threaded *json_string_next
Threaded json_string_space.i

Declare.i JSON_parseObject(*c, *out, nullByte.i)
Structure jsonObj
  type.i
  CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant)
    Map *o.jsonObj(#JSON_DefaultMapSlots) 
  CompilerElse
    Map o.jsonObj(#JSON_DefaultMapSlots)
  CompilerEndIf
  Array *a.jsonObj(1)
  StructureUnion
    length.i
    i.i
  EndStructureUnion
  f.d
  s.s
EndStructure

Enumeration
  #JSON_Type_Undefined
  #JSON_Type_String
  #JSON_Type_Object
  #JSON_Type_Null
  #JSON_Type_True
  #JSON_Type_False
  #JSON_Type_Array
  #JSON_Type_Integer
  #JSON_Type_Float
EndEnumeration

Macro JSON_readChar(CHAR)
  Repeat
    If *c >= nullByte : ProcedureReturn #False : EndIf
    Select *c\c
      Case ' ', 9, 10, 13
        *c + SizeOf(CHARACTER)
      Case CHAR
        Break
      Default
        ProcedureReturn #False
    EndSelect
  ForEver
  *c + SizeOf(CHARACTER)
EndMacro

Macro JSON_readWhitespaces()
  While *c\c = ' ' Or *c\c = 9 Or *c\c = 10 Or *c\c = 13
    If *c >= nullByte : ProcedureReturn #False : EndIf
    *c + SizeOf(CHARACTER)
  Wend
EndMacro

Procedure.i JSON_getType(*obj.jsonObj)
  If *obj\type <> #JSON_Type_Undefined
    ProcedureReturn *obj\type
  EndIf 
  
CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant)
  If *obj\s
CompilerElse
  If MapSize(*obj\o())  
    ProcedureReturn #JSON_Type_Object
  ElseIf *obj\s
CompilerEndIf
    ProcedureReturn #JSON_Type_String
  ElseIf *obj\f
    ProcedureReturn #JSON_Type_Float
  Else
    ProcedureReturn #JSON_Type_Integer
  EndIf
EndProcedure

Procedure.s JSON_parseString(*c.CHARACTER, nullByte.i, *result.INTEGER)
  Protected i.i, hexDigit.s
  Protected string.s = ""  
  Repeat
    Select *c\c
      Case '"'
        Break
      Case '\'
        *c + SizeOf(CHARACTER)
        Select *c\c
          Case '"', '\', '/'
            string + PeekS(*c, 1)
          Case 'b'
            string + Chr(8)
          Case 'f'
            string + Chr(14)
          Case 'n'
            string + Chr(10)
          Case 'r'
            string + Chr(13)
          Case 't'
            string + Chr(9)
          Case 'u'
            If nullByte - *c > 4 * SizeOf(CHARACTER)
              hexDigit = "$"
              hexDigit + PeekS(*c, 4)
              *c + SizeOf(CHARACTER) * 4
              string + Chr(Val(hexDigit))
            Else
              *result\i = #False
              ProcedureReturn string
            EndIf
          Default
            *c - SizeOf(CHARACTER)
        EndSelect
      Default
        string + PeekS(*c, 1)
    EndSelect
    *c + SizeOf(CHARACTER)
    If *c >= nullByte
      *result\i = #False
      ProcedureReturn string
    EndIf
  ForEver
  *result\i =  *c + SizeOf(CHARACTER)
  ProcedureReturn string
EndProcedure

Procedure.i JSON_parseNumber(*c.CHARACTER, *out.jsonObj, nullByte)
  Protected string.s, e.s
  Protected *first = *c
  If LCase(PeekS(*c, 4)) = "null"
    *out\f = #Null
    *out\i = #Null
    *out\type = #JSON_Type_Null
    ProcedureReturn *c + SizeOf(CHARACTER) * 4
  ElseIf LCase(PeekS(*c, 5)) = "false"
    *out\f = #False
    *out\i = #False
    *out\type = #JSON_Type_False
    ProcedureReturn *c + SizeOf(CHARACTER) * 5
  ElseIf LCase(PeekS(*c, 4)) = "true"
    *out\f = #True
    *out\i = #True
    *out\type = #JSON_Type_True
    ProcedureReturn *c + SizeOf(CHARACTER) * 4
  EndIf
  If *c\c = '-' : *c + SizeOf(CHARACTER) : EndIf
  Repeat
    Select *c\c
      Case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'
      Case 'e', 'E'
        *c\c = 'e'
        *c + SizeOf(CHARACTER)
        If *c\c <> '-' And *c\c <> '+' : *c - SizeOf(CHARACTER) : EndIf
      Case ' ', 9, 10, 13, ',', ']', '}'
        Break
      Default
        ProcedureReturn #False
    EndSelect
    *c + SizeOf(CHARACTER)
    If *c >= nullByte : ProcedureReturn #False : EndIf
  ForEver
  string = PeekS(*first, (*c - *first) / SizeOf(CHARACTER))
  If FindString(string, ".", 1)
    *out\s = string
    *out\f = ValD(string)
    *out\i = *out\f
    *out\type = #JSON_Type_Float
  ElseIf FindString(string, "e", 1)
    *out\s = string
    e = StringField(string, 2, "e")
    string = StringField(string, 1, "e")
    *out\f = ValD(string) * Pow(10, Val(e))
    *out\i = *out\f
    *out\type = #JSON_Type_Float
  Else
    *out\i = Val(string)
    *out\f = *out\i
    *out\type = #JSON_Type_Integer
  EndIf
  ProcedureReturn *c
EndProcedure
  
Procedure.i JSON_parseArray(*c.CHARACTER, *out.jsonObj, nullByte.i)
  Protected string.s, i.i = 0, result.i
  Protected arrayLength.i = #JSON_parseArraySteps
  *out\type = #JSON_Type_Array
  JSON_readWhitespaces()
  If *c\c = ']' : ProcedureReturn *c + SizeOf(CHARACTER) : EndIf
  ReDim *out\a.jsonObj(arrayLength)
  Repeat
    *out\a(i) = AllocateMemory(SizeOf(jsonObj))
    Select *c\c
      Case '{'
        InitializeStructure(*out\a(i), jsonObj)
        result = JSON_parseObject(*c + SizeOf(CHARACTER), *out\a(i), nullByte)
      Case '['
        InitializeStructure(*out\a(i), jsonObj)
        result = JSON_parseArray(*c + SizeOf(CHARACTER), *out\a(i), nullByte)
      Case '"'
        string = JSON_parseString(*c + SizeOf(CHARACTER), nullByte, @result)
        *out\a(i)\s = string
        *out\a(i)\type = #JSON_Type_String
      Default
        result = JSON_parseNumber(*c, *out\a(i), nullByte)
    EndSelect
    If Not result : ProcedureReturn #False : EndIf
    *c = result
    JSON_readWhitespaces()
    If *c\c = ','
      i + 1
      If i > arrayLength
        arrayLength + #JSON_parseArraySteps
        ReDim *out\a.jsonObj(arrayLength)
      EndIf
      *c + SizeOf(CHARACTER)
      JSON_readWhitespaces() 
    ElseIf *c\c = ']'
      Break
    EndIf 
  ForEver
  ReDim *out\a.jsonObj(i)
  *out\length = i + 1
  ProcedureReturn *c + SizeOf(CHARACTER)
EndProcedure

Procedure.i JSON_parseObject(*c.CHARACTER, *out.jsonObj, nullByte.i)
  Protected result.i, string.s, key.s
  *out\type = #JSON_Type_Object
  JSON_readWhitespaces()
  If *c\c = '}' : ProcedureReturn *c + SizeOf(CHARACTER) : EndIf
  Repeat
    If *c\c <> '"' : ProcedureReturn #False : EndIf
    *c + SizeOf(CHARACTER)
    key = JSON_parseString(*c, nullByte, @result)
    If Not result : ProcedureReturn #False : EndIf
    *c = result
    JSON_readChar(':')
    JSON_readWhitespaces()
    *out\o(key) 
    CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant)
      *out\o() = AllocateMemory(SizeOf(jsonObj))
    CompilerEndIf
    Select *c\c
      Case '{'
        CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant)
          InitializeStructure(*out\o(), jsonObj)
        CompilerEndIf
        result = JSON_parseObject(*c + SizeOf(CHARACTER), *out\o(), nullByte)
      Case '['
        CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant)
          InitializeStructure(*out\o(), jsonObj)
        CompilerEndIf
        result = JSON_parseArray(*c + SizeOf(CHARACTER), *out\o(), nullByte)
      Case '"'
        string = JSON_parseString(*c + SizeOf(CHARACTER), nullByte, @result)
        *out\o(key)\s = string
        *out\o()\type = #JSON_Type_String
      Default
        result = JSON_parseNumber(*c, *out\o(), nullByte)
    EndSelect
    If Not result : ProcedureReturn #False : EndIf
    *c = result
    JSON_readWhitespaces()
    If *c\c = ','
      *c + SizeOf(CHARACTER)
      JSON_readWhitespaces() 
    ElseIf *c\c = '}'
      Break
    EndIf
    If *c\c = '}' : ProcedureReturn #False : EndIf
  ForEver
  ProcedureReturn *c + SizeOf(CHARACTER)
EndProcedure

Procedure JSON_addString(string.s)
  Protected size.i = StringByteLength(string)
  Protected used.i = *json_string_next - *json_string_buffer
  While json_string_space - used <= size
    json_string_space = json_string_space * 2
    *json_string_buffer = ReAllocateMemory(*json_string_buffer, json_string_space)
    *json_string_next = *json_string_buffer + used
  Wend
  CopyMemoryString(@string, @*json_string_next)
EndProcedure

;- Public functions

Procedure JSON_freeStringBuffer()
  *json_string_buffer = FreeMemory(*json_string_buffer)
  *json_string_next = #Null
  *json_string_buffer = #Null
EndProcedure

Procedure.i JSON_decode(inpString.s)
  inpString = Trim(inpString)
  Protected *c.CHARACTER = @inpString
  Protected result.i
  Protected *out.jsonObj = AllocateMemory(SizeOf(jsonObj))
  InitializeStructure(*out, jsonObj)
  If *c\c = '{'
    *c + SizeOf(CHARACTER)
    result = JSON_parseObject(*c, *out, @inpString + StringByteLength(inpString))
  ElseIf *c\c = '['
    *c + SizeOf(CHARACTER)
    result = JSON_parseArray(*c, *out, @inpString + StringByteLength(inpString))
  EndIf
  If result
    ProcedureReturn *out
  Else  
    ProcedureReturn #False
  EndIf
EndProcedure

Macro JSON_free(pJsonObj)
  JSON_clear(pJsonObj, #False)
  FreeMemory(pJsonObj)
EndMacro

Procedure JSON_clear(*obj.jsonObj, initialize.i = #True)
  Protected last.i = *obj\length - 1
  Protected i.i
  Protected type.i = *obj\type  
  If type = #JSON_Type_Undefined
    type = JSON_getType(*obj)
  EndIf
  Select type
    Case #JSON_Type_Object
      ResetMap(*obj\o())
      While NextMapElement(*obj\o())
        CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant)
          JSON_free(*obj\o())  
        CompilerElse
          JSON_clear(@*obj\o(), #False)
        CompilerEndIf
      Wend
      FreeMap(*obj\o())
    Case #JSON_Type_Array
      For i = 0 To last
        JSON_free(*obj\a(i))
      Next
      Dim *obj\a(0)
  EndSelect
  ClearStructure(*obj, jsonObj)
  If initialize
    InitializeStructure(*obj, jsonObj)
  EndIf
EndProcedure

CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant)
  Macro JSON_create()
    AllocateMemory(SizeOf(jsonObj))
  EndMacro
  Procedure JSON_newObject(*obj.jsonObj)
    If *obj\type <> #JSON_Type_Undefined
      JSON_clear(*obj)
    ElseIf *obj\s
      ClearStructure(*obj, jsonObj)
    EndIf
    *obj\type = #JSON_Type_Object
    InitializeStructure(*obj, jsonObj)
  EndProcedure
  Macro JSON_newPair(pJsonObj, strName)
    pJsonObj\o(strName) = AllocateMemory(SizeOf(jsonObj))
  EndMacro
CompilerEndIf

Procedure.i JSON_dimArray(*obj.jsonObj, Size.i)
  Protected i.i
  If *obj\type <> #JSON_Type_Undefined
    JSON_clear(*obj, #False)
  ElseIf *obj\s
    ClearStructure(*obj, jsonObj)
  EndIf      
  If Size > 0
    *obj\length = Size
    Size - 1
    Dim *obj\a(Size)
    For i = 0 To Size
      *obj\a(i) = AllocateMemory(SizeOf(jsonObj))
      CompilerIf Defined(JSON_UseObjectPointer, #PB_Constant) = #False
        InitializeStructure(*obj\a(i), jsonObj)
      CompilerEndIf
    Next
  Else
    *obj\length = 0
  EndIf
  *obj\type = #JSON_Type_Array
EndProcedure

CompilerIf #PB_Compiler_Debugger
  Procedure JSON_Debug(*obj.jsonObj, key.s, type.i = #JSON_Type_Undefined)
    Protected i.i
    If type = #JSON_Type_Undefined
      type = *obj\type
    EndIf
    Select type
      Case #JSON_Type_False
        Debug key + " (false)"
      Case #JSON_Type_True
        Debug key + " (true)"
      Case #JSON_Type_Null
        Debug key + " (null)"
      Case #JSON_Type_Float
        Debug key + " (float) : " + StrD(*obj\f)
      Case #JSON_Type_Integer
        Debug key + "(int) : " + Str(*obj\i)
      Case #JSON_Type_String
        Debug key + " (string) : " + *obj\s
      Case #JSON_Type_Array
        Debug key + " (array) : ["
        For i = 0 To *obj\length - 1
          JSON_Debug(*obj\a(i), Str(i+1) + ".")
        Next
        Debug "]"
      Case #JSON_Type_Object
        Debug key + " (object) : {"
        ResetMap(*obj\o())
        While NextMapElement(*obj\o())
          JSON_Debug(*obj\o(), MapKey(*obj\o()))
        Wend
        Debug "}"
      Case #JSON_Type_Undefined
        JSON_Debug(*obj, key, JSON_getType(*obj))
    EndSelect   
  EndProcedure
CompilerElse
  Macro JSON_Debug(BLA, BLA2, BLA3=bla4)
  EndMacro
CompilerEndIf

; IDE Options = PureBasic 5.11 (Windows - x86)
; UseMainFile = ..\main.pb
