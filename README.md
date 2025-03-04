# MQL5HighLowAlgorithm
This Algorithm in MQL5 trades Highs and Lows based on a lookback and number of highs/low touches made on a line.
A lookback of X candles( can be set via input variable), is used to hunt for the highs/lows.
The logic first starts countinf at the first high/low that was found in the lookback period, and once more have been detected( also set by input variable), it upates and waits for the number of highs/low to match the input.
Once it is confirmed, a line is drawn and a buy/sell trade is executed.
Very basic and simple.

Here are some additional features of the code:
* Uses a trailing stop with an increment.
* Breakeven stop.
* Add to winners logic, that adds to winning trades after the stoploss of the previous trade has been to breakeven.
* A news filter with inputs to determine how many seconds before/after the news event should we pause trading for(for some symbols not all).
* Mobile notification system that alerts the user when a trade has been placed and/or modified.
* Email notification system that alerts the user when his/her EA has been initialized/deinitialized in the case that you do intend to use it on a vps.
* Signal counter. It counts the number of signals executed and tracks it correctly.
* Proper error handling with error messages.
* very fast execution speeds(under 300ms to 1 second).
* Customizable time filter set via 2 input variables.
* Drawdown protection limit, set via input variable.
* Spread filter also changeable via input variables.
* Calculates spreads and commissions for every trade so you know what your true trading costs are.
* Cleans clutter by removing yesterdays lines, meaning only 1 line is shown at a time on the chart.
* Spread display on screen.
* On screen news display of the next x days news events, also can be changed via an input variables.
* Created with AI, debugging was done manually by me. AI simple generates, and I debug and fix.
