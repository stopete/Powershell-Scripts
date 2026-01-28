# Read the list of target computers from a text file and
# invoke a PowerShell script on each remote system.

# Retrieve credentials from the Secret Vault
$cred = Get-Secret -Vault 'Vault' -Name 'Vault'

# Loop through each computer listed in the file
Get-Content -Path 'C:\Scripts\Computers\ActiveComputers.txt' | ForEach-Object {

    $computer = $_
    Write-Host "Processing computer: $computer"

    # Invoke the scheduled task script on the remote computer
    Invoke-Command `
        -ComputerName $computer `
        -FilePath 'C:\Scripts\3_InvokeScheduleTaskInstallUpdates.ps1' `
        -Credential $cred
}
