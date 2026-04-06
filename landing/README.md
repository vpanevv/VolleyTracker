# VolleyTracker Landing Page

Static marketing page for the VolleyTracker iOS app.

## Contents
- `index.html` — landing page markup
- `styles.css` — styling
- `images/` — real screenshots captured from the iOS simulator
  - `welcome.png` — app welcome screen
  - `groups.png` — groups list with Boys/Girls emoji icons

## Preview locally
Just open the file:

```bash
open index.html
```

Or serve it:

```bash
cd landing && python3 -m http.server 8080
# then visit http://localhost:8080
```

## Deploy
The page is fully static — drop the `landing/` folder on any host
(GitHub Pages, Netlify, Vercel, S3, etc.).
