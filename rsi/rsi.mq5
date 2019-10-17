#property   copyright   "2019, Virtrel"
#property   link        "https://trading.virtrel.com/"
#property   description "Relative Strength Index Expert Advisor"

#define VIRTRELRSI  20191017

input double                inpRsiHigh      = 80.0;         // RSI-High
input double                inpRsiLow       = 20.0;         // RSI-Low
input int                   inpRsiPeriod    = 14;           // RSI-Period
input double                inpTakeProfit   = 20.0;         // Take Profit
input double                inpStopLoss     = 20.0;         // Stop Loss
input double                inpTrailingStop = 0.0;          // Trailing Strop
input double                inpLots         = 0.1;          // Lots
input ENUM_APPLIED_PRICE    inpAppliedPrice = PRICE_CLOSE;  // Applied Price
input ENUM_TIMEFRAMES       inpTimeFrame    = PERIOD_H1;    // Time Period

void OnTick()
{
    int iTicket, iTotal = 1;
    double dRsiValue = iRSI(NULL, inpTimeFrame, inpRsiPeriod, inpAppliedPrice, 0);

    if(OrdersTotal() < iTotal)
    {
        if(AccountFreeMargin() < (inpLots * 1000))
        {
            if(dRsiValue > inpRsiHigh)
            {
                iTicket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, Ask-inpStopLoss*Point, Ask+inpTakeProfit*Point, "RSI - Buy", VIRTRELRSI, 0, Green);

                checkTicket(iTicket, "BUY");
            }
            else if(dRsiValue < inpRsiLow)
            {
                iTicket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, Bid+inpStopLoss*Point, Bid-inpTakeProfit*Point, "RSI - Sell", VIRTRELRSI, 0, Red);

                checkTicket(iTicket, "SELL");
            }
        }
    }

    for(i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
            break;
        
        if(OrderMagicNumber() != VIRTRELRSI || OrderSymbol() != Symbol())
            continue;

        if(OrderType() == OP_BUY)
        {
            if(inpTrailingStop > 0)
            {
                if(Bid - OrderOpenPrice() > Point * inpTrailingStop)
                {
                    if(OrderStopLoss() < Bid - Point * inpTrailingStop)
                    {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), Bid - Point * inpTrailingStop, OrderTakeProfit(), 0, Green))
                            Print("Order modify error: ", GetLastError());
                    }
                }
            }
        }
        else
        {
            if(inpTrailingStop > 0)
            {
                if(OrderOpenPrice() - Ask > Point * inpTrailingStop)
                {
                    if(OrderStopLoss() > Ask + Point * inpTrailingStop || OrderStopLoss() == 0)
                    {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), Ask + Point * inpTrailingStop, OrderTakeProfit(), 0, Red))
                            Print("Order modify error: ", GetLastError());
                    }
                }
            }
        }
    }
}

void checkTicket(int iTicket, string sType)
{
    if(iTicket > 0)
    {
        if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
            Print(sType, " order opened: ", OrderOpenPrice());
    }
    else
        Print("ERROR: Opening ", sType, " order: ", GetLastError());
}