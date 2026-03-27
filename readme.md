<a id="top"></a>

<div align="center">

# ForexScalpingBot

### _SwiftUI forex trading assistant with paper trading and a companion backend_

<img src="https://img.shields.io/badge/SwiftUI-iOS_App-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI badge" />
<img src="https://img.shields.io/badge/Swift-5+-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift badge" />
<img src="https://img.shields.io/badge/Node.js-Server-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js badge" />
<img src="https://img.shields.io/badge/MongoDB-Atlas-47A248?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB badge" />
<img src="https://img.shields.io/badge/Repository-Readme_Refresh-181717?style=for-the-badge&logo=github&logoColor=white" alt="Repository badge" />

**[About](#about) • [Features](#features) • [Tech Stack](#tech-stack) • [Quick Start](#quick-start) • [Project Structure](#project-structure) • [Scripts](#scripts) • [License](#license)**

</div>

---

## 📖 Table of Contents

- [About](#about)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Scripts](#scripts)
- [License](#license)

---

<a id="about"></a>

## About

ForexScalpingBot is a multi-target trading demo that combines a SwiftUI experience, a stock-trading companion app, and a Node-backed service layer. The repo focuses on forex-style dashboards, watchlists, paper trading flows, charts, and data views that make the app feel closer to a product than a prototype.

<a id="features"></a>

## Features

- SwiftUI dashboards for trading, signals, settings, and journaling.
- Chart-heavy views for hourly, historical, earnings, and news-driven context.
- Paper-trading style models for balances, portfolios, wallets, and watchlists.
- Companion Node service for lightweight persistence and API-style responses.
- Separate iOS app targets that let you open the stock project directly in Xcode.

<a id="tech-stack"></a>

## Tech Stack

**Client**

- SwiftUI
- Swift Package Manager
- Combine
- Xcode

**Server**

- Node.js
- Express
- MongoDB
- Mongoose

**Tooling**

- iOS project files
- npm scripts for the server
- Xcode workspace/project settings

<a id="quick-start"></a>

## Quick Start

### Prerequisites

- Xcode 15+
- Swift 5+
- Node.js 20+
- npm

### Run the Node backend

```bash
cd Server
npm install
npm run server
```

### Open the iOS app

```bash
open TradingApp/Stock.xcodeproj
```

### Run the Swift package target

```bash
swift run ForexScalpingBot
```

<a id="project-structure"></a>

## Project Structure

```text
ForexScalpingBot/
├── ForexScalpingBot/   # SwiftUI app, view models, and services
├── TradingApp/Stock/   # Xcode stock app target and assets
├── Server/             # Node service and persistence models
├── imgs/               # Preview images used in the README
└── readme.md           # Project documentation
```

<a id="scripts"></a>

## Scripts

| Command | Purpose |
| --- | --- |
| `cd Server && npm run server` | Start the Node backend with nodemon |
| `swift run ForexScalpingBot` | Launch the Swift package target |
| `open TradingApp/Stock.xcodeproj` | Open the stock app in Xcode |
| `npm install` | Install server dependencies |

<a id="license"></a>

## License

The backend service is licensed under MIT in [`Server/LICENSE`](Server/LICENSE). Refer to the repository files for the full licensing context.

[↑ Back to Top](#top)
