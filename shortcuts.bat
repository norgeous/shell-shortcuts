@@ECHO off
@@::http://stackoverflow.com/questions/9366080/batch-launching-powershell-with-a-multiline-command-parameter
@@setlocal EnableDelayedExpansion
@@::lines 5 and 6 must both be blank
@@set LF=^


@@SET command=$arguments=@()
@@SET command=!command!!LF!$arguments+="%~0"
@@FOR %%x in (%*) do SET command=!command!!LF!$arguments+="%%~x"
@@FOR /F "tokens=*" %%i in ('Findstr -bv @@ "%~f0"') DO SET command=!command!!LF!%%i
@@SET "ps1file=%temp%\%~nx0.ps1"
@@ECHO !command! > "%ps1file%"
@@START PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-noexit -NoProfile -ExecutionPolicy Bypass -File ""%ps1file%""' -Verb RunAs}"
@@goto:eof
Clear-Host
Remove-Item ('{0}\{1}.ps1' -f $env:temp, (Split-Path -Leaf $arguments[0]))

function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
	for ($i = 0; $i -lt $Text.Length; $i++) {Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine}
	Write-Host
}

function showmenu {

	Clear-Host
	Write-Host

	Write-Color -Text ' shorcuts from:',"`t`t$shortcutsfile" -Color Gray,Green
	Write-Color -Text ' working directory:',"`t$wd" -Color Gray,Green
	Write-Color -Text ' after each command:',"`t","`&",' ',$after -Color Gray,White,DarkGreen,DarkGreen,DarkGreen

	$global:count = 0
	$shortcutstxt | Foreach-Object {
		If ($_ -And -Not $_.StartsWith('##')) {		
			If ($_.StartsWith('#')) {
				$sectiontitle = $_.substring(1)
				Write-Host
				Write-Color -Text "`t$sectiontitle" -Color DarkCyan
			} Else {
				$global:count++
				Write-Color -Text "`t",' ',$global:count,': ',"$_" -Color White,White,Cyan,White,Yellow
			}
		}
	}

	Write-Host
	Write-Color -Text ' Enter command number (','1',' to ',$count,')' -Color White,Cyan,White,Cyan,White
	$choice = Read-Host -prompt ' '
	Write-Host

	$global:count = 0
	$global:found = $False
	$shortcutstxt | Foreach-Object {
		If ($_ -And -Not $_.StartsWith('#')) {
			$global:count++
			If ($global:count -eq $choice) {
				$global:found = $True
				$cmdarguments = ('/c ECHO "{0}" & ECHO. & {0} & ECHO. & {1}' -f $_, $after)
				Start-Process -FilePath cmd -ArgumentList $cmdarguments
			}
		}
	}

	If (-Not $global:found) {
		Write-Color -Text (' Menu item "{0}" not found' -f $choice) -Color Magenta
		TIMEOUT 5
	}

	showmenu
}








$after = "PAUSE"
If ($arguments[1]) {
	$wd = Split-Path -Path $arguments[1]
	$shortcutsfile = $arguments[1]
} Else {
	$wd = Split-Path -Path $arguments[0]
	$shortcutsfile = ('{0}\shortcuts.txt' -f (Split-Path -Path $arguments[0]))
}

If (-Not (Test-Path $shortcutsfile)) {

	Write-Host
	Write-Color -Text ('shortcuts config "{0}" was not found' -f $shortcutsfile) -Color Magenta
	Write-Host
	PAUSE

} Else {

	$shortcutstxt = Get-Content "$shortcutsfile"
	$shortcutstxt | Foreach-Object {
		If ($_.StartsWith('##wd=')) {
			$wd = $_.substring(5)
		}
		If ($_.StartsWith('##after=')) {
			$after = $_.substring(8)
		}
	}

	Set-Location "$wd"

	showmenu
}
