//+------------------------------------------------------------------+
//|                    SignalGenerator.mqh                            |
//|                   Trading Signal Generation Engine                |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __SIGNAL_GENERATOR_MQH__
#define __SIGNAL_GENERATOR_MQH__

#include "Enums.mqh"
#include "Structures.mqh"
#include "Config.mqh"
#include "Logger.mqh"

extern CLogger Logger;

//--- Signal Generator class
class CSignalGenerator {
private:
   string      m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   SignalData  m_currentSignal;
   SignalData  m_previousSignal;
   
   // Technical indicators
   double      m_rsi[];
   double      m_macd[];
   double      m_macdSignal[];
   double      m_macdHistogram[];
   double      m_stoch[];
   double      m_bb_upper[];
   double      m_bb_lower[];
   double      m_bb_middle[];
   double      m_atr[];
   double      m_adx[];
   double      m_ma_fast[];
   double      m_ma_slow[];
   
   int         m_bars;
   
public:
   CSignalGenerator();
   ~CSignalGenerator();
   
   bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe);
   void Update();
   
   // Signal generation
   SignalData GenerateSignal();
   SIGNAL_TYPE AnalyzeSignal();
   
   // Indicator analysis
   SIGNAL_TYPE AnalyzeRSI();
   SIGNAL_TYPE AnalyzeMACD();
   SIGNAL_TYPE AnalyzeStochastic();
   SIGNAL_TYPE AnalyzeBollingerBands();
   SIGNAL_TYPE AnalyzeMovingAverages();
   SIGNAL_TYPE AnalyzeADX();
   SIGNAL_TYPE AnalyzeATR();
   
   // Confirmation
   bool ConfirmSignal(SIGNAL_TYPE signal);
   int  GetSignalStrength();
   
   // Accessors
   const SignalData& GetCurrentSignal() const;
   const SignalData& GetPreviousSignal() const;
   double GetRSI(int index = 0) const;
   double GetMACD(int index = 0) const;
   double GetATR(int index = 0) const;
   double GetADX(int index = 0) const;
   
private:
   void CalculateIndicators();
   void UpdateRSI();
   void UpdateMACD();
   void UpdateStochastic();
   void UpdateBollingerBands();
   void UpdateATR();
   void UpdateADX();
   void UpdateMovingAverages();
};

//--- Signal Generator constructor
CSignalGenerator::CSignalGenerator() {
   m_symbol = "";
   m_timeframe = PERIOD_H1;
   m_bars = 0;
   
   ArrayResize(m_rsi, 0);
   ArrayResize(m_macd, 0);
   ArrayResize(m_macdSignal, 0);
   ArrayResize(m_macdHistogram, 0);
   ArrayResize(m_stoch, 0);
   ArrayResize(m_bb_upper, 0);
   ArrayResize(m_bb_lower, 0);
   ArrayResize(m_bb_middle, 0);
   ArrayResize(m_atr, 0);
   ArrayResize(m_adx, 0);
   ArrayResize(m_ma_fast, 0);
   ArrayResize(m_ma_slow, 0);
   
   ZeroMemory(m_currentSignal);
   ZeroMemory(m_previousSignal);
}

//--- Signal Generator destructor
CSignalGenerator::~CSignalGenerator() {
   ArrayFree(m_rsi);
   ArrayFree(m_macd);
   ArrayFree(m_macdSignal);
   ArrayFree(m_macdHistogram);
   ArrayFree(m_stoch);
   ArrayFree(m_bb_upper);
   ArrayFree(m_bb_lower);
   ArrayFree(m_bb_middle);
   ArrayFree(m_atr);
   ArrayFree(m_adx);
   ArrayFree(m_ma_fast);
   ArrayFree(m_ma_slow);
}

//+------------------------------------------------------------------+
//| Initialize Signal Generator                                       |
//+------------------------------------------------------------------+
bool CSignalGenerator::Initialize(string symbol, ENUM_TIMEFRAMES timeframe) {
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_bars = Bars(m_symbol, m_timeframe);
   
   // Allocate arrays
   ArrayResize(m_rsi, m_bars);
   ArrayResize(m_macd, m_bars);
   ArrayResize(m_macdSignal, m_bars);
   ArrayResize(m_macdHistogram, m_bars);
   ArrayResize(m_stoch, m_bars);
   ArrayResize(m_bb_upper, m_bars);
   ArrayResize(m_bb_lower, m_bars);
   ArrayResize(m_bb_middle, m_bars);
   ArrayResize(m_atr, m_bars);
   ArrayResize(m_adx, m_bars);
   ArrayResize(m_ma_fast, m_bars);
   ArrayResize(m_ma_slow, m_bars);
   
   Logger.Log(LOG_INFO, StringFormat(
      "SignalGenerator initialized - Symbol: %s, Timeframe: %d",
      m_symbol,
      m_timeframe
   ));
   
   Update();
   return true;
}

//+------------------------------------------------------------------+
//| Update signal generator                                           |
//+------------------------------------------------------------------+
void CSignalGenerator::Update() {
   m_previousSignal = m_currentSignal;
   CalculateIndicators();
   m_currentSignal = GenerateSignal();
}

//+------------------------------------------------------------------+
//| Calculate all technical indicators                                |
//+------------------------------------------------------------------+
void CSignalGenerator::CalculateIndicators() {
   UpdateRSI();
   UpdateMACD();
   UpdateStochastic();
   UpdateBollingerBands();
   UpdateATR();
   UpdateADX();
   UpdateMovingAverages();
}

//+------------------------------------------------------------------+
//| Update RSI indicator                                              |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateRSI() {
   int handle = iRSI(m_symbol, m_timeframe, RSI_PERIOD, PRICE_CLOSE);
   if (handle != INVALID_HANDLE) {
      CopyBuffer(handle, 0, 0, m_bars, m_rsi);
      IndicatorRelease(handle);
   }
}

//+------------------------------------------------------------------+
//| Update MACD indicator                                             |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateMACD() {
   int handle = iMACD(m_symbol, m_timeframe, MACD_FAST, MACD_SLOW, MACD_SIGNAL, PRICE_CLOSE);
   if (handle != INVALID_HANDLE) {
      CopyBuffer(handle, 0, 0, m_bars, m_macd);
      CopyBuffer(handle, 1, 0, m_bars, m_macdSignal);
      CopyBuffer(handle, 2, 0, m_bars, m_macdHistogram);
      IndicatorRelease(handle);
   }
}

//+------------------------------------------------------------------+
//| Update Stochastic indicator                                       |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateStochastic() {
   int handle = iStochastic(m_symbol, m_timeframe, STOCH_K_PERIOD, STOCH_D_PERIOD, STOCH_SLOWING, MODE_SMA, STO_LOWHIGH);
   if (handle != INVALID_HANDLE) {
      CopyBuffer(handle, 0, 0, m_bars, m_stoch);
      IndicatorRelease(handle);
   }
}

//+------------------------------------------------------------------+
//| Update Bollinger Bands indicator                                  |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateBollingerBands() {
   int handle = iBands(m_symbol, m_timeframe, BB_PERIOD, 0, BB_DEVIATION, PRICE_CLOSE);
   if (handle != INVALID_HANDLE) {
      CopyBuffer(handle, 0, 0, m_bars, m_bb_upper);
      CopyBuffer(handle, 1, 0, m_bars, m_bb_middle);
      CopyBuffer(handle, 2, 0, m_bars, m_bb_lower);
      IndicatorRelease(handle);
   }
}

//+------------------------------------------------------------------+
//| Update ATR indicator                                              |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateATR() {
   int handle = iATR(m_symbol, m_timeframe, ATR_PERIOD);
   if (handle != INVALID_HANDLE) {
      CopyBuffer(handle, 0, 0, m_bars, m_atr);
      IndicatorRelease(handle);
   }
}

//+------------------------------------------------------------------+
//| Update ADX indicator                                              |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateADX() {
   int handle = iADX(m_symbol, m_timeframe, ADX_PERIOD);
   if (handle != INVALID_HANDLE) {
      CopyBuffer(handle, 0, 0, m_bars, m_adx);
      IndicatorRelease(handle);
   }
}

//+------------------------------------------------------------------+
//| Update Moving Averages                                            |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateMovingAverages() {
   int handle_fast = iMA(m_symbol, m_timeframe, MA_FAST_PERIOD, 0, MA_METHOD, MA_PRICE_TYPE);
   int handle_slow = iMA(m_symbol, m_timeframe, MA_SLOW_PERIOD, 0, MA_METHOD, MA_PRICE_TYPE);
   
   if (handle_fast != INVALID_HANDLE) {
      CopyBuffer(handle_fast, 0, 0, m_bars, m_ma_fast);
      IndicatorRelease(handle_fast);
   }
   
   if (handle_slow != INVALID_HANDLE) {
      CopyBuffer(handle_slow, 0, 0, m_bars, m_ma_slow);
      IndicatorRelease(handle_slow);
   }
}

//+------------------------------------------------------------------+
//| Generate trading signal                                           |
//+------------------------------------------------------------------+
SignalData CSignalGenerator::GenerateSignal() {
   SignalData signal;
   ZeroMemory(signal);
   
   signal.timestamp = TimeCurrent();
   signal.symbol = m_symbol;
   signal.timeframe = m_timeframe;
   signal.close = Close[0];
   signal.open = Open[0];
   signal.high = High[0];
   signal.low = Low[0];
   
   signal.signalType = AnalyzeSignal();
   signal.strength = GetSignalStrength();
   signal.confirmed = ConfirmSignal(signal.signalType);
   
   return signal;
}

//+------------------------------------------------------------------+
//| Analyze all signals and combine                                   |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeSignal() {
   SIGNAL_TYPE rsi_signal = AnalyzeRSI();
   SIGNAL_TYPE macd_signal = AnalyzeMACD();
   SIGNAL_TYPE stoch_signal = AnalyzeStochastic();
   SIGNAL_TYPE bb_signal = AnalyzeBollingerBands();
   SIGNAL_TYPE ma_signal = AnalyzeMovingAverages();
   
   // Majority vote
   int buy_votes = 0;
   int sell_votes = 0;
   
   if (rsi_signal == SIGNAL_BUY) buy_votes++; else if (rsi_signal == SIGNAL_SELL) sell_votes++;
   if (macd_signal == SIGNAL_BUY) buy_votes++; else if (macd_signal == SIGNAL_SELL) sell_votes++;
   if (stoch_signal == SIGNAL_BUY) buy_votes++; else if (stoch_signal == SIGNAL_SELL) sell_votes++;
   if (bb_signal == SIGNAL_BUY) buy_votes++; else if (bb_signal == SIGNAL_SELL) sell_votes++;
   if (ma_signal == SIGNAL_BUY) buy_votes++; else if (ma_signal == SIGNAL_SELL) sell_votes++;
   
   if (buy_votes > sell_votes) {
      return SIGNAL_BUY;
   } else if (sell_votes > buy_votes) {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Analyze RSI signal                                                |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeRSI() {
   if (ArraySize(m_rsi) < 2) return SIGNAL_NEUTRAL;
   
   double current_rsi = m_rsi[0];
   
   if (current_rsi < RSI_OVERSOLD) {
      return SIGNAL_BUY;
   } else if (current_rsi > RSI_OVERBOUGHT) {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Analyze MACD signal                                               |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeMACD() {
   if (ArraySize(m_macd) < 2) return SIGNAL_NEUTRAL;
   
   double current_macd = m_macd[0];
   double current_signal = m_macdSignal[0];
   double previous_macd = m_macd[1];
   double previous_signal = m_macdSignal[1];
   
   // MACD crossover
   if (previous_macd < previous_signal && current_macd > current_signal) {
      return SIGNAL_BUY;
   } else if (previous_macd > previous_signal && current_macd < current_signal) {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Analyze Stochastic signal                                         |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeStochastic() {
   if (ArraySize(m_stoch) < 2) return SIGNAL_NEUTRAL;
   
   double current_stoch = m_stoch[0];
   
   if (current_stoch < STOCH_OVERSOLD) {
      return SIGNAL_BUY;
   } else if (current_stoch > STOCH_OVERBOUGHT) {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Analyze Bollinger Bands signal                                    |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeBollingerBands() {
   if (ArraySize(m_bb_upper) < 1) return SIGNAL_NEUTRAL;
   
   double current_close = Close[0];
   double upper = m_bb_upper[0];
   double lower = m_bb_lower[0];
   double middle = m_bb_middle[0];
   
   // Price below lower band = bounce up signal
   if (current_close < lower) {
      return SIGNAL_BUY;
   }
   
   // Price above upper band = pullback signal
   if (current_close > upper) {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Analyze Moving Averages signal                                    |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeMovingAverages() {
   if (ArraySize(m_ma_fast) < 2 || ArraySize(m_ma_slow) < 2) return SIGNAL_NEUTRAL;
   
   double current_fast = m_ma_fast[0];
   double current_slow = m_ma_slow[0];
   double previous_fast = m_ma_fast[1];
   double previous_slow = m_ma_slow[1];
   
   // MA crossover
   if (previous_fast < previous_slow && current_fast > current_slow) {
      return SIGNAL_BUY;
   } else if (previous_fast > previous_slow && current_fast < current_slow) {
      return SIGNAL_SELL;
   }
   
   // Price above slower MA = uptrend
   if (Close[0] > current_slow) {
      return SIGNAL_BUY;
   }
   
   // Price below slower MA = downtrend
   if (Close[0] < current_slow) {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Analyze ADX signal                                                |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeATR() {
   if (ArraySize(m_atr) < 1) return SIGNAL_NEUTRAL;
   
   double current_atr = m_atr[0];
   double avg_atr = 0.0;
   
   // Calculate average ATR
   for (int i = 0; i < MathMin(20, ArraySize(m_atr)); i++) {
      avg_atr += m_atr[i];
   }
   avg_atr /= MathMin(20, ArraySize(m_atr));
   
   // High volatility can be opportunity
   if (current_atr > avg_atr * 1.5) {
      return SIGNAL_BUY;  // Increased volatility
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Analyze ADX trend strength                                        |
//+------------------------------------------------------------------+
SIGNAL_TYPE CSignalGenerator::AnalyzeADX() {
   if (ArraySize(m_adx) < 1) return SIGNAL_NEUTRAL;
   
   double current_adx = m_adx[0];
   
   if (current_adx < ADX_WEAK_TREND) {
      return SIGNAL_NEUTRAL;  // No clear trend
   }
   
   if (current_adx > ADX_STRONG_TREND) {
      // Strong trend - use with directional signal
      if (Close[0] > m_ma_slow[0]) {
         return SIGNAL_BUY;
      } else {
         return SIGNAL_SELL;
      }
   }
   
   return SIGNAL_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Confirm signal with additional criteria                           |
//+------------------------------------------------------------------+
bool CSignalGenerator::ConfirmSignal(SIGNAL_TYPE signal) {
   if (signal == SIGNAL_NEUTRAL) {
      return false;
   }
   
   // Check ADX for trend strength
   if (ArraySize(m_adx) > 0) {
      if (m_adx[0] < ADX_WEAK_TREND) {
         return false;  // Weak trend, don't confirm
      }
   }
   
   // Check spread
   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double spread = (ask - bid) / point;
   
   if (spread > MAX_SPREAD_PIPS) {
      return false;  // Spread too wide
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get signal strength (0-100)                                       |
//+------------------------------------------------------------------+
int CSignalGenerator::GetSignalStrength() {
   int strength = 0;
   
   if (AnalyzeRSI() == m_currentSignal.signalType) strength += 20;
   if (AnalyzeMACD() == m_currentSignal.signalType) strength += 20;
   if (AnalyzeStochastic() == m_currentSignal.signalType) strength += 20;
   if (AnalyzeBollingerBands() == m_currentSignal.signalType) strength += 20;
   if (AnalyzeMovingAverages() == m_currentSignal.signalType) strength += 20;
   
   return strength;
}

//+------------------------------------------------------------------+
//| Get current signal                                                |
//+------------------------------------------------------------------+
const SignalData& CSignalGenerator::GetCurrentSignal() const {
   return m_currentSignal;
}

//+------------------------------------------------------------------+
//| Get previous signal                                               |
//+------------------------------------------------------------------+
const SignalData& CSignalGenerator::GetPreviousSignal() const {
   return m_previousSignal;
}

//+------------------------------------------------------------------+
//| Get RSI value                                                     |
//+------------------------------------------------------------------+
double CSignalGenerator::GetRSI(int index) const {
   if (index >= 0 && index < ArraySize(m_rsi)) {
      return m_rsi[index];
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get MACD value                                                    |
//+------------------------------------------------------------------+
double CSignalGenerator::GetMACD(int index) const {
   if (index >= 0 && index < ArraySize(m_macd)) {
      return m_macd[index];
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get ATR value                                                     |
//+------------------------------------------------------------------+
double CSignalGenerator::GetATR(int index) const {
   if (index >= 0 && index < ArraySize(m_atr)) {
      return m_atr[index];
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get ADX value                                                     |
//+------------------------------------------------------------------+
double CSignalGenerator::GetADX(int index) const {
   if (index >= 0 && index < ArraySize(m_adx)) {
      return m_adx[index];
   }
   return 0.0;
}

#endif
//+------------------------------------------------------------------+
