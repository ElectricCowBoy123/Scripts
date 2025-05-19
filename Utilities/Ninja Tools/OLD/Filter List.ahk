filePath := "" 
!g::
    FileRead, fileContent, %filePath%
    lines := StrSplit(fileContent, "`n")
    for index, line in lines {
        Clipboard := line
        ClipWait, 1
        Send, ^v
        Send, {Enter}
        Sleep, 200
    }
return