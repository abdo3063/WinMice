# Site assets

- `hero-bg.jpg`, `settings-scroll.jpg`, `settings-nav.jpg` — generated marketing stills (downscaled to ~1000–1400px wide, JPEG, kept under ~250&nbsp;KB each).
- Hero demo on the site is a CSS mock (`.demo-mock` in `docs/index.html`) for v1.

## Replace with a real capture later

1. Record 5–12s of middle-click vector scrolling.
2. Export `demo-loop.webm` (preferred) and/or `demo-loop.gif` into this folder (keep under ~5&nbsp;MB if possible).
3. In `docs/index.html`, replace the `.demo-mock` block inside `#demo-band` with:

```html
<video autoplay muted loop playsinline poster="assets/settings-scroll.jpg">
  <source src="assets/demo-loop.webm" type="video/webm">
  <img src="assets/demo-loop.gif" alt="WinMice scrolling demo">
</video>
```

4. Re-run `./scripts/verify-pages-home.sh`.
