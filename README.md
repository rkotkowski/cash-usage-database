# Cash Usage Database

Share of cash in the number and value of consumer payments across countries and years, compiled from central bank payment diaries and surveys (199 observations, 35 countries, 1996–2026).

## Contents

| file | what it is |
|---|---|
| `index.html` | the whole site (HTML + JS, no server, no build step) |
| `data/cud.json` | data used by the site: observations, sources, links, footnotes |
| `eksport_danych.R` | builds `data/cud.json` from the master `RRRRMMDD_Cash Usage Database.xlsx` |

Downloads are not served from this site; the Data tab links to the archived release on Mendeley Data (https://data.mendeley.com/drafts/529hmx9pk6).
| `vendor/d3.min.js` | d3 7.8.5 (ISC licence) |
| `fonts/` | Spectral, IBM Plex Sans, IBM Plex Mono (SIL Open Font License 1.1) |

The site loads nothing from other servers and uses no cookies or analytics.

## Updating the data

```sh
Rscript eksport_danych.R                       # newest ../*_Cash Usage Database.xlsx
Rscript eksport_danych.R "../RRRRMMDD_Cash Usage Database.xlsx"
git add data && git commit -m "Data RRRRMMDD" && git push
```

Revision history on the About tab is written by hand in `index.html`.

Local preview: `python3 -m http.server` in this folder, then http://localhost:8000.

## How to cite

Kotkowski, R., Dybka, P., Piotrowska, A. I., & Van Hove, L. (2025). Everyday cash usage and corruption perception: Evidence from a panel of countries (KAE Working Papers No. 2025/114). SGH Warsaw School of Economics, Collegium of Economic Analysis. http://hdl.handle.net/20.500.12182/1383

## Licence

Data: CC BY 4.0. Site code and scripts: MIT.
