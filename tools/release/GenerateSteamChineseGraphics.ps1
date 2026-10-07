[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class ChineseSteamLayout {
    static void Quality(Graphics g) {
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.CompositingQuality = CompositingQuality.HighQuality;
    }
    public static void Generate(string root) {
        string output = System.IO.Path.Combine(root, "marketing/steam/schinese");
        using (var original = new Bitmap(System.IO.Path.Combine(root,"assets/source/imagegen/steam_chinese_title_local_candidate/chinese_logo_generated.png")))
        using (var art = new Bitmap(System.IO.Path.Combine(root,"assets/ui/endings/update4/ending_minion_wears_the_crown.png"))) {
            int left=original.Width, top=original.Height, right=-1, bottom=-1, transparent=0;
            for(int y=0;y<original.Height;y++) for(int x=0;x<original.Width;x++) {
                int alpha = original.GetPixel(x,y).A;
                if(alpha==0) transparent++;
                if(alpha>32) {left=Math.Min(left,x);top=Math.Min(top,y);right=Math.Max(right,x);bottom=Math.Max(bottom,y);}
            }
            if(transparent==0 || right<left) throw new Exception("Generated logo lacks real transparency or visible text");
            using(var canvas = new Bitmap(1280,720,PixelFormat.Format32bppArgb)) {
                using(var g = Graphics.FromImage(canvas)) {
                    Quality(g);g.Clear(Color.Transparent);
                    double scale=Math.Min(1280.0/original.Width,720.0/original.Height);
                    int w=(int)Math.Round(original.Width*scale),h=(int)Math.Round(original.Height*scale);
                    g.DrawImage(original,new Rectangle((1280-w)/2,(720-h)/2,w,h));
                }
                Save(canvas,output,"library/logo.png");
            }
            var mark = new Rectangle(left,top,right-left+1,bottom-top+1);
            string[] names={"store/header_capsule.png","store/small_capsule.png","store/main_capsule.png","store/vertical_capsule.png","library/capsule.png","library/header.png"};
            int[] widths={920,462,1232,748,600,920}, heights={430,174,706,896,900,430};
            for(int i=0;i<names.Length;i++) {
                int w=widths[i],h=heights[i]; bool vertical=h>w;
                using(var capsule=new Bitmap(w,h,PixelFormat.Format32bppArgb))
                using(var g=Graphics.FromImage(capsule)) {
                    Quality(g);
                    double scale=Math.Max((double)w/art.Width,(double)h/art.Height);
                    double cropW=w/scale,cropH=h/scale;
                    double cx=(vertical?0.48:0.51)*art.Width,cy=0.5*art.Height;
                    var crop=new RectangleF((float)Math.Max(0,Math.Min(art.Width-cropW,cx-cropW/2)),(float)Math.Max(0,Math.Min(art.Height-cropH,cy-cropH/2)),(float)cropW,(float)cropH);
                    g.DrawImage(art,new Rectangle(0,0,w,h),crop,GraphicsUnit.Pixel);
                    var grad=vertical?new Rectangle(0,0,w,(int)Math.Round(h*.58)):new Rectangle(0,(int)Math.Round(h*.48),w,h-(int)Math.Round(h*.48));
                    Color zero=Color.FromArgb(0,12,4,20),dark=Color.FromArgb(vertical?185:175,12,4,20);
                    using(var brush=new LinearGradientBrush(grad,vertical?dark:zero,vertical?zero:dark,LinearGradientMode.Vertical))g.FillRectangle(brush,grad);
                    double targetW=w*(vertical?.88:.72),targetH=mark.Height*targetW/mark.Width;
                    double titleHeightLimit=h*(vertical?.34:.50);
                    if(targetH>titleHeightLimit){targetH=titleHeightLimit;targetW=mark.Width*targetH/mark.Height;}
                    var target=new Rectangle((w-(int)Math.Round(targetW))/2,(int)Math.Round(h*(vertical?.07:.48)),(int)Math.Round(targetW),(int)Math.Round(targetH));
                    g.DrawImage(original,target,mark,GraphicsUnit.Pixel);
                    Save(capsule,output,names[i]);
                }
            }
        }
        string promoDestination=System.IO.Path.Combine(root,"marketing/steam/promo/promo_schinese.png");
        System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(promoDestination));
        System.IO.File.Copy(System.IO.Path.Combine(root,"assets/source/imagegen/steam_chinese_promo_local_candidate/chinese_promo_generated.png"),promoDestination,true);
    }
    static void Save(Bitmap image,string root,string relative) {
        string p=System.IO.Path.Combine(root,relative);System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(p));image.Save(p,ImageFormat.Png);
    }
}
'@
[ChineseSteamLayout]::Generate($repoRoot)
Write-Output 'CHINESE_GRAPHICS: PASS (7 localized PNGs with validated native transparent logo; promo sibling)'
