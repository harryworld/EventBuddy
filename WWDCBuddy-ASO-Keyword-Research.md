# WWDCBuddy ASO Keyword Research

Date: 2026-05-17
Storefront: US
Source: Astro tracked keywords for App Store ID `6746382590`

## Recommendation

Rename the visible brand from `EventBuddy` to `WWDCBuddy`.

The strongest current traction is not the old brand term. Astro shows the app ranking well for WWDC-specific friend and event intent:

- `wwdc events`: rank 1, popularity 5, difficulty 52
- `wwdc friends`: rank 1, popularity 5, difficulty 56
- `wwdc event friends`: rank 1, popularity 5, difficulty 49
- `wwdc friends events`: rank 2, popularity 5, difficulty 65
- `wwdc events app`: rank 11, popularity 5, difficulty 59

The chosen brand is `WWDCBuddy`. Astro's current `wwdc buddy` result surface is noisy, so keep `friends` and `events` in the App Store subtitle and keyword field to preserve the stronger current ranking signals.

## Proposed Metadata

```text
Title:    WWDCBuddy - Friends in Events
Subtitle: Meet Apple friends at WWDC26
Keywords: conference,networking,developer,community,schedule,calendar,reminder,contact,business,card,qr,name
```

Notes:

- The title stays under Apple's 30-character title limit.
- The subtitle stays under Apple's 30-character subtitle limit.
- The keyword field is 98 characters and avoids repeating title/subtitle words.
- The current live subtitle seen in Astro is `Meet friends at WWDC25 events`; update it before the next App Store metadata push because it is dated.

## ASC Update Status

Updated in App Store Connect for en-US app-info on 2026-05-17:

- Name: `WWDCBuddy - Friends in Events`
- Subtitle: `Meet Apple friends at WWDC26`

Created iOS version `2026` in `PREPARE_FOR_SUBMISSION` and updated en-US keywords there:

`conference,networking,developer,community,schedule,calendar,reminder,contact,business,card,qr,name`

## Keyword Priorities

| Keyword | Popularity | Difficulty | Current Rank | Priority | Rationale |
| --- | ---: | ---: | ---: | --- | --- |
| `wwdc event friends` | 5 | 49 | 1 | Primary | Exact fit for the app and lower difficulty than `wwdc buddy`. |
| `wwdc events` | 5 | 52 | 1 | Primary | Strongest existing App Store result surface for the app. |
| `wwdc friends` | 5 | 56 | 1 | Primary | Supports the rename and the core friend-tracking workflow. |
| `developer events` | 5 | 17 | 29 | Secondary | Low difficulty and relevant beyond WWDC. |
| `event networking` | 5 | 21 | 1000 | Secondary | Strong feature fit, but no current rank yet. |
| `conference networking` | 5 | 17 | 1000 | Secondary | Low difficulty; competitor result page is directly relevant. |
| `event connect` | 5 | 13 | 1000 | Secondary | Low difficulty and matches the connection workflow. |
| `wwdc networking` | 5 | 47 | 36 | Secondary | Relevant and already indexed. |
| `meet friends events` | 5 | 56 | 25 | Secondary | Good long-tail phrase for the app's social use case. |
| `digital business card` | 34 | 54 | 1000 | Aspirational | Higher popularity, but crowded with dedicated business-card apps. |
| `qr code` | 47 | 78 | 1000 | Aspirational | High popularity and relevant to profile sharing, but too broad for title/subtitle. |
| `contacts` | 64 | 62 | 1000 | Aspirational | High popularity, but broad and less event-specific. |

## Competitor Notes

- `wwdc events` result page has the app at rank 1, ahead of Community Week, AllEvents, Cvent, Luma, Apple Developer, Apple Invites, Webex Events, Sched, and SAP Events.
- `event networking` and `conference networking` are crowded with Whova, 10times, Grip, Boop, and other conference networking apps. These are relevant but should be treated as secondary terms until the app has stronger metadata and ratings.
- `digital business card` is a separate high-competition market led by Blinq, HiHello, Popl, Dot, and similar apps. Keep QR/contact terms in the keyword field and screenshots, not in the main brand.
