Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

function Get-FittedFont {
  param(
    [System.Drawing.Graphics]$G,
    [string]$Text,
    [System.Drawing.FontFamily]$Family,
    [float]$MaxWidth,
    [float]$MaxHeight,
    [float]$StartSize
  )
  $size = $StartSize
  while ($size -gt 16) {
    $font = New-Object System.Drawing.Font($Family, $size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $measured = $G.MeasureString($Text, $font, [int]$MaxWidth)
    if ($measured.Width -le $MaxWidth -and $measured.Height -le $MaxHeight) {
      return $font
    }
    $font.Dispose()
    $size -= 2
  }
  return New-Object System.Drawing.Font($Family, 16, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-MemeLine {
  param(
    [System.Drawing.Graphics]$G,
    [string]$Text,
    [System.Drawing.Font]$Font,
    [System.Drawing.RectangleF]$Rect
  )
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment = [System.Drawing.StringAlignment]::Center
  $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
  $sf.FormatFlags = [System.Drawing.StringFormatFlags]::NoClip

  $emSize = $Font.Size
  $path.AddString(
    $Text,
    $Font.FontFamily,
    [int]$Font.Style,
    $emSize,
    $Rect,
    $sf
  )

  $stroke = [Math]::Max(8, [Math]::Round($Font.Size / 10))
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), ([float]$stroke)
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $pen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Center

  $G.DrawPath($pen, $path)
  $G.FillPath([System.Drawing.Brushes]::White, $path)

  $pen.Dispose()
  $path.Dispose()
  $sf.Dispose()
}

function Add-MemeCaption {
  param(
    [string]$Src,
    [string]$Dst,
    [string]$Top,
    [string]$Bottom
  )

  $img = [System.Drawing.Image]::FromFile((Resolve-Path $Src).Path)
  $bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height
  $bmp.SetResolution($img.HorizontalResolution, $img.VerticalResolution)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  $g.DrawImage($img, 0, 0, $img.Width, $img.Height)

  $family = New-Object System.Drawing.FontFamily 'Impact'
  $padX = [int]($img.Width * 0.04)
  $bandH = [int]($img.Height * 0.22)
  $maxW = $img.Width - (2 * $padX)
  $startSize = [Math]::Max(36, [int]($img.Width * 0.085))

  if ($Top) {
    $topFont = Get-FittedFont -G $g -Text $Top -Family $family -MaxWidth $maxW -MaxHeight $bandH -StartSize $startSize
    $topRect = New-Object System.Drawing.RectangleF $padX, ([int]($img.Height * 0.02)), $maxW, $bandH
    Draw-MemeLine -G $g -Text $Top -Font $topFont -Rect $topRect
    $topFont.Dispose()
  }

  if ($Bottom) {
    $botFont = Get-FittedFont -G $g -Text $Bottom -Family $family -MaxWidth $maxW -MaxHeight $bandH -StartSize $startSize
    $botRect = New-Object System.Drawing.RectangleF $padX, ($img.Height - $bandH - [int]($img.Height * 0.02)), $maxW, $bandH
    Draw-MemeLine -G $g -Text $Bottom -Font $botFont -Rect $botRect
    $botFont.Dispose()
  }

  $family.Dispose()
  $g.Dispose()
  $img.Dispose()

  $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
  $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]92)
  $outPath = Join-Path (Get-Location) $Dst
  $bmp.Save($outPath, $encoder, $encParams)
  $bmp.Dispose()
  Write-Host "OK $Dst"
}

$jobs = @(
  @{ Src='memes\scene-canada-stamp.jpg'; Dst='memes\meme-canada-stamp.jpg'; Top='CANADA WANTED A DEAL'; Bottom='I WANTED 50%' },
  @{ Src='memes\scene-china-port.jpg'; Dst='memes\meme-china-port.jpg'; Top='CHINA SAID NO DEAL'; Bottom='TARIFFS SAID YES' },
  @{ Src='memes\scene-hockey.jpg'; Dst='memes\meme-hockey.jpg'; Top='NICE STICK, CANADA'; Bottom="THAT'LL BE 50%" },
  @{ Src='memes\scene-toll.jpg'; Dst='memes\meme-toll.jpg'; Top='WELCOME TO HORMUZ'; Bottom="THAT'LL BE 20%" },
  @{ Src='memes\scene-steal-hormuz.jpg'; Dst='memes\meme-steal-hormuz.jpg'; Top='THEY CLOSED THE STRAIT'; Bottom='SO I STOLE HORMUZ' },
  @{ Src='memes\scene-war-room.jpg'; Dst='memes\meme-war-room.jpg'; Top='TARIFFS ON CANADA'; Bottom='WAR ON IRAN' },
  @{ Src='memes\scene-battleship.jpg'; Dst='memes\meme-battleship.jpg'; Top='OPEN THE STRAIT'; Bottom='OR ELSE' },
  @{ Src='memes\scene-maple.jpg'; Dst='memes\meme-maple.jpg'; Top='SORRY CANADA'; Bottom="SYRUP AIN'T FREE" },
  @{ Src='memes\scene-panda-deal.jpg'; Dst='memes\meme-panda-deal.jpg'; Top='NO DEAL, CHINA?'; Bottom='COOL. TARIFFS.' },
  @{ Src='memes\scene-final-boss.jpg'; Dst='memes\meme-final-boss.jpg'; Top='CANADA. CHINA. IRAN.'; Bottom='FINAL BOSS FIGHT' },
  @{ Src='memes\scene-press.jpg'; Dst='memes\meme-press.jpg'; Top="DON'T TARIFF CANADA?"; Bottom='SO I TARIFFED CANADA' },
  @{ Src='memes\scene-binoculars.jpg'; Dst='memes\meme-binoculars.jpg'; Top='MINES IN HORMUZ?'; Bottom='NOT ANYMORE' },
  @{ Src='memes\scene-oil.jpg'; Dst='memes\meme-oil.jpg'; Top="OIL'S UP"; Bottom="AMERICA'S BACK" },
  @{ Src='memes\scene-grocery.jpg'; Dst='memes\meme-grocery.jpg'; Top='CANADIAN IMPORTS'; Bottom='NOW WITH 50% TARIFF' },
  @{ Src='memes\scene-eagle-map.jpg'; Dst='memes\meme-eagle-map.jpg'; Top='THE EAGLE AND ME'; Bottom='TOOK THE STRAIT' },
  @{ Src='memes\scene-two-front.jpg'; Dst='memes\meme-two-front.jpg'; Top='TARIFFS AT 9'; Bottom='HORMUZ AT 10' },
  @{ Src='memes\scene-moose.jpg'; Dst='memes\meme-moose.jpg'; Top='NICE ANTLERS'; Bottom='STILL 50%' }
)

foreach ($j in $jobs) {
  Add-MemeCaption -Src $j.Src -Dst $j.Dst -Top $j.Top -Bottom $j.Bottom
}

Write-Host "DONE $($jobs.Count) memes"
