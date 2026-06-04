FitTrack PWA — Deployment Guide
================================

FILES TO DEPLOY (upload all 5 to Vercel):
  index.html     ← Main app
  manifest.json  ← PWA config
  sw.js          ← Service worker (offline support)
  icon-192.png   ← App icon
  icon-512.png   ← App icon (large)

HOW TO DEPLOY ON VERCEL (free):
  1. Go to vercel.com and sign up with GitHub or email
  2. Click "Add New Project" → "Browse" to upload files
     (or drag all 5 files into the deploy area)
  3. Click Deploy — you'll get a URL like fittrack.vercel.app
  4. Share that URL with friends!

ADD TO IPHONE HOME SCREEN:
  1. Open your Vercel URL in Safari
  2. Tap the Share button (box with arrow at bottom)
  3. Scroll down → tap "Add to Home Screen"
  4. Tap "Add" — the app icon appears on your home screen

HOW TO UPDATE THE APP (when you add new features):
  1. Get the new index.html from Claude
  2. Go to your Vercel project dashboard
  3. Re-deploy by uploading the new file (drag & drop)
  4. Your friends' apps update automatically next time they open it
  5. Your data is safe — it lives on each device in localStorage

SHARING PROGRESS WITH FRIENDS:
  - Tap "History" tab → "Share Progress Card" button
  - Choose This Week / This Month / All Time
  - Tap "Save Image" to download a PNG → share anywhere
  - Or tap "Copy Text" for a plain text summary

DATA STORAGE NOTE:
  Each person's workout data is stored locally on their own device.
  Data is NOT shared between users — everyone has their own private log.
