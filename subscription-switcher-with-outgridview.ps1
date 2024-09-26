#azure-subscription-switcher-with-outgridview
Function Switch-AzContext {
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Host -ForegroundColor Red 'Az.Accounts PowerShell module not installed!'
        return
    }

    Import-Module Az.Accounts -ErrorAction Stop

    try {
        # Select only enabled subscriptions and avoid duplicated subscriptions if the user has multiple tenants enrolled with LightHouse
        $SubscriptionList = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" -and ($_.HomeTenantId -eq $_.TenantId)} | ConvertTo-Json | ConvertFrom-Json

    } catch {
        Write-Host -ForegroundColor Red "You have no context, please login first!"
        return
    }

    try {
        $SubscriptionActive = Get-AzContext | ConvertTo-Json | ConvertFrom-Json
    } catch {
        Write-Host -ForegroundColor Red "You have no subscription, please login first!"
        return
    }

    $available = @()
    $index = 1
    $SubscriptionList | ForEach-Object {
        $available += [PSCustomObject]@{
            Active = if ($_.Id -eq $SubscriptionActive.Subscription.id) { "===>" } else { $null }
            Index = $index++
            Subscription = $_.Name
            SubscriptionId = $_.Id
            State = $_.State
            HomeTenantId = $_.HomeTenantId
            Account = if ($_.Id -eq $SubscriptionActive.Subscription.id) { $SubscriptionActive.Account.id } else { $null }
        }
    }

    $selection = $available | Out-GridView -Title "Select a subscription. Found: $($SubscriptionList.count)" -OutputMode Single

    try {
        if (-not $selection) {
            Write-Host -ForegroundColor Red "No subscription selected. Operation cancelled."
            return
        }

        Write-Host -ForegroundColor Cyan 'Switching to:', $selection.Subscription
        Set-AzContext -SubscriptionId $selection.SubscriptionId | Out-Null
        Get-AzContext
    } catch {
        Write-Host -ForegroundColor Red "Invalid input, please enter a valid index!"
    }
}

Clear-Host
Switch-AzContext