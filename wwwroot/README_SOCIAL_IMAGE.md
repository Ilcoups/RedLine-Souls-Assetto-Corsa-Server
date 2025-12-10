Place the new social preview image at `wwwroot/social-preview-v2.jpg` (public URL: https://red-line.live/social-preview-v2.jpg).

Suggested commands (run from your workstation, replace with local paths):

# Using scp (from your machine):
scp /path/to/new-image.jpg acserver@your-server-ip:/home/acserver/server/wwwroot/social-preview-v2.jpg

# Or upload via curl (if you can POST multipart/form-data to server):
# (requires an HTTP upload endpoint; not provided by simple python http.server)

# As a quick test, you can also base64-encode the file and upload via SSH:
# On your machine:
# base64 /path/to/new-image.jpg > new-image.b64
# Then on server:
# base64 -d new-image.b64 > /home/acserver/server/wwwroot/social-preview-v2.jpg

After placing the file, clear Telegram cache by sending a cache-busted URL, e.g.:
https://red-line.live/?v=2

If you want, I can also:
- Replace the existing `social-preview.jpg` instead of creating a v2 file (dangerous if cache persists),
- Generate a resized version (1200x630) here if you upload the image file contents or allow me to fetch it from a URL.
