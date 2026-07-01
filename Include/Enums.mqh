//+------------------------------------------------------------------+
//|                       Enums.mqh                                   |
//|                  Enumeration Definitions                          |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __ENUMS_MQH__
#define __ENUMS_MQH__

//--- Signal types
enum SIGNAL_TYPE {
   SIGNAL_NONE = 0,
   SIGNAL_BUY = 1,
   SIGNAL_SELL = -1,
   SIGNAL_NEUTRAL = 2
};

//--- Trade direction
enum TRADE_DIRECTION {
   TRADE_LONG = 1,
   TRADE_SHORT = -1,
   TRADE_UNDEFINED = 0
};

//--- Position status
enum POSITION_STATUS {
   POS_OPEN = 0,
   POS_PENDING = 1,
   POS_CLOSED = 2,
   POS_ERROR = 3
};

//--- Money management modes
enum MONEY_MANAGEMENT_MODE {
   MM_FIXED_LOT = 0,
   MM_PERCENTAGE = 1,
   MM_MARTINGALE = 2,
   MM_ANTIMARTINGALE = 3,
   MM_KELLY = 4
};

//--- Log levels
enum LOG_LEVEL {
   LOG_DEBUG = 0,
   LOG_INFO = 1,
   LOG_WARNING = 2,
   LOG_ERROR = 3
};

//--- Trend direction
enum TREND_DIRECTION {
   TREND_UP = 1,
   TREND_DOWN = -1,
   TREND_FLAT = 0
};

//--- Volatility state
enum VOLATILITY_STATE {
   VOL_LOW = 0,
   VOL_NORMAL = 1,
   VOL_HIGH = 2,
   VOL_EXTREME = 3
};

//--- Market condition
enum MARKET_CONDITION {
   MARKET_TREND = 0,
   MARKET_RANGE = 1,
   MARKET_BREAKOUT = 2,
   MARKET_CONSOLIDATION = 3,
   MARKET_UNDEFINED = 4
};

//--- Order type extended
enum ORDER_TYPE_EXTENDED {
   ORDER_BUY = ORDER_TYPE_BUY,
   ORDER_SELL = ORDER_TYPE_SELL,
   ORDER_BUY_LIMIT = ORDER_TYPE_BUY_LIMIT,
   ORDER_SELL_LIMIT = ORDER_TYPE_SELL_LIMIT,
   ORDER_BUY_STOP = ORDER_TYPE_BUY_STOP,
   ORDER_SELL_STOP = ORDER_TYPE_SELL_STOP,
   ORDER_BUY_STOP_LIMIT = ORDER_TYPE_BUY_STOP_LIMIT,
   ORDER_SELL_STOP_LIMIT = ORDER_TYPE_SELL_STOP_LIMIT
};

#endif
//+------------------------------------------------------------------+
