###
#
# ---------------------------------------------
# RunningLow v1.1.1
# ---------------------------------------------
# A small Powershell script to check for low disk space and send e-mail to System Administrators
#
# by Darkseal/Ryadel
# https://www.ryadel.com/
#
# Licensed under GNU - General Public License, v3.0
# https://www.gnu.org/licenses/gpl-3.0.en.html
#
###


# Command-line parameters
param(
  # - minSize : the minimum free disk space acceptable threshold: any checked drive with less available space will raise a warning.
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $minSize = 20GB,

  # - hosts: if specified, will also check the disk space on the given colon-separated list of hostnames (machine names OR ip addresses) within the LAN.
  #            Example: $hosts = "HOSTNAME1:HOSTNAME2:129.168.0.115";
  #           IMPORTANT: Connecting to remote machines will require launching RunningLow with elevated priviledges
  #           and the Windows Management service up, running and reachable (TCP port 5985) on the remote machine.
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $hosts = $null,

  # - volumes: a colon-separated list of the drive volumes (letters) to check: set it to $null to check all local (non-network) drives.
  #            Example: $volumes = "C:D";
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $volumes = $null,

  # - email_to : if specified, will send a low-disk-space warning email to the given colon-separated addresses.
  #              Example: $email_to = "my@email.com:your@email.com";
  #              Default is $null (no e-mail will be sent). Replace it with your@email.com if you don't want to set it from the CLI.
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $email_to = $null,

  # These parameters can be used to set your SMTP configuration: username, password & so on. 
  # It's strongly advisable to set them within the code instead of setting them from the CLI, as you might rarely want to change them.
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_username = "username@yourdomain.com",
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_password = "yourpassword",
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_smtp_host = "smtp.yourdomain.com",
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_smtp_port = 25,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_smtp_SSL = 0,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_from = "username@yourdomain.com"
)

$sep = ":";

# if there are no $cur_hosts set, set the local computer as host. 
if (!$hosts) { $hosts = $env:computername; }

foreach ($cur_host in $hosts.split($sep)) {
    # converts IP to hostNames
    if (($cur_host -As [IPAddress]) -As [Bool]) {
        $cur_host = [System.Net.Dns]::GetHostEntry($cur_host).HostName
    }

	Write-Host ("");
	Write-Host ("");
	Write-Host ("----------------------------------------------");
	Write-Host ($cur_host);
	Write-Host ("----------------------------------------------");
    $drives_to_check = @();

    if ($volumes -eq $null) {
   	    $volArr = 
          If ($cur_host -eq $env:computername) { Get-WMIObject win32_volume }
          Else { Invoke-Command -ComputerName $cur_host -ScriptBlock { Get-WMIObject win32_volume } }

	    $drives_to_check = @();
        foreach ($vol in $volArr | Sort-Object -Property DriveLetter) {
	        if ($vol.DriveType -eq 3 -And $vol.DriveLetter -ne $null ) {
  		        $drives_to_check += $vol.DriveLetter[0];
		    }
	    }
    }
    Else { 
		$drives_to_check = $volumes.split($sep) 
	}

    foreach ($d in $drives_to_check) {
		# Write-Host ("");
		# Write-Host ("  Checking drive " + $d + " ...");
		$disk = If ($cur_host -eq $env:computername) { Get-PSDrive $d }
		Else { Invoke-Command -ComputerName $cur_host -ScriptBlock { Get-PSDrive $using:d } }

		if ($disk.Free -lt $minSize) {
			Write-Host "  - [" -noNewLine
			Write-Host "KO" -noNewLine -ForegroundColor Red
			Write-Host "] " -noNewLine
			Write-Host ("Drive " + $d + " has less than " + $minSize `
				+ " bytes free (" + $disk.Free + " bytes - " + ($disk.Free/1MB).ToString(".00") + " MB)") -noNewLine
         
			if ($email_to) {
				Write-Host(": sending e-mail...") -noNewLine
	
				$message = new-object Net.Mail.MailMessage;
				$message.From = $email_from;
				foreach ($to in $email_to.split($sep)) {
					$message.To.Add($to);
				}
				$message.Subject = 	("[RunningLow] WARNING: " + $cur_host + " drive " + $d);
				$message.Subject +=	(" has less than " + $minSize + " bytes free ");
				$message.Subject +=	("(" + $disk.Free + " bytes - "+ ($disk.Free/1GB).ToString(".00") +" GB)");
				$message.Body =		"Hello there, `r`n`r`n";
				$message.Body += 	"this is an automatic e-mail message ";
				$message.Body += 	"sent by RunningLow Powershell script ";
				$message.Body += 	("to inform you that " + $cur_host + " drive " + $d + " ");
				$message.Body += 	"is running low on free space. `r`n`r`n";
				$message.Body += 	"--------------------------------------------------------------";
				$message.Body +=	"`r`n";
				$message.Body += 	("Machine HostName: " + $cur_host + " `r`n");
				$message.Body += 	"Machine IP Address(es): ";
				$ipAddresses = Get-NetIPAddress -AddressFamily IPv4;
				foreach ($ip in $ipAddresses) {
					if ($ip.IPAddress -like "127.0.0.1") {
						continue;
					}
					$message.Body += ($ip.IPAddress + " ");
				}
				$message.Body += 	"`r`n";
				$message.Body += 	("Used space on drive " + $d + ": " + $disk.Used + " bytes. `r`n");
				$message.Body += 	("Free space on drive " + $d + ": " + $disk.Free + " bytes. `r`n");
				$message.Body += 	"--------------------------------------------------------------";
				$message.Body +=	"`r`n`r`n";
				$message.Body += 	"This warning will fire when the free space is lower ";
				$message.Body +=	("than " + $minSize + " bytes `r`n`r`n");
				$message.Body += 	"Sincerely, `r`n`r`n";
				$message.Body += 	"-- `r`n";
				$message.Body += 	"RunningLow`r`n";
						$message.Body +=        "http://www.ryadel.com/RunningLow";

				$smtp = new-object Net.Mail.SmtpClient($email_smtp_host, $email_smtp_port);
				$smtp.EnableSSL = $email_smtp_SSL;
				$smtp.Credentials = New-Object System.Net.NetworkCredential($email_username, $email_password);

				try {
					$smtp.send($message);
					Write-Host " E-Mail sent!" ;
				}
				catch {
					Write-Host " Error sending E-Mail:" ;
					Write-Host $_.Exception.Message
				}
				$message.Dispose();
			}
			Else {
				Write-Host(".");
			}
		}
		Else {
			Write-Host "  - [" -noNewLine
			Write-Host "OK" -noNewLine -ForegroundColor Green
			Write-Host "] " -noNewLine
			Write-Host ("Drive " + $d + " has more than " + $minSize + " bytes free: nothing to do.")
		}
	}
}
