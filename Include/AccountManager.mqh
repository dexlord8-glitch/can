//+------------------------------------------------------------------+
//|                    AccountManager.mqh                             |
//|                  Account Information Management                   |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __ACCOUNT_MANAGER_MQH__
#define __ACCOUNT_MANAGER_MQH__

#include "Enums.mqh"
#include "Structures.mqh"
#include "Config.mqh"
#include "Logger.mqh"

extern CLogger Logger;

//--- Account Manager class
class CAccountManager {
private:
   ulong       m_magicNumber;
   AccountInfo m_accountInfo;
   double      m_initialBalance;
   double      m_sessionStartBalance;
   double      m_maxBalance;
   double      m_minBalance;
   
public:
   CAccountManager();
   ~CAccountManager();
   
   bool Initialize(ulong magic_number);
   void Update();
   
   // Account information accessors
   double GetBalance() const;
   double GetEquity() const;
   double GetCredit() const;
   double GetProfit() const;
   double GetMargin() const;
   double GetFreeMargin() const;
   double GetMarginLevel() const;
   int    GetOpenPositions() const;
   int    GetTotalTrades() const;
   string GetCurrency() const;
   int    GetLeverage() const;
   bool   GetTradeAllowed() const;
   
   // Account statistics
   double GetDrawdown() const;
   double GetDrawdownPercent() const;
   double GetSessionProfit() const;
   double GetBalanceChange() const;
   double GetMaxBalance() const;
   double GetMinBalance() const;
   
   // Account validation
   bool   IsAccountValid() const;
   bool   IsSufficientMargin(double lot_size) const;
   bool   CanOpenPosition(double lot_size) const;
   bool   IsDrawdownExceeded(double max_dd) const;
   
   // Account details
   const AccountInfo& GetAccountInfo() const;
   
private:
   void UpdateAccountInfo();
   double CalculateMarginRequired(double lot_size) const;
};

//--- Account Manager constructor
CAccountManager::CAccountManager() {
   m_magicNumber = 0;
   m_initialBalance = 0.0;
   m_sessionStartBalance = 0.0;
   m_maxBalance = 0.0;
   m_minBalance = 0.0;
   
   ZeroMemory(m_accountInfo);
}

//--- Account Manager destructor
CAccountManager::~CAccountManager() {
}

//+------------------------------------------------------------------+
//| Initialize Account Manager                                        |
//+------------------------------------------------------------------+
bool CAccountManager::Initialize(ulong magic_number) {
   m_magicNumber = magic_number;
   
   // Get initial account info
   UpdateAccountInfo();
   
   m_initialBalance = m_accountInfo.balance;
   m_sessionStartBalance = m_accountInfo.balance;
   m_maxBalance = m_accountInfo.balance;
   m_minBalance = m_accountInfo.balance;
   
   Logger.Log(LOG_INFO, StringFormat(
      "AccountManager initialized - Balance: %.2f %s, Leverage: 1:%d",
      m_accountInfo.balance,
      m_accountInfo.currency,
      m_accountInfo.leverage
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Update account information                                        |
//+------------------------------------------------------------------+
void CAccountManager::Update() {
   UpdateAccountInfo();
   
   // Update max/min balance
   if (m_accountInfo.balance > m_maxBalance) {
      m_maxBalance = m_accountInfo.balance;
   }
   if (m_accountInfo.balance < m_minBalance) {
      m_minBalance = m_accountInfo.balance;
   }
}

//+------------------------------------------------------------------+
//| Update internal account info                                      |
//+------------------------------------------------------------------+
void CAccountManager::UpdateAccountInfo() {
   m_accountInfo.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_accountInfo.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   m_accountInfo.credit = AccountInfoDouble(ACCOUNT_CREDIT);
   m_accountInfo.profit = AccountInfoDouble(ACCOUNT_PROFIT);
   m_accountInfo.margin = AccountInfoDouble(ACCOUNT_MARGIN);
   m_accountInfo.freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   m_accountInfo.marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   m_accountInfo.openPositions = PositionsTotal();
   m_accountInfo.totalTrades = HistoryDealsTotal();
   m_accountInfo.currency = AccountInfoString(ACCOUNT_CURRENCY);
   m_accountInfo.leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   m_accountInfo.tradeAllowed = AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) != 0;
}

//+------------------------------------------------------------------+
//| Get account balance                                               |
//+------------------------------------------------------------------+
double CAccountManager::GetBalance() const {
   return m_accountInfo.balance;
}

//+------------------------------------------------------------------+
//| Get account equity                                                |
//+------------------------------------------------------------------+
double CAccountManager::GetEquity() const {
   return m_accountInfo.equity;
}

//+------------------------------------------------------------------+
//| Get account credit                                                |
//+------------------------------------------------------------------+
double CAccountManager::GetCredit() const {
   return m_accountInfo.credit;
}

//+------------------------------------------------------------------+
//| Get account profit                                                |
//+------------------------------------------------------------------+
double CAccountManager::GetProfit() const {
   return m_accountInfo.profit;
}

//+------------------------------------------------------------------+
//| Get used margin                                                   |
//+------------------------------------------------------------------+
double CAccountManager::GetMargin() const {
   return m_accountInfo.margin;
}

//+------------------------------------------------------------------+
//| Get free margin                                                   |
//+------------------------------------------------------------------+
double CAccountManager::GetFreeMargin() const {
   return m_accountInfo.freeMargin;
}

//+------------------------------------------------------------------+
//| Get margin level percentage                                       |
//+------------------------------------------------------------------+
double CAccountManager::GetMarginLevel() const {
   return m_accountInfo.marginLevel;
}

//+------------------------------------------------------------------+
//| Get number of open positions                                      |
//+------------------------------------------------------------------+
int CAccountManager::GetOpenPositions() const {
   return m_accountInfo.openPositions;
}

//+------------------------------------------------------------------+
//| Get total trades                                                  |
//+------------------------------------------------------------------+
int CAccountManager::GetTotalTrades() const {
   return m_accountInfo.totalTrades;
}

//+------------------------------------------------------------------+
//| Get account currency                                              |
//+------------------------------------------------------------------+
string CAccountManager::GetCurrency() const {
   return m_accountInfo.currency;
}

//+------------------------------------------------------------------+
//| Get account leverage                                              |
//+------------------------------------------------------------------+
int CAccountManager::GetLeverage() const {
   return m_accountInfo.leverage;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                       |
//+------------------------------------------------------------------+
bool CAccountManager::GetTradeAllowed() const {
   return m_accountInfo.tradeAllowed;
}

//+------------------------------------------------------------------+
//| Calculate current drawdown in pips                                |
//+------------------------------------------------------------------+
double CAccountManager::GetDrawdown() const {
   if (m_maxBalance <= 0.0) {
      return 0.0;
   }
   return m_maxBalance - m_accountInfo.balance;
}

//+------------------------------------------------------------------+
//| Calculate current drawdown percentage                             |
//+------------------------------------------------------------------+
double CAccountManager::GetDrawdownPercent() const {
   if (m_maxBalance <= 0.0) {
      return 0.0;
   }
   return (GetDrawdown() / m_maxBalance) * 100.0;
}

//+------------------------------------------------------------------+
//| Get session profit (from session start)                           |
//+------------------------------------------------------------------+
double CAccountManager::GetSessionProfit() const {
   return m_accountInfo.balance - m_sessionStartBalance;
}

//+------------------------------------------------------------------+
//| Get balance change from initial balance                           |
//+------------------------------------------------------------------+
double CAccountManager::GetBalanceChange() const {
   return m_accountInfo.balance - m_initialBalance;
}

//+------------------------------------------------------------------+
//| Get maximum balance reached                                       |
//+------------------------------------------------------------------+
double CAccountManager::GetMaxBalance() const {
   return m_maxBalance;
}

//+------------------------------------------------------------------+
//| Get minimum balance reached                                       |
//+------------------------------------------------------------------+
double CAccountManager::GetMinBalance() const {
   return m_minBalance;
}

//+------------------------------------------------------------------+
//| Check if account info is valid                                    |
//+------------------------------------------------------------------+
bool CAccountManager::IsAccountValid() const {
   if (m_accountInfo.balance <= 0.0) {
      Logger.Log(LOG_ERROR, "Invalid account: balance <= 0");
      return false;
   }
   
   if (m_accountInfo.marginLevel < 100.0 && m_accountInfo.marginLevel > 0) {
      Logger.Log(LOG_WARNING, StringFormat("Warning: Margin level low (%.2f%%)", m_accountInfo.marginLevel));
      return false;
   }
   
   if (!m_accountInfo.tradeAllowed) {
      Logger.Log(LOG_ERROR, "Trading not allowed on account");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if sufficient margin for lot size                           |
//+------------------------------------------------------------------+
bool CAccountManager::IsSufficientMargin(double lot_size) const {
   double margin_required = CalculateMarginRequired(lot_size);
   
   if (margin_required > m_accountInfo.freeMargin) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Insufficient margin: required %.2f, available %.2f",
         margin_required,
         m_accountInfo.freeMargin
      ));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if can open position                                        |
//+------------------------------------------------------------------+
bool CAccountManager::CanOpenPosition(double lot_size) const {
   if (!IsAccountValid()) {
      return false;
   }
   
   if (!IsSufficientMargin(lot_size)) {
      return false;
   }
   
   // Check if lot size is within limits
   if (lot_size < MIN_LOT_SIZE || lot_size > MAX_LOT_SIZE) {
      Logger.Log(LOG_WARNING, StringFormat(
         "Lot size out of range: %.2f (min: %.2f, max: %.2f)",
         lot_size,
         MIN_LOT_SIZE,
         MAX_LOT_SIZE
      ));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if drawdown exceeded                                        |
//+------------------------------------------------------------------+
bool CAccountManager::IsDrawdownExceeded(double max_dd) const {
   return GetDrawdownPercent() > max_dd;
}

//+------------------------------------------------------------------+
//| Get account info structure                                        |
//+------------------------------------------------------------------+
const AccountInfo& CAccountManager::GetAccountInfo() const {
   return m_accountInfo;
}

//+------------------------------------------------------------------+
//| Calculate margin required for lot size                            |
//+------------------------------------------------------------------+
double CAccountManager::CalculateMarginRequired(double lot_size) const {
   // Get contract size (usually 100000 for standard lot)
   double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   
   // Get bid price
   double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Calculate margin: lot_size * contract_size * bid_price / leverage
   if (contract_size <= 0.0 || bid_price <= 0.0 || m_accountInfo.leverage <= 0) {
      return 0.0;
   }
   
   return (lot_size * contract_size * bid_price) / m_accountInfo.leverage;
}

#endif
//+------------------------------------------------------------------+
