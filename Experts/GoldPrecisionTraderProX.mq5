//+------------------------------------------------------------------+
//|                    GoldPrecisionTraderProX.mq5                    |
//|                     Main Expert Advisor                           |
//|                  GoldPrecisionTraderProX v1.0                     |
//|                  Forex Trading System for Gold                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://github.com/dexlord8-glitch/can"
#property version   "1.00"
#property strict

#include "Include/Enums.mqh"
#include "Include/Structures.mqh"
#include "Include/Config.mqh"
#include "Include/Logger.mqh"
#include "Include/AccountManager.mqh"
#include "Include/PositionManager.mqh"
#include "Include/RiskManager.mqh"
#include "Include/SignalGenerator.mqh"

//--- Global objects
CLogger              Logger;
CAccountManager      AccountManager;
CPositionManager     PositionManager;
CRiskManager         RiskManager;
CSignalGenerator     SignalGenerator;
CTrade               Trade;

//--- Input parameters
input bool           Enable_Trading = true;              // Enable Trading
input string         Trading_Symbol = "XAUUSD";         // Trading Symbol
input ENUM_TIMEFRAMES Trading_Timeframe = PERIOD_H1;    // Trading Timeframe
input double         Risk_Percent = 2.0;                // Risk Percent per trade
input double         Base_Lot_Size = 0.1;               // Base Lot Size
input bool           Use_Money_Management = true;       // Use Money Management
input int            Max_Positions = 3;                 // Maximum Open Positions
input int            Max_Drawdown_Percent = 15;         // Maximum Drawdown %
input bool           Use_Breakeven = true;              // Use Break-Even
input bool           Use_Trailing_Stop = true;          // Use Trailing Stop
input int            Trailing_Stop_Pips = 20;           // Trailing Stop (pips)
input bool           Log_Enabled = true;                // Enable Logging
input LOG_LEVEL      Log_Level = LOG_INFO;              // Log Level

//--- Expert Advisor variables
bool                 m_initialized = false;
datetime             m_last_signal_time = 0;
SIGNAL_TYPE          m_last_signal_type = SIGNAL_NEUTRAL;
int                  m_total_trades = 0;
double               m_total_profit = 0.0;
datetime             m_start_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   m_start_time = TimeCurrent();
   
   // Initialize Logger
   if (!Logger.Initialize(Log_Enabled, Log_Level)) {
      Alert("Failed to initialize Logger");
      return INIT_FAILED;
   }
   
   Logger.Log(LOG_INFO, "========================================");
   Logger.Log(LOG_INFO, "GoldPrecisionTraderProX v1.0 Starting");
   Logger.Log(LOG_INFO, "========================================");
   
   // Validate inputs
   if (Risk_Percent <= 0 || Risk_Percent > MAX_RISK_PERCENT) {
      Logger.Log(LOG_ERROR, StringFormat("Invalid Risk Percent: %.2f", Risk_Percent));
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if (Base_Lot_Size <= 0 || Base_Lot_Size > MAX_LOT_SIZE) {
      Logger.Log(LOG_ERROR, StringFormat("Invalid Base Lot Size: %.2f", Base_Lot_Size));
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Set trading symbol and timeframe
   if (_Symbol != Trading_Symbol) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Chart symbol (%s) differs from trading symbol (%s)",
         _Symbol,
         Trading_Symbol
      ));
   }
   
   // Initialize Account Manager
   if (!AccountManager.Initialize(MAGIC_NUMBER)) {
      Logger.Log(LOG_ERROR, "Failed to initialize AccountManager");
      return INIT_FAILED;
   }
   
   // Initialize Position Manager
   if (!PositionManager.Initialize(MAGIC_NUMBER, Max_Positions)) {
      Logger.Log(LOG_ERROR, "Failed to initialize PositionManager");
      return INIT_FAILED;
   }
   
   // Initialize Risk Manager
   if (!RiskManager.Initialize(Risk_Percent, Base_Lot_Size, Use_Money_Management)) {
      Logger.Log(LOG_ERROR, "Failed to initialize RiskManager");
      return INIT_FAILED;
   }
   
   // Initialize Signal Generator
   if (!SignalGenerator.Initialize(Trading_Symbol, Trading_Timeframe)) {
      Logger.Log(LOG_ERROR, "Failed to initialize SignalGenerator");
      return INIT_FAILED;
   }
   
   // Set trade parameters
   Trade.SetExpertMagicNumber(MAGIC_NUMBER);
   Trade.SetTypeFillingBySymbol(Trading_Symbol);
   Trade.LogLevel(0);  // Disable trade logging (we handle it)
   
   m_initialized = true;
   
   Logger.Log(LOG_INFO, "Expert Advisor initialized successfully");
   Logger.Log(LOG_INFO, StringFormat("Account Balance: %.2f %s",
      AccountManager.GetBalance(),
      AccountManager.GetCurrency()
   ));
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Logger.Log(LOG_INFO, "Expert Advisor shutting down");
   Logger.Log(LOG_INFO, StringFormat("Session Summary:"));
   Logger.Log(LOG_INFO, StringFormat("  Total Trades: %d", m_total_trades));
   Logger.Log(LOG_INFO, StringFormat("  Total Profit: %.2f", m_total_profit));
   Logger.Log(LOG_INFO, StringFormat("  Final Balance: %.2f", AccountManager.GetBalance()));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   if (!m_initialized) {
      return;
   }
   
   if (!Enable_Trading) {
      return;
   }
   
   // Update all managers
   AccountManager.Update();
   PositionManager.Update();
   RiskManager.Update(AccountManager.GetBalance());
   SignalGenerator.Update();
   
   // Check account validity
   if (!AccountManager.IsAccountValid()) {
      Logger.Log(LOG_ERROR, "Account validation failed - stopping trading");
      return;
   }
   
   // Check drawdown limit
   if (AccountManager.IsDrawdownExceeded(Max_Drawdown_Percent)) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Drawdown limit exceeded: %.2f%% (max: %.2f%%)",
         AccountManager.GetDrawdownPercent(),
         Max_Drawdown_Percent
      ));
      return;
   }
   
   // Process positions
   ProcessPositions();
   
   // Generate signals
   const SignalData& signal = SignalGenerator.GetCurrentSignal();
   
   // Check for new signal
   if (signal.signalType != SIGNAL_NEUTRAL && signal.confirmed) {
      if (signal.signalType != m_last_signal_type || TimeCurrent() - m_last_signal_time > SIGNAL_COOLDOWN) {
         ExecuteSignal(signal);
         m_last_signal_type = signal.signalType;
         m_last_signal_time = TimeCurrent();
      }
   }
   
   // Display information
   DisplayInfo();
}

//+------------------------------------------------------------------+
//| Process existing positions                                        |
//+------------------------------------------------------------------+
void ProcessPositions() {
   for (int i = 0; i < PositionManager.GetOpenPositionsCount(); i++) {
      PositionData pos;
      if (!PositionManager.GetPosition(i, pos)) {
         continue;
      }
      
      // Apply break-even
      if (Use_Breakeven) {
         ApplyBreakEven(pos);
      }
      
      // Apply trailing stop
      if (Use_Trailing_Stop) {
         ApplyTrailingStop(pos);
      }
      
      // Check take profit conditions
      CheckTakeProfitConditions(pos);
   }
}

//+------------------------------------------------------------------+
//| Apply break-even stop loss                                        |
//+------------------------------------------------------------------+
void ApplyBreakEven(const PositionData &position) {
   if (position.profitPercent >= BREAKEVEN_TRIGGER) {
      PositionManager.SetBreakEven(position.ticket, BREAKEVEN_BUFFER);
   }
}

//+------------------------------------------------------------------+
//| Apply trailing stop loss                                          |
//+------------------------------------------------------------------+
void ApplyTrailingStop(const PositionData &position) {
   if (position.profit > 0) {
      PositionManager.SetTrailingStop(position.ticket, Trailing_Stop_Pips);
   }
}

//+------------------------------------------------------------------+
//| Check take profit conditions                                      |
//+------------------------------------------------------------------+
void CheckTakeProfitConditions(const PositionData &position) {
   // Close if profit target is hit
   if (position.profit >= position.takeProfit) {
      if (Trade.PositionClose(position.ticket)) {
         Logger.Log(LOG_INFO, StringFormat(
            "Position %d closed - Profit target hit: %.2f",
            position.ticket,
            position.profit
         ));
      }
   }
}

//+------------------------------------------------------------------+
//| Execute trading signal                                            |
//+------------------------------------------------------------------+
void ExecuteSignal(const SignalData &signal) {
   // Check if can open new position
   if (!PositionManager.CanOpenPosition()) {
      Logger.Log(LOG_WARNING, "Maximum positions reached - cannot open new trade");
      return;
   }
   
   // Calculate entry parameters
   double stop_loss_pips = 0.0;
   double take_profit_pips = 0.0;
   double entry_price = 0.0;
   
   if (signal.signalType == SIGNAL_BUY) {
      entry_price = SymbolInfoDouble(signal.symbol, SYMBOL_ASK);
      stop_loss_pips = DEFAULT_STOP_LOSS;
      take_profit_pips = DEFAULT_TAKE_PROFIT;
   } else if (signal.signalType == SIGNAL_SELL) {
      entry_price = SymbolInfoDouble(signal.symbol, SYMBOL_BID);
      stop_loss_pips = DEFAULT_STOP_LOSS;
      take_profit_pips = DEFAULT_TAKE_PROFIT;
   } else {
      return;
   }
   
   // Calculate lot size
   double lot_size = RiskManager.CalculateLotSize(stop_loss_pips);
   
   // Validate lot size
   if (!RiskManager.IsLotSizeValid(lot_size)) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Invalid lot size: %.2f",
         lot_size
      ));
      return;
   }
   
   // Validate risk
   if (!RiskManager.IsRiskAcceptable(lot_size, stop_loss_pips)) {
      Logger.Log(LOG_WARNING, "Risk exceeds acceptable level");
      return;
   }
   
   // Calculate SL and TP
   double point = SymbolInfoDouble(signal.symbol, SYMBOL_POINT);
   double sl = 0.0;
   double tp = 0.0;
   
   if (signal.signalType == SIGNAL_BUY) {
      sl = entry_price - (stop_loss_pips * point);
      tp = entry_price + (take_profit_pips * point);
      
      if (!Trade.Buy(lot_size, signal.symbol, 0, sl, tp, "GoldPrecisionTraderProX BUY")) {
         Logger.Log(LOG_ERROR, StringFormat(
            "Failed to open BUY position: %s",
            Trade.ResultRetcodeDescription()
         ));
         return;
      }
      
      Logger.Log(LOG_INFO, StringFormat(
         "BUY position opened - Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f, Signal Strength: %d%%",
         lot_size,
         entry_price,
         sl,
         tp,
         signal.strength
      ));
   } else if (signal.signalType == SIGNAL_SELL) {
      sl = entry_price + (stop_loss_pips * point);
      tp = entry_price - (take_profit_pips * point);
      
      if (!Trade.Sell(lot_size, signal.symbol, 0, sl, tp, "GoldPrecisionTraderProX SELL")) {
         Logger.Log(LOG_ERROR, StringFormat(
            "Failed to open SELL position: %s",
            Trade.ResultRetcodeDescription()
         ));
         return;
      }
      
      Logger.Log(LOG_INFO, StringFormat(
         "SELL position opened - Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f, Signal Strength: %d%%",
         lot_size,
         entry_price,
         sl,
         tp,
         signal.strength
      ));
   }
   
   m_total_trades++;
}

//+------------------------------------------------------------------+
//| Display trading information                                       |
//+------------------------------------------------------------------+
void DisplayInfo() {
   // Prepare display string
   string info_text = "";
   
   info_text += "=== GoldPrecisionTraderProX v1.0 ===\n";
   info_text += StringFormat("Time: %s\n", TimeToString(TimeCurrent()));
   info_text += "\n--- Account Info ---\n";
   info_text += StringFormat("Balance: %.2f %s\n", AccountManager.GetBalance(), AccountManager.GetCurrency());
   info_text += StringFormat("Equity: %.2f\n", AccountManager.GetEquity());
   info_text += StringFormat("Margin Level: %.2f%%\n", AccountManager.GetMarginLevel());
   info_text += StringFormat("Drawdown: %.2f%% (Max: %.2f%%)\n", 
      AccountManager.GetDrawdownPercent(), 
      Max_Drawdown_Percent
   );
   
   info_text += "\n--- Positions ---\n";
   info_text += StringFormat("Open Positions: %d\n", PositionManager.GetOpenPositionsCount());
   info_text += StringFormat("Long: %d | Short: %d\n", 
      PositionManager.GetLongPositionsCount(),
      PositionManager.GetShortPositionsCount()
   );
   info_text += StringFormat("Total Volume: %.2f\n", PositionManager.GetTotalVolume());
   info_text += StringFormat("Total Profit: %.2f\n", PositionManager.GetTotalProfit());
   
   info_text += "\n--- Signals ---\n";
   const SignalData& signal = SignalGenerator.GetCurrentSignal();
   string signal_text = "NEUTRAL";
   if (signal.signalType == SIGNAL_BUY) signal_text = "BUY";
   else if (signal.signalType == SIGNAL_SELL) signal_text = "SELL";
   
   info_text += StringFormat("Signal: %s\n", signal_text);
   info_text += StringFormat("Strength: %d%%\n", signal.strength);
   info_text += StringFormat("Confirmed: %s\n", signal.confirmed ? "Yes" : "No");
   
   info_text += "\n--- Indicators ---\n";
   info_text += StringFormat("RSI: %.2f\n", SignalGenerator.GetRSI());
   info_text += StringFormat("MACD: %.5f\n", SignalGenerator.GetMACD());
   info_text += StringFormat("ADX: %.2f\n", SignalGenerator.GetADX());
   info_text += StringFormat("ATR: %.5f\n", SignalGenerator.GetATR());
   
   info_text += "\n--- Statistics ---\n";
   info_text += StringFormat("Total Trades: %d\n", m_total_trades);
   info_text += StringFormat("Running Time: %d minutes\n", (TimeCurrent() - m_start_time) / 60);
   
   // Display on chart
   Comment(info_text);
}

//+------------------------------------------------------------------+
//| Handle tester start                                              |
//+------------------------------------------------------------------+
void OnStart() {
   Logger.Log(LOG_INFO, "Backtesting started");
}

//+------------------------------------------------------------------+
//| Handle chart event                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if (id == CHARTEVENT_KEYDOWN) {
      if (sparam == "q") {
         Logger.Log(LOG_INFO, "Manual exit requested by user");
         ExpertRemove();
      }
   }
}

//+------------------------------------------------------------------+
//| End of Expert Advisor                                             |
//+------------------------------------------------------------------+
