# Finance Tracker

A personal finance management application built with Flutter that helps users track their assets, calculate depreciation, and monitor monthly financial activities.

![App Screenshot](assets/screenshots/app_preview.png)

## Features

### Assets Management
- **Multi-currency Support**: Track assets in different currencies (USD, EUR, JPY, IDR)
- **Asset Categories**: Organize assets into types (Transactional, Savings, Investment)
- **Asset Summary**: See total assets by currency with percentage breakdown by category
- **Real-time Formatting**: Thousand separators appear as you type for better readability
- **Multiple Selection**: Select and manage multiple assets simultaneously
- **Sorting Options**: Sort assets by name, value, or date

### Depreciation Tracking (Coming Soon)
- Track the depreciation of your valuable assets over time
- Set depreciation rates and methods for different asset types
- Visualize depreciation curves to understand value reduction
- Generate depreciation schedules for tax and accounting purposes

### Monthly Financial Tracker (Coming Soon)
- Record monthly income and expenses
- Categorize transactions for better financial insights
- View spending patterns and trends
- Set budgets and receive notifications when approaching limits
- Generate monthly financial reports

## Getting Started

### Prerequisites
- Flutter SDK (version 3.6.0 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
```bash
git clone https://github.com/your-username/finance_tracker.git
```

2. Navigate to the project directory
```bash
cd finance_tracker
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## Tech Stack

- **Flutter**: UI framework
- **SQLite**: Local database (via sqflite)
- **Shared Preferences**: User settings storage
- **Intl**: Internationalization and formatting

## Contributing

Contributions are welcome! If you'd like to contribute, please:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- The Flutter team for creating an amazing framework
- All contributors who have helped shape this project
