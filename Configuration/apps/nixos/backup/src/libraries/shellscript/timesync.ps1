# Set the NTP server to "time.windows.com"
$NtpServer = "time.windows.com"

# Check if the system time synchronization service is running
$ServiceStatus = Get-Service w32time

if ($ServiceStatus.Status -eq "Running") {
  # Stop the Windows Time service
  Stop-Service w32time
}

# Configure the NTP server
w32tm /config /manualpeerlist:$NtpServer /syncfromflags:manual /reliable:YES /update

# Start the Windows Time service
Start-Service w32time

# Force synchronization
w32tm /resync

# Display the current time configuration
w32tm /query /status
