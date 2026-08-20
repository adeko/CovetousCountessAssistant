# Covetous Countess Assistant

> This addon was developed with AI assistance for ESO API research, code optimization, and translations. All final code has been personally reviewed, tested, and validated by the author.

An addon for [The Elder Scrolls Online](https://www.elderscrollsonline.com/).

**Highlights treasure-hunt items in your inventory for The Covetous Countess
and optionally Bursar of Tributes (Crow).**

## Features

- Fence icon on relevant treasures (backpack, bank, guild bank, house bank, craft bag)
- Green icon when the item matches an active Countess or Crow quest category, white otherwise
- Independent toggles for Countess / Crow tracking (settings or slash commands)
- Optional auto-skip of Tip Board offers that are not Covetous Countess
- Uses ESO's standard localization system and supports all client languages
- Tracks **Covetous Countess** categories by default:
  - Games, Dolls, and Statues
  - Ritual Objects, Oddities, and Magic Curiosities
  - Writings, Scrivener Supplies, and Maps
  - Cosmetics, Dry Goods, and Wardrobe Accessories
  - Drinkware, Utensils, and Dishes and Cookware
- Optional tracking for **Bursar of Tributes** (Crow) categories:
  - Leisure (Games, Dolls, Children’s Toys)
  - Respect (Drinkware, Utensils, Dishes and Cookware)
  - Tributes (Cosmetics, Grooming Items)
- Toggle tracking independently for Countess / Crow via settings or slash commands
- Settings panel via LibAddonMenu-2.0
- Slash commands:
  - `/ccatrackcountess` — toggle Covetous Countess tracking
  - `/ccatrackcrow` — toggle Bursar of Tributes tracking
  - `/ccatrackstatus` — show current tracking status

## Optional dependency

- [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html) (settings panel; without it, use slash commands)

## Credits & sources

- [UESP](https://en.uesp.net): Treasures, The Covetous Countess, Bursar of Tributes
- [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html) (Seerah, sirinsidiator, contributors)
- [ESOUI](https://www.esoui.com): wiki / community API documentation

## Related prior art (ideas only — independent code)

These projects address similar Countess / Tip Board problems. This addon does **not** use their code, libraries, or file structure; it is a separate implementation.

- [CovetousCountess – Abah's Watch farming helper](https://www.esoui.com/downloads/info1372-CovetousCountess-AbahsWatchfarminghelper.html) by Shinni  
  Inspiration for optional Tip Board filtering (skip non–Covetous Countess offers).

- [LibCovetousCountess](https://www.esoui.com/downloads/info3266-LibCovetousCountess.html) by olegbl and quelron  
  Prior library for Countess / Crow treasure usefulness. This addon does **not** depend on LibCovetousCountess; quest and tag matching are implemented separately.

## Compatibility

**Not compatible** with [CovetousCountess – Abah's Watch farming helper](https://www.esoui.com/downloads/info1372-CovetousCountess-AbahsWatchfarminghelper.html) or any updates, forks, or reuploads of that addon (both may interact with the Tip Board / quest offer flow). Disable one or the other.

LibCovetousCountess is a library only; it can coexist if another addon requires it, but this addon does not use it.

## Notes

- Settings are account-wide and shared across NA / EU / PTS by design.
- If translations look off in your language, please report them.

---

*This Add-on is not created by, affiliated with, or sponsored by, ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and related logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States and/or other countries. All rights reserved.*
