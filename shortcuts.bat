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
	If ($_) {
		If ($_.StartsWith('##wd=')) {
			$wd = $_.substring(5)
		}
		If ($_.StartsWith('##after=')) {
			$after = $_.substring(8)
		}
	}
}

Set-Location "$wd"

function showmenu {
	
	Clear-Host
	Write-Host ""
	Write-Host ' shorcuts from:' -NoNewline
	Write-Host "`t`t$shortcutsfile" -fore Green
	Write-Host ' working directory:' -NoNewline
	Write-Host "`t$wd" -fore Green
	If ($after) {
		Write-Host ' after each command:' -NoNewline
		Write-Host "`t`& $after" -fore Yellow
	}


	$global:count = 0
	$shortcutstxt | Foreach-Object {
		If ($_) {
			If (-Not $_.StartsWith('##')) {
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
			If (-Not $_.StartsWith('##')) {
				If (-Not $_.StartsWith('#')) {
					$global:count++
					If ($global:count -eq $choice) {
						$global:found = $True
						If ($after) {
							$arguments = '/c ECHO {0} & {0} & "{1}"' -f $_, $after
						} Else {
							$arguments = '/c ECHO {0} & {0}' -f $_
						}
						Start-Process -FilePath "cmd.exe" -ArgumentList $arguments
					}
				}
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
