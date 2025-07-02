# MQL5 High Low Breakout Algorithm

[![License](https://img.shields.io/badge/license-Educational-blue.svg)](https://github.com)
[![MT5](https://img.shields.io/badge/platform-MT5-green.svg)](https://www.metatrader5.com/)
[![MQL5](https://img.shields.io/badge/language-MQL5-orange.svg)](https://www.mql5.com/)

## ⚠️ **IMPORTANT DISCLAIMER**

**This trading algorithm is provided for informational and educational purposes only.**

By using this algorithm, you acknowledge and agree to the following terms:

1. **Not Financial Advice** – This algorithm does not constitute financial, investment, legal, or trading advice. I am **not** a licensed financial advisor. Any decisions made using this algorithm are solely your responsibility.

2. **No Guarantees of Performance** – There are no assurances regarding the accuracy, reliability, or profitability of this algorithm. Past performance does not guarantee future results, and market conditions may change unpredictably.

3. **Risk Acknowledgment** – Trading involves substantial financial risk, including the potential loss of capital. You should only trade with funds you can afford to lose and conduct independent research before making any trading decisions.

4. **Limitation of Liability** – Under no circumstances shall I be held liable for any direct, indirect, incidental, or consequential losses or damages resulting from the use or misuse of this algorithm.

5. **User Responsibility** – You assume full responsibility for any trades executed using this algorithm. It is your duty to ensure compliance with applicable financial regulations and risk management practices.

6. **Consult a Professional** – If you require financial advice, you should consult a licensed financial advisor. This algorithm is for educational purposes only and should not be relied upon for making financial decisions.

**By using this algorithm, you acknowledge that you understand and accept these terms. If you do not agree, do NOT use this algorithm.**

---

## 📋 Overview

This MQL5 Expert Advisor implements a High Low Breakout trading strategy that identifies and trades based on significant support and resistance levels. The algorithm analyzes historical price data within a specified lookback period to detect high and low touch points, creating trading opportunities when price breaks through these established levels.

### How It Works

1. **Level Detection**: The algorithm scans the last X candles (configurable via input parameter) to identify significant highs and lows
2. **Confirmation Logic**: It counts the number of touches on potential support/resistance levels
3. **Signal Generation**: Once the required number of touches is confirmed (also configurable), a horizontal line is drawn on the chart
4. **Trade Execution**: When price breaks through the confirmed level, a buy or sell order is executed automatically
5. **Risk Management**: The EA includes comprehensive risk management features including trailing stops, breakeven functionality, and drawdown protection

## ✨ Key Features

### Core Trading Features
- **Dynamic Level Detection**: Automatically identifies support and resistance levels based on historical price action
- **Configurable Parameters**: Customizable lookback period and touch confirmation requirements
- **Fast Execution**: Trade execution speeds under 300ms to 1 second
- **Clean Chart Display**: Automatically removes previous day's lines to keep charts uncluttered

### Risk Management
- **Trailing Stop Loss**: Advanced trailing stop mechanism with customizable increments
- **Breakeven Functionality**: Automatically moves stop loss to breakeven when profitable
- **Add-to-Winners Logic**: Scales into winning positions after initial stop loss moves to breakeven
- **Drawdown Protection**: Built-in drawdown limit to protect account equity
- **Spread Filter**: Configurable spread filtering to avoid trading during high-spread conditions

### Advanced Features
- **News Filter**: Pause trading around news events with customizable time windows
- **Time Filter**: Restrict trading to specific time periods
- **Cost Calculation**: Real-time calculation of spreads and commissions for accurate P&L tracking
- **Signal Counter**: Tracks and displays the number of executed signals
- **Mobile Notifications**: Push notifications for trade placements and modifications
- **Email Alerts**: Email notifications for EA initialization/deinitialization (VPS-friendly)
- **On-Screen Display**: Live spread information and upcoming news events

### Technical Specifications
- **Code Length**: Under 700 lines of optimized code
- **Dependencies**: No external DLLs or services required
- **Error Handling**: Comprehensive error handling with detailed error messages
- **Performance**: Optimized for speed and reliability

## 🚀 Installation Guide

### Prerequisites
- MetaTrader 5 platform installed
- Active trading account (demo or live)
- Basic understanding of MT5 Expert Advisors

### Step-by-Step Installation

1. **Locate the Experts Folder**
   - Option A: Navigate to your MT5 installation directory → `MQL5` → `Experts`
   - Option B: In MT5, click `File` → `Open Data Folder` → `MQL5` → `Experts`

2. **Install the Expert Advisor**
   - Copy the `HighLowBreakoutAlgorithm.ex5` file to the Experts folder
   - Restart MetaTrader 5 or press `Ctrl+R` to refresh

3. **Apply to Chart**
   - Open the desired trading chart
   - In the Navigator panel, expand "Expert Advisors"
   - Find "High Low Breakout Algorithm"
   - Drag and drop the EA onto your chart

4. **Configure Settings**
   - Adjust input parameters according to your trading preferences
   - Ensure "Allow Algo Trading" is enabled (button in the toolbar)
   - Click "OK" to activate the EA

### Optional Configurations

#### Mobile Notifications Setup
- Open MetaTrader 5 mobile app
- Navigate to Settings → Notifications
- Copy your MetaQuotes ID
- Enter this ID in the EA's notification settings

#### Email Notifications Setup
- Configure SMTP server settings in MT5
- Go to Tools → Options → Email
- Enter your email server details
- Test the connection before activating EA email notifications

## ⚙️ Configuration Parameters

The EA includes numerous input parameters for customization:

### Core Strategy Settings
- **Lookback Period**: Number of candles to analyze for high/low detection
- **Touch Confirmation**: Required number of touches to confirm a level
- **Signal Threshold**: Minimum price movement to trigger trades

### Risk Management
- **Stop Loss**: Initial stop loss distance
- **Take Profit**: Target profit level
- **Trailing Stop**: Trailing stop activation and increment settings
- **Maximum Drawdown**: Account protection limit
- **Position Size**: Risk per trade settings

### Filters and Conditions
- **Spread Filter**: Maximum allowed spread for trade execution
- **Time Filter**: Trading hours restriction
- **News Filter**: Time buffer around news events
- **Minimum Gap**: Minimum distance between support/resistance levels

## 📊 Performance Features

- **Real-time P&L Tracking**: Live monitoring of open positions
- **Cost Analysis**: Detailed breakdown of trading costs (spreads, commissions)
- **Signal Statistics**: Historical performance tracking
- **Risk Metrics**: Drawdown monitoring and account protection

## 🛠️ Troubleshooting

### Common Issues
1. **EA Not Trading**: Ensure algo trading is enabled and account has sufficient margin
2. **No Notifications**: Verify MetaQuotes ID and SMTP settings
3. **High Spread Errors**: Adjust spread filter settings for your broker
4. **Time Filter Issues**: Check your broker's server time zone settings

### Error Handling
The EA includes comprehensive error handling for:
- Invalid trade parameters
- Insufficient margin
- Market closure periods
- Connection issues
- Invalid input parameters

## 📈 Usage Tips

1. **Backtesting**: Always backtest the strategy on historical data before live trading
2. **Demo Trading**: Test on a demo account to familiarize yourself with the EA's behavior
3. **Parameter Optimization**: Adjust settings based on your trading style and market conditions
4. **Regular Monitoring**: While automated, regular monitoring is recommended
5. **Risk Management**: Never risk more than you can afford to lose

## 🤝 Development Notes

- **AI-Generated Base**: Initial code generated using AI technology
- **Manual Debugging**: Extensively tested and debugged manually
- **Continuous Improvement**: Regular updates and optimizations
- **Educational Purpose**: Designed primarily for learning and educational use

## 📄 License

This project is provided for educational purposes only. See the disclaimer section for important legal information.

## 📞 Support

For questions or issues related to this EA, please refer to the troubleshooting section or consult the MT5 community forums.

---

**Remember: Trading involves risk. Always trade responsibly and within your means.**
