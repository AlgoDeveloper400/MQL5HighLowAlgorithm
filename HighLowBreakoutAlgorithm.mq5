#property copyright "Property of AlgoDeveloper400 Pty Ltd"
#property version   "1.00"
#property description "The Algorithm Trades Off The High And Lows of a Specified TimeFrame"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

input color colorBreakoutHigh = clrLimeGreen;
input color colorBreakoutLow = clrDodgerBlue;
input int LookBackPeriod = 24;
input int NumberOfHighsOrLows = 3;
input int boxWidth = 55;
input double Lots = 4;
input double StopLoss = 650;
input double EstimatedCommissionPerLot = 0;
input double TrailingStopMultiplier = 1.75;  
input double TrailingStopIncrement = 325;
input int MaxBoxesPerDay = 2;
input double MaxDrawdownPercent = 7.00;
input double MinSpread = 0;
input double MaxSpread = 600;
input int FontSize = 18; 
input int TimeRangeInDays = 1; 
input int TradePauseBeforeAfter = 1800; //IN SECONDS
input int StartHour = 7;  
input int EndHour = 22;    
input bool UseTimeFilter = true;

class CEmail{

private:
   string m_heading;          
   string m_intro;         
   string m_body;             
   string m_conclusion;      
   string m_receiver;      
   string m_ea_name;          

public:
   // Constructor to set default values
   CEmail(const string receiver){
   
      m_heading = "";
      m_intro = "Dear YourNamehere,";
      m_body = "";
      m_conclusion = "Best regards,\nYour Trading Algorithm";
      m_receiver = receiver;
      m_ea_name = StringSubstr(__FILE__, 0, StringFind(__FILE__, ".")); // Set EA name without extension
   }

   // Method to set the heading
   void SetHeading(const string heading){
   
      m_heading = heading;
   }

   // Method to set the body
   void SetBody(const string body){
   
      m_body = body;
   }

   // Method to send the email
   void SendEmail(){
   
      // Compose the full email content, adding EA name at the end
      string emailContent = m_intro + "\n\n" + m_body + "\n\n" + m_conclusion + "\n\nEA Name: " + m_ea_name;

      // Send the email using SendMail
      SendMail(m_heading, emailContent);
   }
};

color FontColor = Lime;
string SpreadLabelName = "SpreadLabel";


CTrade trade;
CPositionInfo positionInfo;

double highs[];
double lows[];

double lastHighLevel = 0;
double lastLowLevel = 0;
datetime lastBoxTime = 0;


int boxCount = 0;   
int lastBoxDay = 0;

datetime lastModificationTime = 0; 
double lastModifiedStopLoss = 0; 
datetime lastEntryTime = 0;  
bool stopLossAtBreakeven = false;
bool tradeExecutedForCurrentBox = false;
double initial_balance;

int OnInit(){

    initial_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    CEmail email("youremail@gmail.com");
    email.SetHeading("EA Initialized");
    email.SetBody("The EA Has Been Added To A Chart, Open Meta Trader 5 If You Suspect This Was Not Done By You!");
    email.SendEmail();

CreateSpreadLabel();

   if(isNewsEvent()){
        Print(" || >>>> ALERT, WE HAVE NEWS... <<<< || ");
    }

 initial_balance = AccountInfoDouble(ACCOUNT_BALANCE);
 
   EventSetMillisecondTimer(100);
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
CEmail email("youremail@gmail.com");
    email.SetHeading("EA Deinitialized");
    email.SetBody("The EA Has Been Removed From A Chart, Open Meta Trader 5 If You Suspect This Was Not Done By You!");
    email.SendEmail();

ObjectsDeleteAll(0);
EventKillTimer();
  }
  
bool IsTradingTime(){
   
   datetime currentTime = TimeCurrent();  
   MqlDateTime timeStruct;
   TimeToStruct(currentTime, timeStruct);   

   int currentHour = timeStruct.hour;
  
   if (currentHour >= StartHour && currentHour < EndHour)
      return true;  // Within trading hours
   else
      return false; // Outside trading hours
}

void OnTimer(){

 UpdateSpreadLabel();
 
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);

    // Calculate the drawdown in percentage using equity (not just balance)
    double drawdown_percent = 100 * (initial_balance - current_equity) / initial_balance;

    if (drawdown_percent >= MaxDrawdownPercent){
        
        Print("Drawdown Limit exceeded. Removing Expert Advisor.");

        CEmail email("youremail@gmail.com");
        email.SetHeading("Max Drawdown Exceeded");
        email.SetBody("The Drawdown Limit Of " + DoubleToString(MaxDrawdownPercent, 2) + "% Has Been Exceeded. Current Drawdown Is " +
                      DoubleToString(drawdown_percent, 2) + "%. The EA Will Be Removed, Please Return To Meta Trader 5 To Make Further Changes...");
        email.SendEmail();

        ExpertRemove();
    }

if (positionInfo.Select(_Symbol)){  
        TrailStopLoss();  
    }
    
    CheckAndAddToWinners();
    
}

void OnTick(){
    {
  
    MqlDateTime currentTime;
    TimeToStruct(TimeCurrent(), currentTime);
    int currentDayOfYear = currentTime.mon * 100 + currentTime.day;

    if (currentDayOfYear != lastBoxDay){
        boxCount = 0;
        tradeExecutedForCurrentBox = false; // Reset trade execution flag for a new day
        lastBoxDay = currentDayOfYear;
    }

    if (boxCount >= MaxBoxesPerDay){
        return;
    }
 
 if (!CanPlaceTrade()) {
        Print("News event window active - trading is blocked.");
        CloseAllTrades();
        return;
    }

 if (UseTimeFilter && !IsTradingTime()){
 CloseAllTrades();

     // Print("Trading blocked outside allowed time window.");
      return;  // Exit without executing further code
   }

    ArrayResize(highs, LookBackPeriod);
    ArrayResize(lows, LookBackPeriod);

    for (int i = 0; i < LookBackPeriod; i++) {
        highs[i] = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, LookBackPeriod, i));
        lows[i] = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, LookBackPeriod, i));
    }

    double highLevel = highs[NumberOfHighsOrLows - 1];
    double lowLevel = lows[NumberOfHighsOrLows - 1];

    double bidPrice, askPrice;
    SymbolInfoDouble(_Symbol, SYMBOL_BID, bidPrice);
    SymbolInfoDouble(_Symbol, SYMBOL_ASK, askPrice);

    double spread = (askPrice - bidPrice) / _Point;

    if (spread < MinSpread || spread > MaxSpread){
        return;
    }

    // Breakout box logic
    if (askPrice > highLevel && highLevel != lastHighLevel){
        RemoveOldBoxes();
        DrawBox(highLevel, "BreakoutHigh", colorBreakoutHigh);
        lastHighLevel = highLevel;
        boxCount++;

        // Check if trade was already executed for this box
        if (!tradeExecutedForCurrentBox){
            double adjustedStopLoss = CalculateAdjustedStopLoss(StopLoss, spread, Lots);
            double sl1 = bidPrice - adjustedStopLoss * _Point;

            if (trade.Buy(Lots, NULL, askPrice, sl1, 0)){
                ulong ticket = trade.ResultOrder();
                RecalculateStopLoss(ticket);
                Print("Buy trade executed successfully at Ask price: ", askPrice);
                tradeExecutedForCurrentBox = true; // Mark trade as executed for this box
            } else{
                Print("Error executing buy trade: ", GetLastError());
            }
        }
    } else if (bidPrice < lowLevel && lowLevel != lastLowLevel){
        RemoveOldBoxes();
        DrawBox(lowLevel, "BreakoutLow", colorBreakoutLow);
        lastLowLevel = lowLevel;
        boxCount++;

        // Check if trade was already executed for this box
        if (!tradeExecutedForCurrentBox){
            double adjustedStopLoss = CalculateAdjustedStopLoss(StopLoss, spread, Lots);
            double sl2 = askPrice + adjustedStopLoss * _Point;

            if (trade.Sell(Lots, NULL, bidPrice, sl2, 0)){
                ulong ticket = trade.ResultOrder();
                RecalculateStopLoss(ticket);
                Print("Sell trade executed successfully at Bid price: ", bidPrice);
                tradeExecutedForCurrentBox = true; // Mark trade as executed for this box
            } else{
                Print("Error executing sell trade: ", GetLastError());
                }
            }
        }
    } 
}

void TrailStopLoss(){
    for (int i = PositionsTotal() - 1; i >= 0; i--){
        if (positionInfo.SelectByIndex(i)) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            double stopLossIncrement = TrailingStopIncrement * _Point;
            double trailingMultiplierAmount = TrailingStopMultiplier * StopLoss * _Point;
            double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double currentStopLoss = PositionGetDouble(POSITION_SL);

            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                // Breakeven logic for each individual buy position
                double breakeven = priceOpen;
                if (currentStopLoss < breakeven && currentPrice >= priceOpen + stopLossIncrement){
                    if (trade.PositionModify(ticket, breakeven, PositionGetDouble(POSITION_TP))){
                        lastModifiedStopLoss = breakeven;
                        lastModificationTime = TimeCurrent();
                        Print("Moved stop-loss for buy trade to breakeven: ", breakeven);
                    }
                }

                double targetPrice = priceOpen + trailingMultiplierAmount;
                if (currentPrice >= targetPrice){
                    double newStopLoss = currentStopLoss + stopLossIncrement;
                    if (newStopLoss < currentPrice && newStopLoss > currentStopLoss){
                        if (trade.PositionModify(ticket, newStopLoss, PositionGetDouble(POSITION_TP))){
                            lastModifiedStopLoss = newStopLoss;
                            lastModificationTime = TimeCurrent();
                            Print("Trailed stop-loss for buy trade to: ", newStopLoss);
                        }
                    }
                }
            } else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                double breakeven = priceOpen;
                if (currentStopLoss > breakeven && currentPrice <= priceOpen - stopLossIncrement){
                    if (trade.PositionModify(ticket, breakeven, PositionGetDouble(POSITION_TP))){
                        lastModifiedStopLoss = breakeven;
                        lastModificationTime = TimeCurrent();
                        Print("Moved stop-loss for sell trade to breakeven: ", breakeven);
                    }
                }

                double targetPrice = priceOpen - trailingMultiplierAmount;
                if (currentPrice <= targetPrice){
                    double newStopLoss = currentStopLoss - stopLossIncrement;
                    if (newStopLoss > currentPrice && newStopLoss < currentStopLoss){
                        if (trade.PositionModify(ticket, newStopLoss, PositionGetDouble(POSITION_TP))){
                            lastModifiedStopLoss = newStopLoss;
                            lastModificationTime = TimeCurrent();
                            Print("Trailed stop-loss for sell trade to: ", newStopLoss);
                        }
                    }
                }
            }
        }
    }
}




void CheckAndAddToWinners(){
    double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double spread = (askPrice - bidPrice) / _Point;

    bool allAtBreakeven = true;
    int openPositionCount = 0;

    double initialLot = Lots;

    for (int i = PositionsTotal() - 1; i >= 0; i--){
        if (positionInfo.SelectByIndex(i) && PositionGetString(POSITION_SYMBOL) == _Symbol){
            openPositionCount++;
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double stopLoss = PositionGetDouble(POSITION_SL);

            if ((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && stopLoss < openPrice) ||
                (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && stopLoss > openPrice)){
                allAtBreakeven = false;
            }
        }
    }

    if (allAtBreakeven && openPositionCount > 0){
        if (TimeCurrent() - lastEntryTime > PeriodSeconds()) {

            double newLotSize = MathMin(initialLot * 2, initialLot * (openPositionCount > 2 ? MathPow(2, openPositionCount) : 2));

            double newStopLossPips = StopLoss / MathPow(2, openPositionCount);
            double adjustedStopLoss = CalculateAdjustedStopLoss(newStopLossPips, spread, newLotSize);

            if (positionInfo.PositionType() == POSITION_TYPE_BUY) {
                if (trade.Buy(newLotSize, _Symbol, askPrice, askPrice - adjustedStopLoss * _Point, 0)){
                    lastEntryTime = TimeCurrent();
                    Print("New buy trade added at price: ", askPrice, " with lot size: ", newLotSize, " and stop-loss: ", adjustedStopLoss);
                }
            } else if (positionInfo.PositionType() == POSITION_TYPE_SELL){
                if (trade.Sell(newLotSize, _Symbol, bidPrice, bidPrice + adjustedStopLoss * _Point, 0)){
                    lastEntryTime = TimeCurrent();
                    Print("New sell trade added at price: ", bidPrice, " with lot size: ", newLotSize, " and stop-loss: ", adjustedStopLoss);
                }
            }
        }
    }
}



// Function to calculate stop loss based on spread and commission
double CalculateAdjustedStopLoss(double stopLossPips, double spread, double lots){
    double adjustedCommission = EstimatedCommissionPerLot * lots;
    double adjustedStopLoss = stopLossPips + spread + adjustedCommission;
    return adjustedStopLoss;
}

// Recalculate stop-loss after trade placement (without spread check)
void RecalculateStopLoss(ulong ticket){
    double commission = GetTradeCommission(ticket);
    double adjustedStopLoss = StopLoss + commission * Lots; // Adjust stop-loss directly with calculated values

    if (positionInfo.SelectByTicket(ticket)){
        double currentStopLoss = PositionGetDouble(POSITION_SL); // Get the current stop-loss price
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            double newStopLoss = PositionGetDouble(POSITION_PRICE_OPEN) - adjustedStopLoss * _Point;
            
            // Only modify stop-loss if the new stop-loss is different
            if (currentStopLoss != newStopLoss){
                trade.PositionModify(ticket, newStopLoss, 0);
                Print("Buy trade stop-loss modified to: ", newStopLoss);
            } else{
                Print("Buy trade stop-loss unchanged.");
            }
        } else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            double newStopLoss = PositionGetDouble(POSITION_PRICE_OPEN) + adjustedStopLoss * _Point;
            
            // Only modify stop-loss if the new stop-loss is different
            if (currentStopLoss != newStopLoss){
                trade.PositionModify(ticket, newStopLoss, 0);
                Print("Sell trade stop-loss modified to: ", newStopLoss);
            } else{
                Print("Sell trade stop-loss unchanged.");
            }
        }
    }
}

double GetTradeCommission(ulong ticket){
    if (positionInfo.SelectByTicket(ticket)){
        return PositionGetDouble(POSITION_COMMISSION);
    }
    return 0;
}

double GetTradeSwap(ulong ticket){
    if (positionInfo.SelectByTicket(ticket)){
        return PositionGetDouble(POSITION_SWAP);
    } else {
        Print("Error: Could not select position for ticket ", ticket);
        return 0;
    }
}

void DrawBox(double levelPrice, string namePrefix, color boxColor){
   // Generate a unique name for each box
   string name = namePrefix + "_" + TimeToString(TimeCurrent(), TIME_MINUTES) + "_" + DoubleToString(levelPrice,_Digits);
   
   // Calculate the coordinates for the horizontal box
   datetime timeStart = iTime(NULL, 0, boxWidth);  // Time for the start of the box (boxWidth bars back)
   datetime timeEnd = TimeCurrent();               // Current time as end of the box
   
   
   // Create a new horizontal line with fixed size
   if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, timeStart, timeEnd)){
      Print("Error creating object: ", GetLastError());
      return;
   }
   
   // Set the color for the box
   if (!ObjectSetInteger(0, name, OBJPROP_COLOR, boxColor)){
      Print("Error setting color: ", GetLastError());
      return;
   }
   
   // Optional: Set box style and width
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT); // Box border type
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);                 // Box width
}

void RemoveOldBoxes(){
   ObjectsDeleteAll(0, "BreakoutHigh");
   ObjectsDeleteAll(0, "BreakoutLow");
}

double GetCurrentSpread(){
    return (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
}

void CreateSpreadLabel(){
    if (!ObjectCreate(0, SpreadLabelName, OBJ_LABEL, 0, 0, 0)){
        Print("Failed to create the spread label.");
        return;
    }
    ObjectSetString(0, SpreadLabelName, OBJPROP_TEXT, "SPREAD: 0.0");
    ObjectSetInteger(0, SpreadLabelName, OBJPROP_FONTSIZE, FontSize);
    ObjectSetInteger(0, SpreadLabelName, OBJPROP_COLOR, FontColor);
    ObjectSetInteger(0, SpreadLabelName, OBJPROP_XDISTANCE, 800);
    ObjectSetInteger(0, SpreadLabelName, OBJPROP_YDISTANCE, 0);
}

void UpdateSpreadLabel(){
    double spread = GetCurrentSpread();
    string spreadText = StringFormat("SPREAD: %.1f", spread);
    ObjectSetString(0, SpreadLabelName, OBJPROP_TEXT, spreadText);
}

void CloseAllTrades() {
    // Close all open positions
    for (int i = PositionsTotal() - 1; i >= 0; i--){
        ulong ticket = PositionGetTicket(i);
       trade.PositionClose(ticket);
    }
}

// THIS ONE HAS THE AUTOMATIC CALENDAR FEATURE
bool isNewsEvent(){
    bool isNews = false;
    int totalNews = 0;
    MqlCalendarValue values[];

    datetime startTime = TimeCurrent();
    datetime endTime = startTime + TimeRangeInDays * PeriodSeconds(PERIOD_D1); 

    int valuesTotal = CalendarValueHistory(values, startTime, endTime);

    // LABEL ADJUSTMENTS
    int baseXPosition = 10;
    int baseYPosition = 30;
    int yOffset = 0;
    int yOffsetIncrement = 20;

    bool firstLabel = true;
    string currentCountry = "";

    // Search code for indices, mapped to relevant currencies
    if (StringFind(_Symbol, "US30") >= 0) {
        currentCountry = "USD";
    } else if (StringFind(_Symbol, "US2000") >= 0) {
        currentCountry = "USD";
    } else if (StringFind(_Symbol, "USTEC") >= 0) {
        currentCountry = "USD";
    } else if (StringFind(_Symbol, "UK100") >= 0) {
        currentCountry = "GBP";
    } else if (StringFind(_Symbol, "JP225") >= 0) {
        currentCountry = "JPY";
    } else if (StringFind(_Symbol, "SA40") >= 0) {
        currentCountry = "ZAR";
    }

    for (int i = 0; i < valuesTotal; i++){
        MqlCalendarEvent event;
        CalendarEventById(values[i].event_id, event);

        MqlCalendarCountry country;
        CalendarCountryById(event.country_id, country);

        // Check if the symbol is a currency pair or index
        if (currentCountry != "") {
            // For index symbols, check if the news matches the country currency
            if (StringFind(currentCountry, country.currency) >= 0){
                if (event.importance == CALENDAR_IMPORTANCE_HIGH){
                    if (values[i].time >= startTime && values[i].time <= endTime){
                        Print(event.name, " || ", country.currency, " || ", EnumToString(event.importance), " || ", values[i].time, " || ", "(NOT YET RELEASED)");
                        totalNews++;

                        if (firstLabel){
                            DrawTextOnChart("UPCOMING NEWS EVENTS:", baseXPosition, baseYPosition, yOffset, false);
                            yOffset += yOffsetIncrement;
                            firstLabel = false;
                        }

                        DrawTextOnChart(event.name, baseXPosition, baseYPosition, yOffset, true);
                        yOffset += yOffsetIncrement;
                    }
                }
            }
        } else if (StringFind(_Symbol, country.currency) >= 0) {
            // For currency pairs, check if the news matches the currency in the symbol
            if (event.importance == CALENDAR_IMPORTANCE_HIGH){
                if (values[i].time >= startTime && values[i].time <= endTime){
                    Print(event.name, " || ", country.currency, " || ", EnumToString(event.importance), " || ", values[i].time, " || ", "(NOT YET RELEASED)");
                    totalNews++;

                    if (firstLabel){
                        DrawTextOnChart("UPCOMING NEWS EVENTS:", baseXPosition, baseYPosition, yOffset, false);
                        yOffset += yOffsetIncrement;
                        firstLabel = false;
                    }

                    DrawTextOnChart(event.name, baseXPosition, baseYPosition, yOffset, true);
                    yOffset += yOffsetIncrement;
                }
            }
        }
    }

    if (totalNews > 0){
        isNews = true;
        Print("(FOUND NEWS EVENTS) >>> TOTAL NEWS ", totalNews, "/", ArraySize(values));
    } else {
        isNews = false;
        Print(">>>> (NEWS EVENTS NOT FOUND) >>> TOTAL NEWS ", totalNews, "/", ArraySize(values));
    }

    return (isNews);
}

bool CanPlaceTrade(){
    MqlCalendarValue values[];
    datetime currentTime = TimeCurrent();
    datetime blockStartTime = currentTime - TradePauseBeforeAfter;
    datetime blockEndTime = currentTime + TradePauseBeforeAfter;

    int valuesTotal = CalendarValueHistory(values, blockStartTime, blockEndTime);

    for (int i = 0; i < valuesTotal; i++){
        MqlCalendarEvent event;
        CalendarEventById(values[i].event_id, event);

        MqlCalendarCountry country;
        CalendarCountryById(event.country_id, country);

        string currentCountry = SymbolCountry(_Symbol);
        if (currentCountry != "" && StringFind(currentCountry, country.currency) >= 0){
            if (event.importance == CALENDAR_IMPORTANCE_HIGH){
                datetime eventTime = values[i].time;

                if (eventTime >= blockStartTime && eventTime <= blockEndTime){
                    Print("Blocked due to high-impact news within time window: ", event.name);
                    return false;
                }
            }
        }
    }
     
    return true;
}


string SymbolCountry(string symbol) {
    if (StringFind(symbol, "US30") >= 0 || StringFind(symbol, "USTEC") >= 0 || StringFind(symbol, "US2000") >= 0) {
        return "USD";
    } else if (StringFind(symbol, "UK100") >= 0) {
        return "GBP";
    } else if (StringFind(symbol, "JP225") >= 0) {
        return "JPY";
    } else if (StringFind(symbol, "SA40") >= 0) {
        return "ZAR";
    }
    return "";
}

void DrawTextOnChart(string text, int baseXPosition, int baseYPosition, int yOffset, bool withBullet = true){
    static int objectCount = 0;
    string objectName = "NewsEvent_" + IntegerToString(objectCount);
    objectCount++;

    // CREATE LABEL
    if (!ObjectCreate(0, objectName, OBJ_LABEL, 0, 0, 0)){
        Print("Failed to create object: ", objectName, " Error: ", GetLastError());
        return;
    }

    ObjectSetInteger(0, objectName, OBJPROP_COLOR, clrLime);
    ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, objectName, OBJPROP_XDISTANCE, baseXPosition); 
    ObjectSetInteger(0, objectName, OBJPROP_YDISTANCE, baseYPosition + yOffset); 

    if (withBullet){
        ObjectSetString(0, objectName, OBJPROP_TEXT, "• " + text);
        
    }else{
        ObjectSetString(0, objectName, OBJPROP_TEXT, text);
    }

    ChartRedraw();
}
