# Q.5.7 Import du module Functions localisé dans le dossier Scripts

Import-Module "C:\Scripts\Functions.psm1"

Function Random-Password
{
    param ([Int]$Length = 8)
    
    $Punc = 46..46
    $Digits = 48..57
    $Letters = 65..90 + 97..122
    $Password = Get-Random -Count $Length -Input ($Punc + $Digits + $Letters) |`
        ForEach -begin { $aa = $null } -process {$aa += [char]$_} -end {$aa}
    Return $Password.ToString()
}

Function ManageAccentsAndCapitalLetters
{
    param ([String]$String)
    
    $StringWithoutAccent = $String -replace '[éèêë]', 'e' -replace '[àâä]', 'a' -replace '[îï]', 'i' -replace '[ôö]', 'o' -replace '[ùûü]', 'u'
    $StringWithoutAccentAndCapitalLetters = $StringWithoutAccent.ToLower()
    $StringWithoutAccentAndCapitalLetters
}

$Path = "C:\Scripts"
$CsvFile = "$Path\Users.csv"
$LogFile = "$Path\Log.log"
# Q.5.3 Modification de Select-Object -Skip 1 au lieu de 2 pour ne pas prendre en compte seulement la première ligne du csv (menu)
# Q.5.5 Ajout pipe avec Select-Object "prenom","nom","fonction","description" pour ne garder que les colonnes utiles
$Users = Import-Csv -Path $CsvFile -Delimiter ";" `
    -Header "prenom","nom","societe","fonction","service","description","mail","mobile","scriptPath","telephoneNumber" `
    -Encoding UTF8  | Select-Object -Skip 1 | Select-Object "prenom","nom","fonction","description"
foreach ($User in $Users)
{
    $Prenom = ManageAccentsAndCapitalLetters -String $User.prenom
    $Nom = ManageAccentsAndCapitalLetters -String $User.Nom
    $Name = "$Prenom.$Nom"
    If (-not(Get-LocalUser -Name "$Prenom.$Nom" -ErrorAction SilentlyContinue))
    {
        $Pass = Random-Password
        $Password = (ConvertTo-secureString $Pass -AsPlainText -Force)
        $Description = "$($User.Description) - $($User.Fonction)"
        # Q.5.4 Ajout de Description et sa variable dans hashtable UserInfo
        # Q.5.11 Modification de PasswordNeverExpires en True
        $UserInfo = @{
            Name                 = "$Prenom.$Nom"
            FullName             = "$Prenom.$Nom"
            Password             = $Password
            AccountNeverExpires  = $True
            PasswordNeverExpires = $True
            Description		 = $Description
        }

        New-LocalUser @UserInfo
        #Q.5.10 Ajout des membres au groupe Utilisateurs (avec un s)
        Add-LocalGroupMember -Group "Utilisateurs" -Member "$Prenom.$Nom"
        # Q.5.6 Aff ichage validation nom et prénom utilisateur + password en clair, le tout en vert
        Write-Host "L'utilisateur $Prenom.$Nom a été crée avec le mot de passe $Pass" -ForegroundColor Green
        # Q.5.8 Journalisation évènement création User réussie
        Log -FilePath $LogFile -Content "Création utilisateur $Prenom.$Nom réussie"
    }
    # Q.5.9 Ajout message si utilisateur déjà existant
    Else 
    {
    Write-Host "L'utilisateur $Prenom.$Nom existe déjà" -ForegroundColor Red
    }
}