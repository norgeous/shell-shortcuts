@@ECHO off
@@::Polyglot adapted from: http://stackoverflow.com/questions/9366080/batch-launching-powershell-with-a-multiline-command-parameter
@@setlocal EnableDelayedExpansion
@@set LF=^


@@SET command=$Script:arguments=@()
@@SET command=!command!!LF!$Script:arguments+="%~0"
@@FOR %%x in (%*) do SET command=!command!!LF!$Script:arguments+="%%~x"
@@FOR /F "tokens=*" %%i in ('Findstr -bv @@ "%~f0"') DO SET command=!command!!LF!%%i
@@SET "ps1file=%temp%\%~nx0.ps1"
@@ECHO !command! > "%ps1file%"
@@START PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File ""%ps1file%""' -Verb RunAs}"
@@goto:eof
# adminstrative powershell from now on
# args passed to the bat are in the '$Script:arguments' array

# location paths of the bat and ps1 files
$Script:batfile = $Script:arguments[0]
$Script:ps1file = ('{0}\{1}.ps1' -f $env:temp, (Split-Path -Leaf $Script:arguments[0]))

# delete the temporary .ps1 file in %TEMP%, comment this line and check %temp% for debug
Remove-Item $Script:ps1file

################################
# end Polyglot code			#
################################

# polyglot caveats:

	# caret (^) must be escaped as double caret (^^)

	# do not include the string !LF!
		# as it will be replaced with a newline

	# use 'kill $pid' to close the window






################################
# start shortcuts.bat.ps1 code #
################################

# colour terminal output function
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
	for ($Local:i = 0; $Local:i -lt $Local:Text.Length; $Local:i++) {Write-Host $Local:Text[$Local:i] -Foreground $Local:Color[$Local:i] -NoNewLine}
	Write-Host
}

# validation helpers
function Test-StringEmpty($String){
	return ([string]::IsNullOrEmpty($Local:String) -Or [string]::IsNullOrWhiteSpace($String))
}
function Test-PathExists($String){
	return (-Not (Test-StringEmpty $Local:String) -And (Test-Path $Local:String))
}

# main logic
function Initialize-Shortcutsbat($Local:configlocation) {

	Clear-Host

	# if no shortcuts config supplied
	If (Test-StringEmpty $Local:configlocation) {

		# set as same dir as bat file
		$Local:shortcutsfile = ('{0}\shortcuts.txt' -f (Split-Path -Path $Script:batfile))

	} Else {

		# else use supplied file
		$Local:shortcutsfile = $Local:configlocation

	}

	# check shortcuts config file actually exists
	If (-Not (Test-PathExists $Local:shortcutsfile)) {

		Write-Host
		Write-Color -Text (' Config file: "{0}" was not found' -f $Local:shortcutsfile) -Color Magenta
		Write-Host

	} Else {

		#
		# config file exists
		#

		# set up defaults for options
		$Local:wd = Split-Path -Path $Local:shortcutsfile				# set the working dir same as shortcuts config file location
		$Local:after = "PAUSE"											# set command that runs afterwards to PAUSE

		# load config file
		$Local:shortcutstxt = Get-Content "$Local:shortcutsfile"
		
		# overwrite default options 'wd' and 'after'
		Foreach ($Local:line in $Local:shortcutstxt) {

			# if line starts with '##wd='
			If ($Local:line.StartsWith('##wd=')) {

				# use the remainder of the line as the new working dir
				$Local:wd = $Local:line.substring(5)

			}

			# if line starts with '##after='
			If ($Local:line.StartsWith('##after=')) {
				
				# use the remainder of the line as 'after'
				$Local:after = $Local:line.substring(8)

			}
		}

		# check config has at least one command
		$Local:hascommands = $False
		Foreach ($Local:line in $Local:shortcutstxt) {
			If (-Not (Test-StringEmpty $Local:line) -And -Not $Local:line.StartsWith('#')) {
				$Local:hascommands = $True
				break
			}
		}
		If (-Not $Local:hascommands) {
			
			Write-Host
			Write-Color -Text (' Config file: "{0}" does not contain any commands' -f $Local:shortcutsfile) -Color Magenta
			Write-Host

		} Else {

			#
			# config file exists
			# config contains at least one command
			# 

			# check that working dir exists
			If (-Not (Test-PathExists $Local:wd)) {

				Write-Host
				Write-Color -Text (' Working directory: "{0}" was not found' -f $Local:wd) -Color Magenta
				Write-Host

			} Else {

				#
				# config file exists
				# config contains at least one command
				# working directory exists
				# 

				# change directory
				Set-Location "$Local:wd"




				# show the menu
				:mainloop While ($True) {

					Clear-Host

					# show some configuration info (header)
					Write-Host
					#Write-Color -Text ' bat location:',"`t","`t","$Script:batfile" -Color Gray,White,White,Green
					#Write-Color -Text ' ps1 location:',"`t","`t","$Script:ps1file" -Color Gray,White,White,Green
					#Write-Host
					Write-Color -Text ' shorcuts from:',"`t","`t","$Local:shortcutsfile" -Color Gray,White,White,Green
					Write-Color -Text ' working directory:',"`t","$Local:wd" -Color Gray,White,Green
					If ($Local:after -ne "PAUSE") {
						Write-Color -Text ' after each command:',"`t",'& ',$Local:after -Color Gray,White,DarkGreen,DarkGreen
					}

					# show numbered menu
					$Local:count = 0
					Foreach ($Local:line in $Local:shortcutstxt) {
						If (-Not (Test-StringEmpty $Local:line) -And -Not $Local:line.StartsWith('##')) {
							If ($Local:line.StartsWith('#')) {

								# show section title
								Write-Host
								Write-Color -Text "`t",($Local:line.substring(1)) -Color White,DarkCyan

							} Else {

								# show numbered commands
								$Local:count++
								Write-Color -Text "`t",' ',$Local:count,': ',"$Local:line" -Color White,White,Cyan,White,Yellow

							}
						}
					}

					# prompt user for input (either a number from the menu or 'e' for exit or 'r' for reload)
					Write-Host
					Write-Color -Text ' Enter menu item number (','1',' to ',$Local:count,')' -Color White,Cyan,White,Cyan,White
					$Local:choice = Read-Host -prompt ' '
					Write-Host

					# process users input
					:decide Switch ($Local:choice) {

						{$_ -match '^^r'} {

							# reload - starts with 'r'
							Write-Color -Text (' Reloading config "{0}"' -f $Local:shortcutsfile) -Color Green
							Start-Sleep -s 1

							# recursion
							Initialize-Shortcutsbat $Script:arguments[1]

							# execution will only return here if any of the checks fail upon reload, so we must break the mainloop to gracefully exit
							break mainloop
						}

						{$_ -match '^^e'} {

							# exit - starts with 'e'
							Write-Color -Text ' Exiting' -Color Green
							Start-Sleep -m 100
							
							# powershell was spawned with -NoExit, so kill the process
							kill $pid
						}

						{$_ -match '^^\d+$'} {

							# choice is a number, so check that number matches a menu item by looping through (as previously)
							$Local:count = 0
							Foreach ($Local:line in $Local:shortcutstxt) {

								# if line not blank and not title or config option add to count
								If (-Not (Test-StringEmpty $Local:line) -And -Not $Local:line.StartsWith('#')) {
									$Local:count++

									# if count equals selection
									If ($Local:count -eq $Local:choice) {

										# spawn command in new CMD window
										Write-Color -Text (' Spawning "{0}"' -f $Local:line) -Color Green
										$Local:cmdarguments = ('/c ECHO "{0}" & ECHO. & {0} & ECHO. & {1}' -f $Local:line, $Local:after)
										Start-Process -FilePath cmd -ArgumentList $Local:cmdarguments
										
										#stop looking for a match (skip over 'not found' message below)
										break decide
									}
								}
							}

							# the count never reached the user supplied number
							Write-Color -Text (' Menu item number "{0}" not found' -f $Local:choice) -Color Magenta

						}

						default {

							# not found
							Write-Color -Text (' Command "{0}" not found' -f $Local:choice) -Color Magenta

						}

					} # end decide switch statement

					# wait between menus for 1 second (for message display)
					Start-Sleep -s 1

				} # end mainloop while loop


				

			} # end working dir exists

		} # end config has commands

	} # end config exists

} # end Initialize-Shortcutsbat function




# start the checks and mainloop (eventually)
Initialize-Shortcutsbat $Script:arguments[1]

# execution only gets here if any of the checks fail or the mainloop ends
