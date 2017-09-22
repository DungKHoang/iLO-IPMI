# iLO-IPMI
The Set-iLOIPMI.ps1 script configures IPMI settings for a given server

# Pre-requisites
The script requires the following HPE Libraries:
    * HPE iLORest cmdlets
    * HPE OneView PowerShell library 

If you are suing a Windows Server 2012 R2 or Windows 7 machine, you need to install the Windows Management Framework v5.0


## Intalling the HPE libraries
    * HPE iLORest cmdlets 
```
    Install-Module HPRestCmdlets
```    
    * HPE OneView PowerShell library
```
    Install-Module HPOneView.310
``` 


### Syntax

There are two(2) scenarios:
    * Connecting to a server through ILO directly
```

    .\ Set-iLOIPMI.ps1 -iloIP 10.234.1.21 -iLOUser admin -iLOPassword password -Enabled:$True
        The script connects to the iLO to enable iLO IPMI 

    .\ Set-iLOIPMI.ps1 -iloIP 10.234.1.21 -iLOUser admin -iLOPassword password -Enabled:$False
        The script connects to the iLO to dsiable iLO IPMI 


```

    * Connecting through OneView
```

    .\ Set-iLOIPMI.ps1 -OVApplianceIP 10.254.1.66 -OVAdminName Administrator -password P@ssword1 -Server "Encl1, Bay3" -Enabled:$True
        The script connects to OneView, selects the server specified in parameter and enables iLO IPMI on this server

    .\ Set-iLOIPMI.ps1 -OVApplianceIP 10.254.1.66 -OVAdminName Administrator -password P@ssword1 -Server "Encl1, Bay3" -Enabled:$False
        The script connects to OneView, selects the server specified in parameter and disables iLO IPMI on this server
```
