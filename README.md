# Movter (not final product, under construction)


**Keep the ticket.** An iOS film app: browse what's trending, keep a watchlist, and score
what you've seen — and every review you save becomes a ticket stub worth keeping.


## App Preview

<table>
  <tr>
    <td colspan="3" align="center">
     <img width="1080" height="1920" alt="6_1-Frame-en-1" src="https://github.com/user-attachments/assets/e792dfa6-087d-4c2c-8806-915f25ab9a5b" />
    </td>
    <td colspan="3" align="center">
      <img width="1080" height="1920" alt="6_1-Frame-en-2" src="https://github.com/user-attachments/assets/aa892887-9a08-49fa-8433-09afc13530a4" />
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <img width="1080" height="1920" alt="6_1-Frame-en-3" src="https://github.com/user-attachments/assets/de0096e6-992d-4079-9b73-c63413c61f17" />
      <br/><sub><b>Share</b></sub>
    </td>
    <td colspan="2" align="center">
      <img width="1080" height="1920" alt="6_1-Frame-en-4" src="https://github.com/user-attachments/assets/71cf6055-f36c-4b7e-b32e-57e085f55853" />
      <br/><sub><b>Swipe</b></sub>
    </td>
    <td colspan="2" align="center">
      <img width="1080" height="1920" alt="6_1-Frame-en-5" src="https://github.com/user-attachments/assets/6ad97b6f-2ce6-438c-b135-81441abc7387" />
      <br/><sub><b>Details</b></sub>
    </td>
  </tr>
</table>


## Features

- **Browse** — a carousel of what's trending, filtered by genre. Every details screen
  carries the trailer, the full cast, and your own score.
- **Search** — search the catalogue by title, or browse by decade, genre, streaming
  service, or rating.
- **Swipe** — a deck of popular films, one at a time. Swipe right to save one to your
  watchlist; the deck remembers every card it has already dealt you.
- **Review** — score a film 1–10 and add a line of your own. Rating a film marks it
  watched, and each saved review becomes a ticket you can open.
- **Profile** — watched, reviewed, and still waiting, in three numbers. Each one is a way
  into the list behind it. Editable profile, notification preferences, and three themes.

## How it works

MVVM, UIKit laid out in code with no storyboards. Each screen is a view controller paired
with a view model that owns its state and its network calls.

Data access sits behind protocols — `MediaFetching`, `ReviewStoring`, `WatchlistStoring` —
with a factory picking the backend, so no screen knows whether a list lives on disk or on a
server. Swapping local storage for a remote one is a change in one `makeStore()`.

Reviews and lists are JSON files in `Documents`, one file per account so switching users
can't expose the previous user's diary. Smaller state — recent searches, seen cards, the
chosen theme, notification preferences — lives in `UserDefaults`. Firebase provides
authentication only.

## Project structure

```
Movter/
├── Models/         Media, Review, WatchlistItem, RatingState
├── Networking/     NetworkService, ImageLoader, GenreProvider, NetworkMonitor
├── Modules/
│   ├── Auth/       sign-in and sign-up
│   ├── MoviesTab/  list, details, actor screens
│   ├── SearchTab/  search home, discover, subcategories
│   ├── SwipeTab/   swipe deck and watchlist
│   ├── ReviewsTab/ review editor, reviews list, ticket
│   └── ProfileTab/ profile, edit profile, notifications
└── Shared/         tab bar, theming, transitions, reusable views
```

## Requirements

Xcode 26.1 · iOS 26

## Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/aqylbermeshtech/Movter.git
   ```

2. Create `Config/Secrets.xcconfig` next to `Movter.xcodeproj` — copy
   `Movter/Config/Secrets.xcconfig.example` and fill in your own
   [TMDb](https://www.themoviedb.org/settings/api) API key.

3. Add `GoogleService-Info.plist` from the
   [Firebase console](https://console.firebase.google.com/) to `Movter/`.

4. Open `Movter.xcodeproj` and run.

> The API key is substituted into `Info.plist` at build time, so it ships inside the app
> and can be read from any build. Use a key you are willing to have public. The Firebase
> key in `GoogleService-Info.plist` is a project identifier rather than a credential —
> Google documents it as safe to ship, and access is controlled by Firebase Security Rules.

## Built with

Swift and UIKit, laid out in code with no storyboards. MVVM, `URLSession`, and Firebase
Auth. Film data from [TMDb](https://www.themoviedb.org/).
