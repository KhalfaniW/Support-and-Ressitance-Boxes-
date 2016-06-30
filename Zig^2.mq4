//+------------------------------------------------------------------+
//|                                                       Zig^2.mq4  |
//|        Khalfani, for i have eddited the code to add functionality|
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Made By Khalfani"
#property link      "Be Happy"
#property strict

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  Red
//---- indicator parameters
input int InpDepth=2;     // Depth
input int InpDeviation=1;  // Deviation
input int InpBackstep=1;   // Backstep
input int barsInView=100; // How Many Bars are you looking at
input int range_width=5;

bool isPriceInARange=false;
bool isNewBar;
int AllExistingLines=0;
double TradeRangeMax =0;
double TradeRangeMin =0;
datetime LastbarTime;

bool FirstCalc=true;
//Copied in no particular order, i didn't know how to dynamically import it. 
color Colors[]= 
  {
   clrBlack,clrDarkGreen,clrDarkSlateGray,clrOlive,clrGreen,clrTeal,clrNavy,clrPurple,
   clrMaroon,clrIndigo,clrMidnightBlue,clrDarkBlue,clrDarkOliveGreen,clrSaddleBrown,clrForestGreen,
   clrOliveDrab,clrSeaGreen,clrDarkGoldenrod,clrDarkSlateBlue,clrSienna,clrMediumBlue,clrBrown,clrDarkTurquoise,clrDimGray,
   clrLightSeaGreen,clrDarkViolet,clrFireBrick,clrMediumVioletRed,clrMediumSeaGreen,clrChocolate,
   clrCrimson,clrSteelBlue,clrGoldenrod,clrMediumSpringGreen,clrLawnGreen,clrCadetBlue,clrDarkOrchid,clrYellowGreen,
   clrLimeGreen,clrOrangeRed,clrDarkOrange,clrOrange,clrGold,clrYellow,clrChartreuse,clrLime,clrSpringGreen,clrAqua,
   clrDeepSkyBlue,clrBlue,clrMagenta,clrRed,clrGray,clrSlateGray,clrPeru,clrBlueViolet,clrLightSlateGray,clrDeepPink,
   clrMediumTurquoise,clrDodgerBlue,clrTurquoise,clrRoyalBlue,clrSlateBlue,clrDarkKhaki,clrIndianRed,clrMediumOrchid,
   clrGreenYellow,clrMediumAquamarine,clrDarkSeaGreen,clrTomato,clrRosyBrown,clrOrchid,clrMediumPurple,clrPaleVioletRed,
   clrCoral,clrCornflowerBlue,clrDarkGray,clrSandyBrown,clrMediumSlateBlue,clrTan,clrDarkSalmon,clrBurlyWood,clrHotPink,
   clrSalmon,clrViolet,clrLightCoral,clrSkyBlue,clrLightSalmon,clrPlum,clrKhaki,clrLightGreen,clrAquamarine,clrSilver,
   clrLightSkyBlue,clrLightSteelBlue,clrLightBlue,clrPaleGreen,clrThistle,clrPowderBlue,clrPaleGoldenrod,clrPaleTurquoise,
   clrLightGray,clrWheat,clrNavajoWhite,clrMoccasin,clrLightPink,clrGainsboro,clrPeachPuff,clrPink,clrBisque,clrLightGoldenrod,
   clrBlanchedAlmond,clrLemonChiffon,clrBeige,clrAntiqueWhite,clrPapayaWhip,clrCornsilk,clrLightYellow,clrLightCyan,clrLinen,
   clrLavender,clrMistyRose,clrOldLace,clrWhiteSmoke,clrSeashell,clrIvory,clrHoneydew,clrAliceBlue,clrLavenderBlush,clrMintCream,clrSnow,clrWhite
  };
//--- globals

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//get 50 integer values which are colors
   if(InpBackstep>=InpDepth)
     {
      Print("Backstep cannot be greater or equal to Depth");
      return(INIT_FAILED);
     }

   isNewBar=true;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                   |
//+------------------------------------------------------------------+  
int initCount=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Line
  {

public:
   double            tenthpip;
   bool              isZigZag,isInitialized,isDrawn;
   //int               range_width;

   double            RangeMax,RangeMin;
   double            price;
   int               StartIndex;
   string            thisRectName;
   datetime          StartTime;

   //Default Constructor (it has empty paramaters)
                     Line(){isInitialized=false;}

                     Line(double input_price,int index)
     {
      isInitialized=false;
      Initialize(input_price,index);
     }

   void Initialize(double input_price,int index)
     {
      if(!isInitialized)
        {
         //range_width=5;//in tenth pips
         price=input_price;
         StartIndex=index;
         StartTime=Time[StartIndex];

         if(StringFind(ChartSymbol(),"JPY")>-1)
            tenthpip=0.001;
         else
            tenthpip=0.00001;

         RangeMax=price+tenthpip*range_width;
         RangeMin=price-tenthpip*range_width;
         thisRectName="Rect From"+RangeMax+","+RangeMin;
         if(StrikesAreGood())
           {
            ObjectCreate(0,thisRectName,OBJ_RECTANGLE,0,Time[StartIndex],RangeMax,Time[0],RangeMin);
            ColorToDeferentiate();
            isDrawn=true;
           }
         isInitialized=true;
        }

     }

   void Update()
     {//checks if rects are good if they are it updates them or 'StrikesAreGood' function destroys them
      StartIndex++;//Time is mobile
      if(MathAbs(iBarShift(NULL,0,StartTime)-iBarShift(NULL,0,Time[0]))>barsInView)//distance between bars is Greater than barsInView
        {//Destroy the object
         DeleteMe();
        }
      else
        {
         if(StrikesAreGood())
           {

            if(isDrawn)
              {
               ObjectSetInteger(0,thisRectName,OBJPROP_TIME2,Time[0]);//edit it
              }
            else
              {
               ObjectCreate(0,thisRectName,OBJ_RECTANGLE,0,StartTime,RangeMax,Time[0],RangeMin);
               ColorToDeferentiate();
               isDrawn=true;
              }
           }
         else
           {
            ObjectDelete(thisRectName);
            isDrawn=false;
           }

        }

     }
   void DeleteMe()
     {
      ObjectDelete(thisRectName);
      isDrawn=false;
      isInitialized=false;//if it is not Initialized it will  not update any more
     }
   void ColorToDeferentiate()
     {

      string Name;
      for(int i=ObjectsTotal() -1;i>=0; i--)
        {
         Name=ObjectName(i);
         if(StringFind(Name,"Rect")>-1 && //it is a rectangle
            Name!=thisRectName && 
            StartTime>datetime(ObjectGet(Name,0)))//this rectangle is newer 
           {
            double RectMax=ObjectGet(Name,1);
            double RectMin=ObjectGet(Name,3);

            if((RangeMax>=RectMin && RangeMax<=RectMax) || //if this rectangle overlaps that from the others bottom
               (RangeMin<=RectMax && RangeMin>=RectMin))//if this rectangle overlaps from the others top
              {//if they overlap
               //then change the color of this
               int colorindex;
               for(colorindex=0;colorindex<ArraySize(Colors);colorindex++)
                 {
                  if(colorindex==ArraySize(Colors)-1)
                    {
                     colorindex=-1;//this is so when you add one it will be zero
                     break;
                    }
                  if(color(ObjectGetInteger(0,Name,OBJPROP_COLOR))==Colors[colorindex])
                     break;
                 }
               ObjectSetInteger(0,thisRectName,OBJPROP_COLOR,Colors[colorindex+1]);

              }
           }
        }
     }

   bool StrikesAreGood()
   //Strkes for need to outnumber or equal strkes against
     {//Strike definition
      // if just entered , wait 5 bars, if it a whole body  opens and closes above the area, then the strke is against it.
      // if it does not exit in 5 bars then it is a strike against
      // if goes in then leaves  in the opposite direction after 5 bars then it is a stirke for
      // if it goes 1.5 pips away then it it is a strike against

      //Get Strikes
      int  strikesfor=0;
      int  strikesagainst=0;
      int j;
      int barstocount=5;//or 20
      for(int i=StartIndex-7; i>barstocount+1; i--)//-7 bars because it should not be the same swing that trigegrs a strike //it has to be greater than bars  
        {
         if(Low[i]<RangeMax && Low[i+1]>RangeMax)//Entered through top
           {
            for(j=0;j<barstocount+1;j++)
              {

               if(Close[i-j]<RangeMin-tenthpip*5)//if any bar after it moves half a pip through
                 {
                  strikesagainst++;
                  break;
                 }
               if(Close[i-j]<RangeMin && Open[i-j]<RangeMin)//if any bar closes insie
                 {
                  strikesagainst++;
                  break;
                 }
               if(j==barstocount)
                 {
                  if(Close[i-barstocount]<=RangeMax)//if it does not close out
                    {
                     strikesagainst++;
                     break;
                    }
                  else
                    {
                     strikesfor++;
                     break;
                    }
                 }

              }

           }

         if(High[i]>RangeMin && High[i+1]<RangeMin)//Entered through bottom
           {
            for(j=0;j<barstocount+1;j++)
              {
               if(Close[i-j]>RangeMax+tenthpip*5)
                 {
                  strikesagainst++;
                  break;
                 }
               if(Close[i-j]>RangeMax && Open[i-j]>RangeMax)
                 {
                  strikesagainst++;
                  break;
                 }
               if(j==barstocount)
                 {
                  if(Close[i-barstocount]>=RangeMin)//if it does not close out
                    {
                     strikesagainst++;
                    }
                  else
                    {
                     strikesfor++;
                    }
                 }

              }
           }
/* if(Low[i]<RangeMax && Low[barstocount+i+1]>RangeMax)//Entered through top x  bars ago
           {
            for(j=0;j<barstocount+1;j++)
              {

               if(Close[i+j]<RangeMin-tenthpip*5)//if it moves half a pip through
                 {
                  strikesagainst++;
                  break;
                 }
               if(Close[i+j]<RangeMin && Open[i+j]<RangeMin)
                 {
                  strikesagainst++;
                  break;
                 }
               if(j==barstocount)
                 {
                  if(Close[i-barstocount]<=RangeMax)//if it does not close out
                    {
                     strikesagainst++;
                     break;
                    }
                  else
                    {
                     strikesfor++;
                     break;
                    }
                 }

              }

           }

         if(High[barstocount+i]>RangeMin && High[barstocount+i+1]<RangeMin)//Entered through bottom 5 bars ago
           {
            for(j=0;j<barstocount+1;j++)
              {
               if(Close[i+j]>RangeMax+tenthpip*15)
                 {
                  strikesagainst++;
                  break;
                 }
               if(Close[i+j]>RangeMax && Open[i+j]>RangeMax)
                 {
                  strikesagainst++;
                  break;
                 }
               if(j==barstocount)
                 {
                  if(Close[i-barstocount]>=RangeMin)//if it does not close out
                    {
                     strikesagainst++;
                    }
                  else
                    {
                     strikesfor++;
                    }
                 }

              }
           }*/

        }

      if(strikesagainst>=strikesfor)//Must be more strikes for then against
        {//Delete Line let
         return false;
        }
      else
        {// Print(strikesagainst+","+strikesfor);

         return true;
        }

     };

  };
Line              ZigZagLines[1000];//Note ALL Line objects must be Initialized!!! //i made this as large as i thought nescesary in an unfroseen circumstance//only loop to barsInView
Line              ZigHighLines[1000];
Line              ZigLowLines[1000];
Line              HighFracLines[1000];
Line              LowFracLines[1000];
Line              AllLines[5][100000];//this number needs to be large because one can expect 2000 requests in just 30 bars
Line              PotentialTradeLine;
double            RectHighs[1000000];
double            RectLows[1000000];
datetime          RectStarttimes[1000000];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deadcount=0;
datetime TimeOfBarThatHasAlreadyBeenAlerted;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   string Name;

   for(int i=ObjectsTotal() -1;i>=0; i--)
     {
      Name=ObjectName(i);
      if(StringFind(Name,"Rect")>-1 && int(ObjectGetString(0,"Speed",OBJPROP_TEXT))!=12345678) //it is a rectangle made by Zig^2 and A trade is not already being processed
        {
         double RectMax=ObjectGet(Name,1);
         double RectMin=ObjectGet(Name,3);
         if(Close[0]<=RectMax && Close[0]>=RectMin && Time[0]!=TimeOfBarThatHasAlreadyBeenAlerted)
           {
            //Change Speed
          
            Alert("Yo"); 
           TimeOfBarThatHasAlreadyBeenAlerted=Time[0];
  
           }

        }
     }

   if(isNewBar)
     {
      for(int k=5; k<barsInView;k++)
        {
         double ZigZag=iCustom(NULL,0,"ZigZag",InpDepth,InpDeviation,InpBackstep,0,k);
         double HighFractal=iFractals(NULL,0,MODE_UPPER,k);
         double LowFractal=iFractals(NULL,0,MODE_LOWER,k);
         double Opens[11]={0,0,0,0,0,0,0,0,0,0,0};//So everything is initialized because i don't want a warning
         double Closes[11]={0,0,0,0,0,0,0,0,0,0,0};

         if(ZigZag>0)//Make Range from highs and lows
           {
            AllLines[0][getFirstAvailable(0)].Initialize(ZigZag,k);

            for(int l=-5; l<5; l++)//from -5 looking forward to 5 bars back
              {
               if(k+l<=iBars(NULL,0))
                 {
                  Opens[l+5]=Open[k+l];//This gets it from 5 bars back and five bars infront
                  Closes[l+5]=Close[k+l];
                 }
              }
            double High_=double(StringSubstr(string(High[k]),0,StringLen(string(High[k]))-1)); //Highs and lows must have the last digit removed
            double Low_=double(StringSubstr(string(Low[k]),0,StringLen(string(Low[k]))-1));

            if(ZigZag>=High_)//ZigZag is at top
              {//find the highest open or close
               AllLines[1][getFirstAvailable(1)].Initialize(MathMax(Opens[ArrayMaximum(Opens)],Closes[ArrayMaximum(Closes)]),k);
              }

            else if(ZigZag<=Low_)//ZigZag is at bottom
              {//find the lowest open or close
               AllLines[2][getFirstAvailable(2)].Initialize(MathMin(Opens[ArrayMinimum(Opens)],Closes[ArrayMinimum(Closes)]),k);
              }

           }

         if(HighFractal>0)
            AllLines[3][getFirstAvailable(3)].Initialize(HighFractal,k);
         if(LowFractal>0)
            AllLines[4][getFirstAvailable(4)].Initialize(LowFractal,k);

        }//update all the ranges
      for(int i=0;i<1000;i++)
        {
         for(int x=0;x<5;x++)
           {
            if(AllLines[x][i].isInitialized)
              {
               AllLines[x][i].Update();
              }
           }
        }

      ObjectDelete("Line Break");
      ObjectCreate(0,"Line Break",OBJ_VLINE,0,Time[barsInView],0);
      ObjectSetInteger(0,"Line Break",OBJPROP_COLOR,clrPurple);
      ObjectSetInteger(0,"Line Break",OBJPROP_WIDTH,4);
      LastbarTime=Time[0];
     }
//--- done 
   if(Time[0]!=LastbarTime)
      isNewBar=true;
   else
      isNewBar=false;
   return(rates_total);
  }
//--- handle price entering the range
int getFirstAvailable(int index)
  {

   for(int j=0;j<ArrayRange(AllLines,1);j++)
     {
      if(AllLines[index][j].isInitialized==false)
        {
         return j;
        }
     }

   return -1;//to cause error
  }
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
       {
        if(id==CHARTEVENT_KEYDOWN)
          {
           if(lparam==9)
             {
             Print("shot taken");
              ChartScreenShot(0,TimeToStr(Time[0]),800,600);
             }
          }
         }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
   EventKillTimer();
  }
//+------------------------------------------------------------------+
