# سایه‌های پارس (Shadows of Pars) — Godot 4

بازی بقا و اکتشاف سه‌بعدی در سرزمین باستانی پارس.

[![Build](https://github.com/USER/sayeha-pars/actions/workflows/build.yml/badge.svg)](https://github.com/USER/sayeha-pars/actions/workflows/build.yml)

> بعد از ساخت ریپو، در لینک بالا `USER/sayeha-pars` را با نام واقعی ریپو عوض کن.

## اجرا از Artifact (بدون نصب Godot)

1. برو به تب **Actions**
2. آخرین workflow موفق را باز کن
3. از بخش **Artifacts** فایل `sayeha-windows-v11` را دانلود کن
4. از حالت فشرده خارج کن و `SayehaPars-Windows.exe` را اجرا کن

### انتشار رسمی
```bash
git tag v11.0.0
git push origin v11.0.0
```
روی هر تگ که با `v` شروع شود، Release با فایل ویندوز و لینوکس ساخته می‌شود.

---

## نیازمندی توسعه

- [Godot 4.3](https://godotengine.org/download) (پیشنهادی؛ با workflow یکی است)
- GPU با Vulkan یا حداقل OpenGL 3.3 (حالت Compatibility)

### ویندوز ۷
ادیتور Godot 4.3+ روی Win7 رسمی پشتیبانی نمی‌شود.  
بیلد را از **GitHub Actions** بگیر. اجرای خود بازی روی Win7 + کارت قدیمی تضمینی نیست.

---

## کنترل‌ها

| کلید | عمل |
|------|------|
| WASD | حرکت |
| موس | نگاه |
| Space | پرش |
| کلیک چپ | حمله |
| Shift | دویدن |
| E | تعامل / پیشرفت کوئست talk |
| V | تعویض دوربین |
| Esc | توقف |

---

## ساختار

```
sayeha_pars_godot/
├── project.godot
├── export_presets.cfg
├── .github/workflows/build.yml
├── scenes/          main, player, enemy
├── scripts/         game, world, quest, enemy, hud
├── shaders/         terrain_pbr, water
└── assets/          textures, audio, fonts
```

## ویژگی‌ها

- جهان رویه‌ای + بیوم
- شیدر PBR زمین (albedo + normal)
- روز/شب، مه volumetric، SDFGI، SSAO
- دشمن (عادی / نخبه / رئیس) + اسپاونر
- سیستم کوئست چندمرحله‌ای
- ذخیره مسیر برای توسعه بیشتر

## مجوز

کد برای استفاده شخصی و آموزشی آزاد است.  
فونت Noto Kufi Arabic تحت مجوز OFL.

---

**نسخه:** 11.0.0  
ساخته‌شده برای بیلد خودکار با GitHub Actions
