######Read Me######
#This script fetches sign in data in terms of user signis and recapitulate in a table in terms of 
#30, 60 and 90 days. Information is extracted from ENTRA sign in logs, bringing the potential limitation of 
#log durability within ENTRA. Additional notes are within the comments of the script. 
######Read Me#######
#Connect via Graph and scope the connection to Azure GOV. Pending on current environmnet Az Cloud set --name AzUSGovernment maight be needed.
Connect-MgGraph -Environment USGov -Scopes "User.Read.All", "AuditLog.Read.All"

# get needed properties on sign in activity logs.
$users = Get-MgUser -All -Property "Id, UserPrincipalName, SignInActivity, AccountEnabled"

# Pre-set array variables to output data later on script
$userAudit = @()
$currentDate = Get-Date

# This portion uses a foreach approach to iterate over the properties (saved as objects) to audit sign-in activities. 
# With this we determine whether the account is disabled, and analyzes the last sign-in activity to categorize in 
# periods of 30,60, and 90 days. 

foreach ($user in $users) {
    $lastSignIn = $null
    $lastSignInPeriod = "Never Signed In"
    $disabled = if ($user.AccountEnabled) { "No" } else { "Yes" }

    if ($null -ne $user.SignInActivity) {
        $lastSignIn = $user.SignInActivity.LastSignInDateTime
        $daysSinceLastSignIn = ($currentDate - $lastSignIn).Days

        if ($daysSinceLastSignIn -le 30) {
            $lastSignInPeriod = "Less than 30 Days"
        } elseif ($daysSinceLastSignIn -le 60) {
            $lastSignInPeriod = "More than 30 Days"
        } elseif ($daysSinceLastSignIn -le 90) {
            $lastSignInPeriod = "More than 60 Days"
        } else {
            $lastSignInPeriod = "More than 90 Days"
        }
    }
# The never portion reflects the date/times that there is no data in the logs
    $userAudit += [PSCustomObject]@{
        UserPrincipalName   = $user.UserPrincipalName
        LastSignInActivity  = if ($lastSignIn -eq $null) { "Never" } else { $lastSignIn.ToString() }
        LastSignInPeriod    = $lastSignInPeriod
        Disabled            = $disabled
    }
}

# Over this couple of lines we download a CSV file that can be analysed and shared.  
$csvPath = "C:\Users\edwar\OneDrive\Desktop\Power Shell and VSC Scripts\MG stuff\userAudit.csv"
$userAudit | Export-Csv -Path $csvPath -NoTypeInformation

Write-Output "User audit details exported to CSV at: $csvPath"

# Table is created and output is also outputed... :-) to the terminal for visual access.
$userAudit | Format-Table -Property UserPrincipalName, LastSignInActivity, LastSignInPeriod, Disabled -AutoSize

$totalUsers = $userAudit.Count
Write-Output "Total Number of Users: $totalUsers"

