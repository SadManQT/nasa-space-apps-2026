# Compose the Blender diagnostic renders on Tanvir's Windows machine.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$catalog = Get-Content -Raw -Encoding UTF8 (Join-Path $repoRoot 'game/assets/environment/terrain/kit.json') | ConvertFrom-Json
$font = [System.Drawing.Font]::new('Segoe UI', 13)
$heading = [System.Drawing.Font]::new('Segoe UI', 21)
$brush = [System.Drawing.Brushes]::White
foreach ($lod in @(0, 1, 2)) {
$sheet = [System.Drawing.Bitmap]::new(1536, 1500)
$graphics = [System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.Color]::FromArgb(20, 23, 29))
$graphics.DrawString("M1-35 | Lunar fracture kit | LOD$lod | 16 variants", $heading, $brush, 20, 14)
$graphics.DrawString('Normalized display size; dimensions below are actual metres. Diagnostic lighting. Surfaces await M1-33.', $font, $brush, 20, 52)
for ($index = 0; $index -lt 16; $index++) {
    $rock = $catalog.rocks[$index]
    $x = ($index % 4) * 384
    $y = 90 + [math]::Floor($index / 4) * 350
    $file = Join-Path $repoRoot ('production/models/lunar_kit/' + $rock.id + '_LOD' + $lod + '.png')
    $picture = [System.Drawing.Image]::FromFile($file)
    $graphics.DrawImage($picture, [int]$x, [int]$y, 384, 320)
    $picture.Dispose()
    $label = '{0:00} {1} | {2} m | {3}/{4}/{5} tris' -f ($index+1), ($rock.id.Split('_')[-1]), $rock.size_m, $rock.triangles[0], $rock.triangles[1], $rock.triangles[2]
    $graphics.DrawString($label, $font, $brush, ($x+10), ($y+321))
}
$target = if ($lod -eq 0) { 'production/review/M1-35_rock_contact.png' } else { "production/review/M1-35_rock_LOD$lod.png" }
$sheet.Save((Join-Path $repoRoot $target), [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$sheet.Dispose()
}
$sheet = [System.Drawing.Bitmap]::new(1536, 630)
$graphics = [System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.Color]::FromArgb(20, 23, 29))
$graphics.DrawString('M1-35 | Provisional regolith | 4 m square repeatable tiles', $heading, $brush, 20, 14)
$graphics.DrawString('Final exterior shading awaits M1-33. No airborne dust, vegetation or atmospheric effects.', $font, $brush, 20, 52)
$index = 0
foreach ($kind in @('Fresh', 'Compacted', 'Disturbed')) {
    $file = Join-Path $repoRoot ('game/assets/environment/terrain/textures/T_Regolith_' + $kind + '_BaseColor.png')
    $picture = [System.Drawing.Image]::FromFile($file)
    $graphics.DrawImage($picture, $index*512, 90, 512, 512)
    $picture.Dispose()
    $graphics.DrawString($kind, $font, $brush, ($index*512+10), 605)
    $index++
}
$sheet.Save((Join-Path $repoRoot 'production/review/M1-35_regolith_contact.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$sheet.Dispose()
$font.Dispose()
$heading.Dispose()
Write-Output 'CONTACT_SHEETS_PASS: rocks and regolith'
