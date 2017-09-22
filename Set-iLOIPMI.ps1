# -------------------------------------------------------------------------------------------------------------
##
##
##      Description:  Configure iLO IPMI.
##
## DISCLAIMER
## The sample scripts are not supported under any HPE standard support program or service.
## The sample scripts are provided AS IS without warranty of any kind. 
## HP further disclaims all implied warranties including, without limitation, any implied 
## warranties of merchantability or of fitness for a particular purpose. 
##
##    
## Scenario
##     	
##	
## Description
##      
##		
##
## Input parameters:
##         iloIP                              = IP address of the ILO Server
##		   iloUSer                            = iLO user name on iLO
##         iloPassword                        = iLO  password
##
##         OVApplianceIP                      = IP address of the OV appliance
##		   OVAdminName                        = Administrator name of the appliance
##         OVAdminPassword                    = Administrator's password
##         OneViewModule                      = OneView library module
##         OVAuthDomain                       = Doamin to authenticate against
##         Server                             = Server hardware in OneView to connect to
##     
##         Enabled                            = Switch to enable/disable IPMI
##
## History: 
##          Aug 2017         - First release
##
##   Version : 1.0
##
##   Version : 1.0 - September 2017
##
## Contact : Dung.HoangKhac@hpe.com
##
##
## -------------------------------------------------------------------------------------------------------------
<#
  .SYNOPSIS
     Configure iLO IPMI.
  
  .DESCRIPTION
	 Configure iLO IPMI.
        
  .EXAMPLE

    .\ Set-iLOIPMI.ps1 -iloIP 10.234.1.21 -iLOUser admin -iLOPassword password -Enabled:$True
        The script connects to the iLO to enable iLO IPMI 

    .\ Set-iLOIPMI.ps1 -iloIP 10.234.1.21 -iLOUser admin -iLOPassword password -Enabled:$False
        The script connects to the iLO to dsiable iLO IPMI 

    .\ Set-iLOIPMI.ps1 -OVApplianceIP 10.254.1.66 -OVAdminName Administrator -password P@ssword1 -Server "Encl1, Bay3" -Enabled:$True
        The script connects to OneView, selects the server specified in parameter and enables iLO IPMI on this server

    .\ Set-iLOIPMI.ps1 -OVApplianceIP 10.254.1.66 -OVAdminName Administrator -password P@ssword1 -Server "Encl1, Bay3" -Enabled:$False
        The script connects to OneView, selects the server specified in parameter and disables iLO IPMI on this server

    

  .PARAMETER iloIP                               
    IP address of the ILO Server

  .PARAMETER iloUSer                            
    iLO user name on iLO

  .PARAMETER iloPassword                       
   iLO  password

  .PARAMETER isoURL                                              
    URL where ISO is OVApplianceIP  

   .PARAMETER Enabled   
     Switch to enable/disable IPMI

  .PARAMETER OVApplianceIP                   
    IP address of the OV appliance

  .PARAMETER OVAdminName                     
    Administrator name of the appliance

  .PARAMETER OVAdminPassword                 
    Administrator s password
  
  .PARAMETER OneViewModule
    Module name for POSH OneView library.
	
  .PARAMETER OVAuthDomain
    Authentication Domain to login in OneView.

  .PARAMETER Server    
    Server hardware in OneView to connect to

  .Notes
    NAME:  Set-iLOIPMI
    LASTEDIT: 09/20/2017
    KEYWORDS: Provision Server
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 5.0
 #>
  
## -------------------------------------------------------------------------------------------------------------

Param ( 

[boolean]$Enabled        = $False,
[string]$iLOIP          = "",
[string]$iLOUser        = "",
[string]$iLOpassword    = "",


[string]$Server                 = "Rack1Bot, Bay 9",
[string]$OVApplianceIP          = "10.254.1.21", 
[string]$OVAdminName            = "Administrator", 
[string]$OVAdminPassword        = "Password",
[string]$OVAuthDomain           = "local",
[string]$OneViewModule          = "HPOneView.310"
)






$RESTRoot      = "/rest/v1"
$RESTAccount   = "/rest/v1/AccountService"
$RESTChassis   = "/rest/v1/Chassis"
$RESTEvent     = "/rest/v1/EventService"
$RESTManagers  = "/rest/v1/Managers"
$RESTSession   = "/rest/v1/SessionService"
$RESTSystems   = "/rest/v1/Systems"

$iLOSession    = $NULL

Disable-HPRESTCertificateAuthentication

if ($iLOIP -and $iLOUser -and $iLOPassword)
{
    Try 
    {
        $iLOSession    = Connect-HPREST -address $iLOIP -username $iLOuser -password $iLOpassword -ErrorAction stop
    }
    catch 
    {
        write-host -foreground Yellow " Cannot connect to ILO with $iLOIP / user: $iLOuser / password: $iLOpassword. "
    }
}
else 
{

    # -------------------------------Use OneView 
    $LoadedModule = get-module -listavailable $OneviewModule


    if ($LoadedModule -ne $NULL)
    {
            $LoadedModule = $LoadedModule.Name.Split('.')[0] + "*"
            remove-module $LoadedModule
    }

    import-module $OneViewModule


    # ---------------- Connect to OneView appliance

    write-host -foreground Cyan "$CR Connect to the OneView appliance..."
    try 
    {
        $ThisConnection =  Connect-HPOVMgmt -hostname $OVApplianceIP -user $OVAdminName -password $OVAdminPassword  -AuthLoginDomain $OVAuthDomain    
    }
    catch 
    {
        write-host -foreground Yellow " Cannot connect to OneView $OVApplianceIP ...."
    }

    # ----------------Get Server 
    if ($Server)
    {
        try 
        {
            $ThisServer     = Get-HPOVServer -name $Server 
        }
        catch 
        {
            $iLOSession = $ThisServer = $NULL
        }
        if ($ThisServer)
        {
            $iLOSession = $ThisServer | Get-HPOVIloSso -IloRestSession
        }
        else 
        {
            write-host -foreground Yellow "Server hardware --> $Server does not exist in OneView. Exiting now... "
            
        }
    }
    else 
    {
        write-host -foreground Yellow "No server specified. Specify server name and re-run the script "
    }
}

if ($iLOSession)
{
    $Managers      = Get-HPRESTDataRaw  -Href $RESTManagers -session $iLOSession

    foreach ($Manager in $Managers.links.member.href) # /rest/v1/managers/1 or /rest/v1/managers/2
    {
        $ManagerData            = Get-HPRESTDataRaw  -Href $Manager -session $iLOSession
        $NetworkService         = Get-HPRESTDataRaw  -Href $ManagerData.links.NetworkService.href -session $iLOSession
       
       
        $NewIPMISetting         = @{'Enabled'=$Enabled}

        $NewNetworkServiceSetting   = @{'IPMI' = $NewIPMISetting}

        $action = if ($Enabled) { 'Enabling '} else { 'Disabling '} 
        write-host -foreground CYAN "$action IPMI...."
        $res = Set-HPRESTData -Href $NetworkService.links.self.href -Setting $NewNetworkServiceSetting -Session $iLOSession

        $NetworkService         = Get-HPRESTDataRaw  -Href $ManagerData.links.NetworkService.href -session $iLOSession
        $CurrentIPMISetting     = $NetworkService.IPMI
        write-host -ForegroundColor CYAN " IPMI setting is now...."
        $CurrentIPMISetting
    }

    # ----- Disconnect
    Disconnect-HPREST -Session $iLOSession
    if ($ThisConnection)
    {
        Disconnect-HPOVMgmt 
    }

}


