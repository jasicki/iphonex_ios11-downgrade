# iPhone X (iOS 11.1) Tethered Boot & Bypass Toolkit

Kompletny, niezale?ny zestaw do uruchamiania i obs?ugi tethered downgrade **iOS 11.1 (Build 15B93)** na **iPhone X (`iPhone10,6` / `d221ap`, A11 Bionic)**.

---

## ?? Struktura folderu

```
~/iPhoneX_iOS11/
??? boot.sh                      # G??wny skrypt uruchamiaj?cy tethered boot iOS 11.1
??? bin/                         # Narz?dzia exploitacyjne (gaster, irecovery)
??? bootchain/                   # Sk?adniki startowe (iBSS, iBEC, devicetree, kernelcache)
??? patches/                     # Poprawki systemowe (SpringBoard, plisty konfiguracyjne, aktywacja)
?   ??? SpringBoard.patched      # Poprawiony SpringBoard (bypasuje Setup, od razu Home Screen)
?   ??? com.apple.purplebuddy.plist
?   ??? com.apple.springboard.plist
?   ??? .GlobalPreferences.plist
?   ??? data_ark.plist
??? scripts/
?   ??? restore_patches_via_ramdisk.sh # Skrypt przywracaj?cy poprawki przez SSH Ramdisk (gdyby telefon zosta? zresetowany)
??? README.md
```

---

## ?? Jak uruchomi? iOS 11.1 (Tethered Boot)

1. Pod??cz iPhone X kablem USB do Maca.
2. Wprowad? telefon w tryb **DFU**:
   * Naci?nij i pu?? **Volume Up**
   * Naci?nij i pu?? **Volume Down**
   * Wci?nij i trzymaj **Side (Power)**, a? ekran zga?nie
   * Trzymaj **Side** i wci?nij **Volume Down** (oba naraz przez 5 sekund)
   * Po 5 sekundach pu?? **Side**, trzymaj dalej **Volume Down** przez kolejne ~5 sekund (ekran ma pozosta? czarny)
3. Uruchom skrypt startowy:
   ```bash
   ~/iPhoneX_iOS11/boot.sh
   ```
   *(lub pro?ciej z katalogu domowego: `./boot_ios11.sh`)*
4. Skrypt wykona exploit checkm8 (`gaster pwn`), wy?le `iBSS`, `iBEC`, `devicetree` oraz `kernelcache` i zabootuje system.
5. Telefon uruchomi si? bezpo?rednio do pulpitu iOS 11.1.

---

## ??? Gdyby telefon zosta? zresetowany / wymazany

Je?li partycja danych zostanie kiedykolwiek zresetowana i powr?ci problem z logo Apple lub bia?ym ekranem Setup:
1. Zabootuj SSH Ramdisk (`cd ~/SSHRD_Script && ./sshrd.sh boot`).
2. Uruchom skrypt:
   ```bash
   ~/iPhoneX_iOS11/scripts/restore_patches_via_ramdisk.sh
   ```
3. Po zako?czeniu wprowad? telefon w DFU i zabootuj `~/iPhoneX_iOS11/boot.sh`.

---

## ?? Co naprawia ten zestaw?
1. **Logo Apple zawieszone przy starcie:**
   W oryginalnym iOS 11 usuni?cie `Setup.app` powodowa?o brak zako?czenia transakcji startowej w SpringBoard, przez co nak?adka `BKSDisplayRenderOverlay` (logo Apple) nigdy nie znika?a. Zmodyfikowana binarka `SpringBoard` wymusza przej?cie do `Destination 1 (Home Screen)` natychmiast po starcie.
2. **Bia?y ekran po ge?cie w Setup.app:**
   Wy??czenie asystenta konfiguracji i aktywacja w `data_ark.plist` eliminuje p?tl? oczekiwania na us?ugi aktywacji.
