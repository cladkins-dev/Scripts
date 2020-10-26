#Monitor file for changes.
#25OCT2020 -cladkins

$testfile = "C:\cache\config.cfg"
$cache = "$PSScriptRoot\.cache"
$start_time = Get-Date


$CredFile="$PSScriptRoot\smtp.cred"

#Email Config
$fromEmail=""
$toEmail=""
$smtpServer=""
$smtpPort=""
$emailSubject=""

if (!(Test-Path $CredFile)) {
    # This will prompt you for your alternate credentials
    $CRED = Get-Credential
    $CRED | Export-CliXml -Path $CredFile
}

$CRED =$(Import-CliXml -Path  $CredFile)


Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"



# Set $hash to the hash reference from the download page:
if(Test-Path -Path "$cache") {
  $hash = $(Get-Content -Path "$cache" -ErrorAction SilentlyContinue)
}
else {
  $hash = "";
}


$hashAlgo = "SHA256"

$computed_hash = (Get-FileHash -Algorithm $hashAlgo $testfile).Hash.ToUpper()


if ($computed_hash.CompareTo($hash.ToUpper()) -eq 0 ) {
    Write-Output "Hash matches for file $file" 
} 
else { 
    Write-Output ("Hash DOES NOT match for file {0}: `nOriginal hash: {1} `nComputed hash: {2}" -f ($file, $hash.ToUpper(), $computed_hash)) 
    $computed_hash| out-file "$cache"

    $PasswordName=$CRED.GetNetworkCredential().password
    $hostName=$env:COMPUTERNAME

    $from = "$fromEmail" 
    $to="$toEmail"
    $smtp = "$smtpServer" 
    $SMTPPort = "$smtpPort"
    $sub = "$emailSubject" 
    $body = "Node: $hostName <br> <br> Previous Hash: $hash <br> <br> New Hash: $computed_hash"
    $secpasswd = ConvertTo-SecureString "$PasswordName" -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential($from, $secpasswd)
    Send-MailMessage -Port $SMTPPort -UseSsl -To $to -From $from -Subject $sub -Body $body -Credential $mycreds -SmtpServer $smtp -DeliveryNotificationOption Never -BodyAsHtml


}

