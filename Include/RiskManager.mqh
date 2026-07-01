//+------------------------------------------------------------------+
//|                     RiskManager.mqh                               |
//|                  Risk Calculation and Management                  |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __RISK_MANAGER_MQH__
#define __RISK_MANAGER_MQH__

#include "Enums.mqh"
#include "Structures.mqh"
#include "Config.mqh"
#include "Logger.mqh"

extern CLogger Logger;

//--- Risk Manager class
class CRiskManager {
private:
   double      m_riskPercent;
   double      m_baseLotSize;
   bool        m_useMoneyManagement;
   double      m_maxLotSize;
   double      m_minLotSize;
   MONEY_MANAGEMENT_MODE m_mmMode;
   double      m_accountBalance;
   
public:
   CRiskManager();
   ~CRiskManager();
   
   bool Initialize(double risk_percent, double base_lot, bool use_mm);
   void Update(double current_balance);
   
   // Lot size calculation
   double CalculateLotSize(double stop_loss_pips);
   double CalculateLotSizeByRisk(double risk_amount);
   double CalculateLotSizePercentage(double risk_percent);
   double CalculateLotSizeATR(double atr_value, double atr_multiple);
   
   // Risk parameters
   double GetRiskPercent() const;
   double GetRiskAmount() const;
   double GetMaxRiskAmount() const;
   double GetAccountBalance() const;
   double GetMaxLotSize() const;
   double GetMinLotSize() const;
   MONEY_MANAGEMENT_MODE GetMMMode() const;
   
   // Risk validation
   bool   IsLotSizeValid(double lot_size) const;
   bool   IsRiskAcceptable(double lot_size, double stop_loss_pips) const;
   bool   IsRiskWithinLimits(double risk_amount) const;
   
   // Risk calculation
   double CalculateRiskAmount(double lot_size, double stop_loss_pips) const;
   double CalculateExpectedProfit(double lot_size, double take_profit_pips) const;
   double CalculateRiskRewardRatio(double stop_loss_pips, double take_profit_pips) const;
   double CalculateMaxStopLoss(double lot_size) const;
   
   // Position sizing
   double OptimizePositionSize(double equity, double risk_percent, double stop_loss_pips);
   double AdjustLotSizeForMargin(double lot_size, double margin_level) const;
   double GetMaxAllowedLotSize() const;
   
   // Money management strategies
   double MartingaleCalculation(int losing_streak) const;
   double AntiMartingaleCalculation(int winning_streak) const;
   double KellyCriterion(double win_rate, double avg_win, double avg_loss) const;
   
private:
   double NormalizeLotSize(double lot_size) const;
   double GetPoint() const;
   double GetTickSize() const;
};

//--- Risk Manager constructor
CRiskManager::CRiskManager() {
   m_riskPercent = DEFAULT_RISK_PERCENT;
   m_baseLotSize = DEFAULT_LOT_SIZE;
   m_useMoneyManagement = true;
   m_maxLotSize = MAX_LOT_SIZE;
   m_minLotSize = MIN_LOT_SIZE;
   m_mmMode = MM_FIXED_LOT;
   m_accountBalance = 0.0;
}

//--- Risk Manager destructor
CRiskManager::~CRiskManager() {
}

//+------------------------------------------------------------------+
//| Initialize Risk Manager                                           |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(double risk_percent, double base_lot, bool use_mm) {
   if (risk_percent <= 0 || risk_percent > MAX_RISK_PERCENT) {
      Logger.Log(LOG_ERROR, StringFormat(
         "Invalid risk percent: %.2f (max: %.2f)",
         risk_percent,
         MAX_RISK_PERCENT
      ));
      return false;
   }
   
   if (base_lot <= 0 || base_lot > MAX_LOT_SIZE) {
      Logger.Log(LOG_ERROR, StringFormat(
         "Invalid base lot: %.2f (max: %.2f)",
         base_lot,
         MAX_LOT_SIZE
      ));
      return false;
   }
   
   m_riskPercent = risk_percent;
   m_baseLotSize = base_lot;
   m_useMoneyManagement = use_mm;
   m_mmMode = MM_PERCENTAGE;
   m_accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   Logger.Log(LOG_INFO, StringFormat(
      "RiskManager initialized - Risk: %.2f%%, Base Lot: %.2f, MM: %s",
      m_riskPercent,
      m_baseLotSize,
      m_useMoneyManagement ? "Enabled" : "Disabled"
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Update risk manager with current balance                          |
//+------------------------------------------------------------------+
void CRiskManager::Update(double current_balance) {
   m_accountBalance = current_balance;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on stop loss                             |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double stop_loss_pips) {
   if (stop_loss_pips <= 0) {
      Logger.Log(LOG_WARNING, "Invalid stop loss pips");
      return m_baseLotSize;
   }
   
   if (!m_useMoneyManagement) {
      return NormalizeLotSize(m_baseLotSize);
   }
   
   // Calculate risk amount
   double risk_amount = (m_accountBalance * m_riskPercent) / 100.0;
   
   // Get pip value in account currency
   double point = GetPoint();
   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * point;
   
   // Calculate lot size: risk_amount / (stop_loss_pips * pip_value)
   double lot_size = risk_amount / (stop_loss_pips * pip_value);
   
   return NormalizeLotSize(lot_size);
}

//+------------------------------------------------------------------+
//| Calculate lot size by risk amount                                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSizeByRisk(double risk_amount) {
   if (risk_amount <= 0) {
      return m_baseLotSize;
   }
   
   double point = GetPoint();
   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * point;
   double default_sl = DEFAULT_STOP_LOSS;
   
   if (default_sl <= 0) {
      return m_baseLotSize;
   }
   
   double lot_size = risk_amount / (default_sl * pip_value);
   return NormalizeLotSize(lot_size);
}

//+------------------------------------------------------------------+
//| Calculate lot size as percentage of account                       |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSizePercentage(double risk_percent) {
   if (risk_percent <= 0 || risk_percent > 100) {
      return m_baseLotSize;
   }
   
   double risk_amount = (m_accountBalance * risk_percent) / 100.0;
   return CalculateLotSizeByRisk(risk_amount);
}

//+------------------------------------------------------------------+
//| Calculate lot size based on ATR                                   |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSizeATR(double atr_value, double atr_multiple) {
   if (atr_value <= 0 || atr_multiple <= 0) {
      return m_baseLotSize;
   }
   
   double point = GetPoint();
   double stop_loss_pips = atr_value * atr_multiple / point;
   
   return CalculateLotSize(stop_loss_pips);
}

//+------------------------------------------------------------------+
//| Get risk percent                                                  |
//+------------------------------------------------------------------+
double CRiskManager::GetRiskPercent() const {
   return m_riskPercent;
}

//+------------------------------------------------------------------+
//| Get risk amount in account currency                               |
//+------------------------------------------------------------------+
double CRiskManager::GetRiskAmount() const {
   return (m_accountBalance * m_riskPercent) / 100.0;
}

//+------------------------------------------------------------------+
//| Get maximum risk amount                                           |
//+------------------------------------------------------------------+
double CRiskManager::GetMaxRiskAmount() const {
   return (m_accountBalance * MAX_RISK_PERCENT) / 100.0;
}

//+------------------------------------------------------------------+
//| Get account balance                                               |
//+------------------------------------------------------------------+
double CRiskManager::GetAccountBalance() const {
   return m_accountBalance;
}

//+------------------------------------------------------------------+
//| Get maximum lot size                                              |
//+------------------------------------------------------------------+
double CRiskManager::GetMaxLotSize() const {
   return m_maxLotSize;
}

//+------------------------------------------------------------------+
//| Get minimum lot size                                              |
//+------------------------------------------------------------------+
double CRiskManager::GetMinLotSize() const {
   return m_minLotSize;
}

//+------------------------------------------------------------------+
//| Get money management mode                                         |
//+------------------------------------------------------------------+
MONEY_MANAGEMENT_MODE CRiskManager::GetMMMode() const {
   return m_mmMode;
}

//+------------------------------------------------------------------+
//| Validate lot size                                                 |
//+------------------------------------------------------------------+
bool CRiskManager::IsLotSizeValid(double lot_size) const {
   if (lot_size < m_minLotSize) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Lot size too small: %.2f (min: %.2f)",
         lot_size,
         m_minLotSize
      ));
      return false;
   }
   
   if (lot_size > m_maxLotSize) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Lot size too large: %.2f (max: %.2f)",
         lot_size,
         m_maxLotSize
      ));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if risk is acceptable                                       |
//+------------------------------------------------------------------+
bool CRiskManager::IsRiskAcceptable(double lot_size, double stop_loss_pips) const {
   double risk_amount = CalculateRiskAmount(lot_size, stop_loss_pips);
   double max_risk = GetMaxRiskAmount();
   
   if (risk_amount > max_risk) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Risk exceeds maximum: %.2f > %.2f",
         risk_amount,
         max_risk
      ));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if risk is within limits                                    |
//+------------------------------------------------------------------+
bool CRiskManager::IsRiskWithinLimits(double risk_amount) const {
   return risk_amount <= GetMaxRiskAmount();
}

//+------------------------------------------------------------------+
//| Calculate risk amount for lot size and stop loss                  |
//+------------------------------------------------------------------+
double CRiskManager::CalculateRiskAmount(double lot_size, double stop_loss_pips) const {
   if (lot_size <= 0 || stop_loss_pips <= 0) {
      return 0.0;
   }
   
   double point = GetPoint();
   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * point;
   
   return lot_size * stop_loss_pips * pip_value;
}

//+------------------------------------------------------------------+
//| Calculate expected profit for lot size and take profit            |
//+------------------------------------------------------------------+
double CRiskManager::CalculateExpectedProfit(double lot_size, double take_profit_pips) const {
   if (lot_size <= 0 || take_profit_pips <= 0) {
      return 0.0;
   }
   
   double point = GetPoint();
   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * point;
   
   return lot_size * take_profit_pips * pip_value;
}

//+------------------------------------------------------------------+
//| Calculate risk/reward ratio                                       |
//+------------------------------------------------------------------+
double CRiskManager::CalculateRiskRewardRatio(double stop_loss_pips, double take_profit_pips) const {
   if (stop_loss_pips <= 0 || take_profit_pips <= 0) {
      return 0.0;
   }
   
   return take_profit_pips / stop_loss_pips;
}

//+------------------------------------------------------------------+
//| Calculate maximum stop loss for lot size                          |
//+------------------------------------------------------------------+
double CRiskManager::CalculateMaxStopLoss(double lot_size) const {
   if (lot_size <= 0) {
      return 0.0;
   }
   
   double risk_amount = GetRiskAmount();
   double point = GetPoint();
   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * point;
   
   if (lot_size * pip_value <= 0) {
      return 0.0;
   }
   
   return risk_amount / (lot_size * pip_value);
}

//+------------------------------------------------------------------+
//| Optimize position size for equity and risk                        |
//+------------------------------------------------------------------+
double CRiskManager::OptimizePositionSize(double equity, double risk_percent, double stop_loss_pips) {
   if (equity <= 0 || risk_percent <= 0 || stop_loss_pips <= 0) {
      return m_baseLotSize;
   }
   
   double risk_amount = (equity * risk_percent) / 100.0;
   double point = GetPoint();
   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * point;
   
   double lot_size = risk_amount / (stop_loss_pips * pip_value);
   
   return NormalizeLotSize(lot_size);
}

//+------------------------------------------------------------------+
//| Adjust lot size based on margin level                             |
//+------------------------------------------------------------------+
double CRiskManager::AdjustLotSizeForMargin(double lot_size, double margin_level) const {
   // Reduce lot size if margin level is too low
   if (margin_level < 200.0) {
      return lot_size * 0.5;  // Reduce by 50%
   }
   if (margin_level < 300.0) {
      return lot_size * 0.75;  // Reduce by 25%
   }
   return lot_size;
}

//+------------------------------------------------------------------+
//| Get maximum allowed lot size based on margin                      |
//+------------------------------------------------------------------+
double CRiskManager::GetMaxAllowedLotSize() const {
   double free_margin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   if (contract_size <= 0 || bid_price <= 0 || leverage <= 0) {
      return m_baseLotSize;
   }
   
   // Max lot = (free_margin * leverage) / (contract_size * bid_price)
   double max_lot = (free_margin * leverage) / (contract_size * bid_price);
   
   return MathMin(max_lot, m_maxLotSize);
}

//+------------------------------------------------------------------+
//| Martingale lot calculation                                        |
//+------------------------------------------------------------------+
double CRiskManager::MartingaleCalculation(int losing_streak) const {
   if (losing_streak <= 0) {
      return m_baseLotSize;
   }
   
   // Double the lot size for each loss: lot * 2^losses
   double martingale_lot = m_baseLotSize * MathPow(2.0, losing_streak);
   
   return NormalizeLotSize(martingale_lot);
}

//+------------------------------------------------------------------+
//| Anti-Martingale lot calculation                                   |
//+------------------------------------------------------------------+
double CRiskManager::AntiMartingaleCalculation(int winning_streak) const {
   if (winning_streak <= 0) {
      return m_baseLotSize;
   }
   
   // Increase lot size gradually with wins
   double anti_martingale_lot = m_baseLotSize * (1.0 + (0.1 * winning_streak));
   
   return NormalizeLotSize(anti_martingale_lot);
}

//+------------------------------------------------------------------+
//| Kelly Criterion position sizing                                   |
//+------------------------------------------------------------------+
double CRiskManager::KellyCriterion(double win_rate, double avg_win, double avg_loss) const {
   if (win_rate <= 0 || win_rate >= 1.0 || avg_win <= 0 || avg_loss <= 0) {
      return m_baseLotSize;
   }
   
   double loss_rate = 1.0 - win_rate;
   
   // Kelly % = (win_rate * avg_win - loss_rate * avg_loss) / avg_win
   double kelly_percent = (win_rate * avg_win - loss_rate * avg_loss) / avg_win;
   
   if (kelly_percent <= 0) {
      return m_baseLotSize;
   }
   
   // Use half Kelly for safety
   kelly_percent = kelly_percent / 2.0;
   
   return CalculateLotSizePercentage(kelly_percent * 100.0);
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker's step                               |
//+------------------------------------------------------------------+
double CRiskManager::NormalizeLotSize(double lot_size) const {
   if (lot_size < m_minLotSize) {
      lot_size = m_minLotSize;
   }
   if (lot_size > m_maxLotSize) {
      lot_size = m_maxLotSize;
   }
   
   // Round to broker's lot step (usually 0.01)
   lot_size = NormalizeDouble(lot_size / LOT_STEP, 0) * LOT_STEP;
   
   return lot_size;
}

//+------------------------------------------------------------------+
//| Get point value                                                   |
//+------------------------------------------------------------------+
double CRiskManager::GetPoint() const {
   return SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Get tick size                                                     |
//+------------------------------------------------------------------+
double CRiskManager::GetTickSize() const {
   return SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
}

#endif
//+------------------------------------------------------------------+
