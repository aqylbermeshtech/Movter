# Movter

An iOS film app: browse what's trending, keep a watchlist, and score what you've seen.

<div align="center">
  <video src="https://github.com/user-attachments/assets/7db2906a-34fa-4262-97bc-6d1617b28575" controls width="300"></video>
</div>

## Features

- **Browse** — trending films, filtered by genre. Details screens carry the trailer, cast, and your own rating.
- **Search** — search the catalogue, or browse by decade, genre, streaming service, or rating.
- **Swipe** — a deck of popular films; swipe right to save one to your watchlist.
- **Diary** — score films 1–10 and write a review, picked from the catalogue or typed in by hand.
- **Account** — email sign-in, editable profile, notification preferences, and three themes.

## Requirements

Xcode 26.1 · iOS 26

## Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/aqylbermeshtech/Movter.git
   ```

2. Create `Config/Secrets.xcconfig` next to `Movter.xcodeproj` — copy `Movter/Config/Secrets.xcconfig.example` and fill in your own [TMDb](https://www.themoviedb.org/settings/api) API key.

3. Add `GoogleService-Info.plist` from the [Firebase console](https://console.firebase.google.com/) to `Movter/`.

4. Open `Movter.xcodeproj` and run.

> The API key is substituted into `Info.plist` at build time, so it ships inside the app and can be read from any build. Use a key you are willing to have public. The Firebase key in `GoogleService-Info.plist` is a project identifier rather than a credential — Google documents it as safe to ship, and access is controlled by Firebase Security Rules.

## Built with

Swift and UIKit, laid out in code with no storyboards. MVVM, `URLSession`, and Firebase Auth. Film data from [TMDb](https://www.themoviedb.org/).
