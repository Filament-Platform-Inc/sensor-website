# sensor.filamentplatform.com

One static page. No build step, no dependencies — open `index.html` to work on it.

    index.html    the page; CSS and JS are inline
    install.sh    what `curl … | sh` runs; downloads the release, calls apt
    logo.png      also the og:image
    favicon.png

The `.deb` is not here — it comes from GitHub Releases, so the download link
always points at the latest version.

## Adding the demo

Drop `demo.mp4` (and optionally `demo-poster.jpg`) beside `index.html`. The
page reveals the `<video>` only once the file actually loads, so until then
visitors see the placeholder rather than a broken player. Nothing else to
change.

Keep it short (~20s), record with audio, and do not cut — the point is that
the latency is real.

## To do

- [ ] Record `demo.mp4`
- [ ] Check `install.sh` is served as `text/plain`, so "Read the script
      first" opens rather than downloads
