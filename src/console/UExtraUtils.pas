{$mode Delphi}
unit UExtraUtils;

interface

uses Dialogs, SysUtils, UDataMod, UMain;

const                         {tbv graphics}
  PosX1=70;
  PosX2=PosX1+600;
  PosY1=70;
  PosY2=PosY1+300;
  LX = PosX2-PosX1;
  LY = PosY2-PosY1;

var
      {Input}
  InputFileName,
  GrTitle1, GrTitle2,
  GrTitle3, Code,
  BriefFileName,
  OriginalName, Mode       : string;
  CalcDone, OutputOpened,
  InputOpened, OutSave     : boolean;
  Xpoint, Ypoint           : array[1..7] of array of real;
    {Graphics}
  PosValues                : array [1..7] of boolean;
  PointX, PointY           : array [1..7] of real;
  Ymax, Ymin               : array[1..7] of real;
  Xcount                   : array of real;
  Xmax, Xmin               : real;
  MaxY, MinY               : array [1..7] of longint;
  MaxX, MinX               : longint;
  Ymaxi, Ymini, Xmaxi,
  Xmini                    : real;
  DecimY, FactorY          : array[1..7] of integer;
  ScaleY                   : array[1..7] of integer;
  ScaleX, NumberWanted     : integer;
  RelYdata                 : array[1..7] of array of integer;
  SideNr                   : array [1..7] of array of integer;
  RelXdata, SeqNr          : array of integer;
  LegendX, LegendY,
  LegendY1, LegendY2,
  LegendY3                 : string;
  HlpNr, Start             : integer;

     {Start}

     {Input}
  procedure CheckGeneralData(var DataOK: boolean);
  procedure CheckNeighbors (var OrderOK : boolean);
  procedure CheckOverallData (var DataOK : boolean);
  procedure CheckNetWorkData (var DataOK : boolean);
  procedure CheckInternalData (var CheckOK : boolean);
  procedure CheckTotPorData (var CheckOK : boolean);
  procedure CheckEffPorData (var CheckOK : boolean);
  procedure CheckLeachingData (var CheckOK : boolean);
  procedure CheckAgricultData (var CheckOK : boolean);
  procedure CheckNegativePolyData (const GroupFile : string;
                                   var CheckOK : boolean;
                                   const NrOfValues : byte);
  procedure CheckAreaData (var CheckOK : boolean);
  procedure CheckNegativeSeasonData (const GroupFile : string;
                                     var CheckOK : boolean);
//  procedure CompareAreaData;
  procedure CheckReUseData (var CheckOK : boolean);
  procedure CheckExtHeadData (var CheckOK : boolean);
  procedure DeleteGroupFiles;
  procedure MoveGroupFiles (var DataPath, DataDir : string);

     {Output}
  procedure CopyFileDown (const NameA, Extension, NameOfFile : string);

    {Graphics}
  procedure MaxMin;
  procedure Scaling;
  procedure Relative;
  procedure GetCorners(var FirstNr : integer);

implementation

     {General Input}

procedure CheckGeneralData(var DataOK: boolean);
{----------------------------------------------}
var ii : byte;
    SumOfMonths : real;
    DurationError : boolean;
begin
  DataOk := false;
  SumOfMonths := 0;
  for ii:=1 to DataMod.NrOfSeasons + DataMod.NrOfSeasonsAdded do
    SumOfMonths := SumOfMonths + DataMod.SeasonDuration[ii];
  if SumOfMonths<>12 then
  begin
    exit;
  end;
  DurationError:=false;
  for ii:=1 to DataMod.NrOfSeasons do
      if DataMod.SeasonDuration[ii]<1 then DurationError:=true;
  if DurationError then
  begin
    exit;
  end;
  if DataMod.TotNrOfPoly+DataMod.NrOfNodesAdded
                        -DataMod.NrOfNodesRemoved>300 then
  begin
    exit;
  end;
  if DataMod.TotNrOfPoly+DataMod.NrOfNodesAdded
                        -DataMod.NrOfNodesRemoved<4 then
  begin
    exit;
  end;
  DataOk:=true;
end; {CheckGeneralData}
{---------------------}


{*****************************************************************************
            End of General Input, start of Polygonal input
******************************************************************************}


procedure CheckOverallData (var DataOK : boolean);
{------------------------------------------------}
var k, NrToBeRemoved : integer;
    NodeError : boolean;
begin
  DataOK:=false;
  with DataMod do
  begin
    NodeError := false;
    for k:=0 to TotNrOfPoly-1 do
    begin
      if (NodeNr[k]<0) then NodeError := true;
    end;
    if NodeError then
    begin
       exit;
    end;
    NodeError:=false;
    if not DataMod.RemovalStage then
    begin
      for k:=0 to TotNrOfPoly-1 do
        if (Int_Ext_Index[k]<>1) and (Int_Ext_Index[k]<>2) then NodeError:=true;
      if NodeError then
      begin
        exit;
      end;
    end else
    begin
      for k:=0 to TotNrOfPoly-1 do
        if (Int_Ext_Index[k]<>1) and (Int_Ext_Index[k]<>2)
           and (Int_Ext_Index[k]<>-1) then NodeError:=true;
      if NodeError then
      begin
        exit;
      end else
      begin
        NrToBeRemoved:=0;
        for k:=0 to TotNrOfPoly-1 do if (Int_Ext_Index[k]=-1) then
            NrToBeRemoved:=NrToBeRemoved+1;
        if NrToBeRemoved<>NrOfNodesRemoved then
        begin
          exit;
        end;
      end;
    end;
    NrOfIntPoly:=0;
    NrOfExtPoly:=0;
    for k:=0 to TotNrOfPoly-1 do
      if Int_Ext_Index[k]=1 then
        NrOfIntPoly:=NrOfIntPoly+1
      else
        if Int_Ext_Index[k]=2 then NrOfExtPoly:=NrOfExtPoly+1;
  end; {with DataMod do}
  DataOK:=true;
end; {CheckOverallData}
{---------------------}



procedure CheckNetWorkData (var DataOK : boolean);
{------------------------------------------------}
var NetworkOK, NegValuePresent : boolean;
    k, j : integer;
begin
  DataOK:=false;
  with DataMod do
  begin
//    if (MainForm.Identity='Network') or (MainForm.Identity='Finished') then
//    begin
      CheckNeighbors (NetWorkOK);
//      if not NetWorkOK then exit;
//    end;
    NegValuePresent:=false;
    //if MainForm.Identity='Conduct' then
    begin
      for k:=0 to NrOfIntPoly-1 do for j:=1 to NrOfSides[k] do
      begin
        if Neighbor[j,k]<0 then NegValuePresent:=true;
        if Conduct[j,k]<0 then NegValuePresent:=true;
        if AquiferType[k]=1 then
        begin
          if (TopCond[j,k]<0) then NegValuePresent:=true;
          if (TopLayer[k]<0) then NegValuePresent:=true;
          if (VertCond[k]<0) then NegValuePresent:=true;
        end else
        begin
          TopCond[j,k]:=-1;
          TopLayer[k]:=-1;
          VertCond[k]:=-1;
        end;
      end;
      if NegValuePresent then
      begin
        exit;
      end;
    end;
  end; {with DataMod do}
  if NetworkOK then DataOK:=true;
end; {CheckNetworkData}
{----------------------}



procedure CheckInternalData (var CheckOK : boolean);
{--------------------------------------------------}
var j, k : integer; PolyError : boolean;
begin
  CheckOK:=false;
  PolyError:=false;
  with DataMod do
  begin
    for k:=0 to NrOfIntPoly-1 do for j:=2 to 3 do
        if HlpValue[j,k]<0.1 then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
    for k:=0 to NrOfIntPoly-1 do
        if (AquiferType[k]<>0) and (AquiferType[k]<>1) then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
  end;
  CheckOK:=true;
end; {TMainForm.CheckInternalData}
{--------------------------------}



procedure CheckTotPorData (var CheckOK : boolean);
{------------------------------------------------}
var j, k : integer;
    PolyError : boolean;
begin
  CheckOK:=false;
  PolyError:=false;
  with DataMod do
  begin
    for k:=0 to NrOfIntPoly-1 do for j:=1 to 3 do
        if (HlpValue[j,k]<0.1) or (HlpValue[j,k]>0.9) then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
  end;
  CheckOK:=true;
end; {CheckTotPorData}
{--------------------}



procedure CheckEffPorData (var CheckOK : boolean);
{------------------------------------------------}
var j, k : integer;
    PolyError, AqError : boolean;
begin
  CheckOK:=false;
  PolyError:=false;
  AqError:=false;
  with DataMod do
  begin
    for k:=0 to NrOfIntPoly-1 do for j:=1 to 4 do
    begin
      if (j<4) and ((HlpValue[j,k]<0.01) or (HlpValue[j,k]>0.5)) then
         PolyError:=true;
      if (j=4) and (DataMod.AquiferType[k]=1) then if HlpValue[j,k]>0.01 then
         AqError:=true;
    end;
    if PolyError then
    begin
      exit;
    end;
  end;
  CheckOK:=true;
end; {CheckEffPorData}
{--------------------}



procedure CheckLeachingData (var CheckOK : boolean);
{--------------------------------------------------}
var j, k : integer;
    PolyError : boolean;
begin
  CheckOK:=false;
  PolyError:=false;
  with DataMod do
  begin
    for k:=0 to NrOfIntPoly-1 do for j:=1 to 3 do
        if (HlpValue[j,k]<0.01) or (HlpValue[j,k]>2) then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
  end;
  CheckOK:=true;
end; {CheckLeachingData}
{----------------------}



procedure CheckAgricultData (var CheckOK : boolean);
{--------------------------------------------------}
var k : integer;
    PolyError : boolean;
begin
  CheckOK:=false;
  PolyError:=false;
  with DataMod do
  begin
    for k:=0 to NrOfIntPoly-1 do
        if (HlpValue[1,k]<>0) and (HlpValue[1,k]<>1) then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
    for k:=0 to NrOfIntPoly-1 do
        if (HlpValue[2,k]<>0) and (HlpValue[2,k]<>1) then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
    for k:=0 to NrOfIntPoly-1 do
        if not round(HlpValue[3,k]) in [0,1,2,3,4] then PolyError:=true;
    for k:=0 to NrOfIntPoly-1 do
        if (HlpValue[4,k]<>0) and (HlpValue[4,k]<>1) then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
  end;
  CheckOK:=true;
end; {CheckAgricultData}
{----------------------}



procedure CheckNegativePolyData (const GroupFile : string;
          var CheckOK : boolean; const NrOfValues : byte);
{--------------------------------------------------------}
var j, k : integer;
    PolyError : boolean;
begin
  CheckOK:=false;
  PolyError:=false;
  with DataMod do
  begin
    for k:=0 to NrOfIntPoly-1 do for j:=1 to NrOfValues do
    begin
      if GroupFile='Drainage' then
      begin
        if (DrainIndex[k]>0) and (HlpValue[j,k]<0) then PolyError:=true;
        if (DrainIndex[k]<1) then HlpValue[j,k]:=-1;
      end else
      if GroupFile='Saltdeep' then
      begin
        if DrainIndex[k]>0 then
        begin
          if HlpValue[1,k]<0 then PolyError:=true;
          if HlpValue[2,k]<0 then PolyError:=true;
          HlpValue[3,k]:=-1;
        end else
        begin
          HlpValue[1,k]:=-1;
          HlpValue[1,k]:=-1;
          if HlpValue[3,k]<0 then PolyError:=true;
          if HlpValue[4,k]<0 then PolyError:=true;
        end;
      end else
      if GroupFile='Critdepth' then
      begin
        if (HlpValue[2,k]<0) then PolyError:=true
      end else
      if GroupFile<>'Extsal' then if DrainIndex[k]>0 then
         if HlpValue[j,k]<0 then PolyError:=true;
    end; {for k:=0 to NrOfIntPoly-1 do for j:=1 to NrOfValues do}
    if GroupFile='Extsal' then
       for k:=0 to NrOfExtPoly-1 do
           if (HlpValue[1,k]<0) then PolyError:=true;
    if PolyError then
    begin
      exit;
    end;
  end; {with DataMod do}
  CheckOK:=true;
end; {CheckNegativePolyData}
{--------------------------}



procedure CheckNeighbors (var OrderOK : boolean);
{-----------------------------------------------}
label 1, 2;
var i, ii, j, jj, k,
    Side, FirstSide,
    NextSide, Tmp,
    TotErr,
    Side1, Side2    : integer;
    Count           : array of integer;
    SideNodeNr,
    NextNodeNr      : array[1..6] of array of integer;
    Swap            : byte;
    DYY, DXX,
    Ang, Temp       : real;
    DX1,DX2,DY1,DY2,
    XM1,XM2,YM1,YM2,
    Tan1,C1,Tan2,C2 : real;
    Angle           : array [1..6] of real;
    ErrInNetw,
    PointErr        : boolean;
    PolyErr         : array of boolean;
    ErrorLine       : string;
begin
  OrderOK:=false;
  with DataMod do
  begin

    ErrInNetw := false;
    for j:=1 to NrOfItems-1 do for k:=0 to NrOfIntPoly-1 do
        if Neighbor[j,k]<0 then ErrInNetw:=true;
    if ErrInNetw then
    begin
       exit;
    end;
    ErrInNetw:=false;
    for k:=0 to NrOfIntPoly-1 do
        if NrOfSides[k]<3 then ErrInNetw:=true;
    if ErrInNetw then
    begin
       exit;
    end;

    {check occurrence of nodal numbers}
    {---------------------------------}
    setlength (Count,TotNrOfPoly);
    for i:=0 to TotNrOfPoly-1 do Count[i]:=0;
    setlength(PolyErr,NrOfIntPoly);
    for i:=0 to NrOfIntPoly-1 do PolyErr[i]:=false;
    ErrInNetw := false;
    TotErr:=0;
                   {Tel het aantal malen dat een bepaalde neighbour voorkomt}
    setlength (NodeNr,TotNrOfPoly);
    for ii:=1 to 6 do setlength(Neighbor[ii],NrOfIntPoly);
    for i:=0 to NrOfIntPoly-1 do
      for ii:=1 to NrOfSides[i] do
        for k:=0 to TotNrOfPoly-1 do
        begin
          if Neighbor[ii,i]=NodeNr[k] then
             Count[k]:=Count[k]+1;
          if (k>NrOfIntPoly-1) and (Neighbor[ii,i]=NodeNr[k]) then
             Count[i]:=Count[i]+1;
        end;
           {Test of het aantal van een bepaalde neighbour overeen komt met het
            aantal zijden van de de interne poly met dat neighbour nummer}
    ErrorLine :='';
    for i:=0 to NrOfIntPoly-1 do
        if Count[i]<>NrOfSides[i] then
        begin
          ErrInNetw  := true;
          PolyErr[i] := true;
          ErrorLine  := ErrorLine + IntToStr(i+1) + ', ';
          TotErr     := TotErr+1;
        end;
    ErrorLine:=copy(ErrorLine,1,length(ErrorLine)-2);

    if ErrInNetw then
    begin
      exit;
    end;

    {Start arranging neighbors}
    {-------------------------}
                 {assigning serial numbers to the neighbor nodes according to
                  the sequence of the nodes in the overall data group and the
                  corresponding coordinates; this is to match the neighbors
                  with the corresponding coordinates}

    for j:=1 to 6 do setlength(SideNodeNr[j],NrOfIntPoly+1);
    for i:=0 to NrOfIntPoly-1 do for j:=1 to NrOfSides[i] do
        SideNodeNr[j,i]:=Neighbor[j,i];
         {SideNodeNr below MAY NOT BE REQUIRED AND CAN BE REPLACED BY Neighbor}
    Tmp:=TotNrOfPoly;
    setlength (SeqNr,TotNrOfPoly+1);
    jj:=-1;
    for i:=0 to TotNrOfPoly-1 do
    begin
      jj:=jj+1;
      SeqNr[NodeNr[i]]:=jj;
    end;
                 {finding angles of lines connecting the nodal point with the
                  neighbors, preparation for arranging neighbors clockwise}
    for k:=0 to NrOfIntPoly-1 do
    begin
      for j:=1 to NrOfSides[k] do
      begin
        Side:=SeqNr[Neighbor[j,k]];
        DYY:=Ycoord[Side]-Ycoord[k];
        DXX:=Xcoord[Side]-Xcoord[k];
        Ang:=0;
        if (DXX=0) and (DYY>0) then Ang:=0;
        if (DXX>0) and (DYY>0) then Ang:=arctan(DXX/DYY);
        if (DYY=0) and (DXX>0) then Ang:=0.5*Pi;
        if (DXX>0) and (DYY<0) then Ang:=-arctan(DYY/DXX)+0.5*Pi;
        if (DXX=0) and (DYY<0) then Ang:=Pi;
        if (DXX<0) and (DYY<0) then Ang:=arctan(DXX/DYY)+Pi;
        if (DYY=0) and (DXX<0) then Ang:=1.5*Pi;
        if (DXX<0) and (DYY>0) then Ang:=arctan(-DXX/DYY)+1.5*Pi;
        if (DXX=0) and (DYY=0) then
        begin
          exit;
        end;
        Angle[j]:=Ang;
      end; {for j:=1 to NrOfSides[k] do}
                                            {arranging neighbors clockwise}
1:    Swap:=0;
      for ii:=1 to NrOfSides[k]-1 do
      begin
        if (Angle[ii]>Angle[ii+1]) then
        begin
          FirstSide:=SeqNr[Neighbor[ii,k]];
          NextSide:=SeqNr[Neighbor[ii+1,k]];
          Temp:=Angle[ii+1];
          Angle[ii+1]:=Angle[ii];
          Angle[ii]:=Temp;
          Tmp:=Neighbor[ii+1,k];
          Neighbor[ii+1,k]:=Neighbor[ii,k];
          Neighbor[ii,k]:=Tmp;
          Swap:=ii;
        end; {Angle[ii]>Angle[ii+1]) then}
        if Swap<>0 then goto 1
      end; {end of Swap loop}

    end; {for k:=1 to NrOfIntPoly-1 do}

    { checking corner points of nodal network}
    {----------------------------------------}
    PointErr:=false;
    for ii:=1 to 7 do setlength (Xpoint[ii],NrOfIntPoly);
    for ii:=1 to 7 do setlength (Ypoint[ii],NrOfIntPoly);
    for j:=1 to 6 do setlength(NextNodeNr[j],NrOfIntPoly+1);
    for j:=1 to 6 do for k:=0 to NrOfIntPoly-1 do
        NextNodeNr[j,k]:=0;

    for k:=0 to NrOfIntPoly-1 do for ii:=1 to NrOfSides[k]-1 do
    begin

      Side1:=SeqNr[Neighbor[ii,k]];
      Side2:=SeqNr[Neighbor[ii+1,k]];
      DX1:=0.5*(Xcoord[Side1]-Xcoord[k]);
      DY1:=0.5*(Ycoord[Side1]-Ycoord[k]);
      DX2:=0.5*(Xcoord[Side2]-Xcoord[k]);
      DY2:=0.5*(Ycoord[Side2]-Ycoord[k]);
      XM1:=Xcoord[k]+DX1;
      YM1:=Ycoord[k]+DY1;
      XM2:=Xcoord[k]+DX2;
      YM2:=Ycoord[k]+DY2;

      Tan1:=0;
      Tan2:=0;
      C1:=0;
      C2:=0;
      if DY1<>0 then
      begin
        Tan1:=-DX1/DY1;
        C1:=YM1-Tan1*XM1;
      end;
      if DY2<>0 then
      begin
        Tan2:=-DX2/DY2;
        C2:=YM2-Tan2*XM2;
      end;
      if (DY1=0) and (DX1<>0) and (DY2<>0) and (DX2<>0) then
      begin
        PointErr:=true;
        NextNodeNr[ii,k]:=SideNodeNr[ii,k];
      end;
      if (DY2=0) and (DX1<>0) and (DY1<>0) and (DX2<>0) then
      begin
        PointErr:=true;
        NextNodeNr[ii,k]:=SideNodeNr[ii,k];
      end;
      if (DX1=0) and (DY1<>0) and (DX2<>0) and (DY2<>0) then
      begin
        Xpoint[ii,k]:=(YM1-C2)/Tan2;
        Ypoint[ii,k]:=YM1;
      end;
      if (DX2=0) and (DY2<>0) and (DX1<>0) and (DY1<>0) then
      begin
        Xpoint[ii,k]:=(YM2-C1)/Tan1;
        Ypoint[ii,k]:=YM2;
      end;
      if (DY1<>0) and (DX1<>0) and (DY2<>0) and (DX2<>0) then
      begin
        if (Tan1=Tan2) then
        begin
          PointErr:=true;
          NextNodeNr[ii,k]:=SideNodeNr[ii,k];
        end;
        if Tan1<>Tan2 then
        begin
          Xpoint[ii,k]:=(C2-C1)/(Tan1-Tan2);
          Ypoint[ii,k]:=Tan1*Xpoint[ii,k]+C1;
        end;
      end;
      if (DY1=0) and (DX1<>0) and (DY2<>0) and (DX2=0) then
      begin
        Xpoint[ii,k]:=XM1;
        Ypoint[ii,k]:=Tan2*XM1+C2;
      end;
      if (DY2=0) and (DX2<>0) and (DY1<>0) and (DX1=0) then
      begin
        Xpoint[ii,k]:=XM2;
        Ypoint[ii,k]:=Tan1*XM2+C1;
      end;
      if ((DY1=0) and (DX1=0)) or ((DY2=0) and (DX2=0)) then
      begin
        PointErr:=true;
        NextNodeNr[ii,k]:=SideNodeNr[ii,k];
      end;
      if PointErr and (ii=NrOfSides[k]) then goto 2;

    end; {for k:=0 to NrOfIntPoly-1 do for ii:=1 to NrOfSides[k]-1 do}

2:  if PointErr then
    begin
      ErrorLine:='';
      for k:=0 to NrOfIntPoly-1 do for j:=1 to NrOfSides[k] do
          if NextNodeNr[j,k]>0 then
             ErrorLine:=ErrorLine+' ('+IntToStr(NodeNr[k])+','+
                        IntToStr(NextNodeNr[j,k])+')  ';
      exit;
    end;

  end; {with DataMod do}
  for j:=1 to 6 do setlength(NextNodeNr[j],1);
  OrderOK := true;
end; {CheckNeighbors}
{-------------------}



procedure GetCorners(var FirstNr : integer);
{------------------------------------------}
var
  C1,C2,DX1,DX2,DY1,DY2,XM1,XM2,YM1,YM2,Tan1,Tan2 : real;
  Num, PoNr, Side1, Side2, ii : integer;
  AuxY1, AuxY2, AuxX1, AuxX2, ADX1, ADX2, ADY1, ADY2 : real;
begin

  PoNr:=FirstNr-1;
  Num:=DataMod.NrOfSides[PoNr];
  SideNr[Num+1,PoNr]:=SideNr[1,PoNr];
                      {the first neighbour is needed extra to close the polygon}
  if Num>2 then with DataMod do for ii:=1 to Num do
  begin
    Side1:=SeqNr[SideNr[ii,PoNr]];
    Side2:=SeqNr[SideNr[ii+1,PoNr]];
    DX1:=0.5*(Xcoord[Side1]-Xcoord[PoNr]);
    DY1:=0.5*(Ycoord[Side1]-Ycoord[PoNr]);
    DX2:=0.5*(Xcoord[Side2]-Xcoord[PoNr]);
    DY2:=0.5*(Ycoord[Side2]-Ycoord[PoNr]);
    XM1:=Xcoord[PoNr]+DX1;
    YM1:=Ycoord[PoNr]+DY1;
    XM2:=Xcoord[PoNr]+DX2;
    YM2:=Ycoord[PoNr]+DY2;
    AuxY1:=0.4;
    AuXY2:=0.4;
    AuxX1:=0.4;
    AuxX2:=0.4;
    ADX1:=abs(DX1);
    ADX2:=abs(DX2);
    ADY1:=abs(DY1);
    ADY2:=abs(DY2);
    Tan1:=1;
    Tan2:=1;
    C1:=1;
    C2:=1;
//    if DY1<>0 then
    if ADY1>AuxY1 then
    begin
      Tan1:=-DX1/DY1;
      C1:=YM1-Tan1*XM1;
    end;
//    if DY2<>0 then
    if ADY2>AuxY2 then
    begin
      Tan2:=-DX2/DY2;
      C2:=YM2-Tan2*XM2;
    end;
//    if (DY1=0) and (DX1<>0) and (DY2<>0) and (DX2<>0) then
    if (ADY1<AuxY1) and (ADX1>AuxX1) and (ADY2>AuxY2) and (ADX2>AuxX2) then
    begin
      PointY[ii]:=YM1;
      PointX[ii]:=(YM1-C2)/Tan2;
    end;
//    if (DY2=0) and (DX1<>0) and (DY1<>0) and (DX2<>0) then
    if (ADY2<AuxY2) and (ADX1>AuxX1) and (ADY1>AuxY1) and (ADX2>AuxX2) then
    begin
      PointY[ii]:=YM2;
      PointX[ii]:=(YM2-C1)/Tan1;
    end;
//    if (DX1=0) and (DY1<>0) and (DX2<>0) and (DY2<>0) then
    if (ADX1<AuxX1) and (ADY1>AuxY1) and (ADX2>AuxX2) and (ADY2>AuxY2) then
    begin
      PointX[ii]:=(YM1-C2)/Tan2;
      PointY[ii]:=YM1;
    end;
//    if (DX2=0) and (DY2<>0) and (DX1<>0) and (DY1<>0) then
    if (ADX2<AuxX2) and (ADY2>AuxY2) and (ADX1>AuxX1) and (ADY1>AuxY1) then
    begin
      PointX[ii]:=(YM2-C1)/Tan1;
      PointY[ii]:=YM2;
    end;
//    if (DY1=0) and (DX1<>0) and (DY2<>0) and (DX2<>0) then
    if (ADY1<AuxY1) and (ADX1>AuxX1) and (ADY2>AuxY2) and (ADX2>AuxX2) then
    begin
      if (Tan1=Tan2) then
      begin
        PointX[ii]:=Xmaxi;
        PointY[ii]:=Ymini;
      end;
      if Tan1<>Tan2 then
      begin
        PointX[ii]:=(C2-C1)/(Tan1-Tan2);
        PointY[ii]:=Tan1*PointX[ii]+C1;
      end;
    end;
//    if (DY1=0) and (DX1<>0) and (DY2<>0) and (DX2=0) then
    if (ADY1<AuxY1) and (ADX1>AuxX1) and (ADY2>AuxY2) and (ADX2<AuxX2) then
    begin
      PointX[ii]:=XM1;
      PointY[ii]:=Tan2*XM1+C2;
    end;
//    if (DY2=0) and (DX2<>0) and (DY1<>0) and (DX1=0) then
    if (ADY2<AuxY2) and (ADX2>AuxX2) and (ADY1>AuxY1) and (ADX1<AuxX1) then
    begin
      PointX[ii]:=XM2;
      PointY[ii]:=Tan1*XM2+C1;
    end;
//    if ((DY1=0) and (DX1=0)) or ((DY2=0) and (DX2=0)) then
    if ((ADY1<AuxY1) and (ADX1<AuxX1)) or ((ADY2<AuxY2) and (ADX2<AuxX2)) then
    begin
      PointX[ii]:=Xmini;
      PointY[ii]:=Ymaxi;
    end;
//    if ((DX1=0) and (DX2=0)) or (DY1=0) and (DY2=0) then
    if ((ADX1<AuxX1) and (ADX2<AuxX2)) or ((ADY1<AuxY1) and (ADY2<AuxY2)) then
    begin
      PointX[ii]:=Xcoord[Side1];
      PointY[ii]:=Ycoord[Side2];
    end;
    if (PointX[ii]>Xmaxi) or (PointX[ii]<Xmini) or
       (PointY[ii]>Ymaxi) or (PointY[ii]<Ymini) then
    begin
        if PointX[ii]>Xmaxi then PointX[ii]:=Xmaxi;
        if PointX[ii]<Xmini then PointX[ii]:=Xmini;
        if PointY[ii]>Ymaxi then PointY[ii]:=Ymaxi;
        if PointY[ii]<Ymini then PointY[ii]:=Ymini;
    end;
  end; {end of sidal loop}
end; {end of GetCorners}
{----------------------}



{*****************************************************************************
     End of Polygonal input, start of Seasonal input
******************************************************************************}


procedure CheckAreaData (var CheckOK : boolean);
{----------------------------------------------}
var i, j : byte; k : integer;
    RiceError, InitCheckOK : boolean;
begin
  InitCheckOK:=CheckOK;
  CheckOK:=false;
  RiceError:=false;
  for i:=1 to 4 do
  begin
    for j:=1 to DataMod.NrOfSeasons do for k:=0 to DataMod.NrOfIntPoly-1 do
    begin
      if (i=1) or (i=2) then if DataMod.AuxValue[i,j,k]>1 then
      begin
        exit;
      end;
    end;
  end;
  for j:=1 to DataMod.NrOfSeasons do for k:=0 to DataMod.NrOfIntPoly-1 do
  begin
    DataMod.AreaA[j,k]:=DataMod.AuxValue[1,j,k];
    DataMod.AreaB[j,k]:=DataMod.AuxValue[2,j,k];
    if (DataMod.AuxValue[1,j,k]>0) then
       if (DataMod.AuxValue[3,j,k]<>0) and (DataMod.AuxValue[3,j,k]<>1) then
           RiceError:=true;
    if (DataMod.AuxValue[2,j,k]>0) then
       if (DataMod.AuxValue[4,j,k]<>0) and (DataMod.AuxValue[4,j,k]<>1) then
           RiceError:=true;
  end;
  if RiceError then
  begin
    exit;
    end;
  for j:=1 to DataMod.NrOfSeasons do for k:=0 to DataMod.NrOfIntPoly-1 do
  begin
    if DataMod.AuxValue[1,j,k]+DataMod.AuxValue[2,j,k]>1.001 then
    begin
      exit;
    end;
  end;
  for j:=1 to DataMod.NrOfSeasons do
      setlength (DataMod.AreaA[j],DataMod.NrOfIntPoly);
  for j:=1 to DataMod.NrOfSeasons do
      setlength (DataMod.AreaB[j],DataMod.NrOfIntPoly);
  for j:=1 to DataMod.NrOfSeasons do for k:=0 to DataMod.NrOfIntPoly-1 do
  begin
    DataMod.AreaA[j,k]:=DataMod.AuxValue[1,j,k];
    DataMod.AreaB[j,k]:=DataMod.AuxValue[2,j,k];
  end;
  CheckOK:=true;
end;{CheckAreaData}
{-----------------}



procedure CheckNegativeSeasonData (const GroupFile : string;
                                   var CheckOK : boolean);
{----------------------------------------------------------}
var j, k : integer;
    PolyError : boolean;
begin
  CheckOK:=false;
  PolyError:=false;
  with DataMod do
  begin
    for j:=1 to NrOfSeasons do for k:=0 to NrOfIntPoly-1 do
    begin
      if GroupFile='Areas' then
      begin
        if AuxValue[1,j,k]<0 then PolyError:=true;
        if AuxValue[2,j,k]<0 then PolyError:=true;
        if AuxValue[1,j,k]=0 then AuxValue[3,j,k]:=-1;
        if AuxValue[2,j,k]=0 then AuxValue[4,j,k]:=-1;
        if (AuxValue[1,j,k]>0) and (AuxValue[3,j,k]<0) then PolyError:=true;
        if (AuxValue[2,j,k]>0) and (AuxValue[4,j,k]<0) then PolyError:=true;
      end
      else
      if GroupFile='Climate' then
      begin
        if (AuxValue[1,j,k]<0) then PolyError:=true;
        if (AreaA[j,k]>0) and (AuxValue[2,j,k]<0) then PolyError:=true;
        if (AreaA[j,k]=0) then AuxValue[2,j,k]:=-1;
        if (AreaB[j,k]>0) and (AuxValue[3,j,k]<0) then PolyError:=true;
        if (AreaB[j,k]=0) then AuxValue[3,j,k]:=-1;
        if (AreaA[j,k]+AreaB[j,k]<1) and (AuxValue[4,j,k]<0) then
            PolyError:=true;
        if (ResponsIndex[k]=1) and (AuxValue[4,j,k]<0) then PolyError:=true;
        if (AreaA[j,k]+AreaB[j,k]=1) and (ResponsIndex[k]=0) then
            AuxValue[4,j,k]:=-1;
      end
      else
      if GroupFile='Surfdrain' then
      begin
        if (AreaA[j,k]+AreaB[j,k]<1) or (ResponsIndex[k]=1) then
        if (AuxValue[1,j,k]<0) or (AuxValue[2,j,k]<0) then
            PolyError:=true;
        if (AreaA[j,k]+AreaB[j,k]=1) and (ResponsIndex[k]=0) then
        begin
          AuxValue[1,j,k]:=-1;
          AuxValue[2,j,k]:=-1;
        end;
        if (AreaA[j,k]>0) and (AuxValue[3,j,k]<0) then PolyError:=true;
        if (AreaA[j,k]=0) then AuxValue[3,j,k]:=-1;
        if (AreaB[j,k]>0) and (AuxValue[4,j,k]<0) then PolyError:=true;
        if (AreaB[j,k]=0) then AuxValue[4,j,k]:=-1;
      end;
      if GroupFile='Irrigation' then
      begin
        if (AreaA[j,k]>0) or (AreaB[j,k]>0) then
            if AuxValue[1,j,k]<0 then PolyError:=true;
        if (AreaA[j,k]>0) or (AreaB[j,k]>0) then
            if AuxValue[2,j,k]<0 then PolyError:=true;
        if (AreaA[j,k]>0) and (AuxValue[3,j,k]<0) then PolyError:=true;
        if (AreaA[j,k]=0) then AuxValue[3,j,k]:=-1;
        if (AreaB[j,k]>0) and (AuxValue[4,j,k]<0) then PolyError:=true;
        if (AreaB[j,k]=0) then AuxValue[4,j,k]:=-1;
      end;
      if GroupFile='Storeff' then
      begin
        if (AreaA[j,k]>0) and (AuxValue[1,j,k]<0) then PolyError:=true;
        if (AreaA[j,k]=0) then AuxValue[1,j,k]:=-1;
        if (AreaB[j,k]>0) and (AuxValue[2,j,k]<0) then PolyError:=true;
        if (AreaB[j,k]=0) then AuxValue[2,j,k]:=-1;
        if (AreaA[j,k]+AreaB[j,k]<1) and (AuxValue[3,j,k]<0) then
            PolyError:=true;
        if (AreaA[j,k]+AreaB[j,k]=1) then
            if (ResponsIndex[k]<1) then AuxValue[3,j,k]:=-1
            else
                if (AuxValue[3,j,k]<0) then PolyError:=true;
      end;
    end; {for j:=1 to NrOfSeasons do for k:=0 to NrOfIntPoly-1 do}
  end; {with DataMod do}
  if PolyError then
  begin
    exit;
  end;
  if not PolyError then CheckOK:=true;
end; {CheckNegativeSeasonData}
{----------------------------}



procedure CheckReUseData (var CheckOK : boolean);
{-----------------------------------------------}
var j, k : integer;
    SeasonError : boolean;
begin
  CheckOK:=false;
  SeasonError:=false;
  with DataMod do for j:=1 to NrOfSeasons do
       for k:=0 to NrOfIntPoly-1 do
           if (DrainIndex[k]>0) and (AuxValue[1,j,k]<0) then SeasonError:=true;
  if SeasonError then
  begin
    exit;
  end;
  SeasonError:=false;
  with DataMod do for j:=1 to NrOfSeasons do
       for k:=0 to NrOfIntPoly-1 do
       if Pumpage[j,k]>0 then
          if (AuxValue[2,j,k]<0) or (AuxValue[2,j,k]>1) then
              SeasonError:=true;
  if SeasonError then
  begin
    exit;
  end;
  CheckOK:=true;
end;{CheckReUseData}
{------------------}



procedure CheckExtHeadData (var CheckOK : boolean);
{-----------------------------------------------}
var ii, jj, NextNode : integer;
    DoBottomTest : array of boolean;
    TmpVar: array [1..5] of array of real;
begin
with DataMod do
begin

  CheckOK:=false;
  for jj:=1 to NrOfSeasons+1 do setlength(TmpVar[jj],NrOfExtPoly);
  for jj:=1 to NrOfSeasons+1 do for ii:=0 to NrOfExtPoly-1 do
      TmpVar[jj,ii]:=HlpValue[jj,ii];
//The above is required to remember HlpValue that is changed in the following
//read procedures
  ReadPolyGroup('Name02',4);
  ReadNetworkGroup('Starting');
  for jj:=1 to NrOfSeasons+1 do setlength(HlpValue[jj],NrOfExtPoly);
  for jj:=1 to NrOfSeasons+1 do for ii:=0 to NrOfExtPoly-1 do
      HlpValue[jj,ii]:=TmpVar[jj,ii];
  setlength (DoBottomTest,TotNrOfPoly);
  for ii:=0 to TotNrOfPoly-1 do DoBottomTest[ii]:=true;
  for ii:=0 to NrOfIntPoly-1 do for jj:=1 to NrOfSides[ii] do
  begin
    NextNode:=Neighbor[jj,ii];
    if (Int_Ext_Index[NextNode-1]=2) and (Conduct[jj,ii]=0) then
        DoBottomTest[NextNode-1]:=false;
  end;
  for jj:=1 to NrOfSeasons do for ii:=0 to NrOfExtPoly-1 do
  begin
    if DoBottomTest[ii+NrOfIntPoly] and (BottomLevel[ii]>=HlpValue[jj+1,ii])
    then
    begin
      exit;
    end;
  end;

  setlength (DoBottomTest,1);
  for jj:=1 to NrOfSeasons+1 do setlength (TmpVar[jj],1);
  CheckOK:=true;

end; {with DataMod do}
end;{CheckExtHeadData}
{--------------------}


{*****************************************************************************
     End of Seasonal Input, start of Output
******************************************************************************}


procedure DeleteGroupFiles;
{-------------------------}
begin
  if fileexists ('Name0') then deletefile ('Name0');
  if fileexists ('Name01') then deletefile ('Name01');
  if fileexists ('Name02') then deletefile ('Name02');
  if fileexists ('Name03') then deletefile ('Name03');
  if fileexists ('Name04') then deletefile ('Name04');
  if fileexists ('Name05') then deletefile ('Name05');
  if fileexists ('Name06') then deletefile ('Name06');
  if fileexists ('Name07') then deletefile ('Name07');
  if fileexists ('Name08') then deletefile ('Name08');
  if fileexists ('Name09') then deletefile ('Name09');
  if fileexists ('Name10') then deletefile ('Name10');
  if fileexists ('Name11') then deletefile ('Name11');
  if fileexists ('Name12') then deletefile ('Name12');
  if fileexists ('Name13') then deletefile ('Name13');
  if fileexists ('Name14') then deletefile ('Name14');
  if fileexists ('Name15') then deletefile ('Name15');
  if fileexists ('Name16') then deletefile ('Name16');
  if fileexists ('Name17') then deletefile ('Name17');
  if fileexists ('Name18') then deletefile ('Name18');
  if fileexists ('Name19') then deletefile ('Name19');
  if fileexists ('Name20') then deletefile ('Name20');
end; {DeleteGroupFiles}
{---------------------}



procedure MoveGroupFiles (var DataPath, DataDir : string);
{--------------------------------------------------------}
var OldName, NewName : string;
begin
  OldName:=DataPath+'\Name0';
  NewName:=DataDir+'\Name0';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name01';
  NewName:=DataDir+'\Name01';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name02';
  NewName:=DataDir+'\Name02';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name03';
  NewName:=DataDir+'\Name03';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name04';
  NewName:=DataDir+'\Name04';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name05';
  NewName:=DataDir+'\Name05';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name06';
  NewName:=DataDir+'\Name06';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name07';
  NewName:=DataDir+'\Name07';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name08';
  NewName:=DataDir+'\Name08';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name09';
  NewName:=DataDir+'\Name09';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name10';
  NewName:=DataDir+'\Name10';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name11';
  NewName:=DataDir+'\Name11';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name12';
  NewName:=DataDir+'\Name12';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name13';
  NewName:=DataDir+'\Name13';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name14';
  NewName:=DataDir+'\Name14';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name15';
  NewName:=DataDir+'\Name15';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name16';
  NewName:=DataDir+'\Name16';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name17';
  NewName:=DataDir+'\Name17';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name18';
  NewName:=DataDir+'\Name18';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name19';
  NewName:=DataDir+'\Name19';
  RenameFile (OldName,NewName);
  OldName:=DataPath+'\Name20';
  NewName:=DataDir+'\Name20';
  RenameFile (OldName,NewName);
end; {MoveGroupFiles}
{-------------------}



procedure CopyFileDown (const NameA, Extension, NameOfFile : string);
{-------------------------------------------------------------------}
var OutFile1,OutFile2 : textfile;
    TextLine, NameB : string;
begin
      AssignFile(OutFile1,NameA);
      Reset(OutFile1);
      NameB:=ChangeFileExt(NameOfFile,Extension);
      AssignFile(OutFile2,NameB);
      Rewrite(OutFile2);
      while not eof(OutFile1) do
      begin
        readln (OutFile1,TextLine);
        writeln (OutFile2,TextLine);
      end;
      closefile (OutFile1);
      closefile (OutFile2);
end; {CopyFileDown}
{-----------------}


{*****************************************************************************
     End of Output, start of Graphics
******************************************************************************}


{MaxMin is part of Graphics}
{--------------------------}
procedure MaxMin;
var ii, jj, Count : integer;
begin
  with DataMod do
  begin
    for ii:=1 to NrOfitems do Ymax[ii] := -1000000;
    for ii:=1 to NrOfitems do Ymin[ii] := 1000000;
    for ii:=1 to NrOfitems do if PosValues[ii] then
        for jj:=0 to DataMod.NrOfData-1 do
        begin
          if Variable[ii,jj]>Ymax[ii] then
             Ymax[ii] := Variable[ii,jj];
          if (Variable[ii,jj]<Ymin[ii]) then
          begin
             Ymin[ii] := 0.95*Variable[ii,jj];
             if Ymin[ii]<0 then Ymin[ii] := 0;
          end;
        end;

    if GroupMark='Zs' then
    if PosValues[5] then
    begin
      Ymax[5]:=-1000000;
      Ymin[5]:=1000000;
      for jj:=0 to DataMod.NrOfData-1 do
      begin
        if Variable[5,jj]>Ymax[5] then
           Ymax[5] := Variable[5,jj];
        if (Variable[6,jj]<Ymin[5]) then
        begin
          Ymin[5] := 0.95*Variable[5,jj];
          if Ymin[5]<0 then Ymin[5] := 0;
        end;
      end;
    end; {if GroupMark='Zs' then}

    if GroupMark='Dw' then
    begin
      Ymax[1]:=-1000000;
      Ymin[1]:=1000000;
      for jj:=0 to DataMod.NrOfData-1 do
      begin
        if Variable[1,jj]>Ymax[1] then
           Ymax[1] := Variable[1,jj];
        if (Variable[1,jj]<Ymin[1]) then
          Ymin[1] := Variable[1,jj];
      end;
    end; {if (GroupMark='Dw') then}

    if GroupMark='EaU' then
    if PosValues[6] then
    begin
      Ymax[6]:=-1000000;
      Ymin[6]:=1000000;
      for jj:=0 to DataMod.NrOfData-1 do
      begin
        if Variable[6,jj]>Ymax[6] then
           Ymax[6] := Variable[6,jj];
        if (Variable[6,jj]<Ymin[6]) then
        begin
          Ymin[6] := Variable[6,jj];
          if Ymin[6]<0 then Ymin[6] := 0;
        end;
      end;
    end; {if GroupMark='EaU' then}

    Count := 0;
    Setlength(Xcount,Count+1);
    Xcount[Count]:=0;
    for ii:=1 to NrOfSeasons do if DataMod.SeasonDuration[ii]=0 then
        DataMod.SeasonDuration[ii]:=12 div DataMod.NrOfSeasons;
    if not PolyData then
    begin
      for jj:=0 to NrOfYears do for ii:=1 to NrOfSeasons do
      begin
        Count := Count+1;
        Setlength(Xcount,Count+1);
        Xcount[Count] := Xcount[Count-1] + DataMod.SeasonDuration[ii];
      end;
    end else
    begin
      Setlength(XCount,NumberWanted+1);
      for jj:=1 to NumberWanted do XCount[jj]:=jj;
    end;

  end; {with DataMod do}
end;
{end of Maxmin}
{-------------}



{Scaling is part of Graphics}
{---------------------------}
procedure Scaling;
var ii, jj : integer;
begin

  for ii:=1 to DataMod.NrOfitems do
  begin
    Ymax[ii]:=1.1*Ymax[ii];
    FactorY[ii]:=1;
  end;

  Start:=1;
  HlpNr:=DataMod.NrOfitems;
  if (DataMod.GroupMark='Zs') or (DataMod.GroupMark='EaU') then
  begin
    Start:=6;
    HlpNr:=6;
  end;
  if (DataMod.GroupMark='Gd') then HlpNr:=4;

  if DataMod.GroupMark<>'Dw' then
  begin

    for ii:=Start to HlpNr do if PosValues[ii]then
    begin
      if (Ymax[ii]<0.01) then
          FactorY[ii]:=1000;
      if (Ymax[ii]>=0.01) and (Ymax[ii]<0.1) then
          FactorY[ii]:=100;
      if (Ymax[ii]<1) and (Ymax[ii]>=0.1) then
          FactorY[ii]:=10;
    end;

    if (DataMod.GroupMark='A') or (DataMod.GroupMark='FfA') then
    for ii:=Start to HlpNr do if PosValues[ii]then
    begin
     FactorY[ii]:=100;
     MinY[ii]:=0;
     MaxY[ii]:=100;
    end;

    for ii:=Start to HlpNr do if PosValues[ii] then
    if FactorY[ii]>1 then
    begin
      for jj:=0 to DataMod.NrOfData-1 do
        DataMod.Variable[ii,jj]:=FactorY[ii]*DataMod.Variable[ii,jj];
      Ymin[ii]:=FactorY[ii]*Ymin[ii];
      Ymax[ii]:=FactorY[ii]*Ymax[ii];
    end;

    for ii:=Start to HlpNr do if PosValues[ii] then
    begin
      if (Ymax[ii]>=1) and (Ymax[ii]<10) then
      begin
        decimY[ii] := 1;
        MinY[ii] := round (Ymin[ii]-0.5);
        MaxY[ii] := round (Ymax[ii]+1.0);
        ScaleY[ii] := MaxY[ii]-MinY[ii];
        if ScaleY[ii]>10 then ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 2;
      end
      else if Ymax[ii]<25 then
      begin
        decimY[ii] := 1;
        MinY[ii] := 4*round ((Ymin[ii]-2)/4);
        MaxY[ii] := 4*round ((Ymax[ii]+2)/4);
        ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 4;
      end
      else if Ymax[ii]<50 then
      begin
        decimY[ii] := 1;
        MinY[ii] := 5*round ((Ymin[ii]-2.5)/5);
        MaxY[ii] := 5*round ((Ymax[ii]+2.5)/5);
        ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 5;
      end
      else if Ymax[ii]<125 then
      begin
        decimY[ii] := 0;
        MinY[ii] := 10*round ((Ymin[ii]-5)/10);
        MaxY[ii] := 10*round ((Ymax[ii]+5)/10);
        ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 10;
      end
      else if Ymax[ii]<250 then
      begin
        decimY[ii] := 0;
        MinY[ii] := 25*round ((Ymin[ii]-12.5)/25);
        MaxY[ii] := 25*round ((Ymax[ii]+12.5)/25);
        ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 25;
      end
      else if Ymax[ii]<500 then
      begin
        decimY[ii] := 0;
        MinY[ii] := 50*round ((Ymin[ii]-25)/50);
        MaxY[ii] := 50*round ((Ymax[ii]+25)/50);
        ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 50;
      end else
      if Ymax[ii]<1000 then
      begin
        decimY[ii] := 0;
        MinY[ii] := 100*round ((Ymin[ii]-50)/100);
        MaxY[ii] := 100*round ((Ymax[ii]+50)/100);
        ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 100;
      end;
      if Ymax[ii]>=1000 then
      begin
        decimY[ii] := 0;
        MinY[ii] := 1000*round ((Ymin[ii]-500)/1000);
        MaxY[ii] := 1000*round ((Ymax[ii]+500)/1000);
        ScaleY[ii] := (MaxY[ii]-MinY[ii]) div 1000;
      end;
    end; {for ii:=1 to DataMod.NrOfitems do}

    for ii:=Start to HlpNr do if PosValues[ii] then
    begin
      if ScaleY[ii]>10 then
      begin
        ScaleY[ii] := 10;
        DecimY[ii] := DecimY[ii]+1;
      end;
      if ScaleY[ii]<4 then
      begin
        ScaleY[ii] := 5;
        DecimY[ii] := DecimY[ii]+1;
      end;
    end;

  end; {if (DataMod.GroupMark<>'Dw') then}

  if DataMod.GroupMark='Zs' then
  begin
    decimY[5] := 1;
    MinY[5] := round (Ymin[5]-0.5);
    if YMax[5]<=0 then MaxY[5]:=0;
    if Ymax[5]>0 then MaxY[5] := round (Ymax[5]+0.5);
    ScaleY[5] := MaxY[1]-MinY[5];
  end;

  if DataMod.GroupMark='Dw' then
  begin
    decimY[1] := 1;
    MinY[1] := round (Ymin[1]-0.5);
    if YMax[1]<=0 then MaxY[1]:=0;
    if Ymax[1]>0 then MaxY[1] := round (Ymax[1]+0.5);
    ScaleY[1] := MaxY[1]-MinY[1];
  end;

  if DataMod.GroupMark='EaU' then
  begin
    decimY[6] := 1;
    MinY[6] := round (Ymin[6]-0.5);
    if YMax[6]<=0 then MaxY[6]:=0;
    if Ymax[6]>0 then MaxY[6] := round (Ymax[6]+0.5);
    ScaleY[6] := MaxY[6]-MinY[1];
  end;

  for ii:=1 to 6 do
  begin
    if ScaleY[ii]<4 then ScaleY[ii]:=4;
    if ScaleY[ii]>10 then ScaleY[ii]:=10;
  end;
    
end;
{end of Scaling}
{--------------}



{Relative is part of Graphics}
{----------------------------}
procedure Relative;
var  count, ii, jj      : integer;
     Start, HlpNr       : integer;
     XdataRel,YdataRel  : real;
     Minimum, Maximum   : real;
begin
  MinX := 0;
  if not DataMod.PolyData then MaxX:=12*DataMod.NrOfYears+12
  else MaxX:=NumberWanted;
  Count:=0;
  for jj:=0 to DataMod.NrOfData-1 do
  begin
    Count:=Count+1;
    setlength (RelXdata,Count+1);
    XdataRel := LX*(Xcount[Count-1]-MinX)/(MaxX-MinX);
    RelXdata[jj] := PosX1+round(XdataRel);
  end;
  Maximum:=0;
  Minimum:=1000000;
  Start:=1;
  HlpNr:=DataMod.NrOfitems;
  for ii:=Start to HlpNr do if PosValues[ii] then
  begin
    if MaxY[ii]>Maximum then Maximum:=MaxY[ii];
    if MinY[ii]<Minimum then Minimum:=MinY[ii];
  end;
  if DataMod.GroupMark='Zs' then
  begin
    Start:=5;
    HlpNr:=5;
    Minimum:=MinY[5];
    Maximum:=MaxY[5];
  end;
  if DataMod.GroupMark='Dw' then
  begin
    Start:=1;
    HlpNr:=1;
    Minimum:=MinY[1];
    Maximum:=MaxY[1];
  end;
  if DataMod.GroupMark='EaU' then
  begin
    Start:=6;
    HlpNr:=6;
    Minimum:=MinY[6];
    Maximum:=MaxY[6];
  end;
  if DataMod.GroupMark<>'Dw' then
  begin
    for ii:=Start to HlpNr do if PosValues[ii] then
      for jj:=0 to DataMod.NrOfData-1 do
      begin
        SetLength (RelYdata[ii],jj+1);
        if (DataMod.Variable[ii,jj]<0) then
            DataMod.Variable[ii,jj]:=0;
         YdataRel :=
            LY*(DataMod.Variable[ii,jj]-Minimum)/(Maximum-Minimum);
         RelYdata[ii,jj] := PosY2-round(YdataRel);
      end;
   end else
     for jj:=0 to DataMod.NrOfData-1 do
     begin
       SetLength (RelYdata[1],jj+1);
       YdataRel := LY*(DataMod.Variable[1,jj]-Minimum)/(Maximum-Minimum);
       RelYdata[1,jj] := PosY2-round(YdataRel);
     end;
  {end;}
end;
{---------------}
{end of Relative}


end.
