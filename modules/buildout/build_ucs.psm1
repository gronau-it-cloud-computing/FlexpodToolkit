﻿function Housekeeping {
    Remove-UcsServerPool -ServerPool default -Force
    Remove-UcsIpPool -IpPool iscsi-initiator-pool -Force
    Remove-UcsUuidSuffixPool -UuidSuffixPool default -Force
    Remove-UcsMacPool -MacPool default -Force
    Remove-UcsWwnPool -WwnPool default -Force
    Remove-UcsWwnPool -WwnPool node-default -Force
    Add-UcsIpPoolBlock -IpPool isci-initiator-pool -From 1.1.1.1 -To 1.1.1.1 -Subnet 255.255.255.0 -DefGw 0.0.0.0 -PrimDns 0.0.0.0 -SecDns 0.0.0.0
    #really should also remove ext-mgmt and create in suborg. Would need to update SPT references as well.

    $rootOrg = Get-UcsOrg -Level root
    $result = Get-UcsOrg -Org $rootOrg -Name $organization
    if(!$result) {
        $ourOrg = Add-UcsOrg -Org $rootOrg -Name $organization
    } else {
        Write-host "Organization $organization already exists, skipping"
        $ourOrg = $result
    }
    Clear-Variable $result
}
export-modulemember -function Housekeeping

function Create-VLANsAndVSANs {

    #Obviously need to move to a CSV format, perhaps take it's location as an argument

    ##It is important to give all VLANs names in this part of the script, as the "name" parameter is used later when creating vNICs. Future iterations will not have this requirement.
    Get-UcsLanCloud | Add-UcsVlan -Name 1000v_Control -Id 232
    Get-UcsLanCloud | Add-UcsVlan -Name NFS -Id 233
    Get-UcsLanCloud | Add-UcsVlan -Name CIFS -Id 234
    Get-UcsLanCloud | Add-UcsVlan -Name SAN_Replication -Id 237
    Get-UcsLanCloud | Add-UcsVlan -Name Back_End -Id 238
    Get-UcsLanCloud | Add-UcsVlan -Name Backup -Id 239

    Get-UcsLanCloud | Add-UcsVlan -Name ESX_MGMT -Id 240
    Get-UcsLanCloud | Add-UcsVlan -Name ESX_VMOTION -Id 241

    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_248 -Id 248
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_249 -Id 249
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_250 -Id 250
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_251 -Id 251
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_252 -Id 252
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_253 -Id 253
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_254 -Id 254
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_255 -Id 255
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_256 -Id 256
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_257 -Id 257
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_258 -Id 258
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_259 -Id 259
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_260 -Id 260
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_261 -Id 261
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_262 -Id 262
    Get-UcsLanCloud | Add-UcsVlan -Name Front_End_263 -Id 263
    Get-UcsLanCloud | Add-UcsVlan -Name NATPool_External -Id 264
    Get-UcsLanCloud | Add-UcsVlan -Name NATPool_Conventional -Id 296
    Get-UcsLanCloud | Add-UcsVlan -Name FinInstPrivate -Id 294

    Get-UcsFiSanCloud -Id A | Add-UcsVsan -Name VSAN_A -Id 235 -fcoevlan 235 -zoningstate disabled
    Get-UcsFiSanCloud -Id B | Add-UcsVsan -Name VSAN_B -Id 236 -fcoevlan 236 -zoningstate disabled

}
export-modulemember -function Create-VLANsAndVSANs


function Create-ResourcePools {

    #ADD Managment IP Pool Block
    add-ucsippoolblock -IpPool "ext-mgmt" -from $mgmt_ippoolstart -to $mgmt_ippoolfinish -defgw $mgmt_ippoolgw -modifypresent:$true

    #create UUID pools
    $uuidPool = Add-UcsUuidSuffixPool -Org $organization -Name "UUID-ESX" -AssignmentOrder "sequential" -Descr "UUID Pool - ESXi" -Prefix derived
    Add-UcsUuidSuffixBlock -UuidSuffixPool $uuidPool -From "0000-25B511EE0000" -To "0000-25B511EE00FF"

    $uuidPool = Add-UcsUuidSuffixPool -Org $organization -Name "UUID-ORC" -AssignmentOrder "sequential" -Descr "UUID Pool - Oracle" -Prefix derived
    Add-UcsUuidSuffixBlock -UuidSuffixPool $uuidPool -From "0000-25B512EE0000" -To "0000-25B512EE00FF"


    #create MAC pools
    $macPool = Add-UcsMacPool -Org $organization -Name "MAC-ESX-A" -AssignmentOrder "sequential" -Descr "ESXi Fabric A"
    Add-UcsMacMemberBlock -MacPool $macPool -From "00:25:B5:11:A0:00" -To "00:25:B5:11:A0:FF"

    $macPool = Add-UcsMacPool -Org $organization -Name "MAC-ESX-B" -AssignmentOrder "sequential" -Descr "ESXi Fabric B"
    Add-UcsMacMemberBlock -MacPool $macPool -From "00:25:B5:11:B0:00" -To "00:25:B5:11:B0:FF"

    $macPool = Add-UcsMacPool -Org $organization -Name "MAC-ORC-A" -AssignmentOrder "sequential" -Descr "Oracle Fabric A"
    Add-UcsMacMemberBlock -MacPool $macPool -From "00:25:B5:12:A0:00" -To "00:25:B5:12:A0:FF"

    $macPool = Add-UcsMacPool -Org $organization -Name "MAC-ORC-B" -AssignmentOrder "sequential" -Descr "Oracle Fabric B"
    Add-UcsMacMemberBlock -MacPool $macPool -From "00:25:B5:12:B0:00" -To "00:25:B5:12:B0:FF"

    #create WWPN pools
    $wwnPool = Add-UcsWwnPool -Org $organization -Name "WWPN-ESX-A" -AssignmentOrder "sequential" -Purpose "port-wwn-assignment" -Descr "ESXi Fabric A"
    Add-UcsWwnMemberBlock -wwnPool $wwnPool -From "20:00:00:25:B5:11:A0:00" -To "20:00:00:25:B5:11:A0:FF"

    $wwnPool = Add-UcsWwnPool -Org $organization -Name "WWPN-ESX-B" -AssignmentOrder "sequential" -Purpose "port-wwn-assignment" -Descr "ESXi Fabric B"
    Add-UcsWwnMemberBlock -wwnPool $wwnPool -From "20:00:00:25:B5:11:B0:00" -To "20:00:00:25:B5:11:B0:FF"

    $wwnPool = Add-UcsWwnPool -Org $organization -Name "WWPN-ORC-A" -AssignmentOrder "sequential" -Purpose "port-wwn-assignment" -Descr "Oracle Fabric A"
    Add-UcsWwnMemberBlock -wwnPool $wwnPool -From "20:00:00:25:B5:12:A0:00" -To "20:00:00:25:B5:12:A0:FF"

    $wwnPool = Add-UcsWwnPool -Org $organization -Name "WWPN-ORC-B" -AssignmentOrder "sequential" -Purpose "port-wwn-assignment" -Descr "Oracle Fabric B"
    Add-UcsWwnMemberBlock -wwnPool $wwnPool -From "20:00:00:25:B5:12:B0:00" -To "20:00:00:25:B5:12:B0:FF"

    #create WWNN pools
    $wwnPool = Add-UcsWwnPool -Org $organization -Name "WWNN-ESX" -AssignmentOrder "sequential" -Purpose "node-wwn-assignment" -Descr "ESXi WWNs"
    Add-UcsWwnMemberBlock -wwnPool $wwnPool -From "20:00:00:25:B5:11:F0:00" -To "20:00:00:25:B5:11:F0:FF"

    $wwnPool = Add-UcsWwnPool -Org $organization -Name "WWNN-ORC" -AssignmentOrder "sequential" -Purpose "node-wwn-assignment" -Descr "Oracle WWNs"
    Add-UcsWwnMemberBlock -wwnPool $wwnPool -From "20:00:00:25:B5:12:F0:00" -To "20:00:00:25:B5:12:F0:FF"


    #create server pools
    Add-UcsServerPool -Org $organization -Name "B200-M3-POOL" -Descr "B200M3 Servers (Vmware)"
    Add-UcsServerPool -Org $organization -Name "B440-M2-POOL" -Descr "B440M2 Servers (Oracle on Vmware)"

}
export-modulemember -function Create-ResourcePools

function Create-StaticPolicies {
    #Set Chassis Discovery Policy
    Get-UcsChassisDiscoveryPolicy | Set-UcsChassisDiscoveryPolicy -Action 2-link -LinkAggregationPref port-channel -Rebalance immediate -Force

    #Set Power Control Policy
    Get-UcsPowerControlPolicy | Set-UcsPowerControlPolicy -Redundancy grid -Force

    #Set MAC Aging Policy
    get-ucslancloud | set-ucslancloud -macaging mode-default -force 

    #Set Global Power Allocation Policy
    #NOTWORKING -  set-ucspowergroup does not modify this... cannot find within PowerTool

    #CONFIGURE QOS
    get-ucsqosclass platinum | set-ucsqosclass -mtu 1500 -Force -Adminstate disabled
    get-ucsqosclass gold | set-ucsqosclass -mtu 1500 -Force -Adminstate disabled
    get-ucsqosclass silver | set-ucsqosclass -mtu 9000 -Force -Adminstate enabled
    get-ucsqosclass bronze | set-ucsqosclass -mtu 9000 -Force -Adminstate enabled
    get-ucsqosclass best-effort | set-ucsqosclass -mtu 1500 -Force -Adminstate enabled

    #Configure NTP
    #add-ucsntpserver -name $ntp1
    #add-ucsntpserver -name $ntp2

    #Configure TimeZone
    #set-ucstimezone -timezone "America/New_York (Eastern Time)" -Force

    #Configure SNMP Community
    #set-ucssnmp -community $snmpcomm -syscontact ENOC -syslocation $snmplocation -adminstate enabled -force

    #Configure SNMP Traps
    #add-ucssnmptrap -hostname $traphost1 -community $snmpcomm -notificationtype traps -port 162 -version v2c
    #add-ucssnmptrap -hostname $traphost2 -community $snmpcomm -notificationtype traps -port 162 -version v2c

    #Create QOS Policies
    Start-UcsTransaction
    $mo = Get-UcsOrg -Name $organization | Add-UcsQosPolicy -Name BE
    $mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -Burst 10240 -HostControl full -Prio "best-effort" -Rate line-rate
    Complete-UcsTransaction

    Start-UcsTransaction
    $mo = Get-UcsOrg -Name $organization | Add-UcsQosPolicy -Name Bronze
    $mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -Burst 10240 -HostControl none -Prio "bronze" -Rate line-rate
    Complete-UcsTransaction

    Start-UcsTransaction
    $mo = Get-UcsOrg -Name $organization | Add-UcsQosPolicy -Name Gold
    $mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -Burst 10240 -HostControl none -Prio "gold" -Rate line-rate
    Complete-UcsTransaction

    Start-UcsTransaction
    $mo = Get-UcsOrg -Name $organization | Add-UcsQosPolicy -Name Platinum
    $mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -Burst 10240 -HostControl none -Prio "platinum" -Rate line-rate
    Complete-UcsTransaction

    Start-UcsTransaction
    $mo = Get-UcsOrg -Name $organization | Add-UcsQosPolicy -Name Silver
    $mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -Burst 10240 -HostControl none -Prio "silver" -Rate line-rate
    Complete-UcsTransaction



    #Server Pool Qualification Policies and map to Server Pool 
    $SPQname = "B200-M3-QUAL"
    $poolDN = "org-root/org-" + $organization + "/compute-pool-B200-M3-POOL"
    $SPQ = Add-UcsServerPoolQualification -Org $organization -Name $SPQname 
    $SPQ | Add-UcsServerModelQualification -Model "UCSB-B200-M3"
    Add-UcsServerPoolPolicy -Org $organization -Name "B200-M3-POOL" -Qualifier $SPQname -PoolDN $poolDN

    $SPQname = "B440-M2-QUAL"
    $poolDN = "org-root/org-" + $organization + "/compute-pool-B440-M2-POOL"
    $SPQ = Add-UcsServerPoolQualification -Org $organization -Name $SPQname 
    $SPQ | Add-UcsServerModelQualification -Model "B440-BASE-M2"
    Add-UcsServerPoolPolicy -Org $organization -Name "B440-M2-POOL" -Qualifier $SPQname -PoolDN $poolDN


    #Create blank host firmware package as a placeholder - must manually configure if you want this to do anything. 
    #More functionality in later versions.
    Add-UcsFirmwareComputeHostPack -Org $organization -Name B200M3-FW-PLCY
    Add-UcsFirmwareComputeHostPack -Org $organization -Name B440M2-FW-PLCY

    <# Need to flush out host firmware package creation here

    $host_firm_pack = Add-UcsFirmwareComputeHostPack -Name host_firm_pack -IgnoreCompCheck no
    $host_firm_pack | Add-UcsFirmwarePackItem -Type adaptor -HwModel N20-AC0002 -HwVendor "Cisco Systems Inc" -Version '1.4(1i)'
    $host_firm_pack | Get-UcsFirmwarePackItem -HwModel N20-AC0002 | Set-UcsFirmwarePackItem -Version '2.0(1t)'

    http://www.cisco.com/en/US/docs/unified_computing/ucs/sw/msft_tools/powertools/ucs_powertool_book/ucs_pwrtool_bkl1.html#wp439024

    #>

    #IMPORTANT - Add UCS Maintenance Policy for user-ack. Need to map all SPs or SPTs to this policy
    Add-UcsMaintenancePolicy -Org $organization -Name "MAINT-USER-ACK" -UptimeDisr user-ack



}
export-modulemember -function Create-StaticPolicies

function Create-BootPolicy {
    #This function was moved out of the main policy creation function because BFS can be driven by data retrieved from the storage array.
    #Ideally, the main function should reach into the array (should have a "retrieve four targets" function for this) then this function gets run with an array as an argument for those four tagets to fall into.

    $bp = Add-UcsBootPolicy -Org $organization -Name "BFS-ESX" -EnforceVnicName yes
    $bp | Add-UcsLsBootVirtualMedia -Access "read-only" -Order "1"
    $bootstorage = $bp | Add-UcsLsbootStorage -ModifyPresent -Order "2"
    $bootsanimage = $bootstorage | Add-UcsLsbootSanImage -Type "primary" -VnicName "ESX-VHBA-A"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "primary" -Wwn "50:00:00:00:00:00:00:00"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "secondary" -Wwn "50:00:00:00:00:00:00:00"

    $bootsanimage = $bootstorage | Add-UcsLsbootSanImage -Type "secondary" -VnicName "ESX-VHBA-B"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "primary" -Wwn "50:00:00:00:00:00:00:00"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "secondary" -Wwn "50:00:00:00:00:00:00:00"

    $bp = Add-UcsBootPolicy -Org $organization -Name "BFS-ORC" -EnforceVnicName yes
    $bp | Add-UcsLsBootVirtualMedia -Access "read-only" -Order "1"
    $bootstorage = $bp | Add-UcsLsbootStorage -ModifyPresent -Order "2"
    $bootsanimage = $bootstorage | Add-UcsLsbootSanImage -Type "primary" -VnicName "ORC-VHBA-A"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "primary" -Wwn "50:00:00:00:00:00:00:00"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "secondary" -Wwn "50:00:00:00:00:00:00:00"

    $bootsanimage = $bootstorage | Add-UcsLsbootSanImage -Type "secondary" -VnicName "ORC-VHBA-B"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "primary" -Wwn "50:00:00:00:00:00:00:00"
    $bootsanimage | Add-UcsLsbootSanImagePath -Lun 0 -Type "secondary" -Wwn "50:00:00:00:00:00:00:00"
}
export-modulemember -function Create-BootPolicy

function Create-vNICvHBATemplates { 

    #Right now, this vNIC/vHBA creation process is pretty much garbage. It works, but it is among the ugliest parts of this script. I will be changing things around quite a bit later.

    # $allowedVLANs is an array, so you can define a list like this: $allowedVLANs =  310, 312, 320, 314, 316, 318

    #create vNIC Templates

    #ESXi
    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ESX-MGMT" -Descr "ESXi Management" -IdentPoolName "MAC-ESX-A" -Mtu 1500 -SwitchId A-B -TemplType "updating-template" -QosPolicyName "BE" 
    $allowedVLANs = 240
    $nativeVLAN = 240
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }

    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ESX-VMOT" -Descr "ESXi vMotion" -IdentPoolName "MAC-ESX-B" -Mtu 9000 -SwitchId B-A -TemplType "updating-template" -QosPolicyName "Bronze" 
    $allowedVLANs = 241
    $nativeVLAN = 241
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }

    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ESX-1KV-A" -Descr "Nexus 1000v Uplink Fabric A" -IdentPoolName "MAC-ESX-A" -Mtu 9000 -SwitchId A -TemplType "updating-template" -QosPolicyName "BE" 
    $allowedVLANs = 232, 233, 234, 237, 238, 239, 240, 241, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 260, 261, 262, 263, 264, 296, 294
    $nativeVLAN = 0
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }

    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ESX-1KV-B" -Descr "Nexus 1000v Uplink Fabric B" -IdentPoolName "MAC-ESX-B" -Mtu 9000 -SwitchId B -TemplType "updating-template" -QosPolicyName "BE" 
    $allowedVLANs = 232, 233, 234, 237, 238, 239, 240, 241, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 260, 261, 262, 263, 264, 296, 294
    $nativeVLAN = 0
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }



    #Oracle
    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ORC-MGMT" -Descr "ESXi Management" -IdentPoolName "MAC-ORC-A" -Mtu 1500 -SwitchId A-B -TemplType "updating-template" -QosPolicyName "BE" 
    $allowedVLANs = 240
    $nativeVLAN = 240
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }

    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ORC-VMOT" -Descr "ESXi vMotion" -IdentPoolName "MAC-ORC-B" -Mtu 9000 -SwitchId B-A -TemplType "updating-template" -QosPolicyName "Bronze" 
    $allowedVLANs = 241
    $nativeVLAN = 241
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }

    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ORC-1KV-A" -Descr "Nexus 1000v Uplink Fabric A" -IdentPoolName "MAC-ORC-A" -Mtu 9000 -SwitchId A -TemplType "updating-template" -QosPolicyName "BE" 
    $allowedVLANs = 232, 233, 234, 237, 238, 239, 240, 241, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 260, 261, 262, 263, 264, 296, 294
    $nativeVLAN = 0
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }

    $vNicTemplate = Add-UcsVnicTemplate -Org $organization -Name "ORC-1KV-B" -Descr "Nexus 1000v Uplink Fabric B" -IdentPoolName "MAC-ORC-B" -Mtu 9000 -SwitchId B -TemplType "updating-template" -QosPolicyName "BE" 
    $allowedVLANs = 232, 233, 234, 237, 238, 239, 240, 241, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 260, 261, 262, 263, 264, 296, 294
    $nativeVLAN = 0
    foreach ($vlan in $allowedVLANs)
    {
        if($vlan -eq $nativeVLAN) {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet true
        } else {
            $vlanName = Get-UcsVlan -Id $vlan | select name
            Add-UcsVnicInterface -VnicTemplate $vNicTemplate -name $vlanName.name -DefaultNet false
        }
    }


    #create vHBA Templates
    $vHbaTemplate = Add-UcsVhbaTemplate -Org $organization -Name "ESX-VHBA-A" -Descr "ESXi Fabric A" -IdentPoolName "WWPN-ESX-A" -SwitchId A -TemplType "updating-template"
    $vsanName = Get-UcsVsan -Id 235 | select name
    Add-UcsVhbaInterface -VhbaTemplate $vHbaTemplate -name $vsanName.name

    $vHbaTemplate = Add-UcsVhbaTemplate -Org $organization -Name "ESX-VHBA-B" -Descr "ESXi Fabric B" -IdentPoolName "WWPN-ESX-B" -SwitchId B -TemplType "updating-template"
    $vsanName = Get-UcsVsan -Id 236 | select name
    Add-UcsVhbaInterface -VhbaTemplate $vHbaTemplate -name $vsanName.name

    $vHbaTemplate = Add-UcsVhbaTemplate -Org $organization -Name "ORC-VHBA-A" -Descr "Oracle Fabric A" -IdentPoolName "WWPN-ORC-A" -SwitchId A -TemplType "updating-template"
    $vsanName = Get-UcsVsan -Id 235 | select name
    Add-UcsVhbaInterface -VhbaTemplate $vHbaTemplate -name $vsanName.name

    $vHbaTemplate = Add-UcsVhbaTemplate -Org $organization -Name "ORC-VHBA-B" -Descr "Oracle Fabric B" -IdentPoolName "WWPN-ORC-B" -SwitchId B -TemplType "updating-template"
    $vsanName = Get-UcsVsan -Id 236 | select name
    Add-UcsVhbaInterface -VhbaTemplate $vHbaTemplate -name $vsanName.name
}
export-modulemember -function Create-vNICvHBATemplates

function Create-SPTemplates { 
    #Create SPT basics
    $SPName = "SPT-ESX"
    $SPT = Add-UcsServiceProfile `
    -Org $organization `
    -Name $SPName `
    -Descr "ESXi Service Profile Template" `
    -ExtIPPoolName "ext-mgmt" `
    -BootPolicyName "BFS-ESX" `
    -ExtIPState "pooled" `
    -HostFwPolicyName "B200M3-FW-PLCY" `
    -IdentPoolName "UUID-ESX" `
    -MaintPolicyName "MAINT-USER-ACK" `
    -Type "updating-template"

    #Assign SPT to pre-existing server pool
    $SPT | Add-UcsServerPoolAssignment -Name "B200-M3-POOL" -RestrictMigration "no"

    #Assign the appropriate WWNN pool to this SPT
    $SPT | Add-UcsVnicFcNode -IdentPoolName "WWNN-ESX"

    #Create a list of vNICs to Assign to this SPT and loop through and assign them
    $vNicArray = `
    "ESX-MGMT", `
    "ESX-VMOT", `
    "ESX-1KV-A", `
    "ESX-1KV-B"


    foreach ($vNicInstance in $vNicArray) {
        Get-UcsServiceProfile -Name $SPName | Add-UcsVnic -NwTemplName $vNicInstance -Name $vNicInstance -AdaptorProfileName "Vmware"
    }

    #Create a list of vHBAs to Assign to this SPT and loop through and assign them
    $vHbaArray = `
    "ESX-VHBA-A", `
    "ESX-VHBA-B"

    foreach ($vHbaInstance in $vHbaArray) {
        Get-UcsServiceProfile -Name $SPName | Add-UcsVhba -NwTemplName $vHbaInstance -Name $vHbaInstance -AdaptorProfileName "Vmware"
    }



    #Create SPT basics
    $SPName = "SPT-ORC"
    $SPT = Add-UcsServiceProfile `
    -Org $organization `
    -Name $SPName `
    -Descr "Oracle Service Profile Template" `
    -ExtIPPoolName "ext-mgmt" `
    -BootPolicyName "BFS-ORC" `
    -ExtIPState "pooled" `
    -HostFwPolicyName "B440M2-FW-PLCY" `
    -IdentPoolName "UUID-ORC" `
    -MaintPolicyName "MAINT-USER-ACK" `
    -Type "updating-template"

    #Assign SPT to pre-existing server pool
    $SPT | Add-UcsServerPoolAssignment -Name "B440-M2-POOL" -RestrictMigration "no"

    #Assign the appropriate WWNN pool to this SPT
    $SPT | Add-UcsVnicFcNode -IdentPoolName "WWNN-ORC"

    #Create a list of vNICs to Assign to this SPT and loop through and assign them
    $vNicArray = `
    "ORC-MGMT", `
    "ORC-VMOT", `
    "ORC-1KV-A", `
    "ORC-1KV-B"

    foreach ($vNicInstance in $vNicArray) {
        Get-UcsServiceProfile -Name $SPName | Add-UcsVnic -NwTemplName $vNicInstance -Name $vNicInstance -AdaptorProfileName "Vmware"
    }

    #Create a list of vHBAs to Assign to this SPT and loop through and assign them
    $vHbaArray = `
    "ORC-VHBA-A", `
    "ORC-VHBA-B"

    foreach ($vHbaInstance in $vHbaArray) {
        Get-UcsServiceProfile -Name $SPName | Add-UcsVhba -NwTemplName $vHbaInstance -Name $vHbaInstance -AdaptorProfileName "Vmware"
    }
}
export-modulemember -function Create-SPTemplates


<#
#Generate 2 Service Profiles from each template - THIS IS TERRIBLE AND UGLY AND YOU NEED TO MAKE THIS NOT SUCK
$SPTArray = Get-UcsServiceProfile -Type updating-template | select name
foreach ($SPTname in $SPTArray) {
    $sptNameLength = $SPTname.name.length
    $spName = "SP_" + $SPTname.name.substring(4, $sptNameLength - 4) + "01"
    Add-UcsServiceProfile -Org $organization -SrcTemplName $SPTname.name -Name $spName
    $spName = "SP_" + $SPTname.name.substring(4, $sptNameLength - 4) + "02"
    Add-UcsServiceProfile -Org $organization -SrcTemplName $SPTname.name -Name $spName
}
#>