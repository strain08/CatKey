# Renders the cat glyph (U+1F431) from Segoe UI Emoji into CatKey.ico.
# White fill with a dark outline so it reads on light and dark taskbars.
# Run with Windows PowerShell: powershell -File tools\make-icon.ps1
Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot "..\CatKey.ico"
$glyph = [char]::ConvertFromUtf32(0x1F431)
$sizes = 16, 20, 24, 32, 40, 48, 64, 256
$pngs = @()

foreach ($size in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $family = New-Object System.Drawing.FontFamily "Segoe UI Emoji"
    $path.AddString($glyph, $family, 0, [single]100, (New-Object System.Drawing.PointF 0, 0),
        [System.Drawing.StringFormat]::GenericTypographic)

    # Scale the glyph outline to fill the icon, leaving room for the stroke
    $stroke = [Math]::Max(1.0, $size / 16.0)
    $b = $path.GetBounds()
    $scale = ($size - 2 * $stroke) / [Math]::Max($b.Width, $b.Height)
    $m = New-Object System.Drawing.Drawing2D.Matrix
    $m.Translate(($size - $b.Width * $scale) / 2, ($size - $b.Height * $scale) / 2)
    $m.Scale($scale, $scale)
    $m.Translate(-$b.X, -$b.Y)
    $path.Transform($m)

    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 32, 32, 32)), ($stroke * 2)
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPath($pen, $path)
    $g.FillPath([System.Drawing.Brushes]::White, $path)

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngs += , $ms.ToArray()
    $g.Dispose(); $bmp.Dispose(); $pen.Dispose(); $path.Dispose()
}

# ICO container: header, one directory entry per size, then PNG payloads
$fs = [System.IO.File]::Create($out)
$w = New-Object System.IO.BinaryWriter $fs
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $dim = if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] }
    $w.Write([byte]$dim); $w.Write([byte]$dim); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([uint16]1); $w.Write([uint16]32)
    $w.Write([uint32]$pngs[$i].Length); $w.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $w.Write($p) }
$w.Close()
Write-Output "wrote $out"
