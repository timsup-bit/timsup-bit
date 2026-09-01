# Genere assets/contributions.svg depuis le calendrier de contributions GitHub.
# Tourne en local (Windows PowerShell) et sur GitHub Actions (pwsh, ubuntu).
param([string]$Login = "timsup-bit", [string]$Out = "assets/contributions.svg")
$ErrorActionPreference = "Stop"

$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) { $gh = "C:\Program Files\GitHub CLI\gh.exe" }

$q = 'query($login:String!){user(login:$login){contributionsCollection{contributionCalendar{totalContributions weeks{contributionDays{date contributionCount weekday}}}}}}'
$cal = (& $gh api graphql -f login=$Login -f query=$q | ConvertFrom-Json).data.user.contributionsCollection.contributionCalendar
$weeks = $cal.weeks
$days  = $weeks | ForEach-Object { $_.contributionDays }

$total  = $cal.totalContributions
$actifs = ($days | Where-Object { $_.contributionCount -gt 0 }).Count
$pic    = ($days | Measure-Object contributionCount -Maximum).Maximum
if ($pic -lt 1) { $pic = 1 }

# plus longue serie de jours consecutifs actifs
$serie = 0; $cur = 0
foreach ($d in $days) {
  if ($d.contributionCount -gt 0) { $cur++; if ($cur -gt $serie) { $serie = $cur } } else { $cur = 0 }
}

# geometrie
$PITCH = 16; $CELL = 13; $GX = 126; $GY = 118
$mois = @('janv','f&#233;vr','mars','avr','mai','juin','juil','ao&#251;t','sept','oct','nov','d&#233;c')
$niv  = @('#111A26', '#0E5A6B', '#17A3BD', '#22E7F5', '#FF2E97')

$sb = [System.Text.StringBuilder]::new()
function W($s) { [void]$sb.AppendLine($s) }

W '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 340" width="1200" height="340" role="img" aria-label="Calendrier de contributions">'
W '<defs>'
W '  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0B0B14"/><stop offset="0.55" stop-color="#06060B"/><stop offset="1" stop-color="#0A0616"/></linearGradient>'
W '  <radialGradient id="gc" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#22E7F5" stop-opacity="0.20"/><stop offset="1" stop-color="#22E7F5" stop-opacity="0"/></radialGradient>'
W '  <radialGradient id="gm" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FF2E97" stop-opacity="0.24"/><stop offset="1" stop-color="#FF2E97" stop-opacity="0"/></radialGradient>'
W '  <pattern id="scan" width="3" height="3" patternUnits="userSpaceOnUse"><rect width="3" height="1" fill="#9FE9FF" opacity="0.05"/></pattern>'
W '  <filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="2.6" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
W '  <clipPath id="frame"><rect width="1200" height="340"/></clipPath>'
W '</defs>'
W '<g clip-path="url(#frame)">'
W '  <rect width="1200" height="340" fill="url(#bg)"/>'
W '  <ellipse cx="880" cy="40" rx="420" ry="200" fill="url(#gc)"/>'
W '  <ellipse cx="220" cy="330" rx="400" ry="190" fill="url(#gm)"/>'
W '  <g stroke="#22E7F5" stroke-width="1.6" fill="none" opacity="0.85" filter="url(#glow)">'
W '    <path d="M40 74 V40 H74"/><path d="M1126 40 H1160 V74"/><path d="M1160 266 V300 H1126"/><path d="M74 300 H40 V266"/>'
W '  </g>'
W ('  <text x="88" y="62" font-family="Consolas, Menlo, DejaVu Sans Mono, monospace" font-size="13" letter-spacing="2.6" fill="#22E7F5" opacity="0.9">CONTRIBUTIONS</text>')
W ('  <text x="1112" y="62" text-anchor="end" font-family="Consolas, Menlo, DejaVu Sans Mono, monospace" font-size="13" letter-spacing="2.6" fill="#5A6B7E">// 12 MOIS</text>')
W '  <rect x="88" y="76" width="1024" height="1" fill="#22E7F5" opacity="0.28"/>'
W '  <rect x="88" y="75" width="118" height="2" fill="#FF2E97" opacity="0.95" filter="url(#glow)"/>'

# etiquettes de mois
$prev = -1; $lastLbl = -9
for ($w = 0; $w -lt $weeks.Count; $w++) {
  $d0 = [datetime]::Parse($weeks[$w].contributionDays[0].date)
  if ($d0.Month -ne $prev -and $w -ge 1 -and ($w - $lastLbl) -ge 3 -and $w -lt ($weeks.Count - 1)) {
    $x = $GX + $w * $PITCH
    W ("  <text x=""$x"" y=""106"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" fill=""#4C5A6B"">" + $mois[$d0.Month - 1] + "</text>")
    $prev = $d0.Month; $lastLbl = $w
  }
}
# etiquettes de jours
foreach ($p in @(@(1,'lun'), @(3,'mer'), @(5,'ven'))) {
  $y = $GY + $p[0] * $PITCH + 10
  W ("  <text x=""112"" y=""$y"" text-anchor=""end"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" fill=""#4C5A6B"">" + $p[1] + "</text>")
}
# cellules
for ($w = 0; $w -lt $weeks.Count; $w++) {
  foreach ($d in $weeks[$w].contributionDays) {
    $x = $GX + $w * $PITCH
    $y = $GY + $d.weekday * $PITCH
    $c = $d.contributionCount
    if ($c -eq 0) { $lv = 0 } else { $lv = [math]::Ceiling($c / $pic * 4); if ($lv -lt 1) { $lv = 1 }; if ($lv -gt 4) { $lv = 4 } }
    $f = $niv[$lv]
    $extra = ""
    if ($lv -eq 4) { $extra = ' filter="url(#glow)"' }
    elseif ($lv -eq 0) { $extra = ' opacity="0.85"' }
    W ("  <rect x=""$x"" y=""$y"" width=""$CELL"" height=""$CELL"" rx=""2"" fill=""$f""$extra><title>$($d.date) : $c</title></rect>")
  }
}
# legende
$lx = 1112 - 5 * 16 - 66
W ("  <text x=""$lx"" y=""256"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" fill=""#4C5A6B"">moins</text>")
for ($i = 0; $i -lt 5; $i++) {
  $x = $lx + 40 + $i * 16
  W ("  <rect x=""$x"" y=""246"" width=""11"" height=""11"" rx=""2"" fill=""" + $niv[$i] + """/>")
}
W ("  <text x=""1112"" y=""256"" text-anchor=""end"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" fill=""#4C5A6B"">plus</text>")

W '  <rect x="88" y="272" width="1024" height="1" fill="#22E7F5" opacity="0.22"/>'
# statistiques
$stats = @(@('TOTAL', "$total"), @('JOURS ACTIFS', "$actifs"), @('S&#201;RIE MAX', "$serie j"), @('MEILLEUR JOUR', "$pic"))
for ($i = 0; $i -lt 4; $i++) {
  $x = 126 + $i * 250
  W ("  <text x=""$x"" y=""296"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" letter-spacing=""2"" fill=""#4C5A6B"">" + $stats[$i][0] + "</text>")
  $col = if ($i -eq 0) { '#FF2E97' } else { '#EAF6FF' }
  W ("  <text x=""$x"" y=""324"" font-family=""Impact, Haettenschweiler, Arial Black, sans-serif"" font-size=""26"" letter-spacing=""1"" fill=""$col"">" + $stats[$i][1] + "</text>")
}
W '  <rect width="1200" height="340" fill="url(#scan)"/>'
W '</g></svg>'

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath ".").Path + [System.IO.Path]::DirectorySeparatorChar + $Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "contributions.svg ecrit - total=$total actifs=$actifs serie=$serie pic=$pic"
