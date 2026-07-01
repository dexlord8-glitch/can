//+------------------------------------------------------------------+
//|                    PositionManager.mqh                            |
//|                  Position Tracking and Management                 |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __POSITION_MANAGER_MQH__
#define __POSITION_MANAGER_MQH__

#include "Enums.mqh"
#include "Structures.mqh"
#include "Config.mqh"
#include "Logger.mqh"

extern CLogger Logger;

//--- Position Manager class
class CPositionManager {
private:
   ulong       m_magicNumber;
   int         m_maxPositions;
   PositionData m_positions[];
   double      m_totalProfit;
   double      m_maxDrawdown;
   double      m_breakEvenLevel;
   
public:
   CPositionManager();
   ~CPositionManager();
   
   bool Initialize(ulong magic_number, int max_positions);
   void Update();
   void CloseAllPositions();
   
   // Position information accessors
   int    GetOpenPositionsCount() const;
   int    GetLongPositionsCount() const;
   int    GetShortPositionsCount() const;
   double GetTotalVolume() const;
   double GetTotalProfit() const;
   double GetMaxDrawdown() const;
   double GetAveragePrice() const;
   
   // Position array access
   bool   GetPosition(int index, PositionData &position) const;
   PositionData GetPositionByTicket(ulong ticket) const;
   
   // Position queries
   bool   PositionExists(ulong ticket) const;
   bool   HasOpenPositions() const;
   bool   CanOpenPosition() const;
   int    GetPositionIndexByTicket(ulong ticket) const;
   
   // Position modifications
   bool   ModifyPosition(ulong ticket, double new_sl, double new_tp);
   bool   SetBreakEven(ulong ticket, int offset_pips);
   bool   SetTrailingStop(ulong ticket, int trailing_pips);
   
   // Position metrics
   double GetPositionProfit(ulong ticket) const;
   double GetPositionProfitPercent(ulong ticket) const;
   double GetTotalExposure() const;
   
private:
   void   RefreshPositions();
   void   CalculateMetrics();
   double CalculateDrawdown();
   int    GetPositionIndex(ulong ticket);
};

//--- Position Manager constructor
CPositionManager::CPositionManager() {
   m_magicNumber = 0;
   m_maxPositions = 3;
   m_totalProfit = 0.0;
   m_maxDrawdown = 0.0;
   m_breakEvenLevel = 0.0;
   
   ArrayResize(m_positions, 0);
}

//--- Position Manager destructor
CPositionManager::~CPositionManager() {
   ArrayFree(m_positions);
}

//+------------------------------------------------------------------+
//| Initialize Position Manager                                       |
//+------------------------------------------------------------------+
bool CPositionManager::Initialize(ulong magic_number, int max_positions) {
   m_magicNumber = magic_number;
   m_maxPositions = max_positions;
   
   Logger.Log(LOG_INFO, StringFormat(
      "PositionManager initialized - Magic: %d, Max Positions: %d",
      m_magicNumber,
      m_maxPositions
   ));
   
   RefreshPositions();
   return true;
}

//+------------------------------------------------------------------+
//| Update position manager                                           |
//+------------------------------------------------------------------+
void CPositionManager::Update() {
   RefreshPositions();
   CalculateMetrics();
}

//+------------------------------------------------------------------+
//| Refresh positions from broker                                     |
//+------------------------------------------------------------------+
void CPositionManager::RefreshPositions() {
   ArrayResize(m_positions, 0);
   
   int total_positions = PositionsTotal();
   int position_count = 0;
   
   for (int i = 0; i < total_positions; i++) {
      ulong ticket = PositionGetTicket(i);
      if (ticket <= 0) continue;
      
      if (PositionGetInteger(POSITION_MAGIC) != m_magicNumber) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      ArrayResize(m_positions, position_count + 1);
      
      PositionData pos;
      pos.ticket = ticket;
      pos.symbol = PositionGetString(POSITION_SYMBOL);
      pos.direction = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? DIRECTION_LONG : DIRECTION_SHORT;
      pos.volume = PositionGetDouble(POSITION_VOLUME);
      pos.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      pos.stopLoss = PositionGetDouble(POSITION_SL);
      pos.takeProfit = PositionGetDouble(POSITION_TP);
      pos.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      pos.profit = PositionGetDouble(POSITION_PROFIT);
      pos.profitPercent = (pos.profit / PositionGetDouble(POSITION_VOLUME)) * 100.0;
      pos.openTime = (datetime)PositionGetInteger(POSITION_TIME);
      pos.status = STATUS_OPEN;
      pos.comment = PositionGetString(POSITION_COMMENT);
      
      m_positions[position_count] = pos;
      position_count++;
   }
}

//+------------------------------------------------------------------+
//| Calculate position metrics                                        |
//+------------------------------------------------------------------+
void CPositionManager::CalculateMetrics() {
   m_totalProfit = 0.0;
   
   for (int i = 0; i < ArraySize(m_positions); i++) {
      m_totalProfit += m_positions[i].profit;
   }
   
   m_maxDrawdown = CalculateDrawdown();
}

//+------------------------------------------------------------------+
//| Calculate current drawdown                                        |
//+------------------------------------------------------------------+
double CPositionManager::CalculateDrawdown() {
   if (ArraySize(m_positions) == 0) {
      return 0.0;
   }
   
   double min_profit = m_positions[0].profit;
   
   for (int i = 1; i < ArraySize(m_positions); i++) {
      if (m_positions[i].profit < min_profit) {
         min_profit = m_positions[i].profit;
      }
   }
   
   return (min_profit < 0.0) ? MathAbs(min_profit) : 0.0;
}

//+------------------------------------------------------------------+
//| Get number of open positions                                      |
//+------------------------------------------------------------------+
int CPositionManager::GetOpenPositionsCount() const {
   return ArraySize(m_positions);
}

//+------------------------------------------------------------------+
//| Get number of long positions                                      |
//+------------------------------------------------------------------+
int CPositionManager::GetLongPositionsCount() const {
   int count = 0;
   for (int i = 0; i < ArraySize(m_positions); i++) {
      if (m_positions[i].direction == DIRECTION_LONG) {
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get number of short positions                                     |
//+------------------------------------------------------------------+
int CPositionManager::GetShortPositionsCount() const {
   int count = 0;
   for (int i = 0; i < ArraySize(m_positions); i++) {
      if (m_positions[i].direction == DIRECTION_SHORT) {
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get total volume of all open positions                            |
//+------------------------------------------------------------------+
double CPositionManager::GetTotalVolume() const {
   double total = 0.0;
   for (int i = 0; i < ArraySize(m_positions); i++) {
      total += m_positions[i].volume;
   }
   return total;
}

//+------------------------------------------------------------------+
//| Get total profit of all open positions                            |
//+------------------------------------------------------------------+
double CPositionManager::GetTotalProfit() const {
   return m_totalProfit;
}

//+------------------------------------------------------------------+
//| Get maximum drawdown on open positions                            |
//+------------------------------------------------------------------+
double CPositionManager::GetMaxDrawdown() const {
   return m_maxDrawdown;
}

//+------------------------------------------------------------------+
//| Get average entry price of all positions                          |
//+------------------------------------------------------------------+
double CPositionManager::GetAveragePrice() const {
   if (ArraySize(m_positions) == 0) {
      return 0.0;
   }
   
   double total_cost = 0.0;
   double total_volume = 0.0;
   
   for (int i = 0; i < ArraySize(m_positions); i++) {
      total_cost += m_positions[i].entryPrice * m_positions[i].volume;
      total_volume += m_positions[i].volume;
   }
   
   if (total_volume == 0.0) {
      return 0.0;
   }
   
   return total_cost / total_volume;
}

//+------------------------------------------------------------------+
//| Get position by index                                             |
//+------------------------------------------------------------------+
bool CPositionManager::GetPosition(int index, PositionData &position) const {
   if (index < 0 || index >= ArraySize(m_positions)) {
      return false;
   }
   
   position = m_positions[index];
   return true;
}

//+------------------------------------------------------------------+
//| Get position by ticket                                            |
//+------------------------------------------------------------------+
PositionData CPositionManager::GetPositionByTicket(ulong ticket) const {
   PositionData empty_pos;
   ZeroMemory(empty_pos);
   
   for (int i = 0; i < ArraySize(m_positions); i++) {
      if (m_positions[i].ticket == ticket) {
         return m_positions[i];
      }
   }
   
   return empty_pos;
}

//+------------------------------------------------------------------+
//| Check if position exists                                          |
//+------------------------------------------------------------------+
bool CPositionManager::PositionExists(ulong ticket) const {
   for (int i = 0; i < ArraySize(m_positions); i++) {
      if (m_positions[i].ticket == ticket) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if there are open positions                                 |
//+------------------------------------------------------------------+
bool CPositionManager::HasOpenPositions() const {
   return ArraySize(m_positions) > 0;
}

//+------------------------------------------------------------------+
//| Check if new position can be opened                               |
//+------------------------------------------------------------------+
bool CPositionManager::CanOpenPosition() const {
   return GetOpenPositionsCount() < m_maxPositions;
}

//+------------------------------------------------------------------+
//| Get position index by ticket                                      |
//+------------------------------------------------------------------+
int CPositionManager::GetPositionIndexByTicket(ulong ticket) const {
   for (int i = 0; i < ArraySize(m_positions); i++) {
      if (m_positions[i].ticket == ticket) {
         return i;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Modify position stop loss and take profit                         |
//+------------------------------------------------------------------+
bool CPositionManager::ModifyPosition(ulong ticket, double new_sl, double new_tp) {
   if (!PositionSelectByTicket(ticket)) {
      Logger.Log(LOG_ERROR, StringFormat("Failed to select position %d", ticket));
      return false;
   }
   
   if (!Trade.PositionModify(ticket, new_sl, new_tp)) {
      Logger.Log(LOG_ERROR, StringFormat(
         "Failed to modify position %d: %s",
         ticket,
         Trade.ResultRetcodeDescription()
      ));
      return false;
   }
   
   Logger.Log(LOG_INFO, StringFormat(
      "Position %d modified - SL: %.5f, TP: %.5f",
      ticket,
      new_sl,
      new_tp
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Set break-even stop loss                                          |
//+------------------------------------------------------------------+
bool CPositionManager::SetBreakEven(ulong ticket, int offset_pips) {
   if (!PositionSelectByTicket(ticket)) {
      return false;
   }
   
   double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
   double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
   ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   
   double point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double break_even_price = 0.0;
   
   if (pos_type == POSITION_TYPE_BUY) {
      // For long positions, breakeven is entry price + offset
      if (current_price > entry_price + (offset_pips * point_value)) {
         break_even_price = entry_price + (BREAKEVEN_BUFFER * point_value);
      } else {
         return false;  // Not enough profit
      }
   } else {
      // For short positions, breakeven is entry price - offset
      if (current_price < entry_price - (offset_pips * point_value)) {
         break_even_price = entry_price - (BREAKEVEN_BUFFER * point_value);
      } else {
         return false;  // Not enough profit
      }
   }
   
   return ModifyPosition(ticket, break_even_price, PositionGetDouble(POSITION_TP));
}

//+------------------------------------------------------------------+
//| Set trailing stop loss                                            |
//+------------------------------------------------------------------+
bool CPositionManager::SetTrailingStop(ulong ticket, int trailing_pips) {
   if (!PositionSelectByTicket(ticket)) {
      return false;
   }
   
   double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
   double current_sl = PositionGetDouble(POSITION_SL);
   ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   
   double point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double new_sl = 0.0;
   
   if (pos_type == POSITION_TYPE_BUY) {
      new_sl = current_price - (trailing_pips * point_value);
      if (new_sl > current_sl) {
         return ModifyPosition(ticket, new_sl, PositionGetDouble(POSITION_TP));
      }
   } else {
      new_sl = current_price + (trailing_pips * point_value);
      if (new_sl < current_sl) {
         return ModifyPosition(ticket, new_sl, PositionGetDouble(POSITION_TP));
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get position profit                                               |
//+------------------------------------------------------------------+
double CPositionManager::GetPositionProfit(ulong ticket) const {
   int index = GetPositionIndexByTicket(ticket);
   if (index >= 0) {
      return m_positions[index].profit;
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get position profit percentage                                    |
//+------------------------------------------------------------------+
double CPositionManager::GetPositionProfitPercent(ulong ticket) const {
   int index = GetPositionIndexByTicket(ticket);
   if (index >= 0) {
      return m_positions[index].profitPercent;
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get total exposure (volume * current price)                       |
//+------------------------------------------------------------------+
double CPositionManager::GetTotalExposure() const {
   double exposure = 0.0;
   double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   
   for (int i = 0; i < ArraySize(m_positions); i++) {
      exposure += m_positions[i].volume * contract_size * m_positions[i].currentPrice;
   }
   
   return exposure;
}

//+------------------------------------------------------------------+
//| Close all open positions                                          |
//+------------------------------------------------------------------+
void CPositionManager::CloseAllPositions() {
   for (int i = 0; i < ArraySize(m_positions); i++) {
      if (!Trade.PositionClose(m_positions[i].ticket)) {
         Logger.Log(LOG_ERROR, StringFormat(
            "Failed to close position %d: %s",
            m_positions[i].ticket,
            Trade.ResultRetcodeDescription()
         ));
      }
   }
   
   Logger.Log(LOG_INFO, "All positions closed");
}

#endif
//+------------------------------------------------------------------+
