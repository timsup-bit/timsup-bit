# Genere assets/langages-dark.svg et assets/langages-light.svg.
# Source : octets de code par langage sur les depots publics non forkes, via l'API GitHub.
# Tourne en local (pwsh / Windows PowerShell) et sur GitHub Actions.
param(
  [string[]]$Logins = @("timsup-bit", "timsup777"),
  [string]$OutDir = "assets",
  # Brouillons de portfolio generes depuis des templates, et depots vides : ils pesent
  # plus lourd que le code ecrit a la main et faussaient completement la repartition.
  [string[]]$Exclure = @(
    "PORTFOLIO", "Timoth-e-berthelot-portfolio2025", "Portfolio-timoth-e-berthelott",
    "Portfolio-Timoth-e-Berthelot", "auto-annotated-portfolio", "auto-annotated-portfolio-1",
    "Timoth-e-berthelot", "next-netlify-starter", "ubiquitous-palm-tree",
    "Test-de-repository-pour-mon-programme-de-test.", "AFTV", "BACK", "MM2", "mon-mental"
  )
)
$ErrorActionPreference = "Stop"

$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) { $gh = "C:\Program Files\GitHub CLI\gh.exe" }

$query = @'
query($login:String!){
  user(login:$login){
    repositories(first:100, privacy:PUBLIC, isFork:false, ownerAffiliations:OWNER){
      nodes{
        name
        isArchived
        languages(first:12, orderBy:{field:SIZE, direction:DESC}){
          edges{ size node{ name color } }
        }
      }
    }
  }
}
'@

# Les deux comptes comptent : le code iOS vit sur le second, le reste sur le premier.
$tous = @()
foreach ($login in $Logins) {
  $tous += (& $gh api graphql -f login=$login -f query=$query | ConvertFrom-Json).data.user.repositories.nodes
}
$repos = $tous | Where-Object { -not $_.isArchived -and $Exclure -notcontains $_.name }

$octets  = @{}
$couleur = @{}
foreach ($r in $repos) {
  foreach ($e in $r.languages.edges) {
    $nom = $e.node.name
    if (-not $octets.ContainsKey($nom)) { $octets[$nom] = 0L; $couleur[$nom] = $e.node.color }
    $octets[$nom] += [long]$e.size
  }
}
if ($octets.Count -eq 0) { throw "Aucun langage trouve pour $Login." }

$total   = ($octets.Values | Measure-Object -Sum).Sum
$classes = $octets.GetEnumerator() | Sort-Object -Property Value -Descending
$TOP     = 6

$parts = @()
$i = 0
foreach ($k in $classes) {
  if ($i -lt $TOP) {
    $col = $couleur[$k.Key]; if (-not $col) { $col = "#8b949e" }
    $parts += [pscustomobject]@{ Nom = $k.Key; Part = $k.Value / [double]$total; Couleur = $col }
  }
  $i++
}
$reste = 1.0 - (($parts | Measure-Object -Property Part -Sum).Sum)
if ($reste -gt 0.004) { $parts += [pscustomobject]@{ Nom = "autres"; Part = $reste; Couleur = "#8b949e" } }

# --- geometrie ---
$W = 1200; $H = 136
$X0 = 6; $X1 = 1194; $BARW = $X1 - $X0
$BY = 62; $BH = 16; $GAP = 3

$SANS = "-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif"
$MONO = "ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, Liberation Mono, monospace"

$themes = @{
  dark  = @{ bg = "#0d1117"; ink = "#e6edf3"; muted = "#8b949e"; dim = "#6e7681"; rule = "#21262d"; piste = "#161b22" }
  light = @{ bg = "#ffffff"; ink = "#1f2328"; muted = "#59636e"; dim = "#818b98"; rule = "#d1d9e0"; piste = "#f0f3f6" }
}

function Esc([string]$s) {
  $sb = [System.Text.StringBuilder]::new()
  foreach ($ch in $s.ToCharArray()) {
    $code = [int]$ch
    if ($ch -eq '&') { [void]$sb.Append('&amp;') }
    elseif ($ch -eq '<') { [void]$sb.Append('&lt;') }
    elseif ($ch -eq '>') { [void]$sb.Append('&gt;') }
    elseif ($code -gt 126) { [void]$sb.Append("&#$code;") }
    else { [void]$sb.Append($ch) }
  }
  $sb.ToString()
}

# Le fichier reste en ASCII pur : Windows PowerShell 5.1 lit les .ps1 en ANSI sans BOM,
# donc les accents passent par des entites XML plutot que par des caracteres litteraux.
$moisFr = @('JANVIER','F&#201;VRIER','MARS','AVRIL','MAI','JUIN','JUILLET','AO&#219;T',
            'SEPTEMBRE','OCTOBRE','NOVEMBRE','D&#201;CEMBRE')
$now    = [datetime]::UtcNow
$maj    = "{0} {1} {2}" -f $now.Day, $moisFr[$now.Month - 1], $now.Year
$nbDep  = $repos.Count
$nbCpt  = $Logins.Count

foreach ($t in $themes.Keys) {
  $c = $themes[$t]
  $o = [System.Collections.Generic.List[string]]::new()
  $add = { param($s) $o.Add($s) }

  & $add ("<svg xmlns=""http://www.w3.org/2000/svg"" viewBox=""0 0 $W $H"" width=""$W"" height=""$H"" role=""img"" aria-label=""Repartition des langages"">")
  & $add ("<rect width=""$W"" height=""$H"" fill=""$($c.bg)""/>")

  # titre
  & $add ("<text x=""$X0"" y=""30"" font-family=""$MONO"" font-size=""12.5"" letter-spacing=""3.2"" fill=""$($c.muted)"">LANGAGES</text>")
  $droite = "$nbDep D&#201;P&#212;TS &#183; $nbCpt COMPTES &#183; $maj"
  & $add ("<text x=""$X1"" y=""30"" text-anchor=""end"" font-family=""$MONO"" font-size=""12.5"" letter-spacing=""2"" fill=""$($c.dim)"">$droite</text>")

  # piste + segments
  & $add ("<rect x=""$X0"" y=""$BY"" width=""$BARW"" height=""$BH"" rx=""3"" fill=""$($c.piste)""/>")
  $x = [double]$X0
  $nb = $parts.Count
  for ($k = 0; $k -lt $nb; $k++) {
    $p = $parts[$k]
    $seg = [math]::Round($p.Part * ($BARW - $GAP * ($nb - 1)), 2)
    if ($seg -lt 3) { $seg = 3 }
    $xr = [math]::Round($x, 2)
    & $add ("  <rect x=""$xr"" y=""$BY"" width=""$seg"" height=""$BH"" rx=""3"" fill=""$($p.Couleur)""><title>$(Esc($p.Nom))</title></rect>")
    $x += $seg + $GAP
  }

  # legende
  $lx = [double]$X0
  foreach ($p in $parts) {
    $pct = [math]::Round($p.Part * 100, 1)
    if ($pct -ge 10) { $pct = [math]::Round($p.Part * 100, 0) }
    $lbl = Esc($p.Nom)
    $xr = [math]::Round($lx, 1)
    $tx = $xr + 15
    $px = $tx + [math]::Round($p.Nom.Length * 7.6, 1) + 10
    & $add ("  <rect x=""$xr"" y=""109"" width=""8"" height=""8"" rx=""2"" fill=""$($p.Couleur)""/>")
    & $add ("  <text x=""$tx"" y=""117"" font-family=""$SANS"" font-size=""13.5"" fill=""$($c.ink)"">$lbl</text>")
    & $add ("  <text x=""$px"" y=""117"" font-family=""$MONO"" font-size=""12.5"" fill=""$($c.dim)"">$pct%</text>")
    $lx = $px + [math]::Round(("$pct%").Length * 7.7, 1) + 26
  }

  & $add ("</svg>")

  $path = Join-Path $OutDir "langages-$t.svg"
  $dir = Split-Path -Parent $path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  [System.IO.File]::WriteAllText(
    [System.IO.Path]::Combine((Get-Location).Path, $path),
    ($o -join "`n") + "`n",
    (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "ecrit $path"
}

Write-Host ("total = {0:N0} octets sur {1} depots, {2} comptes" -f $total, $nbDep, $nbCpt)
