//+------------------------------------------------------------------+
//|                     TradeExecutor.mqh                             |
//|                  Trade Execution Management                       |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __TRADE_EXECUTOR_MQH__
#define __TRADE_EXECUTOR_MQH__

#include "Enums.mqh"
#include "Structures.mqh"
#include "Config.mqh"
#include "Logger.mqh"

extern CLogger Logger;

//--- Trade Executor class
class CTradeExecutor {
private:
   CTrade       m_trade;
   ulong        m_magic_number;
   bool         m_initialized;
   int          m_last_error;
   
public:
   CTradeExecutor();
   ~CTradeExecutor();
   
   bool Initialize(ulong magic_number);
   
   // Trade execution
   bool OpenBuyPosition(double lot_size, double stop_loss, double take_profit);
   bool OpenSellPosition(double lot_size, double stop_loss, double take_profit);
   bool ClosePosition(ulong ticket);
   bool ModifyPosition(ulong ticket, double stop_loss, double take_profit);
   
   // Accessors
   int  GetLastError() const;
   bool IsInitialized() const;
   ulong GetMagicNumber() const;
};

//--- Trade Executor constructor
CTradeExecutor::CTradeExecutor() {
   m_magic_number = 0;
   m_initialized = false;
   m_last_error = 0;
}

//--- Trade Executor destructor
CTradeExecutor::~CTradeExecutor() {
}

//+------------------------------------------------------------------+
//| Initialize Trade Executor                                         |
//+------------------------------------------------------------------+
bool CTradeExecutor::Initialize(ulong magic_number) {
   m_magic_number = magic_number;
   
   // Set trade parameters
   m_trade.SetExpertMagicNumber(m_magic_number);
   m_trade.SetTypeFillingBySymbol(_Symbol);
   m_trade.LogLevel(0);  // Disable internal logging
   
   m_initialized = true;
   
   Logger.Log(LOG_INFO, StringFormat(
      "TradeExecutor initialized - Magic: %d",
      m_magic_number
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Open BUY position                                                  |
//+------------------------------------------------------------------+
bool CTradeExecutor::OpenBuyPosition(double lot_size, double stop_loss, double take_profit) {
   if (!m_initialized) {
      Logger.Log(LOG_ERROR, "TradeExecutor not initialized");
      return false;
   }
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if (ask <= 0) {
      Logger.Log(LOG_ERROR, "Invalid ASK price");
      return false;
   }
   
   // Calculate SL and TP in absolute prices
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double sl = ask - (stop_loss * point);
   double tp = ask + (take_profit * point);
   
   // Adjust for pip precision
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   if (!m_trade.Buy(lot_size, _Symbol, 0, sl, tp)) {
      m_last_error = m_trade.ResultRetcode();
      Logger.Log(LOG_ERROR, StringFormat(
         "Failed to open BUY: %s (code: %d)",
         m_trade.ResultRetcodeDescription(),
         m_last_error
      ));
      return false;
   }
   
   Logger.Log(LOG_INFO, StringFormat(
      "BUY opened - Ticket: %d, Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f",
      m_trade.ResultOrder(),
      lot_size,
      ask,
      sl,
      tp
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Open SELL position                                                 |
//+------------------------------------------------------------------+
bool CTradeExecutor::OpenSellPosition(double lot_size, double stop_loss, double take_profit) {
   if (!m_initialized) {
      Logger.Log(LOG_ERROR, "TradeExecutor not initialized");
      return false;
   }
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if (bid <= 0) {
      Logger.Log(LOG_ERROR, "Invalid BID price");
      return false;
   }
   
   // Calculate SL and TP in absolute prices
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double sl = bid + (stop_loss * point);
   double tp = bid - (take_profit * point);
   
   // Adjust for pip precision
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   if (!m_trade.Sell(lot_size, _Symbol, 0, sl, tp)) {
      m_last_error = m_trade.ResultRetcode();
      Logger.Log(LOG_ERROR, StringFormat(
         "Failed to open SELL: %s (code: %d)",
         m_trade.ResultRetcodeDescription(),
         m_last_error
      ));
      return false;
   }
   
   Logger.Log(LOG_INFO, StringFormat(
      "SELL opened - Ticket: %d, Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f",
      m_trade.ResultOrder(),
      lot_size,
      bid,
      sl,
      tp
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Close position                                                    |
//+------------------------------------------------------------------+
bool CTradeExecutor::ClosePosition(ulong ticket) {
   if (!m_initialized) {
      Logger.Log(LOG_ERROR, "TradeExecutor not initialized");
      return false;
   }
   
   if (!PositionSelectByTicket(ticket)) {
      Logger.Log(LOG_ERROR, StringFormat("Position %d not found", ticket));
      return false;
   }
   
   if (!m_trade.PositionClose(ticket)) {
      m_last_error = m_trade.ResultRetcode();
      Logger.Log(LOG_ERROR, StringFormat(
         "Failed to close position %d: %s",
         ticket,
         m_trade.ResultRetcodeDescription()
      ));
      return false;
   }
   
   Logger.Log(LOG_INFO, StringFormat("Position %d closed", ticket));
   return true;
}

//+------------------------------------------------------------------+
//| Modify position                                                   |
//+------------------------------------------------------------------+
bool CTradeExecutor::ModifyPosition(ulong ticket, double stop_loss, double take_profit) {
   if (!m_initialized) {
      Logger.Log(LOG_ERROR, "TradeExecutor not initialized");
      return false;
   }
   
   if (!PositionSelectByTicket(ticket)) {
      Logger.Log(LOG_ERROR, StringFormat("Position %d not found", ticket));
      return false;
   }
   
   double sl = NormalizeDouble(stop_loss, _Digits);
   double tp = NormalizeDouble(take_profit, _Digits);
   
   if (!m_trade.PositionModify(ticket, sl, tp)) {
      m_last_error = m_trade.ResultRetcode();
      Logger.Log(LOG_ERROR, StringFormat(
         "Failed to modify position %d: %s",
         ticket,
         m_trade.ResultRetcodeDescription()
      ));
      return false;
   }
   
   Logger.Log(LOG_INFO, StringFormat(
      "Position %d modified - SL: %.5f, TP: %.5f",
      ticket,
      sl,
      tp
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Get last error                                                    |
//+------------------------------------------------------------------+
int CTradeExecutor::GetLastError() const {
   return m_last_error;
}

//+------------------------------------------------------------------+
//| Check if initialized                                              |
//+------------------------------------------------------------------+
bool CTradeExecutor::IsInitialized() const {
   return m_initialized;
}

//+------------------------------------------------------------------+
//| Get magic number                                                  |
//+------------------------------------------------------------------+
ulong CTradeExecutor::GetMagicNumber() const {
   return m_magic_number;
}

#endif
//+------------------------------------------------------------------+
