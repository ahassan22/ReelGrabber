# ReelGrabber 2.0 - audio, video and transcripts from Facebook, YouTube, TikTok, Instagram and more
# FieldBuilt · by Ahmed Hassan · https://github.com/ahassan22/ReelGrabber
# Needs yt-dlp, ffmpeg and Deno (Install.bat installs them).
param([string]$Url = "")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
. (Join-Path $PSScriptRoot 'ReelGrabber.Core.ps1')

# Reload PATH so tools installed after the browser or Explorer started are found
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
            (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links')

$AppVersion   = "2.0.3"
$AppName      = "ReelGrabber"
$ProfileUrl   = "https://github.com/ahassan22/ReelGrabber"
$LinkedInUrl  = "https://www.linkedin.com/in/ahmedhassan30/"
$ContactEmail = "ahassanccna@gmail.com"
$SettingsDir  = Join-Path $env:APPDATA $AppName
$SettingsFile = Join-Path $SettingsDir "settings.json"
$WorkRoot     = Join-Path $env:TEMP $AppName
$AssetsDir    = Join-Path $PSScriptRoot 'assets'
$IconPath     = Join-Path $AssetsDir 'fieldbuilt.ico'
$LogoPath     = Join-Path $AssetsDir 'icon-128.png'
$DocLogoPath  = Join-Path $AssetsDir 'icon-256.png'
$BrandTeal    = [System.Drawing.Color]::FromArgb(15, 94, 89)
$BrandAmber   = [System.Drawing.Color]::FromArgb(217, 142, 4)
$BrandGray    = [System.Drawing.Color]::FromArgb(74, 90, 87)

# ---------- text in both languages ----------
$T = @{
  en = @{
    title = "ReelGrabber · Audio, video and transcripts"; url = "Video link:"; paste = "Paste"
    mode = "What to download"; video = "Video"; audio = "Audio"; text = "Transcript only"
    quality = "Quality:"; format = "Format:"; formats = "Show available qualities"
    bitrate = "Bitrate:"; speed = "Speed:"; effect = "Effect:"; preview = "Preview 10 s"
    lang = "Language:"; textnote = "Downloads the captions that already exist on the video, as a Word file (.docx) and an SRT file. It does not listen to the audio."
    folder = "Save to:"; browse = "Browse..."; download = "Download"; open = "Open folder"; about = "About"
    ready = "Ready"; starting = "Starting..."; downloading = "Downloading... {0}%"; processing = "Applying speed and effect..."
    done = "Done"; failed = "Failed - see the log below"; previewready = "Playing the preview"
    notext = "No transcript is available for this video."; textdone = "Transcript saved ({0} file(s))"
    formatsdone = "Available qualities are listed below"
    badurl = "The link is not valid. Copy the full video link starting with https."
    nofolder = "The save folder does not exist. Choose another folder."
    notool = "{0} is not installed. Run Install.bat again."
    busy = "A download is already running."
    q_best = "Best available"; l_ar = "Arabic"; l_en = "English"; l_both = "Arabic and English"
    fx_none = "None"; fx_normalize = "Even out loudness"; fx_denoise = "Reduce background noise"; fx_clarity = "Clearer speech"
    fx_silence = "Remove silences"; fx_boost = "Make louder"; fx_echo = "Echo"; fx_hall = "Hall"; fx_bass = "Bass boost"
    fx_phone = "Radio / phone"; fx_pitchdown = "Deeper voice"; fx_pitchup = "Higher voice"; fx_fade = "Fade in and out"
    m_source = "Source"; m_link = "Link"; m_lang = "Language"; m_date = "Downloaded"; m_duration = "Length"; m_heading = "Transcript"
    close = "Close"
  }
  ar = @{
    title = "تحميل الصوت والفيديو والنص · ReelGrabber"; url = "رابط الفيديو:"; paste = "لصق"
    mode = "ماذا تريد أن تحمّل"; video = "فيديو"; audio = "صوت"; text = "النص فقط"
    quality = "الجودة:"; format = "الصيغة:"; formats = "عرض الجودات المتاحة"
    bitrate = "معدل البت:"; speed = "السرعة:"; effect = "المؤثر:"; preview = "معاينة 10 ثوانٍ"
    lang = "اللغة:"; textnote = "يحمّل الترجمة الموجودة على الفيديو أصلًا كملف Word (.docx) وملف SRT، ولا يستمع إلى الصوت."
    folder = "مكان الحفظ:"; browse = "اختيار..."; download = "تحميل"; open = "فتح المجلد"; about = "عن البرنامج"
    ready = "جاهز"; starting = "جارٍ البدء..."; downloading = "جارٍ التحميل... {0}%"; processing = "جارٍ تطبيق السرعة والمؤثر..."
    done = "تم بنجاح"; failed = "فشل - راجع السجل بالأسفل"; previewready = "يتم تشغيل المعاينة"
    notext = "لا يوجد نص متاح لهذا الفيديو."; textdone = "تم حفظ النص ({0} ملف)"
    formatsdone = "الجودات المتاحة معروضة بالأسفل"
    badurl = "الرابط غير صحيح. انسخ رابط الفيديو كاملًا ويبدأ بـ https"
    nofolder = "مكان الحفظ غير موجود. اختر مجلدًا آخر."
    notool = "برنامج {0} غير مثبت. شغّل Install.bat مرة أخرى."
    busy = "يوجد تحميل قيد التشغيل بالفعل."
    q_best = "أفضل جودة متاحة"; l_ar = "العربية"; l_en = "الإنجليزية"; l_both = "العربية والإنجليزية"
    fx_none = "بدون"; fx_normalize = "توحيد مستوى الصوت"; fx_denoise = "إزالة الضوضاء"; fx_clarity = "وضوح الكلام"
    fx_silence = "حذف فترات السكوت"; fx_boost = "تكبير الصوت"; fx_echo = "صدى"; fx_hall = "قاعة"; fx_bass = "تقوية البيز"
    fx_phone = "صوت راديو / تليفون"; fx_pitchdown = "صوت أتخن"; fx_pitchup = "صوت أرفع"; fx_fade = "دخول وخروج ناعم"
    m_source = "المصدر"; m_link = "الرابط"; m_lang = "اللغة"; m_date = "تاريخ التحميل"; m_duration = "المدة"; m_heading = "النص"
    close = "إغلاق"
  }
}
function S([string]$key) { return $T[$script:lang][$key] }

$QualityKeys = @('best', '1080', '720', '480')
$VideoFmtKeys = @('mp4', 'mkv')
$AudioFmtKeys = @('mp3', 'm4a', 'wav', 'flac', 'opus')
$BitrateKeys = @(128, 192, 320)
$LangKeys = @('ar', 'en', 'both')
$EffectKeys = @($script:EffectChains.Keys)

# ---------- settings ----------
$settings = @{ folder = (Join-Path ([Environment]::GetFolderPath('UserProfile')) "Downloads"); lang = "en"; mode = "audio"
               quality = 0; vfmt = 0; afmt = 0; bitrate = 1; speed = 20; effect = 0; tlang = 2 }
if (Test-Path $SettingsFile) {
    try {
        $saved = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($k in @($settings.Keys)) { if ($null -ne $saved.$k) { $settings[$k] = $saved.$k } }
        if (-not (Test-Path $settings.folder)) { $settings.folder = (Join-Path ([Environment]::GetFolderPath('UserProfile')) "Downloads") }
    } catch { }
}
$script:lang = if ($settings.lang -eq 'ar') { 'ar' } else { 'en' }

# ---------- link coming from the browser extension ----------
$startMode = $settings.mode
if ($Url -match '^reelgrab:') {
    $payload = $Url.Substring(9).TrimStart('/').TrimStart('?')
    $Url = ""
    foreach ($pair in ($payload -split '&')) {
        $kv = $pair -split '=', 2
        if ($kv.Count -eq 2) {
            $val = [System.Uri]::UnescapeDataString($kv[1])
            if ($kv[0] -eq 'mode' -and $val -in @('audio', 'video', 'transcript')) { $startMode = $val }
            elseif ($kv[0] -eq 'url') { $Url = $val }
        }
    }
}

# ---------- one window only ----------
# If ReelGrabber is already open, hand the link to that window and quit.
$Handoff = Join-Path $SettingsDir 'incoming.txt'
$isFirst = $false
$script:mutex = New-Object System.Threading.Mutex($true, 'Local\FieldBuilt.ReelGrabber', [ref]$isFirst)
if (-not $isFirst) {
    try {
        if (-not (Test-Path $SettingsDir)) { New-Item -ItemType Directory -Path $SettingsDir | Out-Null }
        [System.IO.File]::WriteAllText($Handoff, ($startMode + "`n" + $Url), (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
    exit
}
Remove-Item -LiteralPath $Handoff -Force -ErrorAction SilentlyContinue

# ---------- window ----------
$font = New-Object System.Drawing.Font("Segoe UI", 10)
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(676, 712)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = $font
if (Test-Path $IconPath) { try { $form.Icon = New-Object System.Drawing.Icon($IconPath) } catch { } }

function New-Ctl([string]$type, [int]$x, [int]$y, [int]$w, [int]$h) {
    $c = New-Object "System.Windows.Forms.$type"
    $c.Location = New-Object System.Drawing.Point($x, $y)
    if ($w -gt 0) { $c.Size = New-Object System.Drawing.Size($w, $h) } else { $c.AutoSize = $true }
    return $c
}
function New-Combo([int]$x, [int]$y, [int]$w) { $c = New-Ctl 'ComboBox' $x $y $w 28; $c.DropDownStyle = 'DropDownList'; return $c }

# language switch (two joined buttons, the active one filled)
$btnEn = New-Ctl 'Button' 560 8 44 28; $btnEn.Text = "EN"; $btnEn.FlatStyle = 'Flat'
$btnAr = New-Ctl 'Button' 604 8 44 28; $btnAr.Text = "ع";  $btnAr.FlatStyle = 'Flat'

$lblUrl = New-Ctl 'Label' 16 16 0 0
$txtUrl = New-Ctl 'TextBox' 16 42 520 28; $txtUrl.RightToLeft = 'No'; $txtUrl.Text = $Url
$btnPaste = New-Ctl 'Button' 544 40 104 30

$grpMode = New-Ctl 'GroupBox' 16 80 632 58
$rbVideo = New-Ctl 'RadioButton' 16 24 0 0
$rbAudio = New-Ctl 'RadioButton' 220 24 0 0
$rbText  = New-Ctl 'RadioButton' 424 24 0 0
$grpMode.Controls.AddRange(@($rbVideo, $rbAudio, $rbText))

# video panel
$pnlVideo = New-Ctl 'Panel' 16 148 632 150
$lblQ = New-Ctl 'Label' 0 8 0 0;    $cmbQ = New-Combo 110 4 210
$lblVF = New-Ctl 'Label' 340 8 0 0; $cmbVF = New-Combo 430 4 110
$btnFormats = New-Ctl 'Button' 0 46 260 32
$pnlVideo.Controls.AddRange(@($lblQ, $cmbQ, $lblVF, $cmbVF, $btnFormats))

# audio panel
$pnlAudio = New-Ctl 'Panel' 16 148 632 150
$lblAF = New-Ctl 'Label' 0 8 0 0;   $cmbAF = New-Combo 110 4 120
$lblBR = New-Ctl 'Label' 250 8 0 0; $cmbBR = New-Combo 350 4 120
$lblSpeed = New-Ctl 'Label' 0 52 0 0
$trkSpeed = New-Ctl 'TrackBar' 104 44 400 45
$trkSpeed.Minimum = 10; $trkSpeed.Maximum = 40; $trkSpeed.TickFrequency = 5; $trkSpeed.SmallChange = 1; $trkSpeed.LargeChange = 5
$lblSpeedVal = New-Ctl 'Label' 512 52 0 0; $lblSpeedVal.RightToLeft = 'No'
$lblFx = New-Ctl 'Label' 0 104 0 0; $cmbFx = New-Combo 110 100 290
$btnPreview = New-Ctl 'Button' 420 98 200 32
$pnlAudio.Controls.AddRange(@($lblAF, $cmbAF, $lblBR, $cmbBR, $lblSpeed, $trkSpeed, $lblSpeedVal, $lblFx, $cmbFx, $btnPreview))

# transcript panel
$pnlText = New-Ctl 'Panel' 16 148 632 150
$lblTL = New-Ctl 'Label' 0 8 0 0; $cmbTL = New-Combo 110 4 240
$lblTNote = New-Ctl 'Label' 0 48 620 60; $lblTNote.ForeColor = $BrandGray
$pnlText.Controls.AddRange(@($lblTL, $cmbTL, $lblTNote))

$lblFolder = New-Ctl 'Label' 16 306 0 0
$txtFolder = New-Ctl 'TextBox' 16 332 520 28; $txtFolder.RightToLeft = 'No'; $txtFolder.ReadOnly = $true; $txtFolder.Text = $settings.folder
$btnBrowse = New-Ctl 'Button' 544 330 104 30

$btnDownload = New-Ctl 'Button' 16 374 150 40
$btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnDownload.BackColor = $BrandTeal; $btnDownload.ForeColor = [System.Drawing.Color]::White; $btnDownload.FlatStyle = 'Flat'
$btnOpen = New-Ctl 'Button' 176 374 130 40
$lblStatus = New-Ctl 'Label' 316 384 332 24

$txtLog = New-Ctl 'TextBox' 16 424 632 196
$txtLog.Multiline = $true; $txtLog.ScrollBars = 'Vertical'; $txtLog.ReadOnly = $true; $txtLog.RightToLeft = 'No'
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)

$lblBrand = New-Ctl 'Label' 16 632 0 0
$lblBrand.Text = "FieldBuilt · by Ahmed Hassan"; $lblBrand.RightToLeft = 'No'
$lblBrand.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $lblBrand.ForeColor = $BrandTeal
$btnAbout = New-Ctl 'Button' 528 626 120 30

$form.Controls.AddRange(@($btnEn, $btnAr, $lblUrl, $txtUrl, $btnPaste, $grpMode, $pnlVideo, $pnlAudio, $pnlText,
                          $lblFolder, $txtFolder, $btnBrowse, $btnDownload, $btnOpen, $lblStatus, $txtLog, $lblBrand, $btnAbout))

# ---------- language ----------
function Fill-Combo($combo, [string[]]$items, [int]$selected) {
    $combo.Items.Clear()
    foreach ($i in $items) { [void]$combo.Items.Add($i) }
    if ($selected -ge 0 -and $selected -lt $items.Count) { $combo.SelectedIndex = $selected } else { $combo.SelectedIndex = 0 }
}

function Update-Speed {
    $v = $trkSpeed.Value * 0.05
    $lblSpeedVal.Text = $v.ToString('0.00', [System.Globalization.CultureInfo]::InvariantCulture) + 'x'
}

function Set-Language([string]$lang) {
    $script:lang = $lang
    $rtl = ($lang -eq 'ar')
    $form.SuspendLayout()
    $form.RightToLeft = $(if ($rtl) { 'Yes' } else { 'No' })
    $form.RightToLeftLayout = $rtl
    $form.Text = S 'title'
    $lblUrl.Text = S 'url'; $btnPaste.Text = S 'paste'
    $grpMode.Text = S 'mode'; $rbVideo.Text = S 'video'; $rbAudio.Text = S 'audio'; $rbText.Text = S 'text'
    $lblQ.Text = S 'quality'; $lblVF.Text = S 'format'; $btnFormats.Text = S 'formats'
    $lblAF.Text = S 'format'; $lblBR.Text = S 'bitrate'; $lblSpeed.Text = S 'speed'; $lblFx.Text = S 'effect'; $btnPreview.Text = S 'preview'
    $lblTL.Text = S 'lang'; $lblTNote.Text = S 'textnote'
    $lblFolder.Text = S 'folder'; $btnBrowse.Text = S 'browse'; $btnDownload.Text = S 'download'; $btnOpen.Text = S 'open'; $btnAbout.Text = S 'about'
    if (-not $script:job) { $lblStatus.Text = S 'ready' }

    Fill-Combo $cmbQ @((S 'q_best'), '1080p (Full HD)', '720p', '480p') $(if ($cmbQ.Items.Count) { $cmbQ.SelectedIndex } else { [int]$settings.quality })
    Fill-Combo $cmbVF @('MP4', 'MKV') $(if ($cmbVF.Items.Count) { $cmbVF.SelectedIndex } else { [int]$settings.vfmt })
    Fill-Combo $cmbAF @('MP3', 'M4A', 'WAV', 'FLAC', 'OPUS') $(if ($cmbAF.Items.Count) { $cmbAF.SelectedIndex } else { [int]$settings.afmt })
    Fill-Combo $cmbBR @('128 kbps', '192 kbps', '320 kbps') $(if ($cmbBR.Items.Count) { $cmbBR.SelectedIndex } else { [int]$settings.bitrate })
    Fill-Combo $cmbFx @($EffectKeys | ForEach-Object { S ("fx_" + $_) }) $(if ($cmbFx.Items.Count) { $cmbFx.SelectedIndex } else { [int]$settings.effect })
    Fill-Combo $cmbTL @((S 'l_ar'), (S 'l_en'), (S 'l_both')) $(if ($cmbTL.Items.Count) { $cmbTL.SelectedIndex } else { [int]$settings.tlang })

    foreach ($b in @($btnEn, $btnAr)) { $b.BackColor = [System.Drawing.Color]::White; $b.ForeColor = $BrandTeal; $b.FlatAppearance.BorderColor = $BrandTeal }
    $active = if ($rtl) { $btnAr } else { $btnEn }
    $active.BackColor = $BrandTeal; $active.ForeColor = [System.Drawing.Color]::White
    $form.ResumeLayout()
}

function Update-Panels {
    $pnlVideo.Visible = $rbVideo.Checked
    $pnlAudio.Visible = $rbAudio.Checked
    $pnlText.Visible = $rbText.Checked
}

function Save-Settings {
    try {
        if (-not (Test-Path $SettingsDir)) { New-Item -ItemType Directory -Path $SettingsDir | Out-Null }
        $mode = if ($rbVideo.Checked) { 'video' } elseif ($rbText.Checked) { 'transcript' } else { 'audio' }
        @{ folder = $txtFolder.Text; lang = $script:lang; mode = $mode; quality = $cmbQ.SelectedIndex; vfmt = $cmbVF.SelectedIndex
           afmt = $cmbAF.SelectedIndex; bitrate = $cmbBR.SelectedIndex; speed = $trkSpeed.Value; effect = $cmbFx.SelectedIndex; tlang = $cmbTL.SelectedIndex } |
            ConvertTo-Json | Set-Content -Path $SettingsFile -Encoding UTF8
    } catch { }
}

# ---------- jobs ----------
$script:job = $null
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

function Get-Tool([string]$name) {
    $c = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $c) { [System.Windows.Forms.MessageBox]::Show(((S 'notool') -f $name), $AppName) | Out-Null; return $null }
    return $c.Source
}

function Start-Stage([string]$exe, [string]$argLine) {
    $script:job.out = Join-Path $script:job.dir ("out" + $script:job.stage + ".txt")
    $script:job.err = Join-Path $script:job.dir ("err" + $script:job.stage + ".txt")
    $p = Start-Process -FilePath $exe -ArgumentList $argLine -WindowStyle Hidden -WorkingDirectory $script:job.dir `
        -RedirectStandardOutput $script:job.out -RedirectStandardError $script:job.err -PassThru
    $null = $p.Handle
    $script:job.proc = $p
}

function Set-Status([string]$text, $color) {
    $lblStatus.Text = $text
    $lblStatus.ForeColor = $(if ($color) { $color } else { [System.Drawing.SystemColors]::ControlText })
}

function Finish-Job([bool]$ok, [string]$message) {
    $timer.Stop()
    $btnDownload.Enabled = $true; $btnPreview.Enabled = $true; $btnFormats.Enabled = $true
    if ($ok) { Set-Status $message ([System.Drawing.Color]::DarkGreen) } else { Set-Status $message ([System.Drawing.Color]::DarkRed) }
    $keep = ($script:job.kind -eq 'preview')
    $dir = $script:job.dir
    $script:job = $null
    if (-not $keep) { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

function New-Job([string]$kind) {
    if ($script:job) { [System.Windows.Forms.MessageBox]::Show((S 'busy'), $AppName) | Out-Null; return $false }
    $u = $txtUrl.Text.Trim()
    if (-not (Test-VideoUrl $u)) { [System.Windows.Forms.MessageBox]::Show((S 'badurl'), $AppName) | Out-Null; return $false }
    if ($kind -ne 'formats' -and -not (Test-Path $txtFolder.Text)) { [System.Windows.Forms.MessageBox]::Show((S 'nofolder'), $AppName) | Out-Null; return $false }
    $yt = Get-Tool 'yt-dlp'; if (-not $yt) { return $false }
    $ff = $null
    if ($kind -ne 'formats') { $ff = Get-Tool 'ffmpeg'; if (-not $ff) { return $false } }
    $dir = Join-Path $WorkRoot ([guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $script:job = @{ kind = $kind; stage = 1; dir = $dir; url = $u; yt = $yt; ff = $ff; folder = $txtFolder.Text; proc = $null; final = $null }
    Save-Settings
    $txtLog.Text = ""
    Set-Status (S 'starting') $null
    $btnDownload.Enabled = $false; $btnPreview.Enabled = $false; $btnFormats.Enabled = $false
    return $true
}

function Find-Downloaded([string]$dir) {
    Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Extension -notin @('.txt', '.json', '.part', '.ytdl', '.srt', '.vtt') } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Start-AudioStage2 {
    $src = Find-Downloaded $script:job.dir
    if (-not $src) { Finish-Job $false (S 'failed'); return }
    $fmt = $AudioFmtKeys[$cmbAF.SelectedIndex]
    $kbps = $BitrateKeys[$cmbBR.SelectedIndex]
    $effect = $EffectKeys[$cmbFx.SelectedIndex]
    $speed = $trkSpeed.Value * 0.05
    $filter = Get-AudioFilter $effect $speed
    if ($script:job.kind -eq 'preview') {
        $out = Join-Path $script:job.dir ("preview." + $fmt)
    } else {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($src.Name)
        $out = Join-Path $script:job.folder ($base + (Get-AudioSuffix $effect $speed) + "." + $fmt)
    }
    $script:job.final = $out
    $script:job.stage = 2
    Set-Status (S 'processing') $null
    Start-Stage $script:job.ff (Get-FfmpegArgs $src.FullName $out $fmt $kbps $filter ($script:job.kind -eq 'preview'))
}

function Complete-Transcript {
    $srts = @(Get-ChildItem -LiteralPath $script:job.dir -Filter *.srt -File)
    if ($srts.Count -eq 0) {
        Finish-Job $false (S 'notext')
        [System.Windows.Forms.MessageBox]::Show((S 'notext'), $AppName) | Out-Null
        return
    }
    $info = $null
    $infoFile = Get-ChildItem -LiteralPath $script:job.dir -Filter *.info.json -File | Select-Object -First 1
    if ($infoFile) { try { $info = [System.IO.File]::ReadAllText($infoFile.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json } catch { } }
    $title = if ($info -and $info.title) { [string]$info.title } else { [System.IO.Path]::GetFileNameWithoutExtension($srts[0].Name) }
    $saved = 0
    foreach ($s in $srts) {
        $isAr = ($s.Name -match '\.ar(-[^.]*)?\.srt$')
        $lines = Read-SrtLines $s.FullName
        if ($lines.Count -eq 0) { continue }
        $paras = ConvertTo-Paragraphs $lines 70
        $docLang = if ($isAr) { 'ar' } else { 'en' }
        $L = $T[$docLang]
        $meta = [ordered]@{}
        $meta[$L.m_source] = if ($info -and $info.extractor_key) { [string]$info.extractor_key } else { '-' }
        $meta[$L.m_link] = if ($info -and $info.webpage_url) { [string]$info.webpage_url } else { $script:job.url }
        if ($info -and $info.duration_string) { $meta[$L.m_duration] = [string]$info.duration_string }
        $meta[$L.m_lang] = if ($isAr) { $L.l_ar } else { $L.l_en }
        $meta[$L.m_date] = (Get-Date).ToString('yyyy-MM-dd')
        $base = [System.IO.Path]::GetFileNameWithoutExtension($s.Name)   # "title [id].ar"
        $docx = Join-Path $script:job.folder ($base + ".docx")
        try {
            New-TranscriptDocx $docx $title $meta $L.m_heading $paras $isAr $DocLogoPath
            Copy-Item -LiteralPath $s.FullName -Destination (Join-Path $script:job.folder $s.Name) -Force
            $saved++
        } catch { $txtLog.AppendText("`r`n" + $_.Exception.Message) }
    }
    if ($saved -gt 0) { Finish-Job $true ((S 'textdone') -f $saved) }
    else { Finish-Job $false (S 'notext'); [System.Windows.Forms.MessageBox]::Show((S 'notext'), $AppName) | Out-Null }
}

$timer.Add_Tick({
    if (-not $script:job) { $timer.Stop(); return }
    $out = Read-Shared $script:job.out
    $err = Read-Shared $script:job.err
    $lines = (($out + "`r`n" + $err).Trim()) -split "`r?`n" | Where-Object { $_ -ne "" }
    if ($script:job.kind -ne 'formats' -and $lines.Count -gt 40) { $lines = $lines[-40..-1] }
    $txtLog.Text = ($lines -join "`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    if ($script:job.stage -eq 1) {
        $pct = [regex]::Matches($out, '\[download\]\s+(\d+(\.\d+)?)%')
        if ($pct.Count -gt 0) { Set-Status ((S 'downloading') -f $pct[$pct.Count - 1].Groups[1].Value) $null }
    }
    $p = $script:job.proc
    if (-not $p -or -not $p.HasExited) { return }
    $ok = ($p.ExitCode -eq 0)
    switch ($script:job.kind) {
        'formats' { if ($ok) { Finish-Job $true (S 'formatsdone') } else { Finish-Job $false (S 'failed') } }
        'video'   { if ($ok) { Finish-Job $true (S 'done') } else { Finish-Job $false (S 'failed') } }
        'transcript' { Complete-Transcript }
        default {
            if ($script:job.stage -eq 1) {
                if ($ok) { Start-AudioStage2 } else { Finish-Job $false (S 'failed') }
            } else {
                $final = $script:job.final
                $isPreview = ($script:job.kind -eq 'preview')
                if ($ok -and (Test-Path -LiteralPath $final)) {
                    if ($isPreview) { Finish-Job $true (S 'previewready'); Start-Process -FilePath $final }
                    else { Finish-Job $true (S 'done') }
                } else { Finish-Job $false (S 'failed') }
            }
        }
    }
})

function Start-Job([string]$kind) {
    if (-not (New-Job $kind)) { return }
    switch ($kind) {
        'formats'    { Start-Stage $script:job.yt (Get-FormatsArgs $script:job.url) }
        'video'      { Start-Stage $script:job.yt (Get-VideoArgs $script:job.folder $script:job.url $QualityKeys[$cmbQ.SelectedIndex] $VideoFmtKeys[$cmbVF.SelectedIndex]) }
        'transcript' { Start-Stage $script:job.yt (Get-TranscriptArgs $script:job.dir $script:job.url $LangKeys[$cmbTL.SelectedIndex]) }
        default      { Start-Stage $script:job.yt (Get-AudioDownloadArgs $script:job.dir $script:job.url ($kind -eq 'preview')) }
    }
    $timer.Start()
}

# ---------- about ----------
function Show-About {
    $about = New-Object System.Windows.Forms.Form
    $about.Text = S 'about'
    $about.Size = New-Object System.Drawing.Size(380, 470)
    $about.StartPosition = "CenterParent"; $about.FormBorderStyle = "FixedDialog"
    $about.MaximizeBox = $false; $about.MinimizeBox = $false
    $about.BackColor = [System.Drawing.Color]::White; $about.Font = $font
    if ($form.Icon) { $about.Icon = $form.Icon }
    $y = 18
    if (Test-Path $LogoPath) {
        $pic = New-Object System.Windows.Forms.PictureBox
        $pic.Image = [System.Drawing.Image]::FromFile($LogoPath); $pic.SizeMode = "Zoom"
        $pic.Size = New-Object System.Drawing.Size(96, 96); $pic.Location = New-Object System.Drawing.Point(134, $y)
        $about.Controls.Add($pic); $y += 104
    }
    $rows = @(
        @(("FieldBuilt"), 18, $true, $BrandTeal),
        @(("فيلد بِلت"), 12, $true, $BrandTeal),
        @(("Field-tested. Research-backed."), 10, $false, $BrandGray),
        @(("من البحث إلى الميدان"), 10, $false, $BrandGray),
        @(("ReelGrabber $AppVersion · by Ahmed Hassan"), 10, $false, [System.Drawing.Color]::Black)
    )
    foreach ($r in $rows) {
        $style = if ($r[2]) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $r[0]; $lbl.Font = New-Object System.Drawing.Font("Segoe UI", $r[1], $style); $lbl.ForeColor = $r[3]
        $lbl.TextAlign = "MiddleCenter"; $lbl.Size = New-Object System.Drawing.Size(344, ([int]$lbl.Font.GetHeight() + 8))
        $lbl.Location = New-Object System.Drawing.Point(10, $y); $about.Controls.Add($lbl); $y += $lbl.Height + 2
    }
    $y += 4
    foreach ($c in @(
        @($ContactEmail, ("mailto:" + $ContactEmail)),
        @("github.com/ahassan22/ReelGrabber", $ProfileUrl),
        @("linkedin.com/in/ahmedhassan30", $LinkedInUrl))) {
        $link = New-Object System.Windows.Forms.LinkLabel
        $link.Text = $c[0]; $link.Tag = $c[1]; $link.TextAlign = "MiddleCenter"; $link.LinkColor = $BrandTeal
        $link.Size = New-Object System.Drawing.Size(344, 24); $link.Location = New-Object System.Drawing.Point(10, $y)
        $link.Add_LinkClicked({ param($s, $e) try { Start-Process $s.Tag } catch { } }); $about.Controls.Add($link)
        $y += 26
    }
    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = S 'close'; $ok.Size = New-Object System.Drawing.Size(100, 32); $ok.Location = New-Object System.Drawing.Point(132, ($y + 12))
    $ok.Add_Click({ $about.Close() }); $about.Controls.Add($ok); $about.AcceptButton = $ok
    [void]$about.ShowDialog($form)
}

# ---------- events ----------
$btnEn.Add_Click({ Set-Language 'en'; Save-Settings })
$btnAr.Add_Click({ Set-Language 'ar'; Save-Settings })
$btnPaste.Add_Click({ $clip = [System.Windows.Forms.Clipboard]::GetText(); if ($clip) { $txtUrl.Text = $clip.Trim() } })
$rbVideo.Add_CheckedChanged({ Update-Panels }); $rbAudio.Add_CheckedChanged({ Update-Panels }); $rbText.Add_CheckedChanged({ Update-Panels })
$trkSpeed.Add_ValueChanged({ Update-Speed })
$cmbAF.Add_SelectedIndexChanged({ $cmbBR.Enabled = ($AudioFmtKeys[$cmbAF.SelectedIndex] -notin @('wav', 'flac')) })
$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.SelectedPath = $txtFolder.Text
    if ($dlg.ShowDialog() -eq "OK") { $txtFolder.Text = $dlg.SelectedPath; Save-Settings }
})
$btnOpen.Add_Click({ if (Test-Path $txtFolder.Text) { Start-Process explorer.exe -ArgumentList "`"$($txtFolder.Text)`"" } })
$btnFormats.Add_Click({ Start-Job 'formats' })
$btnPreview.Add_Click({ Start-Job 'preview' })
$btnDownload.Add_Click({
    if ($rbVideo.Checked) { Start-Job 'video' } elseif ($rbText.Checked) { Start-Job 'transcript' } else { Start-Job 'audio' }
})
$btnAbout.Add_Click({ Show-About })
$form.Add_FormClosing({ Save-Settings })

# ---------- start ----------
$trkSpeed.Value = [Math]::Min(40, [Math]::Max(10, [int]$settings.speed))
Update-Speed
Set-Language $script:lang
switch ($startMode) { 'video' { $rbVideo.Checked = $true } 'transcript' { $rbText.Checked = $true } default { $rbAudio.Checked = $true } }
Update-Panels
$cmbBR.Enabled = ($AudioFmtKeys[$cmbAF.SelectedIndex] -notin @('wav', 'flac'))

# Watch for links sent by a second launch (browser extension or shortcut) and bring this window to the front
$watch = New-Object System.Windows.Forms.Timer
$watch.Interval = 700
$watch.Add_Tick({
    if (-not (Test-Path -LiteralPath $Handoff)) { return }
    try {
        $content = [System.IO.File]::ReadAllText($Handoff, [System.Text.Encoding]::UTF8)
        Remove-Item -LiteralPath $Handoff -Force
    } catch { return }
    $parts = $content -split "`r?`n", 2
    $m = $parts[0].Trim()
    $u = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "" }
    if ($u) {
        $txtUrl.Text = $u
        switch ($m) { 'video' { $rbVideo.Checked = $true } 'transcript' { $rbText.Checked = $true } 'audio' { $rbAudio.Checked = $true } }
    }
    if ($form.WindowState -eq 'Minimized') { $form.WindowState = 'Normal' }
    $form.TopMost = $true; $form.Activate(); $form.TopMost = $false
})
$watch.Start()

# Application.Run keeps the window alive when switching language rebuilds it (ShowDialog would close it)
[System.Windows.Forms.Application]::Run($form)
$watch.Stop()
try { $script:mutex.ReleaseMutex() } catch { }
$script:mutex.Dispose()
