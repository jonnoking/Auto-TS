iisreset
xcopy SourceCodeANZ.Forms.Controls.Calendar.dll "C:\Program Files (x86)\K2 blackpearl\K2 SmartForms Designer\bin\" /y /r
xcopy SourceCodeANZ.Forms.Controls.Calendar.dll "C:\Program Files (x86)\K2 blackpearl\K2 SmartForms Runtime\bin\" /y /r
"C:\Program Files (x86)\K2 blackpearl\Bin\controlutil.exe" register -assembly:"C:\Program Files (x86)\K2 blackpearl\K2 SmartForms Designer\bin\SourceCodeANZ.Forms.Controls.Calendar.dll"
pause