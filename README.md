<p align="center"><img src="docs/banner.jpg" alt="ReelGrabber" width="720"></p>

<h1 align="center">ReelGrabber</h1>
<p align="center"><b>Audio, video and transcripts from Facebook, YouTube, TikTok, Instagram and more, on Windows.</b><br>
FieldBuilt · by Ahmed Hassan · <i>Field-tested. Research-backed.</i></p>

<p align="center">
<a href="../../releases/latest"><b>⬇ Download the latest version</b></a>
</p>

---

<div dir="rtl">

## بالعربي

**ReelGrabber** برنامج صغير ومجاني لويندوز. بيحمّل الصوت أو الفيديو أو النص (الترجمة) من فيسبوك ويوتيوب وتيك توك وإنستجرام ومواقع تانية كتير، من غير أوامر ولا CMD.

### بيعمل إيه
- **فيديو** بالجودة اللي تختارها: أفضل جودة متاحة، أو 1080p، أو 720p، أو 480p. وفيه زرار بيعرض الجودات المتاحة فعلًا للفيديو.
- **صوت** بصيغ MP3 و M4A و WAV و FLAC و OPUS، وتختار معدل البت.
- **السرعة** من 0.5x لـ 2x من غير ما نبرة الصوت تتغير. مفيدة للمحاضرات ولتعلم اللغات.
- **مؤثرات صوتية:**
  - عملية: ضبط المستوى، وإزالة الضوضاء، ووضوح الكلام، وحذف السكوت.
  - إبداعية: صدى، وقاعة، وصوت راديو، وصوت أتخن أو أرفع.
- **معاينة 10 ثواني** قبل ما تنزّل الملف كله.
- **النص فقط:** لو الفيديو عليه ترجمة، بتنزل في ملف Word منسق ومعاه ملف SRT.
- **إضافة لكروم وفايرفوكس:** كليك يمين على أي فيديو، والبرنامج يفتح والرابط جاهز فيه.
- **الواجهة** عربي وإنجليزي بضغطة زرار.

### التثبيت
1. نزّل ملف ‎`ReelGrabber-v*.zip`‎ من صفحة [Releases](../../releases/latest).
2. فك الضغط في فولدر اسمه إنجليزي، زي ‎`C:\ReelGrabber`‎. متشغّلوش من جوه WinRAR.
3. شغّل **Install.bat**. هيسطّب yt-dlp و ffmpeg و Deno لوحده من winget، ويعمل اختصار على سطح المكتب.
4. لو ظهرتلك رسالة SmartScreen، اختار **More info**، وبعدين **Run anyway**. البرنامج مكتوب بالكامل بـ PowerShell، والكود كله قدامك هنا.

### إضافة المتصفح (اختياري)
- **كروم أو إيدج:** افتح ‎`chrome://extensions`‎، وشغّل **Developer mode**، واختار **Load unpacked**، وبعدين فولدر ‎`extension`‎.
- **فايرفوكس:** افتح ‎`about:debugging`‎، وادخل على **This Firefox**، واختار **Load Temporary Add-on**، وبعدين ملف ‎`extension/manifest.json`‎.

### الإزالة
شغّل **Uninstall.bat**، وبعدين امسح الفولدر.

</div>

---

## English

**ReelGrabber** is a small, free Windows app (PowerShell + WinForms) built on [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [FFmpeg](https://ffmpeg.org/).

- **Video:** best / 1080p / 720p / 480p, with a button that lists the formats a video really has.
- **Audio:** MP3, M4A, WAV, FLAC and OPUS, with a choice of bitrate.
- **Speed:** 0.5x–2x without changing pitch.
- **Effects:** 12 audio effects, with a 10-second preview before the full download.
- **Transcript only:** the video's existing captions saved as a branded Word file (.docx) plus SRT.
- **Browser extension:** for Chrome, Edge and Firefox. Right-click any video to send it to the app.
- **Interface:** Arabic and English.

### Install
1. Download `ReelGrabber-v*.zip` from [Releases](../../releases/latest).
2. Extract it to a folder with a plain English path, for example `C:\ReelGrabber`.
3. Run **Install.bat**. It installs yt-dlp, FFmpeg and Deno through winget if they are missing, registers the `reelgrab:` link type for the current user only (no admin rights), and adds a desktop shortcut.

**Requirements:** Windows 10 or 11 with winget (App Installer).

<p align="center"><img src="docs/screenshot.png" alt="ReelGrabber window" width="420"></p>

## Fair use

Download only content you own, content that is licensed for reuse, or content you are allowed to save for personal use. Respect creators and each platform's terms of service. ReelGrabber does not bypass DRM or paywalls.

## Contact

Ahmed Hassan · ahassanccna@gmail.com · [LinkedIn](https://www.linkedin.com/in/ahmedhassan30/) · [GitHub](https://github.com/ahassan22)

## License

ReelGrabber is free software released under the **GNU General Public License v3.0** (see [LICENSE](LICENSE)). You may use, study, share and modify it. If you distribute a modified version, you must release its source under the same license and keep the original credit.

Copyright © 2026 Ahmed Hassan (FieldBuilt).
