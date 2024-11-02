# Verificar se o script está sendo executado com privilégios elevados
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Por favor, execute este script como Administrador!"
    break
}

# Função para testar a conectividade com a internet
function Test-InternetConnection {
    try {
        $testConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Conexão com a internet é necessária, mas não está disponível. Verifique sua conexão."
        return $false
    }
}

# Função para instalar Nerd Fonts
function Install-NerdFonts {
    param (
        [string]$FontName = "CascadiaCode",
        [string]$FontDisplayName = "CaskaydiaCove NF",
        [string]$Version = "3.2.1"
    )

    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -notcontains "${FontDisplayName}") {
            $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
        } else {
            Write-Host "Fonte ${FontDisplayName} já está instalada"
        }
    }
    catch {
        Write-Error "Falha ao baixar ou instalar a fonte ${FontDisplayName}. Erro: $_"
    }
}

# Verificar conectividade com a internet antes de prosseguir
if (-not (Test-InternetConnection)) {
    break
}

# Criação ou atualização do perfil
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detectar a versão do PowerShell e criar diretórios de perfil, se não existirem
        $profilePath = ""
        if ($PSVersionTable.PSEdition -eq "Core") {
            $profilePath = "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory"
        }

        Invoke-RestMethod https://raw.githubusercontent.com/josucafd/powershell-profile/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "O perfil em [$PROFILE] foi criado."
        Write-Host "Se desejar fazer alterações ou personalizações, faça-as em [$profilePath\Profile.ps1], pois há um atualizador no perfil instalado que usa hash para atualizar o perfil, o que pode resultar na perda de alterações."
    }
    catch {
        Write-Error "Falha ao criar ou atualizar o perfil. Erro: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod https://raw.githubusercontent.com/josucafd/powershell-profile/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "O perfil em [$PROFILE] foi criado e o perfil antigo foi removido."
        Write-Host "Faça backup de qualquer componente persistente do seu perfil antigo em [$HOME\Documents\PowerShell\Profile.ps1], pois há um atualizador no perfil instalado que usa hash para atualizar o perfil, o que pode resultar na perda de alterações."
    }
    catch {
        Write-Error "Falha ao fazer backup e atualizar o perfil. Erro: $_"
    }
}

# Instalação do Oh My Posh
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
    Write-Error "Falha ao instalar Oh My Posh. Erro: $_"
}

# Instalação da Fonte
Install-NerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"

# Verificação final e mensagem para o usuário
if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($fontFamilies -contains "CaskaydiaCove NF")) {
    Write-Host "Configuração concluída com sucesso. Reinicie sua sessão do PowerShell para aplicar as mudanças."
} else {
    Write-Warning "Configuração concluída com erros. Verifique as mensagens de erro acima."
}

# Instalação do Chocolatey
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
catch {
    Write-Error "Falha ao instalar o Chocolatey. Erro: $_"
}

# Instalação do Terminal Icons
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
    Write-Error "Falha ao instalar o módulo Terminal Icons. Erro: $_"
}

# Instalação do zoxide
try {
    winget install -e --id ajeetdsouza.zoxide
    Write-Host "zoxide instalado com sucesso."
}
catch {
    Write-Error "Falha ao instalar o zoxide. Erro: $_"
}
