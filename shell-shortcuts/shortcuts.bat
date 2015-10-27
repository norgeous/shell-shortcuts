@@ECHO off
@@setlocal EnableDelayedExpansion
@@REM lines 5 and 6 must both be blank
@@set LF=^


@@SET command=#
@@FOR /F "tokens=*" %%i in ('Findstr -bv @@ "%~f0"') DO SET command=!command!!LF!%%i
@@START powershell -noexit -command !command! & goto:eof
#powershell script starts below this line

$shortcutsfile = 'shortcuts.txt'
$shortcutsfilepath = ('{0}\{1}' -f $pwd, $shortcutsfile)
$shortcutstxt = Get-Content "$shortcutsfilepath"

$wd = Split-Path -Path $pwd -Parent
Set-Location "$wd"

function showmenu {
	
	Clear-Host
	Write-Host ""
	Write-Host ' shorcuts from:' -NoNewline
	Write-Host "`t`t$shortcutsfilepath" -fore Green
	Write-Host ' working directory:' -NoNewline
	Write-Host "`t$wd" -fore Green
	Write-Host ""

	Write-Host ' Available commands:'
	$global:count = 0
	$shortcutstxt | Foreach-Object {
		If ($_) {
			If ($_.StartsWith('#')) {
				$comment = $_.substring(1) 
				Write-Host ""
				Write-Host "`t$comment"
			} Else {
				$global:count++
				Write-Host "`t $global:count" -NoNewline -fore Cyan
				Write-Host ': ' -NoNewline
				Write-Host "$_" -fore Yellow
			}
		}
	}

    Write-Host ""
    Write-Host ' Enter command number (' -NoNewline
    Write-Host "1" -NoNewline -fore Cyan
    Write-Host ' to ' -NoNewline
    Write-Host $count -NoNewline -fore Cyan
    Write-Host ')'
    $choice = Read-Host -prompt ' '
	Write-Host ""

	$global:count = 0
	$global:found = $False
	$shortcutstxt | Foreach-Object {
		If ($_) {
			If (-Not $_.StartsWith('#')) {
				$global:count++
				If ($global:count -eq $choice) {
					$global:found = $True
					Start-Process -FilePath "cmd.exe" -ArgumentList ('/c "{0}" & TIMEOUT 30' -f $_)
				}
			}
		}
	}

	If (-Not $global:found) {
	   Write-Host (' Command number `"{0}`" not found' -f $choice) -fore Magenta
	   TIMEOUT 3
    }

	showmenu
}
showmenu
