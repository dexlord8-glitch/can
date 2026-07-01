//+------------------------------------------------------------------+
//|                         Config.mqh                                |
//|                  Configuration Constants                          |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __CONFIG_MQH__
#define __CONFIG_MQH__

//--- EA Identification
#define EA_NAME              "GoldPrecisionTraderProX"
#define EA_VERSION           "1.00"
#define EA_AUTHOR            "GoldPrecisionTraderProX Team"
#define EA_COPYRIGHT         "GoldPrecisionTraderProX 2026"

//--- Trading Defaults
#define DEFAULT_MAGIC_NUMBER 123456
#define DEFAULT_SYMBOL       "XAUUSD"
#define DEFAULT_TIMEFRAME    PERIOD_H1
#define DEFAULT_SLIPPAGE     10

//--- Lot Size Parameters
#define MIN_LOT_SIZE         0.01
#define MAX_LOT_SIZE         100.0
#define DEFAULT_LOT_SIZE     0.1
#define LOT_STEP             0.01

//--- Risk Management
#define DEFAULT_RISK_PERCENT 2.0
#define MAX_RISK_PERCENT     10.0
#define MIN_RISK_PERCENT     0.1
#define DEFAULT_STOP_LOSS    50    // in pips
#define DEFAULT_TAKE_PROFIT  100   // in pips

//--- Position Management
#define MAX_POSITIONS        10
#define MIN_POSITIONS        1
#define DEFAULT_MAX_POSITIONS 3

//--- Money Management Modes
#define MM_MODE_FIXED        0     // Fixed lot size
#define MM_MODE_PERCENT      1     // Percentage of account
#define MM_MODE_MARTINGALE   2     // Martingale strategy

//--- ATR Settings
#define ATR_PERIOD           14
#define ATR_MULTIPLIER_SL    1.5
#define ATR_MULTIPLIER_TP    2.5

//--- Moving Average Settings
#define MA_FAST_PERIOD       20
#define MA_SLOW_PERIOD       50
#define MA_SIGNAL_PERIOD     200
#define MA_METHOD            MODE_SMA
#define MA_PRICE_TYPE        PRICE_CLOSE

//--- RSI Settings
#define RSI_PERIOD           14
#define RSI_OVERBOUGHT       70
#define RSI_OVERSOLD         30
#define RSI_THRESHOLD        5    // Threshold for signal strength

//--- MACD Settings
#define MACD_FAST            12
#define MACD_SLOW            26
#define MACD_SIGNAL          9
#define MACD_THRESHOLD       0.0001

//--- Stochastic Settings
#define STOCH_K_PERIOD       5
#define STOCH_D_PERIOD       3
#define STOCH_SLOWING        3
#define STOCH_OVERBOUGHT     80
#define STOCH_OVERSOLD       20

//--- Bollinger Bands Settings
#define BB_PERIOD            20
#define BB_DEVIATION         2.0
#define BB_THRESHOLD         0.5   // % of band width

//--- ADX Settings
#define ADX_PERIOD           14
#define ADX_STRONG_TREND     25    // Strong trend threshold
#define ADX_WEAK_TREND       20    // Weak trend threshold

//--- Volatility Settings
#define VOLATILITY_LOW       0.0005
#define VOLATILITY_NORMAL    0.001
#define VOLATILITY_HIGH      0.002
#define VOLATILITY_EXTREME   0.003

//--- Time Settings
#define TRADING_HOUR_START   8     // London session start (8:00 GMT)
#define TRADING_HOUR_END     22    // New York session end (22:00 GMT)
#define TOKYO_HOUR_START     22    // Tokyo session start (22:00 GMT previous day)
#define SYDNEY_HOUR_START    0     // Sydney session start

//--- Drawdown Settings
#define MAX_DAILY_DRAWDOWN   5.0   // Maximum daily drawdown %
#define MAX_MONTHLY_DRAWDOWN 10.0  // Maximum monthly drawdown %
#define MAX_TOTAL_DRAWDOWN   20.0  // Maximum total drawdown %

//--- Trailing Stop Settings
#define TRAILING_STOP_PIPS   30
#define TRAILING_STEP_PIPS   5
#define MIN_PROFIT_FOR_TRAIL 20

//--- Break-even Settings
#define BREAKEVEN_PIPS       10
#define BREAKEVEN_BUFFER     2

//--- Logging Settings
#define LOG_FILE_NAME        "GoldPrecisionTraderProX.log"
#define LOG_MAX_SIZE         1048576     // 1 MB
#define ENABLE_FILE_LOGGING  true
#define ENABLE_JOURNAL_LOGGING true

//--- Alert Settings
#define ENABLE_SOUND_ALERTS  false
#define ENABLE_EMAIL_ALERTS  false
#define ENABLE_PUSH_ALERTS   false
#define ALERT_SOUND_FILE     "alert.wav"

//--- Optimization Settings
#define OPTIMIZE_BY_PROFIT   0
#define OPTIMIZE_BY_SHARPE   1
#define OPTIMIZE_BY_WINRATE  2
#define OPTIMIZE_BY_DRAWDOWN 3

//--- Order Expiration (in minutes)
#define ORDER_EXPIRY_LIMIT   60
#define ORDER_EXPIRY_STOP    480   // 8 hours

//--- Retry Settings
#define MAX_RETRIES          3
#define RETRY_DELAY_MS       100

//--- Correlation Settings
#define CORRELATION_SYMBOLS  {"EURUSD", "GBPUSD", "USDJPY"}
#define CORRELATION_PERIOD   20
#define MAX_CORRELATION      0.9   // Maximum acceptable correlation

//--- Performance Metrics
#define MIN_WIN_RATE         0.40  // 40% minimum win rate
#define MIN_PROFIT_FACTOR    1.5   // 1.5 minimum profit factor
#define MAX_CONSECUTIVE_LOSS 5     // Maximum consecutive losses allowed

//--- Session Filters
#define USE_SESSION_FILTER   false
#define FILTER_SESSION       SESSION_LONDON

//--- Breakout Settings
#define BREAKOUT_PERIOD      20
#define BREAKOUT_METHOD      0     // 0=HighLow, 1=Channels

//--- Scalping Settings
#define SCALP_MIN_PROFIT     10    // Minimum pips for scalp
#define SCALP_TIMEOUT        5     // Scalp timeout in minutes
#define SCALP_ENABLED        false

//--- Hedging Settings
#define ENABLE_HEDGING       false
#define HEDGE_RATIO          0.5   // Hedge 50% of position

//--- News Trading Settings
#define NEWS_TRADING_ENABLED false
#define NEWS_TIME_BUFFER     60    // Minutes before/after news

//--- Spread Settings
#define MAX_SPREAD_PIPS      20
#define MIN_SPREAD_PIPS      1

//--- Commission Settings
#define COMMISSION_TYPE      0     // 0=Fixed, 1=Percentage
#define COMMISSION_VALUE     5.0   // Points or %

//--- Market Conditions
#define TREND_THRESHOLD      50    // Trend strength threshold
#define RANGE_THRESHOLD      20    // Range detection threshold
#define VOLATILITY_MA_PERIOD 20    // MA period for volatility calc

//--- Neural Network / ML Settings (Future expansion)
#define ML_ENABLED           false
#define ML_UPDATE_PERIOD     60    // Update period in minutes
#define ML_CONFIDENCE_LEVEL  0.75  // Minimum confidence level

//--- System Settings
#define USE_ECN_MODE         true
#define USE_FILLED_ORDERS    true
#define CHECK_PERMISSIONS    true
#define SAFE_MODE            true

//--- Backtesting Settings
#define BACKTEST_START_YEAR  2020
#define BACKTEST_START_MONTH 1
#define BACKTEST_START_DAY   1
#define BACKTEST_END_YEAR    2025
#define BACKTEST_END_MONTH   12
#define BACKTEST_END_DAY     31

//--- Version Control
#define BUILD_DATE           __DATE__
#define BUILD_TIME           __TIME__
#define MQL_VERSION          5

#endif
//+------------------------------------------------------------------+
