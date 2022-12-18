# Base64 Encoded xml/json of clean install rules
# Role based enbumeration and rule creation
# firewall script

# Can do netsh advfirewall export "file.wfw"
# and netsh advfirewall import "file.wfw"

# Outline
<#
    Remove firewall rules 
    Backup firewall rules
    Restore firewall rules
    Golden image rules
    Role-Based rules
#>
param([switch]$Help, $Restore, $Backup, [switch]$Fresh)

function GetRoles{
    $Features = Get-WindowsFeature | ? installed
    foreach($x in $Features){
        # Create rules
        Switch($x){
            "AD-Domain-Services" {rules}
            "DNS" {rules}
            "Web-Server" {rules}
        }
    }
}

function BackupRules{
    $Rules = Get-NetFirewallRule -All | ft Name, DisplayName, Description, Group, Enabled, Profile, Platform, Direction, Action, EdgeTraversalPolicy,`
    LooseSourceMapping, LocalOnlyMapping, @{Name='Protocol';Expression={($PSItem | Get-NetFirewallPortFilter).Protocol}}, @{Name='LocalPort';Expression={($PSItem | Get-NetFirewallPortFilter).LocalPort}},`
    @{Name='LocalAddress';Expression={($PSItem | Get-NetFirewallPortFilter).LocalAddress}}, @{Name='RemotePort';Expression={($PSItem | Get-NetFirewallPortFilter).RemotePort}},`
    @{Name='RemoteAddress';Expression={($PSItem | Get-NetFirewallPortFilter).RemoteAddress}}
    Export-Csv -InputObject $rules -Path $Backup
}

function RestoreRules{
    $Rules = Import-Csv -Path $Restore
    foreach($x in $Rules){
        Write-Progress -Activity "Writing Firewall Rules" -Status "Current Rule: $x.DisplayName"
        New-NetFirewallRule -Name $x.Name -DisplayName $x.DisplayName -Description $x.Description `
        -Group $x.Group -Enabled $x.Enabled -Profile $x.Profile -Platform $x.Platform -Direction $x.Direction `
        -Action $x.Action -EdgeTraversalPolicy $x.EdgeTraversalPolicy -LooseSourceMapping $x.LooseSourceMapping `
        -LocalOnlyMapping $x.LocalOnlyMapping -Protocol $x.Protocol -LocalAddress $x.LocalAddress -RemoteAddress $x.RemoteAddress `
        -LocalPort $x.LocalPort -RemotePort $x.RemotePort 
    }
    Write-Progress -Completed True
}

function RemoveRules{
    Write-Host "Do you want to remove ALL firewall rules`n[Y] Yes [N] No"
    $response = Read-Host 
    if($response -eq 'Y'){
        Remove-NetFirewallRule -All
        }else{exit}
}

function GoldenImage{
    netsh advfirewall import "gimg.wfw"
}
function Help{
    write-host @"
    AlienBlaster is a Simple Firewall Rule Manager for Windows Servers

    EXAMPLE USAGE: AlienBlaster -Restore Backup.json
    USAGE: 
        -Help
            Displays this menu
        -Restore [JSON File]
            Removes current rules and restores from backup file
        -Backup [JSON File]
            Backs up the current rule list
        -Fresh
            Removes the current rules and restores from a "golden image"
            and installs role-based rules for installed features
"@
}


if($help){
    Help
    exit
}
if($Restore){
    RestoreRules
    exit
}
if($Backup){
    BackupRules
    exit
}
if($Fresh){
    RemoveRules
    GoldenImage
    exit
}