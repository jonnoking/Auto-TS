
#
# Created by Arleta Wanat, 2015 
#
# The following cmdlets are a result of passion and hours of work and research. 
# They are distributed freely and happily to anyone who needs them in a day-to-day administration
# in hope they will make your work easier and allow you to manage your SharePoint Online 
# in ways not possible either through User Interface or Sharepoint Online Management Shell.
#
#
#
# The cmdlets can be used as basis for creating scripts and other solutions.
# If you are using the following code for any of your own works, please acknowledge my contribution.
#
#



function Get-SPOListCount
{
  
  $ctx.Load($ctx.Web.Lists)
  $ctx.ExecuteQuery()
  $i=0

  foreach( $ll in $ctx.Web.Lists)
  {
            
        $i++

        
        }
  
        $obj = New-Object PSObject
        $obj | Add-Member NoteProperty Url($ctx.Web.Url)
        $obj | Add-Member NoteProperty Count($i)
        
        Write-Output $obj
  
  
  }




function Get-SPOList
{
  
   param (
        [Parameter(Mandatory=$false,Position=0)]
		[bool]$IncludeAllProperties=$false
		)
  
  
  
  $ctx.Load($ctx.Web.Lists)
  $ctx.ExecuteQuery()
  Write-Host 
  Write-Host $ctx.Url -BackgroundColor White -ForegroundColor DarkGreen
  foreach( $ll in $ctx.Web.Lists)
  {
            
        $ctx.Load($ll.RootFolder)
        $ctx.Load($ll.DefaultView)
        $ctx.Load($ll.Views)
        $ctx.Load($ll.WorkflowAssociations)

        try
        {
        $ctx.ExecuteQuery()
        }
        catch
        {
        }

        if($IncludeAllProperties)
        {
        
        $obj = New-Object PSObject
  $obj | Add-Member NoteProperty Title($ll.Title)
  $obj | Add-Member NoteProperty Created($ll.Created)
  $obj | Add-Member NoteProperty Tag($ll.Tag)
  $obj | Add-Member NoteProperty RootFolder.ServerRelativeUrl($ll.RootFolder.ServerRelativeUrl)
  $obj | Add-Member NoteProperty BaseType($ll.BaseType)
  $obj | Add-Member NoteProperty BaseTemplate($ll.BaseTemplate)
  $obj | Add-Member NoteProperty AllowContenttypes($ll.AllowContenttypes)
  $obj | Add-Member NoteProperty ContentTypesEnabled($ll.ContentTypesEnabled)
  $obj | Add-Member NoteProperty DefaultView.Title($ll.DefaultView.Title)
  $obj | Add-Member NoteProperty Description($ll.Description)
  $obj | Add-Member NoteProperty DocumentTemplateUrl($ll.DocumentTemplateUrl)
  $obj | Add-Member NoteProperty DraftVersionVisibility($ll.DraftVersionVisibility)
  $obj | Add-Member NoteProperty EnableAttachments($ll.EnableAttachments)
  $obj | Add-Member NoteProperty EnableMinorVersions($ll.EnableMinorVersions)
  $obj | Add-Member NoteProperty EnableFolderCreation($ll.EnableFolderCreation)
  $obj | Add-Member NoteProperty EnableVersioning($ll.EnableVersioning)
  $obj | Add-Member NoteProperty EnableModeration($ll.EnableModeration)
  $obj | Add-Member NoteProperty Fields.Count($ll.Fields.Count)
  $obj | Add-Member NoteProperty ForceCheckout($ll.ForceCheckout)
  $obj | Add-Member NoteProperty Hidden($ll.Hidden)
  $obj | Add-Member NoteProperty Id($ll.Id)
  $obj | Add-Member NoteProperty IRMEnabled($ll.IRMEnabled)
  $obj | Add-Member NoteProperty IsApplicationList($ll.IsApplicationList)
  $obj | Add-Member NoteProperty IsCatalog($ll.IsCatalog)
  $obj | Add-Member NoteProperty IsPrivate($ll.IsPrivate)
  $obj | Add-Member NoteProperty IsSiteAssetsLibrary($ll.IsSiteAssetsLibrary)
  $obj | Add-Member NoteProperty ItemCount($ll.ItemCount)
  $obj | Add-Member NoteProperty LastItemDeletedDate($ll.LastItemDeletedDate)
  $obj | Add-Member NoteProperty MultipleDataList($ll.MultipleDataList)
  $obj | Add-Member NoteProperty NoCrawl($ll.NoCrawl)
  $obj | Add-Member NoteProperty OnQuickLaunch($ll.OnQuickLaunch)
  $obj | Add-Member NoteProperty ParentWebUrl($ll.ParentWebUrl)
  $obj | Add-Member NoteProperty TemplateFeatureId($ll.TemplateFeatureId)
  $obj | Add-Member NoteProperty Views.Count($ll.Views.Count)
  $obj | Add-Member NoteProperty WorkflowAssociations.Count($ll.WorkflowAssociations.Count)



        Write-Output $obj
        }
        else
        {

        
       
        
        $obj = New-Object PSObject
  $obj | Add-Member NoteProperty Title($ll.Title)
  $obj | Add-Member NoteProperty Created($ll.Created)
  $obj | Add-Member NoteProperty RootFolder.ServerRelativeUrl($ll.RootFolder.ServerRelativeUrl)
        
        
        Write-Output $obj
        
        
     }  
        
        }
  
        

  
  
  }





function Set-SPOList
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=1)]
		[bool]$NoCrawl,
[Parameter(Mandatory=$false,Position=2)]
		[string]$Title,
[Parameter(Mandatory=$false,Position=3)]
		[string]$Tag,
[Parameter(Mandatory=$false,Position=5)]
		[bool]$ContentTypesEnabled, 
[Parameter(Mandatory=$false,Position=6)]
		[string]$Description, 
[Parameter(Mandatory=$false,Position=7)]
[ValidateSet(0,1,2)]
		[Int]$DraftVersionVisibility, 
[Parameter(Mandatory=$false,Position=8)]
		[bool]$EnableAttachments,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$EnableMinorVersions,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$EnableFolderCreation,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$EnableVersioning,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$EnableModeration,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$ForceCheckout,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$Hidden,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$IRMEnabled,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$IsApplicationList,
[Parameter(Mandatory=$false,Position=8)]
		[bool]$OnQuickLaunch     
		)

$ll=$ctx.Web.Lists.GetByTitle($ListName)
    if($PSBoundParameters.ContainsKey("NoCrawl"))
  {$ll.NoCrawl=$NoCrawl}
  if($PSBoundParameters.ContainsKey("Title"))
  {$ll.Title=$Title}
  if($PSBoundParameters.ContainsKey("Tag"))
  {$ll.Tag=$Tag}
  if($PSBoundParameters.ContainsKey("ContentTypesEnabled"))
  {
  $ll.ContentTypesEnabled=$ContentTypesEnabled
  }
  if($PSBoundParameters.ContainsKey("Description"))
  {
  $ll.Description=$Description
  }
  if($PSBoundParameters.ContainsKey("DraftVersionVisibility"))
  {
  $ll.DraftVersionVisibility=$DraftVersionVisibility
  }
  if($PSBoundParameters.ContainsKey("EnableAttachments"))
  {
  $ll.EnableAttachments=$EnableAttachments
  }
  if($PSBoundParameters.ContainsKey("EnableMinorVersions"))
  {$ll.EnableMinorVersions=$EnableMinorVersions}
  if($PSBoundParameters.ContainsKey("EnableFolderCreation"))
  {$ll.EnableFolderCreation=$EnableFolderCreation}
  if($PSBoundParameters.ContainsKey("EnableVersioning"))
  {$ll.EnableVersioning=$EnableVersioning}
  if($PSBoundParameters.ContainsKey("EnableModeration"))
  {$ll.EnableModeration=$EnableModeration}
    if($PSBoundParameters.ContainsKey("ForceCheckout"))
  {$ll.ForceCheckout=$ForceCheckout}
    if($PSBoundParameters.ContainsKey("Hidden"))
  {$ll.Hidden=$Hidden}
    if($PSBoundParameters.ContainsKey("IRMEnabled"))
  {$ll.IRMEnabled=$IRMEnabled}
    if($PSBoundParameters.ContainsKey("IsApplicationList"))
  {$ll.IsApplicationList=$IsApplicationList}
        if($PSBoundParameters.ContainsKey("OnQuickLaunch"))
  {$ll.OnQuickLaunch=$OnQuickLaunch}

      $ll.Update()
    try
    {

        $ctx.ExecuteQuery()
        Write-Host "Done" -ForegroundColor Green
       }

       catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }


}


function New-SPOList
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$Title,
        [Parameter(Mandatory=$false,Position=1)]
		[int]$TemplateType=100,
        [Parameter(Mandatory=$false,Position=2)]
		[string]$Description="",
        [Parameter(Mandatory=$false,Position=3)]
		[Int]$DocumentTemplateType,
        [Parameter(Mandatory=$false,Position=4)]
		[GUID]$TemplateFeatureID,
        [Parameter(Mandatory=$false,Position=5)]
		[string]$ListUrl=""
		)

  $ListUrl=$Title

  $lci =New-Object Microsoft.SharePoint.Client.ListCreationInformation
  $lci.Description=$Description
  $lci.Title=$Title
  $lci.Templatetype=$TemplateType
  if($PSBoundParameters.ContainsKey("ListUrl"))
  {
  $lci.Url =$ListUrl
  }
  if($PSBoundParameters.ContainsKey("DocumentTemplateType"))
  {
  $lci.DocumentTemplateType=$DocumentTemplateType
  }
  if($PSBoundParameters.ContainsKey("TemplateFeatureID"))
  {
  $lci.TemplateFeatureID=$TemplateFeatureID
  }
  $list = $ctx.Web.Lists.Add($lci)
  $ctx.Load($list)
  try
     {
       
         $ctx.ExecuteQuery()
         Write-Host "List " $Title " has been added to " $Url
     }
     catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }

     

}


function Set-SPOListCheckout
{
  param (
		[Parameter(Mandatory=$true,Position=1)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=2)]
		[bool]$ForceCheckout=$true
		)
 
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.ForceCheckout = $ForceCheckout
    $ll.Update()
    
        $listurl=$null
        if($ctx.Url.EndsWith("/")) {$listurl= $ctx.Url+$ll.Title}
        else {$listurl=$ctx.Url+"/"+$ll.Title}
        try
        {
        #$ErrorActionPreference="Stop"
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}

function Set-SPOListVersioning
{
  param (
		[Parameter(Mandatory=$true,Position=1)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=2)]
		[bool]$Enabled=$true
		)
   
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.EnableVersioning=$Enabled
    $ll.Update()
    
       
        try
        {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


function Set-SPOListMinorVersioning
{
  param (
		[Parameter(Mandatory=$true,Position=1)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=2)]
		[bool]$Enabled=$true
		)
  
  
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.EnableMinorVersions=$Enabled
    $ll.Update()
    

        try
        {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


function Remove-SPOListInheritance
{
  param (
		[Parameter(Mandatory=$true,Position=1)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=2)]
		[bool]$KeepPermissions=$true
		)
   
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.BreakRoleInheritance($KeepPermissions, $false)
    $ll.Update()
    

        try     {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {        
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


function Restore-SPOListInheritance
{
  param (
		[Parameter(Mandatory=$true,Position=0)]
		[string]$ListName
		)
 
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.ResetRoleInheritance()
    $ll.Update()
    
        try        {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


function Set-SPOListContentTypesEnabled
{
  param (
		[Parameter(Mandatory=$true,Position=0)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=1)]
		[bool]$Enabled=$true
		)
  
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.ContentTypesEnabled=$Enabled
    $ll.Update()
    
        try
        {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


function Remove-SPOList
{
  param (
		[Parameter(Mandatory=$true,Position=0)]
		[string]$ListName
		)

  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.DeleteObject();
        try
        {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
           Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


function Set-SPOListFolderCreationEnabled
{
  param (
		[Parameter(Mandatory=$true,Position=0)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=1)]
		[bool]$Enabled=$true
		)
  
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.EnableFolderCreation=$Enabled
    $ll.Update()
    
        try
        {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


function Set-SPOListIRMEnabled
{
  param (
		[Parameter(Mandatory=$true,Position=0)]
		[string]$ListName,
        [Parameter(Mandatory=$false,Position=1)]
		[bool]$Enabled=$true
		)
   
  $ll=$ctx.Web.Lists.GetByTitle($ListName)
    $ll.IrmEnabled=$Enabled
    $ll.Update()

        try
        {
        $ctx.ExecuteQuery() 
        Write-Host "Done!" -ForegroundColor DarkGreen             
        }

        catch [Net.WebException] 
        {
            
            Write-Host "Failed" $_.Exception.ToString() -ForegroundColor Red
        }
          
  

}


#
#
#
#
#
#
# 
#
#
# Column Cmdlets
#
#
#
#
#
#
#
#
#
#
#
#




function Get-SPOListColumn
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
[Parameter(Mandatory=$true,Position=1)]
		[string]$FieldTitle

		)

  $List=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.ExecuteQuery()
  $Field=$List.Fields.GetByInternalNameOrTitle($FieldTitle)
  $ctx.Load($Field)

  try
  {
   $ctx.ExecuteQuery()
   

   $obj = New-Object PSObject
   $obj | Add-Member NoteProperty CanBeDeleted($Field.CanBeDeleted)
   $obj | Add-Member NoteProperty DefaultValue($Field.DefaultValue)
        $obj | Add-Member NoteProperty Description($Field.Description)
        $obj | Add-Member NoteProperty Direction($Field.Direction)
        $obj | Add-Member NoteProperty EnforceUniqueValues($Field.EnforceUniqueValues)
        $obj | Add-Member NoteProperty EntityPropertyName($Field.EntityPropertyName)
        $obj | Add-Member NoteProperty Filterable($Field.Filterable)
        $obj | Add-Member NoteProperty FromBaseType($Field.FromBaseType)
        $obj | Add-Member NoteProperty Group($Field.Group)
        $obj | Add-Member NoteProperty Hidden($Field.Hidden)
        $obj | Add-Member NoteProperty ID($Field.Id)
        $obj | Add-Member NoteProperty Indexed($Field.Indexed)
        $obj | Add-Member NoteProperty InternalName($Field.InternalName)
        $obj | Add-Member NoteProperty JSLink($Field.JSLink)
        $obj | Add-Member NoteProperty ReadOnlyField($Field.ReadOnlyField)
        $obj | Add-Member NoteProperty Required($Field.Required)
        $obj | Add-Member NoteProperty SchemaXML($Field.SchemaXML)
        $obj | Add-Member NoteProperty Scope($Field.Scope)
        $obj | Add-Member NoteProperty Sealed($Field.Sealed)
        $obj | Add-Member NoteProperty StaticName($Field.StaticName)
        $obj | Add-Member NoteProperty Sortable($Field.Sortable)
        $obj | Add-Member NoteProperty Tag($Field.Tag)
        $obj | Add-Member NoteProperty Title($Field.Title)
        $obj | Add-Member NoteProperty FieldType($Field.FieldType)
        $obj | Add-Member NoteProperty TypeAsString($Field.UIVersionLabel)
        $obj | Add-Member NoteProperty TypeDisplayName($Field.UIVersionLabel)
        $obj | Add-Member NoteProperty TypeShortDescription($Field.UIVersionLabel)
        $obj | Add-Member NoteProperty ValidationFormula($Field.UIVersionLabel)
        $obj | Add-Member NoteProperty ValidationMessage($Field.UIVersionLabel)
        

        Write-Output $obj
  }
  catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
  
 



}





function New-SPOListColumn
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
[Parameter(Mandatory=$true,Position=1)]
		[string]$FieldDisplayName,
  [Parameter(Mandatory=$true, Position=2)]
        [ValidateSet('AllDayEvent','Attachments','Boolean', 'Calculate', 'Choice', 'Computed', 'ContenttypeID', 'Counter', 'CrossProjectLink', 'Currency', 'DateTime', 'Error', 'File', 'Geolocation', 'GridChoice', 'Guid', 'Integer', 'Invalid', 'Lookup', 'MaxItems', 'ModStat', 'MultiChoice', 'Note', 'Number', 'OutcomeChoice', 'PageSeparator', 'Recurrence', 'Text', 'ThreadIndex', 'Threading', 'Url','User', 'WorkflowEventType', 'WorkflowStatus')]
        [System.String]$FieldType,
[Parameter(Mandatory=$false,Position=3)]
		[string]$Description="",
[Parameter(Mandatory=$false,Position=4)]
		[string]$Required="false",
[Parameter(Mandatory=$false,Position=5)]
		[string]$Group="",
[Parameter(Mandatory=$false,Position=6)]
		[string]$StaticName,
[Parameter(Mandatory=$false,Position=7)]
		[string]$Name,
[Parameter(Mandatory=$false,Position=8)]
		[string]$Version="1"         
		)

  $List=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.ExecuteQuery()

  if($PSBoundParameters.ContainsKey("StaticName")) {$StaticName=$StaticName}
  else {$StaticName=$FieldDisplayName}
  if($PSBoundParameters.ContainsKey("Name")) {$Name=$Name}
  else {$Name=$FieldDisplayName}

   $FieldOptions=[Microsoft.SharePoint.Client.AddFieldOptions]::AddToAllContentTypes 
   $xml="<Field Type='"+$FieldType+"' Description='"+$Description+"' Required='"+$Required+"' Group='"+$Group+"' StaticName='"+$StaticName+"' Name='"+$Name+"' DisplayName='"+$FieldDisplayName+"' Version='"+$Version+"'></Field>"    
   Write-Host $xml
$List.Fields.AddFieldAsXml($xml,$true,$FieldOptions) 
$List.Update() 
 
  try
     {
       
         $ctx.ExecuteQuery()
         Write-Host "Field " $FieldDisplayName " has been added to " $ListTitle
     }
     catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()-ForegroundColor Red
     }

     



}






function Set-SPOListColumn
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
        [Parameter(Mandatory=$false,Position=1)]
		[string]$DefaultValue,
        [Parameter(Mandatory=$false,Position=2)]
		[string]$Description="",
        [Parameter(Mandatory=$false,Position=3)]
        [ValidateSet('LTR','RTL','none')]
		[string]$Direction,
        [Parameter(Mandatory=$false,Position=4)]
		[bool]$EnforceUniqueValues,
[Parameter(Mandatory=$false,Position=5)]
		[string]$Group="",
[Parameter(Mandatory=$false,Position=6)]
		[bool]$Hidden,
[Parameter(Mandatory=$false,Position=7)]
		[bool]$Indexed,
[Parameter(Mandatory=$false,Position=8)]
		[string]$JSLink="",
[Parameter(Mandatory=$false,Position=9)]
		[bool]$ReadOnlyField,
[Parameter(Mandatory=$false,Position=10)]
		[bool]$Required,
[Parameter(Mandatory=$false,Position=11)]
		[string]$SchemaXML,
[Parameter(Mandatory=$false,Position=12)]
		[string]$StaticName,
[Parameter(Mandatory=$false,Position=13)]
		[string]$Tag,
[Parameter(Mandatory=$false,Position=14)]
		[string]$FieldTitle
		)


  $List=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.ExecuteQuery()
  $lci=$List.Fields.GetByTitle($FieldTitle)
   $ctx.ExecuteQuery()
  if($PSBoundParameters.ContainsKey("Description"))
  {
  $lci.Description=$Description
  }
  if($PSBoundParameters.ContainsKey("DefaultValue"))
  {
  $lci.DefaultValue=$DefaultValue
  }

  if($PSBoundParameters.ContainsKey("Direction"))
  {
  $lci.Direction=$Direction
  }
  if($PSBoundParameters.ContainsKey("EnforceUniqueValues"))
  {
  $lci.EnforceUniqueValues=$EnforceUniqueValues
  }
  
  if($PSBoundParameters.ContainsKey("Group"))
  {
  $lci.Group=$Group
  }
  if($PSBoundParameters.ContainsKey("Hidden")){
  $lci.Hidden=$Hidden
  }
  if($PSBoundParameters.ContainsKey("Indexed"))
  {
  $lci.Indexed=$Indexed
  }
  
  if($PSBoundParameters.ContainsKey("JSLink"))
  {
  $lci.JSLink=$JSLink
  }
  if($PSBoundParameters.ContainsKey("ReadOnlyField"))
  {
  $lci.ReadOnlyField=$ReadOnlyField
  }
  if($PSBoundParameters.ContainsKey("Required"))
  {
  $lci.Required=$Required
  }
  if($PSBoundParameters.ContainsKey("SchemaXML"))
  {
  $lci.SchemaXML=$SchemaXML
  }
 
  
  if($PSBoundParameters.ContainsKey("StaticName"))
  {
  $lci.StaticName=$StaticName
  }
 
  if($PSBoundParameters.ContainsKey("Tag"))
  {
  $lci.Tag=$Tag
  }


  $lci.Update()
  $ctx.load($lci)
  try
     {
       
         $ctx.ExecuteQuery()
         Write-Host $FieldTitle " has been updated"
     }
     catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }

     



}



function Remove-SPOListColumn
{

param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
[Parameter(Mandatory=$false,Position=1)]
		[string]$FieldTitle

		)

  $List=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.ExecuteQuery()
  $Field=$List.Fields.GetByTitle($FieldTitle)
   $ctx.ExecuteQuery()
   $Field.DeleteObject()
   $ctx.ExecuteQuery()

}


function Get-SPOListColumnFieldIsObjectPropertyInstantiated
{

param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
[Parameter(Mandatory=$false,Position=1)]
		[string]$FieldTitle,
[Parameter(Mandatory=$false,Position=2)]
		[string]$FieldID,
[Parameter(Mandatory=$false,Position=3)]
		[string]$ObjectPropertyName

		)

  $List=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.ExecuteQuery()
  if($PSBoundParameters.ContainsKey("FieldTitle"))
  {
  $Field=$List.Fields.GetByInternalNameorTitle($FieldTitle)
  }
  if($PSBoundParameters.ContainsKey("FieldID"))
  {
  $Field=$List.Fields.GetById($FieldID)
  }
   $ctx.ExecuteQuery()
   $Field.IsObjectPropertyInstantiated($ObjectPropertyName)
   $ctx.ExecuteQuery()

}



function Get-SPOListColumnFieldIsPropertyAvailable
{

param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
[Parameter(Mandatory=$false,Position=1)]
		[string]$FieldTitle,
[Parameter(Mandatory=$false,Position=2)]
		[string]$FieldID,
[Parameter(Mandatory=$false,Position=3)]
		[string]$PropertyName

		)

  $List=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.ExecuteQuery()
  if($PSBoundParameters.ContainsKey("FieldTitle"))
  {
  $Field=$List.Fields.GetByInternalNameorTitle($FieldTitle)
  }
  if($PSBoundParameters.ContainsKey("FieldID"))
  {
  $Field=$List.Fields.GetById($FieldID)
  }
   $ctx.ExecuteQuery()
   $Field.IsPropertyAvailable($PropertyName)
   $ctx.ExecuteQuery()

}



function New-SPOListChoiceColumn
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
[Parameter(Mandatory=$true,Position=1)]
		[string]$FieldDisplayName,
[parameter(Mandatory=$true, ValueFromPipeline=$true)]
            [String[]]
            $ChoiceNames,
            [Parameter(Mandatory=$false,Position=2)]
		[string]$Description="",
[Parameter(Mandatory=$false,Position=3)]
		[string]$Required="false",
[Parameter(Mandatory=$false,Position=4)]
[ValidateSet('Dropdown','RadioButtons')]
		[string]$Format="Dropdown",
[Parameter(Mandatory=$false,Position=5)]
		[string]$Group="",
[Parameter(Mandatory=$true,Position=6)]
		[string]$StaticName,
[Parameter(Mandatory=$true,Position=7)]
		[string]$Name,
[Parameter(Mandatory=$false,Position=8)]
		[string]$Version="1",
[Parameter(Mandatory=$false,Position=9)]
[ValidateSet('MultiChoice')]
		[string]$Type
          
		)

  $List=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.ExecuteQuery()
   $FieldOptions=[Microsoft.SharePoint.Client.AddFieldOptions]::AddToAllContentTypes 
    if($PSBoundParameters.ContainsKey("Type"))
   {
    $xml="<Field Type='MultiChoice' Description='"+$Description+"' Required='"+$Required+"' FillInChoice='FALSE' "
   }
   else
   {
   $xml="<Field Type='Choice' Description='"+$Description+"' Required='"+$Required+"' FillInChoice='FALSE' "
   }
   if($PSBoundParameters.ContainsKey("Format"))
   {
     $xml+="Format='"+$Format+"' "
     }
     
     $xml+="Group='"+$Group+"' StaticName='"+$StaticName+"' Name='"+$Name+"' DisplayName='"+$FieldDisplayName+"' Version='"+$Version+"'>
   <CHOICES>"
     
   foreach($choice in $ChoiceNames)
   {
   $xml+="<CHOICE>"+$choice+"</CHOICE>
   "
   
   }
   
   $xml+="</CHOICES>
   </Field>"
   
   
   Write-Host $xml
$List.Fields.AddFieldAsXml($xml,$true,$FieldOptions) 
$List.Update() 
 
  try
     {
       
         $ctx.ExecuteQuery()
         Write-Host "Field " $FieldDisplayName " has been added to " $ListTitle
     }
     catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString() -ForegroundColor
     }

     



}




function Get-SPOListFields
{
 param (
        [Parameter(Mandatory=$true,Position=3)]
		[string]$ListTitle,
        [Parameter(Mandatory=$false,Position=4)]
		[bool]$IncludeSubsites=$false
		)

  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.Load($ll.Fields)
  $ctx.ExecuteQuery()


  $fieldsArray=@()
  $fieldslist=@()
 foreach ($fiel in $ll.Fields)
 {
  #Write-Host $fiel.Description `t $fiel.EntityPropertyName `t $fiel.Id `t $fiel.InternalName `t $fiel.StaticName `t $fiel.Tag `t $fiel.Title  `t $fiel.TypeDisplayName

  $array=@()
  $array+="InternalName"
    $array+="StaticName"
      $array+="Tag"
       $array+="Title"

  $obj = New-Object PSObject
  $obj | Add-Member NoteProperty $array[0]($fiel.InternalName)
  $obj | Add-Member NoteProperty $array[1]($fiel.StaticName)
  $obj | Add-Member NoteProperty $array[2]($fiel.Tag)
  $obj | Add-Member NoteProperty $array[3]($fiel.Title)

  $fieldsArray+=$obj
  $fieldslist+=$fiel.InternalName
  Write-Output $obj
 }
 

 $ctx.Dispose()
  return $fieldsArray

}



function Get-SPOListItems
{
  
   param (
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ListTitle,
        [Parameter(Mandatory=$false,Position=5)]
		[bool]$IncludeAllProperties=$false,
        [switch]$Recursive
		)
  
  
  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.Load($ll.Fields)
  $ctx.ExecuteQuery()
  $i=0



 $spqQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
# $spqQuery.ViewAttributes = "Scope='Recursive'"

if($Recursive)
{
$spqQuery.ViewXml ="<View Scope='RecursiveAll' />";
}
   $bobo=Get-SPOListFields -ListTitle $ListTitle 


  $itemki=$ll.GetItems($spqQuery)
  $ctx.Load($itemki)
  $ctx.ExecuteQuery()

  
 
 $objArray=@()

  for($j=0;$j -lt $itemki.Count ;$j++)
  {
        
        $obj = New-Object PSObject
        
        if($IncludeAllProperties)
        {

        for($k=0;$k -lt $bobo.Count ; $k++)
        {
          
         # Write-Host $k
         $name=$bobo[$k].InternalName
         $value=$itemki[$j][$name]
          $obj | Add-Member NoteProperty $name($value) -Force
          
        }

        }
        else
        {
          $obj | Add-Member NoteProperty ID($itemki[$j]["ID"])
          $obj | Add-Member NoteProperty Title($itemki[$j]["Title"])

        }

      #  Write-Host $obj.ID `t $obj.Title
        $objArray+=$obj
    
   
  }

 
  
  return $objArray
  
  
  }

#
#
#
#
#
#
# 
#
#
# Item Cmdlets
#
#
#
#
#
#
#
#
#
#
#
#












function New-SPOListItem
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=1)]
		[string]$ItemTitle,
[Parameter(Mandatory=$false,Position=2)]
		[string]$AdditionalField="",
[Parameter(Mandatory=$false,Position=3)]
		[string]$AdditionalValue=""
		)


  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()

  $lici =New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
  
  
  $listItem = $ll.AddItem($lici)
  $listItem["Title"]=$ItemTitle
  if($AdditionalField -ne "")
  {
   $listItem[$AdditionalField]=$AdditionalValue
  }
  $listItem.Update()
  $ll.Update()
  
  try
     {      
         $ctx.ExecuteQuery()
         Write-Host "Item " $ItemTitle " has been added to list " $ListTitle
     }
     catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }


}



function Remove-SPOListItemInheritance
{
  
   param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=1)]
		[Int]$ItemID
		)
  
  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()


  $itemek=$ll.GetItemByID($ItemID)
  $ctx.Load($itemek)
  $ctx.ExecuteQuery()
  $itemek.BreakRoleInheritance($true, $false)
  try
  {
  $ctx.ExecuteQuery()
  write-host $itemek.Name " Success"
  }
 catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
  
  
  }


  function Remove-SPOListItemPermissions
{
  
   param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=1)]
		[Int]$ItemID
		)
  
  
  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()


  $itemek=$ll.GetItemByID($ItemID)
  $ctx.Load($itemek)
  $ctx.ExecuteQuery()
  $itemek.BreakRoleInheritance($false, $false)
  try
  {
  $ctx.ExecuteQuery()
  write-host $itemek.Name " Success"
  }
catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
  
  
  }


  function Restore-SPOListItemInheritance
{
  
   param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=1)]
		[Int]$ItemID
		)
  
  
  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()


  $itemek=$ll.GetItemByID($ItemID)
  $ctx.Load($itemek)
  $ctx.ExecuteQuery()
  $itemek.ResetRoleInheritance()
  try
  {
  $ctx.ExecuteQuery()
  write-host $itemek.Name " Success"
  }
 catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
  
  
  }

  function Remove-SPOListItem
{
  
   param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=1)]
		[Int]$ItemID
		)
  
  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()


  $itemek=$ll.GetItemByID($ItemID)
  $ctx.Load($itemek)
  $ctx.ExecuteQuery()
  $itemek.DeleteObject()
  try
  {
  $ctx.ExecuteQuery()
  write-host $itemek.Name " Success"
  }
catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
  
  
  }




  function Update-SPOListItem
{
  
   param (
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=5)]
		[Int]$ItemID,
[Parameter(Mandatory=$true,Position=6)]
		[string]$FieldToUpdate,
[Parameter(Mandatory=$true,Position=7)]
		[string]$ValueToUpdate
		)
  

  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()


  $itemek=$ll.GetItemByID($ItemID)
  $ctx.Load($itemek)
  $ctx.ExecuteQuery()
  $itemek[$FieldToUpdate] = $ValueToUpdate
  $itemek.Update()
  try
  {
  $ctx.ExecuteQuery()
  write-host $itemek.Name " Success"
  }
  catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
  
  
  }







  #
#
#
#
#
#
# 
#
#
# File Cmdlets
#
#
#
#
#
#
#
#
#
#
#
#







  function Set-SPOFileCheckout
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl     
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.CheckOut()
  $ctx.Load($file)
  try
  {
  $ctx.ExecuteQuery()        
        
       Write-Host $file.Name " has been checked out"   -ForegroundColor DarkGreen 
       }
       catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }

}



function Approve-SPOFile
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl,
        [Parameter(Mandatory=$false,Position=1)]
		[string]$ApprovalComment=""    
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.Approve($ApprovalComment)
  $ctx.Load($file)

  try
  {
  $ctx.ExecuteQuery()        
        

        Write-Host $file.Name " has been approved"  -ForegroundColor DarkGreen 
        }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
}



function Set-SPOFileCheckin
{
param (
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ServerRelativeUrl,
        [Parameter(Position=5)]
        [ValidateSet('MajorCheckIn','MinorCheckIn','OverwriteCheckIn')]
        [System.String]$CheckInType,
        [Parameter(Mandatory=$false,Position=6)]
		[string]$CheckinComment=""     
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.CheckIn($CheckInComment, $CheckInType)
  $ctx.Load($file)
  try
  {
  $ctx.ExecuteQuery()        
  Write-Host $file.Name " has been checked in"     -ForegroundColor DarkGreen 
  }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }


}




function Copy-SPOFile
{
param (
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ServerRelativeUrl,
        [Parameter(Mandatory=$true,Position=5)]
		[string]$DestinationLibrary,
        [Parameter(Mandatory=$false,Position=6)]
		[bool]$Overwrite=$true,
        [Parameter(Mandatory=$false,Position=7)]
		[string]$NewName=""
    
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

        if($NewName -eq "")
        {
           $NewName=$file.Name

        }

        if($DestinationLibrary.EndsWith("/")){}
        else {$DestinationLibrary=$DestinationLibrary+"/"}

$file.CopyTo($DestinationLibrary+$NewName, $Overwrite)
  try
  {
  $ctx.ExecuteQuery()        
        
       Write-Host $file.Name " has been copied to" $DestinationLibrary   -ForegroundColor DarkGreen 
       }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
}



function Remove-SPOFile
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl     
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.DeleteObject()
  try
  {
  $ctx.ExecuteQuery()        
        
       Write-Host $file.Name " has been deleted"   -ForegroundColor DarkGreen 
       }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
}




function Deny-SPOFileApproval
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl,
        [Parameter(Mandatory=$false,Position=1)]
		[string]$ApprovalComment=""    
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.Deny($ApprovalComment)
  $ctx.Load($file)

  try
  {
  $ctx.ExecuteQuery()        
        

        Write-Host $file.Name " has been denied"  -ForegroundColor DarkGreen 
        }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
}



function Get-SPOFileIsPropertyAvailable
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl, 
[Parameter(Mandatory=$true,Position=1)]
		[string]$propertyName    
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  if($file.IsPropertyAvailable($propertyName))
  {
  Write-Host "True"
  }
  else
  {
  Write-Host "False"
  }
  

}


function Move-SPOFile
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl,
        [Parameter(Mandatory=$true,Position=1)]
		[string]$DestinationLibrary,
        [Parameter(Mandatory=$false,Position=2)]
		[bool]$Overwrite=$false,
        [Parameter(Mandatory=$false,Position=3)]
		[string]$NewName=""     
		)



  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

        if($PSBoundParameters.ContainsKey("NewName"))
        {
         $DestinationLibrary+=$NewName

        }
        else
        {
        $DestinationLibrary+=$file.Name

        }

        if($PSBoundParameters.ContainsKey("Overwrite"))
        {

  $file.MoveTo($DestinationLibrary,"Overwrite")
  }
  else
  {
  $file.MoveTo($DestinationLibrary,"none")
  }
  
  try
  {
  $ctx.ExecuteQuery()        
        
       Write-Host $file.Name " has been moved to "  $DestinationLibrary -ForegroundColor DarkGreen 
       }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }

}



function Publish-SPOFile
{
param (
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ServerRelativeUrl,
        [Parameter(Mandatory=$false,Position=5)]
		[string]$Comment=""    
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.Publish($Comment)
  $ctx.Load($file)

  try
  {
  $ctx.ExecuteQuery()        
  Write-Host $file.Name " has been published"  -ForegroundColor DarkGreen 
        }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }
}



function Undo-SPOFileCheckout
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl     
		)

  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.UndoCheckOut()
  $ctx.Load($file)
  try
  {
  $ctx.ExecuteQuery()        
        
       Write-Host "Checkout for " $file.Name " has been undone"   -ForegroundColor DarkGreen 
       }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }

}


function Undo-SPOFilePublish
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl,
        [Parameter(Mandatory=$false,Position=1)]
		[string]$Comment     
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()

  $file.Unpublish($Comment)
  $ctx.Load($file)
  try
  {
  $ctx.ExecuteQuery()        
        
       Write-Host $file.Name " has been unpublished"   -ForegroundColor DarkGreen 
       }
        catch [Net.WebException]
     { 
        Write-Host $_.Exception.ToString()
     }

}



function Get-SPOFolderFilesCount
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl     
		)


  $fileCollection =
        $ctx.Web.GetFolderByServerRelativeUrl($ServerRelativeUrl).Files;
        $ctx.Load($fileCollection)
        $ctx.ExecuteQuery()

        
        return $fileCollection.Count

}




function Get-SPOFolderFiles
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl     
		)



  $fileCollection =
        $ctx.Web.GetFolderByServerRelativeUrl($ServerRelativeUrl).Files;
        $ctx.Load($fileCollection)
        $ctx.ExecuteQuery()

        
        foreach ($file in $fileCollection)
        {

        $ctx.Load($file.ListItemAllFields)
        $Author=$file.Author
        $CheckedOutByUser=$file.CheckedOutByUser
        $LockedByUser=$file.LockedByUser
        $ModifiedBy=$file.ModifiedBy
        $ctx.Load($Author)
        $ctx.Load($CheckedOutByUser)
        $ctx.Load($LockedByUser)
        $ctx.Load($ModifiedBy)
        $ctx.ExecuteQuery()
        
        
        $obj = New-Object PSObject
        $obj | Add-Member NoteProperty Name($file.Name)
        $obj | Add-Member NoteProperty Author.LoginName($file.Author.LoginName)
        $obj | Add-Member NoteProperty CheckedOutByUser.LoginName($file.CheckedOutByUser.LoginName)
        $obj | Add-Member NoteProperty CheckinComment($file.CheckinComment)
        $obj | Add-Member NoteProperty ContentTag($file.ContentTag)
        $obj | Add-Member NoteProperty ETag($file.ETag)
        $obj | Add-Member NoteProperty Exists($file.Exists)
        $obj | Add-Member NoteProperty Length($file.Length)
        $obj | Add-Member NoteProperty LockedByUser.LoginName($file.LockedByUser.LoginName)
        $obj | Add-Member NoteProperty MajorVersion($file.MajorVersion)
        $obj | Add-Member NoteProperty MinorVersion($file.MinorVersion)
        $obj | Add-Member NoteProperty ModifiedBy.LoginName($file.ModifiedBy.LoginName)
        $obj | Add-Member NoteProperty ServerRelativeUrl($file.ServerRelativeUrl)
        $obj | Add-Member NoteProperty Tag($file.Tag)
        $obj | Add-Member NoteProperty TimeCreated($file.TimeCreated)
        $obj | Add-Member NoteProperty TimeLastModified($file.TimeLastModified)
        $obj | Add-Member NoteProperty Title($file.Title)
        $obj | Add-Member NoteProperty UIVersion($file.UIVersion)
        $obj | Add-Member NoteProperty UIVersionLabel($file.UIVersionLabel)
        

        Write-Output $obj
        }



}



function Get-SPOFileByServerRelativeUrl
{
param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$ServerRelativeUrl     
		)


  $file =
        $ctx.Web.GetFileByServerRelativeUrl($ServerRelativeUrl);
        $ctx.Load($file)
        $ctx.ExecuteQuery()
        $Author=$file.Author
        $CheckedOutByUser=$file.CheckedOutByUser
        $LockedByUser=$file.LockedByUser
        $ModifiedBy=$file.ModifiedBy
        $ctx.Load($Author)
        $ctx.Load($CheckedOutByUser)
        $ctx.Load($LockedByUser)
        $ctx.Load($ModifiedBy)
        $ctx.ExecuteQuery()
        $obj = New-Object PSObject
        $obj | Add-Member NoteProperty Name($file.Name)
        $obj | Add-Member NoteProperty Author.LoginName($file.Author.LoginName)
        $obj | Add-Member NoteProperty CheckedOutByUser.LoginName($file.CheckedOutByUser.LoginName)
        $obj | Add-Member NoteProperty CheckinComment($file.CheckinComment)
        $obj | Add-Member NoteProperty ContentTag($file.ContentTag)
        $obj | Add-Member NoteProperty ETag($file.ETag)
        $obj | Add-Member NoteProperty Exists($file.Exists)
        $obj | Add-Member NoteProperty Length($file.Length)
        $obj | Add-Member NoteProperty LockedByUser.LoginName($file.LockedByUser.LoginName)
        $obj | Add-Member NoteProperty MajorVersion($file.MajorVersion)
        $obj | Add-Member NoteProperty MinorVersion($file.MinorVersion)
        $obj | Add-Member NoteProperty ModifiedBy.LoginName($file.ModifiedBy.LoginName)
        $obj | Add-Member NoteProperty ServerRelativeUrl($file.ServerRelativeUrl)
        $obj | Add-Member NoteProperty Tag($file.Tag)
        $obj | Add-Member NoteProperty TimeCreated($file.TimeCreated)
        $obj | Add-Member NoteProperty TimeLastModified($file.TimeLastModified)
        $obj | Add-Member NoteProperty Title($file.Title)
        $obj | Add-Member NoteProperty UIVersion($file.UIVersion)
        $obj | Add-Member NoteProperty UIVersionLabel($file.UIVersionLabel)
        
        Write-Output $obj



}








function Get-SPOFolderByServerRelativeUrl
{
param (
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ServerRelativeUrl     
		)



  $folderCollection =
        $ctx.Web.GetFolderByServerRelativeUrl($ServerRelativeUrl).Folders;
        $ctx.Load($folderCollection)
        $ctx.ExecuteQuery()


        
        foreach ($fof in $folderCollection)
        {
        $obj = New-Object PSObject
        $ctx.Load($fof.ListItemAllFields)
        $ctx.ExecuteQuery()
        $obj | Add-Member NoteProperty Name($fof.Name)
        $obj | Add-Member NoteProperty Itemcount($fof.ItemCount)
        $obj | Add-Member NoteProperty WelcomePage($fof.WelcomePage)

        Write-Output $obj
        }



}



#
#
#
#
#
#
# 
#
#
# Web
#
#
#
#
#
#
#
#
#
#
#
#




function Get-SPOWeb
{
param (
        [Parameter(Mandatory=$true,Position=1)]
		[string]$Username,
		[Parameter(Mandatory=$true,Position=2)]
		[string]$Url,
        [Parameter(Mandatory=$true,Position=3)]
		[string]$AdminPassword,
        [Parameter(Mandatory=$false,Position=4)]
		[bool]$IncludeSubsites=$false
		)

$password = ConvertTo-SecureString -string $AdminPassword -AsPlainText -Force
  $ctx=New-Object Microsoft.SharePoint.Client.ClientContext($Url)
  $ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $password)
  $ctx.Load($ctx.Web)
  $ctx.Load($ctx.Web.Webs)
  $ctx.ExecuteQuery()

if($ctx.Web.Webs.Count -eq 0)
{
Write-Host "None found" 

}

  for($i=0;$i -lt $ctx.Web.Webs.Count ;$i++)
     {
        $obj = new-Object PSOBject
        $obj | Add-Member NoteProperty AllowRSSFeeds($ctx.Web.Webs[$i].AllowRssFeeds)
        $obj | Add-Member NoteProperty Created($ctx.Web.Webs[$i].Created)
        $obj | Add-Member NoteProperty CustomMasterUrl($ctx.Web.Webs[$i].CustomMasterUrl)
        $obj | Add-Member NoteProperty Description($ctx.Web.Webs[$i].Description)
        $obj | Add-Member NoteProperty EnableMinimalDownload($ctx.Web.Webs[$i].EnableMinimalDownload)
        $obj | Add-Member NoteProperty ID($ctx.Web.Webs[$i].Id)
        $obj | Add-Member NoteProperty Language($ctx.Web.Webs[$i].Language)
        $obj | Add-Member NoteProperty LastItemModifiedDate($ctx.Web.Webs[$i].LastItemModifiedDate)
        $obj | Add-Member NoteProperty MasterUrl($ctx.Web.Webs[$i].MasterUrl)
        $obj | Add-Member NoteProperty QuickLaunchEnabled($ctx.Web.Webs[$i].QuickLaunchEnabled)
        $obj | Add-Member NoteProperty RecycleBinEnabled($ctx.Web.Webs[$i].RecycleBinEnabled)
        $obj | Add-Member NoteProperty ServerRelativeUrl($ctx.Web.Webs[$i].ServerRelativeUrl)
        $obj | Add-Member NoteProperty Title($ctx.Web.Webs[$i].Title)
        $obj | Add-Member NoteProperty TreeViewEnabled($ctx.Web.Webs[$i].TreeViewEnabled)
        $obj | Add-Member NoteProperty UIVersion($ctx.Web.Webs[$i].UIVersion)
        $obj | Add-Member NoteProperty UIVersionConfigurationEnabled($ctx.Web.Webs[$i].UIVersionConfigurationEnabled)
        $obj | Add-Member NoteProperty Url($ctx.Web.Webs[$i].Url)
        $obj | Add-Member NoteProperty WebTemplate($ctx.Web.Webs[$i].WebTemplate)

        Write-Output $obj
     }

     
     
if($ctx.Web.Webs.Count -gt 0 -and $IncludeSubsites)
  {
     Write-Host "--"-ForegroundColor DarkGreen
     for($i=0;$i -lt $ctx.Web.Webs.Count ;$i++)
     {
        Get-SPOWeb -Username $Username -Url $ctx.Web.Webs[$i].Url -AdminPassword $AdminPassword -IncludeSubsites $IncludeSubsites
        }
     }
   
     



}











#
#
#
#
#
#
# 
#
#
# Connect
#
#
#
#
#
#
#
#
#
#
#
#


function Connect-SPOCSOM
{
 param (
  [Parameter(Mandatory=$true,Position=1)]
		[string]$Username,
		[Parameter(Mandatory=$true,Position=2)]
		[string]$AdminPassword,
        [Parameter(Mandatory=$true,Position=3)]
		[string]$Url
)

$password = ConvertTo-SecureString -string $AdminPassword -AsPlainText -Force
  $ctx=New-Object Microsoft.SharePoint.Client.ClientContext($Url)
  $ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $password)
  $ctx.ExecuteQuery()  
$global:ctx=$ctx
}


$global:ctx






# Paths to SDK. Please verify location on your computer.
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 




Export-ModuleMember -Function "Get-SPOWeb","Get-SPOListCount","Get-SPOList", "Set-SPOList", "New-SPOList","Set-SPOListCheckout","Set-SPOListVersioning","Set-SPOListMinorVersioning","Remove-SPOListInheritance","Restore-SPOListInheritance","Set-SPOListContentTypesEnabled","Remove-SPOList","Set-SPOListFolderCreationEnabled","Set-SPOListIRMEnabled","Get-SPOListColumn","New-SPOListColumn","Set-SPOListColumn","Remove-SPOListColumn","Get-SPOListColumnFieldIsObjectPropertyInstantiated","Get-SPOListColumnFieldIsPropertyAvailable","New-SPOListChoiceColumn","Get-SPOListFields","Get-SPOListItems","New-SPOListItem","Remove-SPOListItemInheritance","Remove-SPOListItemPermissions","Restore-SPOListItemInheritance","Remove-SPOListItem","Update-SPOListItem","Set-SPOFileCheckout","Approve-SPOFile","Set-SPOFileCheckin","Copy-SPOFile","Remove-SPOFile","Deny-SPOFileApproval","Get-SPOFileIsPropertyAvailable","Move-SPOFile","Publish-SPOFile","Undo-SPOFileCheckout","Undo-SPOFilePublish","Get-SPOFolderFilesCount","Get-SPOFolderFiles","Get-SPOFileByServerRelativeUrl","Get-SPOFolderByServerRelativeUrl","Connect-SPOCSOM"
