[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$TargetOU,

    [string[]]$ExcludedGroups = @("Domain Users")
)

Import-Module ActiveDirectory

# Verify target OU exists
Get-ADOrganizationalUnit -Identity $TargetOU -ErrorAction Stop | Out-Null

# Find expired, enabled accounts
$ExpiredUsers = Search-ADAccount -AccountExpired -UsersOnly |
    Where-Object { $_.Enabled }

foreach ($User in $ExpiredUsers) {
    $Groups = Get-ADPrincipalGroupMembership -Identity $User |
        Where-Object { $_.Name -notin $ExcludedGroups }

    # Remove selected group memberships
    if ($Groups) {
        Remove-ADPrincipalGroupMembership -Identity $User `
            -MemberOf $Groups -Confirm:$false -WhatIf:$WhatIfPreference
    }

    # Disable and move account
    Disable-ADAccount -Identity $User -WhatIf:$WhatIfPreference
    Move-ADObject -Identity $User -TargetPath $TargetOU `
        -WhatIf:$WhatIfPreference
}
