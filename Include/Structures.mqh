//+------------------------------------------------------------------+
//|                        Structures.mqh                             |
//|                    Data Structure Definitions                     |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __STRUCTURES_MQH__
#define __STRUCTURES_MQH__

#include "Enums.mqh"

//--- Signal data structure
struct SignalData {
   SIGNAL_TYPE type;           // Signal type (BUY/SELL/NONE)
   double      strength;       // Signal strength (0.0 - 1.0)
   double      entryPrice;     // Suggested entry price
   double      stopLoss;       // Stop loss price
   double      takeProfit;     // Take profit price
   double      riskReward;     // Risk/reward ratio
   datetime    timestamp;      // Signal generation time
   string      source;         // Signal source identifier
};

//--- Position data structure
struct PositionData {
   ulong       ticket;         // Position ticket
   string      symbol;         // Trading symbol
   TRADE_DIRECTION direction;  // Trade direction (LONG/SHORT)
   double      volume;         // Position volume
   double      entryPrice;     // Entry price
   double      stopLoss;       // Stop loss level
   double      takeProfit;     // Take profit level
   double      currentPrice;   // Current market price
   double      profit;         // Current profit/loss
   double      profitPercent;  // Profit percentage
   datetime    openTime;       // Position open time
   datetime    closeTime;      // Position close time
   POSITION_STATUS status;     // Position status
   string      comment;        // Position comment
};

//--- Account information structure
struct AccountInfo {
   double      balance;        // Account balance
   double      equity;         // Account equity
   double      credit;         // Account credit
   double      profit;         // Account profit
   double      margin;         // Used margin
   double      freeMargin;     // Free margin
   double      marginLevel;    // Margin level %
   int         openPositions;  // Number of open positions
   int         totalTrades;    // Total trades
   string      currency;       // Account currency
   int         leverage;       // Account leverage
   bool        tradeAllowed;   // Trading allowed flag
};

//--- Risk parameters structure
struct RiskParams {
   double      riskPercent;    // Risk per trade %
   double      maxLotSize;     // Maximum lot size
   double      minLotSize;     // Minimum lot size
   double      maxRiskAmount;  // Maximum risk per trade
   double      maxDrawdown;    // Maximum drawdown %
   int         maxPositions;   // Maximum concurrent positions
   MONEY_MANAGEMENT_MODE mmMode;  // Money management mode
   bool        enableTrailing; // Enable trailing stop
   double      trailingStop;   // Trailing stop in pips
};

//--- Market condition structure
struct MarketCondition {
   TREND_DIRECTION trend;      // Current trend direction
   VOLATILITY_STATE volatility; // Current volatility state
   MARKET_CONDITION condition;  // Market condition
   double      volatilityValue; // Volatility value (ATR)
   double      rsi;            // RSI value
   double      macdValue;      // MACD value
   double      bbUpper;        // Bollinger Bands upper
   double      bbMiddle;       // Bollinger Bands middle
   double      bbLower;        // Bollinger Bands lower
   double      highestHigh;    // Highest high (20 periods)
   double      lowestLow;      // Lowest low (20 periods)
   datetime    lastUpdate;     // Last update time
};

//--- Trade statistics structure
struct TradeStats {
   int         totalTrades;    // Total trades executed
   int         winningTrades;  // Winning trades count
   int         losingTrades;   // Losing trades count
   double      totalProfit;    // Total profit/loss
   double      totalPips;      // Total pips won/lost
   double      winRate;        // Win rate percentage
   double      profitFactor;   // Profit factor (gross profit / gross loss)
   double      avgWin;         // Average win per trade
   double      avgLoss;        // Average loss per trade
   double      maxWin;         // Largest winning trade
   double      maxLoss;        // Largest losing trade
   double      maxDrawdown;    // Maximum drawdown
   double      sharpeRatio;    // Sharpe ratio
};

//--- Order parameters structure
struct OrderParams {
   TRADE_DIRECTION direction;  // Order direction
   ORDER_TYPE_EXTENDED type;   // Order type
   double      volume;         // Order volume (lot size)
   double      price;          // Order price
   double      stopLoss;       // Stop loss price
   double      takeProfit;     // Take profit price
   string      comment;        // Order comment
   ulong       magicNumber;    // Magic number
   int         slippage;       // Allowed slippage in points
   datetime    expiration;     // Order expiration time
};

//--- Technical indicator values structure
struct IndicatorValues {
   double      rsi[3];         // RSI values (current, previous, 2 bars back)
   double      macd[3];        // MACD values
   double      signal[3];      // Signal line values
   double      histogram[3];   // MACD histogram values
   double      stoch[3];       // Stochastic values
   double      stochSignal[3]; // Stochastic signal line
   double      atr;            // Average True Range
   double      adx;            // Average Directional Index
   double      movAvg20;       // 20-period moving average
   double      movAvg50;       // 50-period moving average
   double      movAvg200;      // 200-period moving average
};

//--- Performance metrics structure
struct PerformanceMetrics {
   double      returnPercent;  // Return percentage
   double      volatility;     // Volatility (standard deviation)
   double      sharpeRatio;    // Sharpe ratio
   double      soRatio;        // Sortino ratio
   double      calmarRatio;    // Calmar ratio
   double      maxDrawdown;    // Maximum drawdown
   int         consecutiveWins;   // Consecutive winning trades
   int         consecutiveLosses; // Consecutive losing trades
   double      recoveryFactor; // Recovery factor
};

//--- Trade event structure
struct TradeEvent {
   datetime    timestamp;      // Event timestamp
   ulong       ticket;         // Trade ticket
   string      symbol;         // Trading symbol
   TRADE_DIRECTION direction;  // Trade direction
   double      volume;         // Trade volume
   double      price;          // Execution price
   double      stopLoss;       // Stop loss price
   double      takeProfit;     // Take profit price
   string      eventType;      // Event type (OPEN/CLOSE/MODIFY)
   double      profit;         // Trade profit/loss
   string      comment;        // Event comment
};

//--- Configuration structure
struct ConfigData {
   bool        enableAutoTrading;  // Enable auto trading
   bool        enableLogging;      // Enable logging
   bool        enableSoundAlerts;  // Enable sound alerts
   bool        enableEmailAlerts;  // Enable email alerts
   bool        enablePushNotifications; // Enable push notifications
   int         logLevel;           // Log level (DEBUG/INFO/WARNING/ERROR)
   string      logFilePath;        // Log file path
   int         maxLogFileSize;     // Maximum log file size
   bool        enableBacktesting;  // Enable backtesting mode
   int         backtestStartDate;  // Backtest start date
   int         backtestEndDate;    // Backtest end date
};

#endif
//+------------------------------------------------------------------+
