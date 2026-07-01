//+------------------------------------------------------------------+
//|                         Logger.mqh                                |
//|                    Professional Logging System                    |
//|                  GoldPrecisionTraderProX v1.0                     |
//+------------------------------------------------------------------+
#ifndef __LOGGER_MQH__
#define __LOGGER_MQH__

#include "Enums.mqh"
#include "Config.mqh"

//--- Logger class
class CLogger {
private:
   string      m_logFile;
   LOG_LEVEL   m_logLevel;
   bool        m_fileLogging;
   bool        m_journalLogging;
   int         m_maxFileSize;
   
public:
   CLogger();
   ~CLogger();
   
   bool Initialize(string ea_name, bool enable_logging);
   void Finalize();
   void Log(LOG_LEVEL level, string message);
   void LogTrade(ulong ticket, double volume, double price, string direction);
   void LogError(int error_code);
   void SetLogLevel(LOG_LEVEL level);
   LOG_LEVEL GetLogLevel() const;
   
private:
   string GetLogFileName();
   string GetTimestamp();
   string GetLevelName(LOG_LEVEL level);
   void WriteToFile(string log_line);
   void CheckFileSize();
};

//--- Logger constructor
CLogger::CLogger() {
   m_logFile = "";
   m_logLevel = LOG_INFO;
   m_fileLogging = ENABLE_FILE_LOGGING;
   m_journalLogging = ENABLE_JOURNAL_LOGGING;
   m_maxFileSize = LOG_MAX_SIZE;
}

//--- Logger destructor
CLogger::~CLogger() {
   Finalize();
}

//+------------------------------------------------------------------+
//| Initialize logger                                                 |
//+------------------------------------------------------------------+
bool CLogger::Initialize(string ea_name, bool enable_logging) {
   if (!enable_logging) {
      m_fileLogging = false;
      m_journalLogging = false;
      return true;
   }
   
   m_logFile = GetLogFileName();
   
   // Create log file if it doesn't exist
   if (m_fileLogging) {
      int file_handle = FileOpen(m_logFile, FILE_WRITE | FILE_TXT);
      if (file_handle != INVALID_HANDLE) {
         FileWrite(file_handle, "=== " + ea_name + " Log Started ===");
         FileWrite(file_handle, "Date: " + GetTimestamp());
         FileWrite(file_handle, "=================================");
         FileClose(file_handle);
         return true;
      } else {
         Print("Logger: Failed to create log file");
         m_fileLogging = false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Finalize logger                                                   |
//+------------------------------------------------------------------+
void CLogger::Finalize() {
   if (m_fileLogging && m_logFile != "") {
      WriteToFile("=== Log Ended ===");
   }
}

//+------------------------------------------------------------------+
//| Log message                                                       |
//+------------------------------------------------------------------+
void CLogger::Log(LOG_LEVEL level, string message) {
   if (level < m_logLevel) {
      return;  // Skip messages below the current log level
   }
   
   string level_name = GetLevelName(level);
   string timestamp = GetTimestamp();
   string log_line = "[" + timestamp + "] [" + level_name + "] " + message;
   
   // Write to journal
   if (m_journalLogging) {
      Print(log_line);
   }
   
   // Write to file
   if (m_fileLogging && m_logFile != "") {
      WriteToFile(log_line);
   }
}

//+------------------------------------------------------------------+
//| Log trade execution                                               |
//+------------------------------------------------------------------+
void CLogger::LogTrade(ulong ticket, double volume, double price, string direction) {
   string message = StringFormat(
      "TRADE [Ticket: %d | Direction: %s | Volume: %.2f | Price: %.5f]",
      ticket, direction, volume, price
   );
   Log(LOG_INFO, message);
}

//+------------------------------------------------------------------+
//| Log error with error code                                         |
//+------------------------------------------------------------------+
void CLogger::LogError(int error_code) {
   string error_text = "";
   
   switch (error_code) {
      case 0:
         error_text = "No error";
         break;
      case 1:
         error_text = "Unknown error";
         break;
      case 2:
         error_text = "Wrong function pointer";
         break;
      case 3:
         error_text = "Array index is out of range";
         break;
      case 4:
         error_text = "No memory for function call stack";
         break;
      case 5:
         error_text = "No memory for parameter string";
         break;
      case 6:
         error_text = "No memory for temp string";
         break;
      case 7:
         error_text = "Stack overflow";
         break;
      case 8:
         error_text = "Zero divide";
         break;
      case 9:
         error_text = "Unknown command";
         break;
      case 10:
         error_text = "Wrong jump (never generated error)";
         break;
      case 11:
         error_text = "Not initialized variable";
         break;
      case 12:
         error_text = "Not confirmed error";
         break;
      case 13:
         error_text = "Code page conversion error";
         break;
      case 64:
         error_text = "Insecure operation";
         break;
      case 65:
         error_text = "String parameter expected";
         break;
      case 66:
         error_text = "Integer parameter expected";
         break;
      case 67:
         error_text = "Double parameter expected";
         break;
      case 68:
         error_text = "Array as parameter expected";
         break;
      case 128:
         error_text = "Trade is not allowed";
         break;
      case 129:
         error_text = "Long position is not allowed";
         break;
      case 130:
         error_text = "Short position is not allowed";
         break;
      default:
         error_text = "Unknown error code";
         break;
   }
   
   string message = StringFormat("ERROR [Code: %d | %s]", error_code, error_text);
   Log(LOG_ERROR, message);
}

//+------------------------------------------------------------------+
//| Set log level                                                     |
//+------------------------------------------------------------------+
void CLogger::SetLogLevel(LOG_LEVEL level) {
   m_logLevel = level;
   string level_name = GetLevelName(level);
   Log(LOG_INFO, "Log level set to: " + level_name);
}

//+------------------------------------------------------------------+
//| Get log level                                                     |
//+------------------------------------------------------------------+
LOG_LEVEL CLogger::GetLogLevel() const {
   return m_logLevel;
}

//+------------------------------------------------------------------+
//| Get log file name                                                 |
//+------------------------------------------------------------------+
string CLogger::GetLogFileName() {
   string file_name = LOG_FILE_NAME;
   string date_str = TimeToString(TimeCurrent(), TIME_DATE);
   date_str = StringSubstr(date_str, 0, 10);  // Get date portion
   
   // Replace dots with dashes for better file naming
   StringReplace(date_str, ".", "-");
   
   return "Logs/" + date_str + "_" + file_name;
}

//+------------------------------------------------------------------+
//| Get current timestamp                                             |
//+------------------------------------------------------------------+
string CLogger::GetTimestamp() {
   return TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Get log level name                                                |
//+------------------------------------------------------------------+
string CLogger::GetLevelName(LOG_LEVEL level) {
   switch (level) {
      case LOG_DEBUG:
         return "DEBUG";
      case LOG_INFO:
         return "INFO";
      case LOG_WARNING:
         return "WARNING";
      case LOG_ERROR:
         return "ERROR";
      default:
         return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Write to log file                                                 |
//+------------------------------------------------------------------+
void CLogger::WriteToFile(string log_line) {
   CheckFileSize();
   
   int file_handle = FileOpen(m_logFile, FILE_APPEND | FILE_TXT);
   if (file_handle != INVALID_HANDLE) {
      FileWrite(file_handle, log_line);
      FileClose(file_handle);
   }
}

//+------------------------------------------------------------------+
//| Check and manage file size                                        |
//+------------------------------------------------------------------+
void CLogger::CheckFileSize() {
   if (!FileIsExist(m_logFile)) {
      return;
   }
   
   int file_handle = FileOpen(m_logFile, FILE_READ | FILE_TXT);
   if (file_handle != INVALID_HANDLE) {
      long file_size = FileSize(file_handle);
      FileClose(file_handle);
      
      if (file_size > m_maxFileSize) {
         // Rename old log file
         string backup_file = m_logFile + ".bak";
         FileDelete(backup_file);  // Delete old backup if exists
         FileMove(m_logFile, 0, backup_file, 0);  // Move current to backup
         
         // Create new log file
         file_handle = FileOpen(m_logFile, FILE_WRITE | FILE_TXT);
         if (file_handle != INVALID_HANDLE) {
            FileWrite(file_handle, "=== New Log Session ===");
            FileWrite(file_handle, "Previous log archived to: " + backup_file);
            FileWrite(file_handle, "=====================================");
            FileClose(file_handle);
         }
      }
   }
}

#endif
//+------------------------------------------------------------------+
