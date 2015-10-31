@@ECHO off
@@setlocal EnableDelayedExpansion
@@REM lines 5 and 6 must both be blank
@@set LF=^


@@IF [%1] EQU [] (SET "command=$shortcutsfile='%~dp0shortcuts.txt'") ELSE (SET "command=$shortcutsfile='%~f1'")
@@SET "command=!command!!LF!$wd='%~dp0'"
@@FOR /F "tokens=*" %%i in ('Findstr -bv @@ "%~f0"') DO SET command=!command!!LF!%%i
@@START PowerShell -noexit -command !command! & goto:eof

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

function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
	for ($i = 0; $i -lt $Text.Length; $i++) {Write-Host "$Text[$i]" -Foreground $Color[$i] -NoNewLine}
	Write-Host
}

function showmenu {
	
	Clear-Host
	Write-Host
	Write-Color -Text ' shorcuts from:',"`t`t$shortcutsfile" -Color Gray,Green
	Write-Color -Text ' working directory:',"`t$wd" -Color Gray,Green
	If ($after) {
		Write-Color -Text ' after each command:',"`t","`&",' ',$after -Color Gray,White,DarkGreen,DarkGreen,DarkGreen
	}

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
				If ($after) {
					$arguments = '/c ECHO {0} & {0} & {1}' -f $_, $after
				} Else {
					$arguments = '/c ECHO {0} & {0}' -f $_
				}
				Start-Process -FilePath "cmd.exe" -ArgumentList $arguments
			}
		}
	}

	If (-Not $global:found) {
	   Write-Host (' Menu item `"{0}`" not found' -f $choice) -fore Magenta
	   TIMEOUT 5
	}

	showmenu
}
showmenu
