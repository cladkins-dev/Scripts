Param (
    [string]$SearchString = $( Read-Host "Input search string, please" )
 )


$ADSERVER="test.acme"

 if(!$SearchString){
    throw "Not Using Null String...."
    Exit 
 }


 $RootPath=$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\'))
 $CredFile="$RootPath\Creds\User.cred"


 $url = ""
 $output = "$RootPath\Cache\Node-Passwords.csv"


 
if (!(Test-Path $CredFile)) {
    # This will prompt you for your alternate credentials
    $CRED = Get-Credential
    $CRED | Export-CliXml -Path $CredFile
}

$CRED =$(Import-CliXml -Path  $CredFile)



Invoke-WebRequest -Uri $url -OutFile $output
$CSVRows_NodeMatches=$(Import-CSV $output | Where{$_.Node -match "$SearchString"})
$CSVRows_PatchGroup=$(Import-CSV $output | Where{$_."Patch Group" -match "$SearchString"})


ForEach($NodeRow in $CSVRows_NodeMatches+$CSVRows_PatchGroup){


    try {
        $IP = [System.Net.Dns]::gethostentry($NodeRow."Primary IP")
    }
    catch {
        Write-Output -Verbose 'No such host is known'
    }



     If ($IP){

        $HostName = [string]$IP.HostName
        $HOSTNAME=$HOSTNAME.Substring(0, $HOSTNAME.IndexOf('.'))

        try{
        
            $ComputerObject=$(Get-ADComputer -ErrorAction Ignore $HOSTNAME -server $ADSERVER -Credential $CRED -Properties *)
            $LapsPassword=$(($ComputerObject | Select-Object ms-Mcs-AdmPwd) | ForEach-Object {$_."ms-Mcs-AdmPwd"})
        
        } catch{
        
            $PasswordName=($NodeRow."Password Name")
            $CredFileTmp="$RootPath\Creds\$PasswordName"
            $PasswordFileHash=new-object System.Security.Cryptography.SHA256Managed | ForEach-Object {$_.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PasswordName))} | ForEach-Object {$_.ToString("x2")}
   
            $CredFileLocation="$RootPath\Creds\$PasswordFileHash"

            if (!(Test-Path $CredFileLocation)) {
                # This will prompt you for your alternate credentials
                $TmpCred = Get-Credential
                $TmpCred | Export-CliXml -Path $CredFileLocation
            }
      
            $TmpCred =$(Import-CliXml -Path  $CredFileLocation)
            $PasswordName=$TmpCred.GetNetworkCredential().password
        
        }

        $machinename=($NodeRow."Primary IP")

      } Else {
      
      
      
            $PasswordName=($NodeRow."Password Name")
            $CredFileTmp="$RootPath\Creds\$PasswordName"
            $PasswordFileHash=new-object System.Security.Cryptography.SHA256Managed | ForEach-Object {$_.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PasswordName))} | ForEach-Object {$_.ToString("x2")}
   
            $CredFileLocation="$RootPath\Creds\$PasswordFileHash"

            if (!(Test-Path $CredFileLocation)) {
                # This will prompt you for your alternate credentials
                $TmpCred = Get-Credential
                $TmpCred | Export-CliXml -Path $CredFileLocation
            }
      
            $TmpCred =$(Import-CliXml -Path  $CredFileLocation)
            $PasswordName=$TmpCred.GetNetworkCredential().password
      
      
            $machinename=($NodeRow."Primary IP")
      
      
      }



       Write-Output $NodeRow
       Write-Output $ComputerObject

       if("$PasswordName"){
            Write-Output "Password: $PasswordName"
            $ExecPassword="$PasswordName"




       }

       if("$LapsPassword"){
            Write-Output "Laps Password: $LapsPassword"
            $ExecPassword="$LapsPassword"
    
       }



       $CMD_MACHINE="$machinename"


       if(($NodeRow."OS") -eq "RHEL 7"){
        $CMD_STR="-ssh root@$CMD_MACHINE -pw "+'"'+$ExecPassword+'"'
        Write-Host "$CMD_STR"
        #plink.exe "$CMD_MACHINE" -P 22 -l root -pw "$ExecPassword"
        Start-Process -FilePath "$RootPath\Bin\putty.exe" -ArgumentList "$CMD_STR"
        
       }else{
       
       


       #Set-Clipboard -Value "$ExecPassword"

       $CMD_USER="administrator"

       $CMD_W="{0}" -f [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width,[System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height
       $CMD_H="{1}" -f [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width,[System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height

       $CMD_W=$CMD_W-150
       $CMD_H=$CMD_H-150

       #Write-Output "Launching in Resolution: $CMD_W :: $CMD_H"
       
       $CMD_RESOLUTION="/w:$CMD_W /h:$CMD_H"
       
       $CMD_GROUP=($NodeRow."Patch Group")
       $CMD_GROUP=$CMD_GROUP -replace 'GROUP:',''
       $CMD_TITLE="$CMD_MACHINE, $CMD_GROUP"
       $CMD_STR="/u:$CMD_USER /p:"+'"'+$ExecPassword+'"'+" /v:$CMD_MACHINE "+$CMD_RESOLUTION+" /t:"+'"'+"$CMD_TITLE"+'"'
       #Write-Host "$CMD_STR"
       Start-Process -FilePath "$RootPath\Bin\wfreerdp.exe" -ArgumentList "$CMD_STR"
       
       }




}





