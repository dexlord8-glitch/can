//+------------------------------------------------------------------+
//|                     GoldPrecisionTraderProX.mq5                  |
//|                   Professional Gold Trading EA                  |
//|                     Version: 1.0 Production                      |
//+------------------------------------------------------------------+
#property copyright "GoldPrecisionTraderProX"
#property link      "https://github.com/dexlord8-glitch/can"
#property version   "1.00"
#property strict
#property description "Advanced algorithmic gold trading system with ML-ready architecture"

//--- Input parameters
input double   InpLotSize          = 0.1;      // Initial lot size
input int      InpMaxPositions     = 3;        // Maximum concurrent positions
input double   InpRiskPercent      = 2.0;      // Risk per trade (%)
input int      InpMagicNumber      = 123456;   // Magic number for trade identification
input bool     InpUseMoneyManagement = true;   // Enable money management
input bool     InpEnableTradeLogging = true;   // Enable trade logging

//--- Include dependencies
#include "Include/Enums.mqh"
#include "Include/Structures.mqh"
#include "Include/Config.mqh"
#include "Include/Logger.mqh"
#include "Include/AccountManager.mqh"
#include "Include/PositionManager.mqh"
#include "Include/RiskManager.mqh"
#include "Include/SignalGenerator.mqh"
#include "Include/TradeExecutor.mqh"

//--- Global variables
CLogger          Logger;
CAccountManager  AccountMgr;
CPositionManager PositionMgr;
CRiskManager     RiskMgr;
CSignalGenerator SignalGen;
CTradeExecutor   TradeEx;

//--- Statistics
struct Statistics {
   int      totalTrades;
   int      winningTrades;
   int      losingTrades;
   double   totalProfit;
   double   maxDrawdown;
   double   profitFactor;
};

Statistics Stats;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // Initialize logger
   Logger.Initialize("GoldPrecisionTraderProX", InpEnableTradeLogging);
   Logger.Log(LOG_INFO, "EA initialization started");
   
   // Validate inputs
   if (!ValidateInputs()) {
      Logger.Log(LOG_ERROR, "Input validation failed");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Initialize managers
   if (!AccountMgr.Initialize(InpMagicNumber)) {
      Logger.Log(LOG_ERROR, "Account manager initialization failed");
      return INIT_RUNTIME_ERROR;
   }
   
   if (!PositionMgr.Initialize(InpMagicNumber, InpMaxPositions)) {
      Logger.Log(LOG_ERROR, "Position manager initialization failed");
      return INIT_RUNTIME_ERROR;
   }
   
   if (!RiskMgr.Initialize(InpRiskPercent, InpLotSize, InpUseMoneyManagement)) {
      Logger.Log(LOG_ERROR, "Risk manager initialization failed");
      return INIT_RUNTIME_ERROR;
   }
   
   if (!SignalGen.Initialize()) {
      Logger.Log(LOG_ERROR, "Signal generator initialization failed");
      return INIT_RUNTIME_ERROR;
   }
   
   if (!TradeEx.Initialize(InpMagicNumber)) {
      Logger.Log(LOG_ERROR, "Trade executor initialization failed");
      return INIT_RUNTIME_ERROR;
   }
   
   // Initialize statistics
   Stats.totalTrades = 0;
   Stats.winningTrades = 0;
   Stats.losingTrades = 0;
   Stats.totalProfit = 0.0;
   Stats.maxDrawdown = 0.0;
   Stats.profitFactor = 0.0;
   
   Logger.Log(LOG_INFO, "EA initialization completed successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Logger.Log(LOG_INFO, "EA deinitialization started");
   
   // Log deinit reason
   string reason_text = GetDeinitReasonText(reason);
   Logger.Log(LOG_INFO, StringFormat("Deinit reason: %s", reason_text));
   
   // Close all positions if needed
   if (reason == REASON_CHARTCLOSE || reason == REASON_CHARTCHANGE) {
      Logger.Log(LOG_WARNING, "Closing EA - closing all open positions");
      PositionMgr.CloseAllPositions();
   }
   
   // Finalize logger
   Logger.Finalize();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // Update market data
   if (!RefreshRates()) {
      Logger.Log(LOG_ERROR, "Failed to refresh rates");
      return;
   }
   
   // Update account information
   AccountMgr.Update();
   
   // Update position manager
   PositionMgr.Update();
   
   // Check if we can trade
   if (!CanTrade()) {
      return;
   }
   
   // Generate trading signals
   SignalData signal = SignalGen.GenerateSignal();
   
   // Process signal
   if (signal.strength > 0.5) {  // Signal threshold
      ProcessTradingSignal(signal);
   }
   
   // Update risk metrics
   UpdateRiskMetrics();
}

//+------------------------------------------------------------------+
//| Validate input parameters                                        |
//+------------------------------------------------------------------+
bool ValidateInputs() {
   if (InpLotSize <= 0) {
      Logger.Log(LOG_ERROR, "Invalid lot size: must be > 0");
      return false;
   }
   
   if (InpMaxPositions <= 0 || InpMaxPositions > 10) {
      Logger.Log(LOG_ERROR, "Invalid max positions: must be between 1 and 10");
      return false;
   }
   
   if (InpRiskPercent <= 0 || InpRiskPercent > 10) {
      Logger.Log(LOG_ERROR, "Invalid risk percent: must be between 0 and 10");
      return false;
   }
   
   if (InpMagicNumber <= 0) {
      Logger.Log(LOG_ERROR, "Invalid magic number: must be > 0");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool CanTrade() {
   // Check if terminal is connected
   if (!TerminalInfoInteger(TERMINAL_CONNECTED)) {
      return false;
   }
   
   // Check if trading is allowed
   if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
      return false;
   }
   
   // Check if expert trading is allowed
   if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Process trading signal                                           |
//+------------------------------------------------------------------+
void ProcessTradingSignal(const SignalData &signal) {
   // Check position limit
   if (PositionMgr.GetOpenPositionsCount() >= InpMaxPositions) {
      Logger.Log(LOG_WARNING, "Maximum positions reached");
      return;
   }
   
   // Calculate lot size with risk management
   double lot_size = RiskMgr.CalculateLotSize(signal.stopLoss);
   
   if (lot_size <= 0) {
      Logger.Log(LOG_WARNING, "Invalid lot size calculated");
      return;
   }
   
   // Execute trade
   if (signal.type == SIGNAL_BUY) {
      TradeEx.OpenBuyPosition(lot_size, signal.stopLoss, signal.takeProfit);
   } else if (signal.type == SIGNAL_SELL) {
      TradeEx.OpenSellPosition(lot_size, signal.stopLoss, signal.takeProfit);
   }
}

//+------------------------------------------------------------------+
//| Update risk metrics                                              |
//+------------------------------------------------------------------+
void UpdateRiskMetrics() {
   double current_profit = PositionMgr.GetTotalProfit();
   double current_drawdown = PositionMgr.GetMaxDrawdown();
   
   // Update drawdown if worse
   if (current_drawdown < Stats.maxDrawdown) {
      Stats.maxDrawdown = current_drawdown;
   }
   
   // Update total profit
   Stats.totalProfit = current_profit;
}

//+------------------------------------------------------------------+
//| Get deinit reason text                                           |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason) {
   switch (reason) {
      case REASON_ACCOUNT:     return "Account changed";
      case REASON_CHARTCHANGE: return "Chart changed";
      case REASON_CHARTCLOSE:  return "Chart closed";
      case REASON_PARAMETERS:  return "Parameters changed";
      case REASON_RECOMPILE:   return "Program recompiled";
      case REASON_REMOVE:      return "Program removed";
      case REASON_TEMPLATE:    return "Template changed";
      default:                 return "Unknown reason";
   }
}

//+------------------------------------------------------------------+
//| Refresh market rates                                             |
//+------------------------------------------------------------------+
bool RefreshRates() {
   int attempts = 0;
   const int MAX_ATTEMPTS = 3;
   
   while (attempts < MAX_ATTEMPTS) {
      if (BarsCalculated(_Symbol, PERIOD_CURRENT) > 0) {
         return true;
      }
      attempts++;
      Sleep(100);
   }
   
   return false;
}
//+------------------------------------------------------------------+
