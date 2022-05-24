Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
#Functions
function SortApplications{
    param ([string]$Path)
	Get-ItemProperty $Path | ForEach-Object {
		if (($_.DisplayName) -or ($_.Version)) {
			[PSCustomObject]@{
				Name = $_.DisplayName;
                Key = $_.PSChildName;
                PPath = $_.PSParentPath	
			}
		}
	}
}
function GetInstalledPrograms{
    $InstalledProgramsRaw = @()
	$InstalledProgramsRaw += SortApplications 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
	$InstalledProgramsRaw += SortApplications 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
	$InstalledProgramsRaw | Sort-Object -Property Name | Export-Csv C:\apps.csv
    $InstalledProgramsSorted = import-csv "C:\apps.csv"
    Remove-Item "C:\apps.csv"
    return $InstalledProgramsSorted
}
function Retrievinator{
    param ([string]$Path,[String]$ArgumentList,[string]$Type)
    $a = GetInstalledPrograms
    Install -Path $Path -ArgumentList $ArgumentList -Type $Type
    $b = GetInstalledPrograms
    $b | ForEach-Object {
        if (!($a.Name -contains $_.Name)) {
            return $_.Key + ";" + $_.PPath + ";" + $_.Name
        }
    }
}

function Install {
    param ([String]$Path, [String]$ArgumentList,[string]$Type)
    if ($Type -eq "msi") {
        $ArgumentList = "" + $ArgumentList
        $ArgumentList = '/i "{0}" {1}' -f $Path, $ArgumentList
        Start-Process -Wait -Verb RunAs msiexec.exe -ArgumentList $ArgumentList  
    } elseif ($Type -eq "exe") {
        $ArgumentList = " " + $ArgumentList
        Start-Process -Wait -Verb RunAs -FilePath $Path -ArgumentList $ArgumentList    
    } elseif ($Type -eq "ps1") {
        $ArgumentList = '-ExecutionPolicy ByPass -File "{0}"' -f $Path
        Start-Process -Wait -Verb RunAs powershell.exe -ArgumentList $ArgumentList
    }
}

function Click {
    $Path = $InstallPath.Text
    $Type = $InstallPath.Text.split(".")[1]
    $Values = Retrievinator -Path $Path -ArgumentList $ArgumentListBox.Text -Type $Type
    $RKey.Text = $Values.split(";")[0]
    $temppath = $Values.split(";")[1]
    Write-Host $temppath
    $RPath.Text = $temppath.split("::")[-1] + "\"
    $RName.Text = $Values.split(";")[2]
    $RKey.Enabled = $true
    $RPath.Enabled = $true
    $RName.Enabled = $true  
}

function ClearClick {
    $form.Controls | Where-Object{ $_ -is [system.windows.forms.richtextbox] } | ForEach-Object{ $_.Clear() }
    $RKey.Enabled = $false
    $RPath.Enabled = $false
    $RName.Enabled = $false  
}
#Form
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'yeah you get those registry entries good job'
$form.Size = New-Object System.Drawing.Size(600,350)
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,20)
$label.Text = 'Install Path:'
$form.Controls.Add($label)
$InstallPath = New-Object System.Windows.Forms.RichTextBox
$InstallPath.Location = New-Object System.Drawing.Point(10,40)
$InstallPath.Size = New-Object System.Drawing.Size(560,20)
$InstallPath.AcceptsTab = $true
$InstallPath.ShortcutsEnabled = $true
$form.Controls.Add($InstallPath)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,70)
$label.Size = New-Object System.Drawing.Size(300,20)
$label.Text = 'Install Arguments:'
$form.Controls.Add($label)
$ArgumentListBox = New-Object System.Windows.Forms.RichTextBox
$ArgumentListBox.Location = New-Object System.Drawing.Point(10,90)
$ArgumentListBox.Size = New-Object System.Drawing.Size(560,20)
$ArgumentListBox.AcceptsTab = $true
$ArgumentListBox.ShortcutsEnabled = $true
$form.Controls.Add($ArgumentListBox)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Point(140,120)
$clearButton.Size = New-Object System.Drawing.Size(130,23)
$clearButton.Text = 'Clear Fields'
$form.Controls.Add($clearButton)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Location = New-Object System.Drawing.Point(10,120)
$installButton.Size = New-Object System.Drawing.Size(130,23)
$installButton.Text = 'Get Values'
$form.Controls.Add($installButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,150)
$label.Size = New-Object System.Drawing.Size(300,20)
$label.Text = 'Registry Path:'
$form.Controls.Add($label)
$RPath= New-Object System.Windows.Forms.RichTextBox
$RPath.Location = New-Object System.Drawing.Point(10,170)
$RPath.Size = New-Object System.Drawing.Size(560,20)
$RPath.AcceptsTab = $true
$RPath.ShortcutsEnabled = $true
$RPath.Enabled = $false
$form.Controls.Add($RPath)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,200)
$label.Size = New-Object System.Drawing.Size(300,20)
$label.Text = 'Registry Key:'
$form.Controls.Add($label)
$RKey= New-Object System.Windows.Forms.RichTextBox
$RKey.Location = New-Object System.Drawing.Point(10,220)
$RKey.Size = New-Object System.Drawing.Size(560,20)
$RKey.AcceptsTab = $true
$RKey.ShortcutsEnabled = $true
$RKey.Enabled = $false
$form.Controls.Add($RKey)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,250)
$label.Size = New-Object System.Drawing.Size(300,20)
$label.Text = 'Program Registry Name:'
$form.Controls.Add($label)
$RName= New-Object System.Windows.Forms.RichTextBox
$RName.Location = New-Object System.Drawing.Point(10,270)
$RName.Size = New-Object System.Drawing.Size(560,20)
$RName.Enabled = $false
$form.Controls.Add($RName)

$installButton.Add_Click({Click})
$clearButton.Add_Click({ClearClick})
$form.Topmost = $true
$form.ShowDialog()