# Label approved-source Blender studies and build the A/B decision sheet.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$work = Join-Path $repoRoot 'production/models/lookdev_exterior_v1'
$font = [System.Drawing.Font]::new('Segoe UI', 17)
$titleFont = [System.Drawing.Font]::new('Segoe UI Semibold', 27)
$smallFont = [System.Drawing.Font]::new('Segoe UI', 14)
$white = [System.Drawing.Brushes]::White
$muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(176, 188, 202))
$bg = [System.Drawing.Color]::FromArgb(14, 19, 27)
$frames = @(
    @('aurora_A','01_Aurora_A.png','A / CEL SHADING + FINE OUTLINES','Aurora observation bay | approved cast, sealed pressurized interior'),
    @('aurora_B','02_Aurora_B.png','B / SOFTER MATERIAL SHADING','Same cast, pose, camera, terrain and lighting as option A'),
    @('road','03_Relay_Road.png','RELAY ROAD / SCALE AND HARD SHADOWS','Pressurized rover and route markers | surface contact, no dust plume'),
    @('coldtrap','04_Cold_Trap.png','COLD TRAP / HEADLIGHTS ONLY','Vault shelf detail | no Sun, ambient sky light, fog or visible light beam'),
    @('summit','05_Malapert_Summit.png','MALAPERT / RELAY PLATFORM STUDY','Relay hardware and rover | Earth omitted pending verified viewing geometry')
)
foreach ($frame in $frames) {
    $source = [System.Drawing.Image]::FromFile((Join-Path $work ($frame[0]+'.png')))
    if ($source.Width -ne 1920 -or $source.Height -ne 1080) { throw ('Final render size mismatch: '+$frame[0]) }
    $sheet = [System.Drawing.Bitmap]::new(1920, 1220)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear($bg)
    $g.DrawString($frame[2], $titleFont, $white, 30, 12)
    $g.DrawString($frame[3], $font, $muted, 30, 56)
    $g.DrawImage($source, 0, 100, 1920, 1080)
    $g.DrawString('M1-32 ART STUDY / Procedural terrain proxy; surveyed geography and dated lighting pending M1-34.', $smallFont, $muted, 30, 1188)
    $sheet.Save((Join-Path $PSScriptRoot $frame[1]), [System.Drawing.Imaging.ImageFormat]::Png)
    $source.Dispose()
    $g.Dispose()
    $sheet.Dispose()
}
$sheet = [System.Drawing.Bitmap]::new(1920, 1730)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear($bg)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawString('CHOOSE THE CHARACTER TREATMENT', $titleFont, $white, 28, 10)
$g.DrawString('A / Cel shading + fine outlines', $font, $white, 28, 63)
$g.DrawString('B / Softer material shading', $font, $white, 988, 63)
for ($i=0; $i -lt 2; $i++) {
    $option = if ($i -eq 0) { 'A' } else { 'B' }
    $picture = [System.Drawing.Image]::FromFile((Join-Path $work ('aurora_'+$option+'.png')))
    $g.DrawImage($picture, ($i*960), 105, 960, 540)
    $destination = [System.Drawing.Rectangle]::new(($i*960), 675, 960, 960)
    $sourceRect = [System.Drawing.Rectangle]::new(80, 350, 620, 620)
    $g.DrawImage($picture, $destination, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
    $picture.Dispose()
}
$g.DrawString('Full frame above / matching character detail below', $smallFont, $muted, 28, 648)
$g.DrawString('Same approved models, pose, camera, lights and terrain. Only character shading / outlines change.', $font, $white, 28, 1655)
$g.DrawString('M1-33: Tanvir approved A on 4 Nov 2026. Terrain remains a composition proxy; no performance claim.', $smallFont, $muted, 28, 1694)
$sheet.Save((Join-Path $PSScriptRoot '00_Compare_A_B.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$sheet.Dispose()
$font.Dispose()
$titleFont.Dispose()
$smallFont.Dispose()
$muted.Dispose()
Write-Output 'LOOKDEV_COMPOSE_PASS: five scene frames and A/B decision sheet'
