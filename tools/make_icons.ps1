# 生成番茄钟 App 的全部 watchOS 图标 PNG（黑底 + Ultra 橙进度环）
# 使用 Windows 自带的 .NET System.Drawing，无需安装任何软件。
# 用法（在项目根目录）：powershell -NoProfile -ExecutionPolicy Bypass -File tools\make_icons.ps1

Add-Type -AssemblyName System.Drawing

$outDir = Join-Path $PSScriptRoot "..\PomodoroWatch\Assets.xcassets\AppIcon.appiconset"
$outDir = [System.IO.Path]::GetFullPath($outDir)
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$icons = @(
  @("icon-24@2x.png", 48),   @("icon-27.5@2x.png", 55),  @("icon-29@2x.png", 58),
  @("icon-29@3x.png", 87),   @("icon-40@2x.png", 80),    @("icon-44@2x.png", 88),
  @("icon-46@2x.png", 92),   @("icon-50@2x.png", 100),   @("icon-51@2x.png", 102),
  @("icon-54@2x.png", 108),  @("icon-86@2x.png", 172),   @("icon-98@2x.png", 196),
  @("icon-108@2x.png", 216), @("icon-117@2x.png", 234),  @("icon-129@2x.png", 258),
  @("icon-1024.png", 1024)
)

$orange = [System.Drawing.Color]::FromArgb(255, 255, 96, 0)  # #FF6000

foreach ($icon in $icons) {
  $name = $icon[0]
  $size = [int]$icon[1]
  $ss = if ($size -lt 256) { 4 } else { 2 }  # 超采样倍数

  # 1. 高分辨率绘制
  $S = $size * $ss
  $bmp = New-Object System.Drawing.Bitmap($S, $S)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Black)

  $pen = New-Object System.Drawing.Pen($orange, [single]($S * 0.055))
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $r = [single]($S * 0.40)
  $rect = New-Object System.Drawing.RectangleF(([single]$S / 2 - $r), ([single]$S / 2 - $r), (2 * $r), (2 * $r))
  $g.DrawArc($pen, $rect, -90, 270)  # 从顶部顺时针 270 度，留 1/4 缺口（进度环造型）
  $pen.Dispose()
  $g.Dispose()

  # 2. 高质量缩小到目标尺寸
  $final = New-Object System.Drawing.Bitmap($size, $size)
  $fg = [System.Drawing.Graphics]::FromImage($final)
  $fg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $fg.DrawImage($bmp, 0, 0, $size, $size)
  $fg.Dispose()
  $bmp.Dispose()

  # 3. 保存 PNG
  $path = Join-Path $outDir $name
  $final.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $final.Dispose()
  Write-Output "OK  $name  (${size}x${size})"
}
Write-Output "共生成 $($icons.Count) 个图标 -> $outDir"
