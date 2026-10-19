from pathlib import Path
root=Path(__file__).resolve().parent
text=(root.parent/'release_audit_v130b/ocr_capture.ps1').read_text(encoding='utf-8')
text='param([string]$CapturePath)\n[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()\n'+text.replace("$capturePath = Join-Path $PSScriptRoot 'captures/cu_ocr.png'",'')
text=text.replace("$language = New-Object Windows.Globalization.Language 'ko'","$language = New-Object Windows.Globalization.Language 'en-US'")
text=text.replace('$result = Await-WinRT ($engine.RecognizeAsync($bitmap))',"if ($null -eq $engine) { $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage((New-Object Windows.Globalization.Language 'ko')) }\n$result = Await-WinRT ($engine.RecognizeAsync($bitmap))")
(root/'ocr_capture.ps1').write_text(text,encoding='utf-8-sig')
path=root/'harness/V130RReleaseLayoutTest.gd'
text=(root.parents[1]/'tools/tests/V130RReleaseLayoutTest.gd').read_text(encoding='utf-8')
text=text.replace('res://tmp/v130r_release_blockers/','res://_mockup/release_audit_v130c/')
text=text.replace('category=="general" and DisplayServer','category=="display" and DisplayServer')
text=text.replace('toast.queue_free(); await release()', '''if DisplayServer.get_name()!="headless":
\t\tawait RenderingServer.frame_post_draw
\t\tvar image := get_viewport().get_texture().get_image()
\t\timage.resize(960,540,Image.INTERPOLATE_LANCZOS)
\t\timage.save_png("res://_mockup/release_audit_v130c/toast_zh_CN.png")
\ttoast.queue_free(); await release()''')
path.write_text(text,encoding='utf-8')
