# Generated on 04/16/2025 21:38:23 by .\build\orca\Update-OrcaTests.ps1

using module ".\orcaClass.psm1"

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectComparisonWithNull', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()


<#

ORCA-107 Check if End-user Spam notification is enabled and the notification frequency is less than equal to 3 days

#>



class ORCA107 : ORCACheck
{
    <#
    
        CONSTRUCTOR with Check Header Data
    
    #>

    ORCA107()
    {
        $this.Control="ORCA-107"
        $this.Area="Quarantine Policies"
        $this.Name="End-user Spam notifications"
        $this.PassText="End-user spam notification is enabled"
        $this.FailRecommendation="Enable End-user Spam notifications on a quarantine policy"
        $this.Importance="Enable End-user Spam notifications to let users manage their own spam-quarantined messages (Release, Block sender, Review). End-user spam notifications contain a list of all spam-quarantined messages that the end-user has received during a time period. Policies that do not apply to a spam policy as either a spam, or bulk action, will appear disabled below."
        $this.ExpandResults=$True
        $this.CheckType=[CheckType]::ObjectPropertyValue
        $this.ObjectType="Quarantine Policy"
        $this.ItemName="Setting"
        $this.DataType="Current Value"
        $this.Links= @{
            "Microsoft 365 Defender Portal - Anti-spam settings"="https://security.microsoft.com/antispam"
            "Configure end-user spam notifications in Exchange Online"="https://aka.ms/orca-antispam-docs-2"
            "Recommended settings for EOP and Office 365 Microsoft Defender for Office 365 security"="https://aka.ms/orca-atpp-docs-6"
        }
    }

    <#
    
        RESULTS
    
    #>

    GetResults($Config)
    {
        $GlobalPolicy = $Config["QuarantinePolicyGlobal"]

        ForEach($QuarantinePolicy in $Config["QuarantinePolicy"])
        {

            $AppliesSpam = $False
            $AppliesPhish = $False

            ForEach($Policy in $Config["HostedContentFilterPolicy"])
            {
                if($Config["PolicyStates"][$Policy.Guid.ToString()].Applies -eq $True)
                {
                    # Check Spam action
                    if($Policy.SpamAction -eq "Quarantine" -and $Policy.SpamQuarantineTag -eq $QuarantinePolicy.Name)
                    {
                        $AppliesSpam = $True
                    }

                    # Check HC Spam Action
                    if($Policy.HighConfidenceSpamAction -eq "Quarantine" -and $Policy.HighConfidenceSpamQuarantineTag -eq $QuarantinePolicy.Name)
                    {
                        $AppliesSpam = $True
                    }

                    # Check Bulk Action
                    if($Policy.BulkSpamAction -eq "Quarantine" -and $Policy.BulkQuarantineTag -eq $QuarantinePolicy.Name)
                    {
                        $AppliesSpam = $True
                    }

                    # Check Phish Action
                    if($Policy.PhishSpamAction -eq "Quarantine" -and $Policy.PhishQuarantineTag -eq $QuarantinePolicy.Name)
                    {
                        $AppliesPhish = $True
                    }

                    # Check HC Phish Action
                    if($Policy.HighConfidencePhishAction -eq "Quarantine" -and $Policy.HighConfidencePhishQuarantineTag -eq $QuarantinePolicy.Name)
                    {
                        $AppliesPhish = $True
                    }
                }
            }
            
            $ConfigObject = [ORCACheckConfig]::new()
            $ConfigObject.Object=$QuarantinePolicy.Name
            $ConfigObject.ConfigReadonly=($QuarantinePolicy.Name -eq "DefaultFullAccessWithNotificationPolicy" -or $QuarantinePolicy.Name -eq "DefaultFullAccessPolicy" -or $QuarantinePolicy.Name -eq "AdminOnlyAccessPolicy")
            $ConfigObject.ConfigItem="ESNEnabled"
            $ConfigObject.ConfigData = $QuarantinePolicy.ESNEnabled

            if($AppliesSpam)
            {
                if($QuarantinePolicy.ESNEnabled -eq $True)
                {
                    $ConfigObject.SetResult([ORCAConfigLevel]::Standard,[ORCAResult]::Pass)
                } 
                else 
                {
                    $ConfigObject.SetResult([ORCAConfigLevel]::Standard,[ORCAResult]::Fail)
                }
                
                $this.AddConfig($ConfigObject)
            } 
            else 
            {
                # Quarantine policy does not apply to any spam policy
                if($QuarantinePolicy.ESNEnabled -eq $False)
                {
                    $ConfigObject.ConfigDisabled = $True
                    $ConfigObject.SetResult([ORCAConfigLevel]::All,[ORCAResult]::Informational)
                    $ConfigObject.InfoText = "This quarantine policy has notifications turned off, however, it is not used in any spam related action. It is being flagged for awareness purposes only."
                
                    $this.AddConfig($ConfigObject)
                }
            }

        }        
    }

}
