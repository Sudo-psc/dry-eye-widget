# Gera o resumo digital hash (SHA-512) do codigo-fonte para registro no INPI (e-Software)
# Programa: dry_eye_widget
# Uso: pwsh -File inpi/gerar-hash-inpi.ps1   (executar a partir da raiz do repositorio)
#
# O documento consolidado NAO contem data/hora interna, de modo que o hash e
# reproduzivel: qualquer pessoa pode reexecutar este script no mesmo commit e
# obter exatamente o mesmo resumo digital.

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path "$PSScriptRoot\..").Path
Set-Location $root

# Conjunto de arquivos que caracteriza o programa: todo o codigo-fonte Dart (lib/)
# e o manifesto de dependencias (pubspec.yaml). Lista canonica vinda do git,
# ordenada alfabeticamente para garantir determinismo.
$files = & git ls-files 'lib/*.dart' 'pubspec.yaml' | Sort-Object

$outDir   = Join-Path $root 'inpi'
$consPath = Join-Path $outDir 'codigo-fonte-consolidado.txt'
$manPath  = Join-Path $outDir 'manifesto-hash.txt'

# Le metadados do programa
$pubspec = Get-Content (Join-Path $root 'pubspec.yaml') -Raw
$name    = ([regex]::Match($pubspec, '(?m)^name:\s*(.+)$')).Groups[1].Value.Trim()
$version = ([regex]::Match($pubspec, '(?m)^version:\s*(.+)$')).Groups[1].Value.Trim()

# Monta o documento consolidado (UTF-8 sem BOM, quebras de linha normalizadas para LF)
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine('CODIGO-FONTE CONSOLIDADO PARA REGISTRO DE PROGRAMA DE COMPUTADOR')
[void]$sb.AppendLine('Instituto Nacional da Propriedade Industrial (INPI) - e-Software')
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine("Programa: $name")
[void]$sb.AppendLine("Versao:   $version")
[void]$sb.AppendLine("Arquivos: $($files.Count)")
[void]$sb.AppendLine('Algoritmo de resumo: SHA-512')
[void]$sb.AppendLine('================================================================')
[void]$sb.AppendLine('')

foreach ($f in $files) {
    $content = (Get-Content -LiteralPath $f -Raw -Encoding UTF8) -replace "`r`n", "`n"
    [void]$sb.AppendLine('---------- 8< ----------------------------------------------------')
    [void]$sb.AppendLine("ARQUIVO: $f")
    [void]$sb.AppendLine('------------------------------------------------------------------')
    [void]$sb.Append($content)
    if (-not $content.EndsWith("`n")) { [void]$sb.Append("`n") }
    [void]$sb.AppendLine('')
}

$consolidated = ($sb.ToString()) -replace "`r`n", "`n"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($consolidated)
[System.IO.File]::WriteAllBytes($consPath, $bytes)

# Funcao de hash SHA-512 -> hex maiusculo
function Get-Sha512Hex([byte[]]$data) {
    $sha = [System.Security.Cryptography.SHA512]::Create()
    try { ($sha.ComputeHash($data) | ForEach-Object { $_.ToString('X2') }) -join '' }
    finally { $sha.Dispose() }
}

$mainHash = Get-Sha512Hex $bytes

# Manifesto: hash individual de cada arquivo + hash do consolidado
$mb = [System.Text.StringBuilder]::new()
[void]$mb.AppendLine('MANIFESTO DE RESUMOS DIGITAIS (SHA-512)')
[void]$mb.AppendLine("Programa: $name  |  Versao: $version")
[void]$mb.AppendLine('Algoritmo: SHA-512')
[void]$mb.AppendLine('')
[void]$mb.AppendLine('--- Resumo por arquivo ---')
foreach ($f in $files) {
    $fb = [System.IO.File]::ReadAllBytes((Join-Path $root $f))
    [void]$mb.AppendLine("$(Get-Sha512Hex $fb)  $f")
}
[void]$mb.AppendLine('')
[void]$mb.AppendLine('--- Resumo do documento consolidado (valor a informar no e-Software) ---')
[void]$mb.AppendLine("$mainHash  inpi/codigo-fonte-consolidado.txt")
[System.IO.File]::WriteAllBytes($manPath, [System.Text.Encoding]::UTF8.GetBytes(($mb.ToString() -replace "`r`n","`n")))

Write-Host ''
Write-Host '================ RESUMO DIGITAL (SHA-512) ================'
Write-Host "Programa : $name $version"
Write-Host "Arquivos : $($files.Count)  |  Bytes consolidado: $($bytes.Length)"
Write-Host "Documento: inpi/codigo-fonte-consolidado.txt"
Write-Host ''
Write-Host 'Hash SHA-512 do documento consolidado:'
Write-Host $mainHash
Write-Host '========================================================='
