# Movter (not final product, under construction)

**Keep the ticket.** An iOS film app: browse what's trending, discover films with an on-device personalized swipe deck, organize your library, and score what you've seen — every review you save becomes a ticket stub worth keeping.

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

- **Home & Search** — a hero carousel and genre-filtered trending grid, plus a search overlay with recent searches and discover filters (release decade, streaming service, popularity, rating, and upcoming releases). Every details screen carries the trailer, full cast & crew, actor filmographies, similar titles, tracking controls, favorites, and your review.
- **Swipe** — a personalized discovery deck built on an on-device taste engine. Cards show rating (or `Upcoming`), primary genre, and release year pills over prefetched textless posters with cross-dissolve upgrades. Supports velocity-aware gesture physics, real-time background stack interpolation, threshold haptics, **Undo**, a **14-day "Maybe Later" cooldown**, and an interactive 10-card session checkpoint (**Deal 10 More** / **Open Watchlist**).
- **Stubs & Reviews** — score films 1–10 with notes, collect saved reviews in an interactive stacked ticket-stub deck, and curate your Top Favorites.
- **Library** — organize your films across **Watchlist**, **Coming Soon**, **Favorites**, and **Seen** folders with live search.

## Swipe Discovery Algorithm

The Swipe deck (`SwipeTab`) runs an on-device recommendation and ranking pipeline with zero backend dependency:

1. **Unified Cross-Tab Exclusions & Cooldowns** — `GetExcludedSwipeMediaIDsUseCase` excludes films already in your Watchlist, Watched list, Reviews, Top Favorites, or active swipe history, and reconciles the active deck whenever you return from another tab or movie details. A single left-swipe ("Maybe Later") enters a 14-day cooldown before becoming eligible again; liking or passing twice excludes the title permanently. A per-user pagination cursor prevents cold-start refetch storms.
2. **On-Device Taste Profile** — `BuildUserTasteProfileUseCase` synthesizes weighted genre, decade, and seed signals from Top Favorites (`+3.0`), high reviews `8–10` (`+2.5`), low reviews `1–4` (`-2.0`), Watchlist/Watched (`+1.5`), and pass history (`-1.0`), then updates affinities in real time on every in-session swipe (`+0.35` on like, `-0.15` on pass).
3. **60 / 25 / 15 Candidate Blending & Hygiene** — `FetchPopularSwipeDeckUseCase` fetches taste-matched recommendations/genre discovery (60%), weekly trending/popular momentum (25%), and high-acclaim serendipity excluding your #1 genre (15%) concurrently via `async let`, filtering out duplicates, missing posters, and `< 40`-vote released titles (with a cold-start fallback for new users).
4. **Bayesian & Diversity Reranking** — `RankSwipeCandidatesUseCase` scores candidates using Bayesian-smoothed ratings (`m = 250`, `C = 6.8`) combined with genre and decade affinities, then greedily reorders the deck with same-primary-genre (`-0.25`) and same-title-prefix (`-0.20`) anti-clumping penalties.

## Architecture

Clean Architecture + MVVM + Coordinators, laid out in code (UIKit + SwiftUI) with no storyboards. Each feature tab is split into `Data`, `Domain` (entities, repositories, use cases), and `Presentation` (view models, view controllers/views, coordinators, factories).

Shared infrastructure lives in the local Swift Package **`MovterPlatformSDK`** (`MovterCore`, `MovterDomain`, `MovterNetwork`, `MovterStorage`, `MovterUI`). Reviews, watchlists, and favorites are stored as local JSON files via `LocalJSONFileStore`, while lightweight state (swipe history, pagination cursor, recent searches, theme) lives in `UserDefaults`.

## Project Structure

```
Movter/
├── Movter/
│   ├── Models/               Media, DiscoverQuery, MovieGenre, WatchlistItem, Credits, Video
│   ├── Networking/           TMDBService, MediaFetching, GenreProvider
│   ├── Modules/
│   │   ├── LibraryTab/       Watchlist, Coming Soon, Favorites, Seen folders
│   │   ├── MoviesTab/        Home carousel, trending grid, search overlay, details, cast, actor
│   │   ├── ReviewsTab/       Review editor, film picker, reviews list, ticket stub
│   │   ├── StubsTab/         Stacked stubs deck & Top Favorites
│   │   └── SwipeTab/         Personalized swipe deck, taste engine, reranker, watchlist
│   └── Shared/               Custom tab bar, transitions, rating formatter, reusable views
├── MovterPlatformSDK/        Local Swift Package
│   └── Sources/
│       ├── MovterCore/       DIContainer, ViewState, Logger, extensions
│       ├── MovterDomain/     RatingState
│       ├── MovterNetwork/    NetworkService, TMDBRequestBuilder, ImageLoader, NetworkMonitor
│       ├── MovterStorage/    LocalJSONFileStore
│       └── MovterUI/         Typography, adaptive colors, ThemeManager
└── MovterTests/              XCTest unit test suite (125 tests)
    ├── MovterSmokeTests.swift
    ├── M1_GesturePhysics/
    ├── M2_ExclusionReconciliation/
    ├── M3_HistoryAndPagination/
    ├── M4_TasteProfile/
    ├── M5_CandidateGenerationAndRanking/
    ├── M6_CardUIAndSessionLoop/
    └── Support/
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

3. Open `Movter.xcodeproj` and run.

> The TMDb API key is substituted into `Info.plist` at build time, so it ships inside the
> app bundle. Use a key you are comfortable shipping in a client app.

## Testing

Run the `MovterTests` unit test suite (125 tests covering smoke checks, swipe gesture physics, cross-tab exclusions, 14-day cooldown history, taste profiling, 60/25/15 candidate ranking, and card UI/session flows) via Xcode (`⌘U`) or `xcodebuild`:

```bash
xcodebuild test \
  -project Movter.xcodeproj \
  -scheme Movter \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Built With

Swift, UIKit & SwiftUI (100% programmatic UI), Clean Architecture + MVVM, `MovterPlatformSDK`, [Alamofire](https://github.com/Alamofire/Alamofire), [Swinject](https://github.com/Swinject/Swinject), and film data from [TMDb](https://www.themoviedb.org/).
