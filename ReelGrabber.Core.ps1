# ReelGrabber core logic (no window code) - FieldBuilt · by Ahmed Hassan
# Dot-sourced by ReelGrabber.ps1. Works on Windows PowerShell 5.1.

function Test-VideoUrl([string]$u) {
    $u = $u.Trim()
    if ($u -match '["\s<>|^]') { return $false }
    $uri = $null
    if (-not [System.Uri]::TryCreate($u, [System.UriKind]::Absolute, [ref]$uri)) { return $false }
    return ($uri.Scheme -eq 'http' -or $uri.Scheme -eq 'https')
}

function Read-Shared([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return "" }
    try {
        $fs = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        $text = $sr.ReadToEnd()
        $sr.Close()
        return $text
    } catch { return "" }
}

function Q([string]$s) { return '"' + $s + '"' }

# ---------- audio ----------
$script:EffectChains = [ordered]@{
    'none'      = ''
    'normalize' = 'loudnorm=I=-16:TP=-1.5:LRA=11'
    'denoise'   = 'afftdn=nf=-25'
    'clarity'   = 'highpass=f=100,lowpass=f=8000,acompressor=threshold=-20dB:ratio=3:attack=5:release=50,loudnorm=I=-16:TP=-1.5:LRA=11'
    'silence'   = 'silenceremove=stop_periods=-1:stop_duration=0.7:stop_threshold=-40dB'
    'boost'     = 'volume=6dB,alimiter=limit=0.95'
    'echo'      = 'aecho=0.8:0.88:60:0.4'
    'hall'      = 'aecho=0.8:0.85:120|240|360:0.35|0.25|0.15'
    'bass'      = 'bass=g=8:f=110,alimiter=limit=0.95'
    'phone'     = 'highpass=f=300,lowpass=f=3400,acompressor=threshold=-18dB:ratio=4'
    'pitchdown' = 'aresample=44100,asetrate=44100*0.89,aresample=44100,atempo=1.1236'
    'pitchup'   = 'aresample=44100,asetrate=44100*1.12,aresample=44100,atempo=0.8929'
    'fade'      = 'afade=t=in:d=3,areverse,afade=t=in:d=3,areverse'
}

function Get-AudioFilter([string]$effect, [double]$speed) {
    $parts = @()
    if ($script:EffectChains.Contains($effect) -and $script:EffectChains[$effect]) { $parts += $script:EffectChains[$effect] }
    if ([math]::Abs($speed - 1.0) -gt 0.001) {
        $parts += ('atempo=' + $speed.ToString('0.00', [System.Globalization.CultureInfo]::InvariantCulture))
    }
    return ($parts -join ',')
}

function Get-AudioCodecArgs([string]$fmt, [int]$kbps) {
    switch ($fmt) {
        'mp3'  { return "-c:a libmp3lame -b:a ${kbps}k" }
        'm4a'  { return "-c:a aac -b:a ${kbps}k" }
        'opus' { return "-c:a libopus -b:a ${kbps}k" }
        'wav'  { return "-c:a pcm_s16le" }
        'flac' { return "-c:a flac" }
        default { return "-c:a libmp3lame -b:a ${kbps}k" }
    }
}

# Stage 1 of audio: download best audio into a work folder (no conversion)
function Get-AudioDownloadArgs([string]$workDir, [string]$url, [bool]$preview) {
    $tmpl = [System.IO.Path]::Combine($workDir, '%(title).80s [%(id)s].%(ext)s')
    $a = "--no-playlist --newline --encoding utf-8 -f " + (Q 'ba/b') + " -o " + (Q $tmpl)
    if ($preview) { $a += " --download-sections " + (Q '*0-15') }
    return "$a " + (Q $url)
}

# Stage 2 of audio: ffmpeg applies speed/effect and encodes
function Get-FfmpegArgs([string]$inFile, [string]$outFile, [string]$fmt, [int]$kbps, [string]$filter, [bool]$preview) {
    $a = "-y -hide_banner -i " + (Q $inFile) + " -vn"
    if ($preview) { $a += " -t 10" }
    if ($filter) { $a += " -af " + (Q $filter) }
    $a += " " + (Get-AudioCodecArgs $fmt $kbps)
    return "$a " + (Q $outFile)
}

function Get-AudioSuffix([string]$effect, [double]$speed) {
    $tags = @()
    if ([math]::Abs($speed - 1.0) -gt 0.001) { $tags += ($speed.ToString('0.00', [System.Globalization.CultureInfo]::InvariantCulture) + 'x') }
    if ($effect -and $effect -ne 'none') { $tags += $effect }
    if ($tags.Count -eq 0) { return "" }
    return " (" + ($tags -join ', ') + ")"
}

# ---------- video ----------
function Get-VideoArgs([string]$folder, [string]$url, [string]$quality, [string]$container) {
    $tmpl = [System.IO.Path]::Combine($folder, '%(title).80s [%(id)s].%(ext)s')
    $sort = @()
    if ($quality -ne 'best') { $sort += "res:$quality" }
    if ($container -eq 'mp4') { $sort += 'ext:mp4:m4a' }
    $a = "--no-playlist --newline --encoding utf-8 -f " + (Q 'bv*+ba/b')
    if ($sort.Count -gt 0) { $a += " -S " + (Q ($sort -join ',')) }
    $a += " --merge-output-format $container -o " + (Q $tmpl)
    return "$a " + (Q $url)
}

function Get-FormatsArgs([string]$url) {
    return "--no-playlist --encoding utf-8 -F " + (Q $url)
}

# ---------- transcript ----------
function Get-TranscriptArgs([string]$workDir, [string]$url, [string]$lang) {
    $langs = switch ($lang) { 'ar' { 'ar.*' } 'en' { 'en.*' } default { 'ar.*,en.*' } }
    $tmpl = [System.IO.Path]::Combine($workDir, '%(title).80s [%(id)s].%(ext)s')
    return "--no-playlist --encoding utf-8 --skip-download --write-info-json --write-subs --write-auto-subs --sub-langs " +
           (Q $langs) + " --sub-format " + (Q 'vtt/srt/best') + " --convert-subs srt -o " + (Q $tmpl) + " " + (Q $url)
}

function Read-SrtLines([string]$path) {
    $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $out = New-Object System.Collections.Generic.List[string]
    $last = ""
    foreach ($line in ($raw -split "`r?`n")) {
        $t = $line.Trim()
        if ($t -eq "") { continue }
        if ($t -match '^\d+$') { continue }
        if ($t -match '-->') { continue }
        $t = [regex]::Replace($t, '<[^>]+>', '')
        $t = [regex]::Replace($t, '\{\\[^}]*\}', '')
        $t = [System.Net.WebUtility]::HtmlDecode($t).Trim()
        if ($t -eq "" -or $t -eq $last) { continue }
        if ($last -and $t.StartsWith($last)) { $out[$out.Count - 1] = $t; $last = $t; continue }
        $out.Add($t); $last = $t
    }
    return ,$out.ToArray()
}

function ConvertTo-Paragraphs([string[]]$lines, [int]$wordsPerParagraph = 70) {
    $paras = New-Object System.Collections.Generic.List[string]
    $buf = New-Object System.Collections.Generic.List[string]
    $count = 0
    foreach ($l in $lines) {
        $buf.Add($l)
        $count += ($l -split '\s+').Count
        if ($count -ge $wordsPerParagraph -and $l -match '[\.\!\?؟،…]$') {
            $paras.Add(($buf -join ' ')); $buf.Clear(); $count = 0
        } elseif ($count -ge ($wordsPerParagraph * 2)) {
            $paras.Add(($buf -join ' ')); $buf.Clear(); $count = 0
        }
    }
    if ($buf.Count -gt 0) { $paras.Add(($buf -join ' ')) }
    return ,$paras.ToArray()
}

# ---------- branded Word file (.docx) without Microsoft Word ----------
function X([string]$s) { return [System.Security.SecurityElement]::Escape($s) }

function New-DocxRun([string]$text, [hashtable]$o) {
    $rpr = '<w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>'
    if ($o.bold) { $rpr += '<w:b/><w:bCs/>' }
    if ($o.color) { $rpr += "<w:color w:val=`"$($o.color)`"/>" }
    if ($o.size) { $rpr += "<w:sz w:val=`"$($o.size)`"/><w:szCs w:val=`"$($o.size)`"/>" }
    if ($o.rtl) { $rpr += '<w:rtl/>' }
    return "<w:r><w:rPr>$rpr</w:rPr><w:t xml:space=`"preserve`">$(X $text)</w:t></w:r>"
}

function New-DocxPara([string]$runs, [hashtable]$o) {
    $ppr = ''
    if ($o.rtl) { $ppr += '<w:bidi/>' }
    if ($o.border) { $ppr += "<w:pBdr><w:bottom w:val=`"single`" w:sz=`"8`" w:space=`"4`" w:color=`"$($o.border)`"/></w:pBdr>" }
    $before = if ($o.before) { $o.before } else { 0 }
    $after = if ($o.after) { $o.after } else { 160 }
    $ppr += "<w:spacing w:before=`"$before`" w:after=`"$after`" w:line=`"320`" w:lineRule=`"auto`"/>"
    if ($o.jc) { $ppr += "<w:jc w:val=`"$($o.jc)`"/>" }
    return "<w:p><w:pPr>$ppr</w:pPr>$runs</w:p>"
}

function New-DocxPicture([string]$rid, [int]$id, [long]$emu, [bool]$watermark) {
    $blip = "<a:blip r:embed=`"$rid`"/>"
    $graphic = "<a:graphic><a:graphicData uri=`"http://schemas.openxmlformats.org/drawingml/2006/picture`"><pic:pic><pic:nvPicPr><pic:cNvPr id=`"$id`" name=`"logo.png`"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill>$blip<a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x=`"0`" y=`"0`"/><a:ext cx=`"$emu`" cy=`"$emu`"/></a:xfrm><a:prstGeom prst=`"rect`"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic>"
    if (-not $watermark) {
        return "<w:r><w:drawing><wp:inline distT=`"0`" distB=`"0`" distL=`"0`" distR=`"0`"><wp:extent cx=`"$emu`" cy=`"$emu`"/><wp:docPr id=`"$id`" name=`"Logo`"/><wp:cNvGraphicFramePr/>$graphic</wp:inline></w:drawing></w:r>"
    }
    return "<w:r><w:drawing><wp:anchor distT=`"0`" distB=`"0`" distL=`"0`" distR=`"0`" simplePos=`"0`" relativeHeight=`"0`" behindDoc=`"1`" locked=`"0`" layoutInCell=`"1`" allowOverlap=`"1`"><wp:simplePos x=`"0`" y=`"0`"/><wp:positionH relativeFrom=`"page`"><wp:align>center</wp:align></wp:positionH><wp:positionV relativeFrom=`"page`"><wp:align>center</wp:align></wp:positionV><wp:extent cx=`"$emu`" cy=`"$emu`"/><wp:effectExtent l=`"0`" t=`"0`" r=`"0`" b=`"0`"/><wp:wrapNone/><wp:docPr id=`"$id`" name=`"Watermark`"/><wp:cNvGraphicFramePr/>$graphic</wp:anchor></w:drawing></w:r>"
}

function Add-ZipText($zip, [string]$name, [string]$text) {
    $entry = $zip.CreateEntry($name)
    $sw = New-Object System.IO.StreamWriter($entry.Open(), (New-Object System.Text.UTF8Encoding($false)))
    $sw.Write($text)
    $sw.Close()
}

# $meta: ordered hashtable of label -> value; $labels: @{ title; transcript }
function New-TranscriptDocx([string]$outPath, [string]$title, $meta, [string]$heading, [string[]]$paragraphs, [bool]$rtl, [string]$logoPath) {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $ns = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"'
    $teal = '0F5E59'; $amber = 'D98E04'; $gray = '4A5A57'
    $hasLogo = [bool]($logoPath -and (Test-Path -LiteralPath $logoPath))
    $wmPath = if ($logoPath) { [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($logoPath), 'watermark.png') } else { '' }
    $hasWm = [bool]($hasLogo -and $wmPath -and (Test-Path -LiteralPath $wmPath))

    # body
    $body = New-DocxPara (New-DocxRun $title @{ bold = $true; color = $teal; size = 36; rtl = $rtl }) @{ rtl = $rtl; after = 200; border = $amber }
    $rows = ''
    foreach ($k in $meta.Keys) {
        $cellL = "<w:tc><w:tcPr><w:tcW w:w=`"2600`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"E2F2EF`"/></w:tcPr>" + (New-DocxPara (New-DocxRun $k @{ bold = $true; color = $teal; size = 20; rtl = $rtl }) @{ rtl = $rtl; after = 40 }) + "</w:tc>"
        $cellR = "<w:tc><w:tcPr><w:tcW w:w=`"6900`" w:type=`"dxa`"/></w:tcPr>" + (New-DocxPara (New-DocxRun ([string]$meta[$k]) @{ size = 20; color = '16201F' }) @{ after = 40 }) + "</w:tc>"
        $rows += "<w:tr>$cellL$cellR</w:tr>"
    }
    $bidiVisual = if ($rtl) { '<w:bidiVisual/>' } else { '' }
    $body += "<w:tbl><w:tblPr>$bidiVisual<w:tblW w:w=`"9500`" w:type=`"dxa`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"4`" w:color=`"DCE3E1`"/><w:bottom w:val=`"single`" w:sz=`"4`" w:color=`"DCE3E1`"/><w:insideH w:val=`"single`" w:sz=`"4`" w:color=`"DCE3E1`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"60`" w:type=`"dxa`"/><w:left w:w=`"120`" w:type=`"dxa`"/><w:bottom w:w=`"60`" w:type=`"dxa`"/><w:right w:w=`"120`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tblGrid><w:gridCol w:w=`"2600`"/><w:gridCol w:w=`"6900`"/></w:tblGrid>$rows</w:tbl>"
    $body += New-DocxPara (New-DocxRun $heading @{ bold = $true; color = $teal; size = 28; rtl = $rtl }) @{ rtl = $rtl; before = 360; after = 160 }
    foreach ($p in $paragraphs) {
        $body += New-DocxPara (New-DocxRun $p @{ size = 23; color = '16201F'; rtl = $rtl }) @{ rtl = $rtl; jc = 'both'; after = 200 }
    }
    $sect = '<w:sectPr><w:headerReference w:type="default" r:id="rId2"/><w:footerReference w:type="default" r:id="rId3"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1500" w:right="1200" w:bottom="1300" w:left="1200" w:header="600" w:footer="600" w:gutter="0"/></w:sectPr>'
    $document = "<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?><w:document $ns><w:body>$body$sect</w:body></w:document>"

    # header: logo + name + amber rule, faint watermark behind the page
    $hdrRuns = ''
    if ($hasLogo) { $hdrRuns += New-DocxPicture 'rIdLogo' 1 274320 $false }
    $hdrRuns += New-DocxRun '  FieldBuilt' @{ bold = $true; color = $teal; size = 24 }
    $hdrRuns += New-DocxRun '  ·  by Ahmed Hassan' @{ color = $gray; size = 18 }
    if ($hasWm) { $hdrRuns += New-DocxPicture 'rIdWm' 2 3657600 $true }
    $header = "<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?><w:hdr $ns>" + (New-DocxPara $hdrRuns @{ border = $amber; after = 0 }) + "</w:hdr>"

    # footer: brand line + page number
    $ftrRuns = (New-DocxRun 'FieldBuilt · by Ahmed Hassan · Field-tested. Research-backed. · ' @{ color = $gray; size = 16 })
    $ftrRuns += (New-DocxRun 'من البحث إلى الميدان' @{ color = $gray; size = 16; rtl = $true })
    $ftrRuns += (New-DocxRun '   |   ' @{ color = $gray; size = 16 })
    $ftrRuns += '<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:rPr><w:color w:val="0F5E59"/><w:sz w:val="16"/></w:rPr><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:rPr><w:color w:val="0F5E59"/><w:sz w:val="16"/></w:rPr><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>'
    $footer = "<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?><w:ftr $ns><w:p><w:pPr><w:pBdr><w:top w:val=`"single`" w:sz=`"4`" w:space=`"4`" w:color=`"DCE3E1`"/></w:pBdr><w:jc w:val=`"center`"/></w:pPr>$ftrRuns</w:p></w:ftr>"

    $styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial" w:eastAsia="Arial"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="160" w:line="300" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style></w:styles>'
    $types = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/></Types>'
    $rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>'
    $docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/></Relationships>'
    $hdrRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rIdLogo" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/logo.png"/><Relationship Id="rIdWm" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/watermark.png"/></Relationships>'
    $now = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $core = "<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?><cp:coreProperties xmlns:cp=`"http://schemas.openxmlformats.org/package/2006/metadata/core-properties`" xmlns:dc=`"http://purl.org/dc/elements/1.1/`" xmlns:dcterms=`"http://purl.org/dc/terms/`" xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`"><dc:title>$(X $title)</dc:title><dc:creator>FieldBuilt ReelGrabber</dc:creator><dcterms:created xsi:type=`"dcterms:W3CDTF`">$now</dcterms:created></cp:coreProperties>"

    if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }
    $zip = [System.IO.Compression.ZipFile]::Open($outPath, 'Create')
    try {
        Add-ZipText $zip '[Content_Types].xml' $types
        Add-ZipText $zip '_rels/.rels' $rootRels
        Add-ZipText $zip 'docProps/core.xml' $core
        Add-ZipText $zip 'word/document.xml' $document
        Add-ZipText $zip 'word/styles.xml' $styles
        Add-ZipText $zip 'word/header1.xml' $header
        Add-ZipText $zip 'word/footer1.xml' $footer
        Add-ZipText $zip 'word/_rels/document.xml.rels' $docRels
        if ($hasLogo) {
            Add-ZipText $zip 'word/_rels/header1.xml.rels' $hdrRels
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $logoPath, 'word/media/logo.png')
            if ($hasWm) { [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $wmPath, 'word/media/watermark.png') }
        }
    } finally { $zip.Dispose() }
}
