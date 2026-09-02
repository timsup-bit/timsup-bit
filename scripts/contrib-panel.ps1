# Genere assets/contributions.svg depuis le calendrier de contributions GitHub.
# Palette sobre monochrome + balayage anime. Tourne en local et sur GitHub Actions (pwsh).
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
$serie = 0; $cur = 0
foreach ($d in $days) {
  if ($d.contributionCount -gt 0) { $cur++; if ($cur -gt $serie) { $serie = $cur } } else { $cur = 0 }
}

$PITCH = 16; $CELL = 13; $GX = 126; $GY = 118
$NW = $weeks.Count
$GW = $NW * $PITCH
$SWEEP = 9.0
$mois = @('janv','f&#233;vr','mars','avr','mai','juin','juil','ao&#251;t','sept','oct','nov','d&#233;c')
# rampe monochrome : aucun neon
$niv = @('#16181C', '#2B3038', '#474D56', '#727982', '#BFC4CC')

$sb = [System.Text.StringBuilder]::new()
function W($s) { [void]$sb.AppendLine($s) }

W '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 340" width="1200" height="340" role="img" aria-label="Calendrier de contributions">'
W '<defs>'
W '  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0C0C0E"/><stop offset="0.62" stop-color="#08080A"/><stop offset="1" stop-color="#0A0A0C"/></linearGradient>'
W '  <radialGradient id="vig" cx="0.5" cy="0.46" r="0.78"><stop offset="0.42" stop-color="#000000" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity="0.82"/></radialGradient>'
W '  <linearGradient id="sweep" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#DDE2EA" stop-opacity="0"/><stop offset="0.5" stop-color="#DDE2EA" stop-opacity="0.05"/><stop offset="1" stop-color="#DDE2EA" stop-opacity="0"/></linearGradient>'
W '  <linearGradient id="head" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#BFC4CC" stop-opacity="0"/><stop offset="1" stop-color="#BFC4CC" stop-opacity="0.5"/></linearGradient>'
W '  <pattern id="scan" width="3" height="3" patternUnits="userSpaceOnUse"><rect width="3" height="1" fill="#AEB6C2" opacity="0.026"/></pattern>'
W '  <filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="3" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter>'
W '  <clipPath id="frame"><rect width="1200" height="340"/></clipPath>'
W '</defs>'
W '<g clip-path="url(#frame)">'
W '  <rect width="1200" height="340" fill="url(#bg)"/>'
W '  <g stroke="#31353C" stroke-width="1.4" fill="none">'
W '    <path d="M40 74 V40 H74"/><path d="M1126 40 H1160 V74"/><path d="M1160 266 V300 H1126"/><path d="M74 300 H40 V266"/>'
W '  </g>'
W '  <text x="88" y="62" font-family="Consolas, Menlo, DejaVu Sans Mono, monospace" font-size="13" letter-spacing="2.6" fill="#6B6F77">CONTRIBUTIONS</text>'
W '  <text x="1112" y="62" text-anchor="end" font-family="Consolas, Menlo, DejaVu Sans Mono, monospace" font-size="13" letter-spacing="2.6" fill="#3E434A">// 12 MOIS</text>'
W '  <rect x="88" y="76" width="1024" height="1" fill="#23262B"/>'
W '  <rect x="88" y="75" width="0" height="2" fill="#8E949D"><animate attributeName="width" values="0;0;118;118;118;0" keyTimes="0;0.04;0.30;0.92;0.97;1" dur="8.5s" repeatCount="indefinite"/></rect>'

$prev = -1; $lastLbl = -9
for ($w = 0; $w -lt $NW; $w++) {
  $d0 = [datetime]::Parse($weeks[$w].contributionDays[0].date)
  if ($d0.Month -ne $prev -and $w -ge 1 -and ($w - $lastLbl) -ge 3 -and $w -lt ($NW - 1)) {
    $x = $GX + $w * $PITCH
    W ("  <text x=""$x"" y=""106"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" fill=""#4A515C"">" + $mois[$d0.Month - 1] + "</text>")
    $prev = $d0.Month; $lastLbl = $w
  }
}
foreach ($p in @(@(1,'lun'), @(3,'mer'), @(5,'ven'))) {
  $y = $GY + $p[0] * $PITCH + 10
  W ("  <text x=""112"" y=""$y"" text-anchor=""end"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" fill=""#4A515C"">" + $p[1] + "</text>")
}

for ($w = 0; $w -lt $NW; $w++) {
  foreach ($d in $weeks[$w].contributionDays) {
    $x = $GX + $w * $PITCH
    $y = $GY + $d.weekday * $PITCH
    $c = $d.contributionCount
    if ($c -eq 0) { $lv = 0 } else { $lv = [math]::Ceiling($c / $pic * 4); if ($lv -lt 1) { $lv = 1 }; if ($lv -gt 4) { $lv = 4 } }
    $f = $niv[$lv]
    if ($lv -eq 0) {
      W ("  <rect x=""$x"" y=""$y"" width=""$CELL"" height=""$CELL"" fill=""$f""><title>$($d.date) : $c</title></rect>")
    } else {
      # la cellule est allumee au passage de la ligne de balayage
      $frac = [math]::Round($w / [double]($NW - 1), 4)
      if ($frac -lt 0.03) { $frac = 0.03 }
      if ($frac -gt 0.97) { $frac = 0.97 }
      $k1 = [math]::Round($frac - 0.02, 4); $k2 = [math]::Round($frac + 0.03, 4)
      W ("  <rect x=""$x"" y=""$y"" width=""$CELL"" height=""$CELL"" fill=""$f"" opacity=""0.62""><title>$($d.date) : $c</title><animate attributeName=""opacity"" values=""0.62;0.62;1;0.62;0.62"" keyTimes=""0;$k1;$frac;$k2;1"" dur=""${SWEEP}s"" repeatCount=""indefinite""/></rect>")
    }
  }
}

# ligne de balayage qui traverse la grille
$gx2 = $GX + $GW
$gh2 = 7 * $PITCH - 3
$gxStart = $GX - 46
W ("  <rect x=""$GX"" y=""$GY"" width=""46"" height=""$gh2"" fill=""url(#head)"" opacity=""0.5""><animate attributeName=""x"" values=""$gxStart;$gx2"" dur=""${SWEEP}s"" repeatCount=""indefinite""/></rect>")
W ("  <rect x=""$GX"" y=""$GY"" width=""1.6"" height=""$gh2"" fill=""#BFC4CC"" opacity=""0.55""><animate attributeName=""x"" values=""$GX;$gx2"" dur=""${SWEEP}s"" repeatCount=""indefinite""/></rect>")

$lx = 1112 - 5 * 16 - 66
W ("  <text x=""$lx"" y=""256"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" fill=""#4A515C"">moins</text>")
for ($i = 0; $i -lt 5; $i++) {
  $x = $lx + 40 + $i * 16
  W ("  <rect x=""$x"" y=""246"" width=""11"" height=""11"" fill=""" + $niv[$i] + """/>")
}
W '  <text x="1112" y="256" text-anchor="end" font-family="Consolas, Menlo, DejaVu Sans Mono, monospace" font-size="10" fill="#4A515C">plus</text>'
W '  <rect x="88" y="272" width="1024" height="1" fill="#23262B"/>'

$stats = @(@('TOTAL', "$total"), @('JOURS ACTIFS', "$actifs"), @('S&#201;RIE MAX', "$serie j"), @('MEILLEUR JOUR', "$pic"))
for ($i = 0; $i -lt 4; $i++) {
  $x = 126 + $i * 250
  W ("  <text x=""$x"" y=""296"" font-family=""Consolas, Menlo, DejaVu Sans Mono, monospace"" font-size=""10"" letter-spacing=""2"" fill=""#4A515C"">" + $stats[$i][0] + "</text>")
  $col = if ($i -eq 0) { '#D9D8D4' } else { '#8A9099' }
  W ("  <text x=""$x"" y=""324"" font-family=""Impact, Haettenschweiler, Arial Black, sans-serif"" font-size=""26"" letter-spacing=""1"" fill=""$col"">" + $stats[$i][1] + "</text>")
}
W '  <rect x="-420" y="0" width="420" height="340" fill="url(#sweep)"><animate attributeName="x" values="-420;1200" dur="11s" repeatCount="indefinite"/></rect>'
W '  <rect width="1200" height="340" fill="url(#scan)"/>'
W '  <rect width="1200" height="340" fill="url(#vig)"/>'
W '  <rect width="1200" height="340" filter="url(#grain)" opacity="0.07"/>'
W '</g></svg>'

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath ".").Path + [System.IO.Path]::DirectorySeparatorChar + $Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "contributions.svg ecrit - total=$total actifs=$actifs serie=$serie pic=$pic"
