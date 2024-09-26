#azure-subscription-switcher
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
            Active = if ($_.Id -eq $SubscriptionActive.Subscription.Id) { "===>" } else { $null }
            Index = $index++
            Subscription = $_.Name
            SubscriptionId = $_.Id
            State = $_.State
            HomeTenantId = $_.HomeTenantId
            Account = if ($_.Id -eq $SubscriptionActive.Subscription.Id) { $SubscriptionActive.Account.Id } else { $null }
        }
    }

    $available | Format-Table -AutoSize

    try {
        [int]$userInput = Read-Host "Index (0 to quit)"

        if ($userInput -eq 0) {
            Write-Host -ForegroundColor Red 'Won''t switch Azure PowerShell context!'
            return
        } elseif ($userInput -lt 1 -or $userInput -gt $index-1) {
            Write-Host -ForegroundColor Red "Input out of range"
            return
        }

        $selection = $available | Where-Object { $_.Index -eq $userInput }
        Write-Host -ForegroundColor Cyan 'Switching to:', $selection.Subscription
        Set-AzContext -SubscriptionId $selection.SubscriptionId | Out-Null
        Get-AzContext
    } catch {
        Write-Host -ForegroundColor Red "Invalid input, please enter a valid index!"
    }
}

Clear-Host
Switch-AzContext