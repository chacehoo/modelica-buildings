﻿within Buildings.Controls.OBC.ASHRAE.PrimarySystem.ChillerPlant.Tower.FanSpeed.ReturnWaterTemperature.Subsequences;
block Enable "Sequence for enabling and disabling tower fan"

  parameter Integer nChi=2 "Total number of chillers";
  parameter Integer nTowCel=4 "Total number of cooling tower cells";
  parameter Real fanSpeChe = 0.005 "Lower threshold value to check fan speed";
  parameter Real fanSpeMin = 0.1 "Minimum tower fan speed";

  Buildings.Controls.OBC.CDL.Interfaces.RealInput uMaxTowSpeSet[nChi](
    final min=fill(0, nChi),
    final max=fill(1, nChi),
    final unit=fill("1", nChi))
    "Maximum cooling tower speed setpoint from each chiller head pressure control loop"
    annotation (Placement(transformation(extent={{-220,160},{-180,200}}),
      iconTransformation(extent={{-140,80},{-100,120}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealInput uFanSpe(
    final min=0,
    final max=1,
    final unit="1") "Tower fan speed"
    annotation (Placement(transformation(extent={{-220,100},{-180,140}}),
      iconTransformation(extent={{-140,40},{-100,80}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealInput TTowSet(
    final unit="K",
    final quantity="ThermodynamicTemperature") "Tower temperature setpoint"
    annotation (Placement(transformation(extent={{-220,20},{-180,60}}),
      iconTransformation(extent={{-140,0},{-100,40}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealInput TTow(
    final unit="K",
    final quantity="ThermodynamicTemperature") "Measured tower temperature"
    annotation (Placement(transformation(extent={{-220,-20},{-180,20}}),
      iconTransformation(extent={{-140,-40},{-100,0}})));
  Buildings.Controls.OBC.CDL.Interfaces.BooleanInput uTowSta[nTowCel]
    "Cooling tower operating status: true=running tower cell"
    annotation (Placement(transformation(extent={{-220,-140},{-180,-100}}),
      iconTransformation(extent={{-140,-80},{-100,-40}})));
  Buildings.Controls.OBC.CDL.Interfaces.IntegerInput uConWatPumNum
    "Number of enabled condenser water pumps"
    annotation (Placement(transformation(extent={{-220,-180},{-180,-140}}),
      iconTransformation(extent={{-140,-120},{-100,-80}})));
  Buildings.Controls.OBC.CDL.Interfaces.BooleanOutput yTow
    "Tower fan status: true=enable fans; false=disable all fans"
    annotation (Placement(transformation(extent={{180,-160},{220,-120}}),
      iconTransformation(extent={{100,-20},{140,20}})));

protected
  Buildings.Controls.OBC.CDL.Continuous.Feedback feedback[nChi] "Input difference"
    annotation (Placement(transformation(extent={{-70,150},{-50,170}})));
  Buildings.Controls.OBC.CDL.Continuous.Hysteresis hys[nChi](
    final uLow=fill(fanSpeChe, nChi),
    final uHigh=fill(fanSpeChe + 0.005, nChi))
    "Check if chiller head pressure control maximum tower speed is greater than the minimum tower speed "
    annotation (Placement(transformation(extent={{-40,150},{-20,170}})));
  Buildings.Controls.OBC.CDL.Logical.MultiOr mulOr(final nu=nChi)
    annotation (Placement(transformation(extent={{40,150},{60,170}})));
  Buildings.Controls.OBC.CDL.Logical.Not not1[nChi] "Logical not"
    annotation (Placement(transformation(extent={{0,150},{20,170}})));
  Buildings.Controls.OBC.CDL.Logical.Timer tim
    "Count the time when the chiller head pressure control maximum  tower speed equals tower minimum speed"
    annotation (Placement(transformation(extent={{80,150},{100,170}})));
  Buildings.Controls.OBC.CDL.Continuous.Hysteresis hys1[nChi](
    final uLow=fill(fanSpeChe, nChi),
    final uHigh=fill(fanSpeChe + 0.005, nChi))
    "Check if chiller has been enabled, an enabled chiller will have the head pressure control maximum cooling tower speed that is greater than zero"
    annotation (Placement(transformation(extent={{-140,170},{-120,190}})));
  Buildings.Controls.OBC.CDL.Logical.Switch swi[nChi] "Logical switch"
    annotation (Placement(transformation(extent={{-100,150},{-80,170}})));
  Buildings.Controls.OBC.CDL.Continuous.GreaterEqualThreshold greEquThr(
    final threshold=300)
    "Threshold time"
    annotation (Placement(transformation(extent={{120,150},{140,170}})));
  Buildings.Controls.OBC.CDL.Continuous.Feedback feedback1 "Input difference"
    annotation (Placement(transformation(extent={{-90,110},{-70,130}})));
  Buildings.Controls.OBC.CDL.Continuous.Hysteresis hys2(
    final uLow=fanSpeChe,
    final uHigh=fanSpeChe + 0.005)
    "Check if tower fan speed is greater than minimum speed"
    annotation (Placement(transformation(extent={{-40,110},{-20,130}})));
  Buildings.Controls.OBC.CDL.Logical.Not not2 "Logical not"
    annotation (Placement(transformation(extent={{0,110},{20,130}})));
  Buildings.Controls.OBC.CDL.Continuous.Feedback feedback2 "Input difference"
    annotation (Placement(transformation(extent={{-90,30},{-70,50}})));
  Buildings.Controls.OBC.CDL.Continuous.Hysteresis hys3(
    final uLow=0.1, final uHigh=0.15)
    "Check if tower temperature is below setpoint minus 1 degF"
    annotation (Placement(transformation(extent={{-40,30},{-20,50}})));
  Buildings.Controls.OBC.CDL.Logical.And and2 "Logical and"
    annotation (Placement(transformation(extent={{80,70},{100,90}})));
  Buildings.Controls.OBC.CDL.Logical.Or or2 "Logical or"
    annotation (Placement(transformation(extent={{120,110},{140,130}})));
  Buildings.Controls.OBC.CDL.Logical.MultiOr mulOr1(final nu=nTowCel)
    annotation (Placement(transformation(extent={{-140,-130},{-120,-110}})));
  Buildings.Controls.OBC.CDL.Logical.Not not3 "Logical not"
    annotation (Placement(transformation(extent={{-60,-130},{-40,-110}})));
  Buildings.Controls.OBC.CDL.Logical.Timer tim1 "Count the time when all tower cells are off"
    annotation (Placement(transformation(extent={{-20,-130},{0,-110}})));
  Buildings.Controls.OBC.CDL.Continuous.GreaterEqualThreshold greEquThr1(
    final threshold=60)
    "Check if the tower has been off for 1 minute"
    annotation (Placement(transformation(extent={{20,-130},{40,-110}})));
  Buildings.Controls.OBC.CDL.Continuous.Feedback feedback3 "Input difference"
    annotation (Placement(transformation(extent={{-60,-50},{-40,-30}})));
  Buildings.Controls.OBC.CDL.Continuous.Hysteresis hys4(
    final uLow=0.1, final uHigh=0.15)
    "Check if tower temperature is below setpoint minus 1 degF"
    annotation (Placement(transformation(extent={{20,-50},{40,-30}})));
  Buildings.Controls.OBC.CDL.Logical.MultiAnd mulAnd(final nu=nChi)
    "Check if all enabled chillers head pressure control maximum tower speed are greater than tower minimum speed"
    annotation (Placement(transformation(extent={{20,-10},{40,10}})));
  Buildings.Controls.OBC.CDL.Logical.And3 and3 "Check if tower fans should be enabled"
    annotation (Placement(transformation(extent={{60,-50},{80,-30}})));
  Buildings.Controls.OBC.CDL.Integers.Equal intEqu
    "Check integer number equality"
    annotation (Placement(transformation(extent={{-80,-170},{-60,-150}})));
  Buildings.Controls.OBC.CDL.Integers.Sources.Constant conInt(final k=0) "Zero constant"
    annotation (Placement(transformation(extent={{-140,-190},{-120,-170}})));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant minTowSpe[nChi](
    final k=fill(fanSpeMin, nChi))
    "Minimum tower speed"
    annotation (Placement(transformation(extent={{-140,70},{-120,90}})));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant one[nChi](
    final k=fill(1, nChi)) "Constant one"
    annotation (Placement(transformation(extent={{-140,130},{-120,150}})));
  Buildings.Controls.OBC.CDL.Continuous.AddParameter addPar(
    final p=5/9, final k=1) "Tower temperature setpoint plus 1 degF"
    annotation (Placement(transformation(extent={{-140,-90},{-120,-70}})));
  Buildings.Controls.OBC.CDL.Continuous.AddParameter addPar1(
    final p=-5/9, final k=1) "Tower temperature setpoint minus 1 degF"
    annotation (Placement(transformation(extent={{-140,30},{-120,50}})));
  Buildings.Controls.OBC.CDL.Logical.Timer tim2
    "Count the time when the tower fan is at minimum speed"
    annotation (Placement(transformation(extent={{40,110},{60,130}})));
  Buildings.Controls.OBC.CDL.Continuous.GreaterEqualThreshold greEquThr2(
    final threshold=300)
    "Threshold time"
    annotation (Placement(transformation(extent={{40,70},{60,90}})));
  Buildings.Controls.OBC.CDL.Logical.LogicalSwitch logSwi2 "Logical switch"
    annotation (Placement(transformation(extent={{140,-150},{160,-130}})));
  Buildings.Controls.OBC.CDL.Logical.Sources.Constant disFan1(
    final k=false)
    "Disable tower fan when no condenser water pump is ON"
    annotation (Placement(transformation(extent={{80,-130},{100,-110}})));
  Buildings.Controls.OBC.CDL.Logical.Latch lat
    "Maintain a true input until condition changes"
    annotation (Placement(transformation(extent={{140,-50},{160,-30}})));
  Buildings.Controls.OBC.CDL.Logical.Edge edg
    "Output true at the moment when input becomes true"
    annotation (Placement(transformation(extent={{100,-50},{120,-30}})));
  Buildings.Controls.OBC.CDL.Logical.Edge edg1
    "Output true at the moment when input becomes true"
    annotation (Placement(transformation(extent={{140,70},{160,90}})));

equation
  connect(minTowSpe.y, feedback.u2)
    annotation (Line(points={{-118,80},{-60,80},{-60,148}}, color={0,0,127}));
  connect(feedback.y, hys.u)
    annotation (Line(points={{-48,160},{-42,160}}, color={0,0,127}));
  connect(hys.y, not1.u)
    annotation (Line(points={{-18,160},{-2,160}}, color={255,0,255}));
  connect(mulOr.y, tim.u)
    annotation (Line(points={{62,160},{78,160}},   color={255,0,255}));
  connect(uMaxTowSpeSet, hys1.u)
    annotation (Line(points={{-200,180},{-142,180}}, color={0,0,127}));
  connect(hys1.y, swi.u2)
    annotation (Line(points={{-118,180},{-110,180},{-110,160},{-102,160}},
      color={255,0,255}));
  connect(uMaxTowSpeSet, swi.u1)
    annotation (Line(points={{-200,180},{-160,180},{-160,168},{-102,168}},
      color={0,0,127}));
  connect(one.y, swi.u3)
    annotation (Line(points={{-118,140},{-110,140},{-110,152},{-102,152}},
      color={0,0,127}));
  connect(swi.y, feedback.u1)
    annotation (Line(points={{-78,160},{-72,160}}, color={0,0,127}));
  connect(tim.y, greEquThr.u)
    annotation (Line(points={{102,160},{118,160}}, color={0,0,127}));
  connect(uFanSpe, feedback1.u1)
    annotation (Line(points={{-200,120},{-92,120}}, color={0,0,127}));
  connect(minTowSpe[1].y, feedback1.u2)
    annotation (Line(points={{-118,80},{-80,80},{-80,108}},color={0,0,127}));
  connect(feedback1.y, hys2.u)
    annotation (Line(points={{-68,120},{-42,120}}, color={0,0,127}));
  connect(hys2.y, not2.u)
    annotation (Line(points={{-18,120},{-2,120}}, color={255,0,255}));
  connect(TTow, feedback2.u2)
    annotation (Line(points={{-200,0},{-80,0},{-80,28}}, color={0,0,127}));
  connect(feedback2.y, hys3.u)
    annotation (Line(points={{-68,40},{-42,40}}, color={0,0,127}));
  connect(hys3.y, and2.u2)
    annotation (Line(points={{-18,40},{70,40},{70,72},{78,72}}, color={255,0,255}));
  connect(greEquThr.y, or2.u1)
    annotation (Line(points={{142,160},{150,160},{150,140},{110,140},{110,120},
      {118,120}}, color={255,0,255}));
  connect(and2.y, or2.u2)
    annotation (Line(points={{102,80},{110,80},{110,112},{118,112}},
      color={255,0,255}));
  connect(mulOr1.y, not3.u)
    annotation (Line(points={{-118,-120},{-62,-120}},  color={255,0,255}));
  connect(not3.y, tim1.u)
    annotation (Line(points={{-38,-120},{-22,-120}}, color={255,0,255}));
  connect(tim1.y, greEquThr1.u)
    annotation (Line(points={{2,-120},{18,-120}}, color={0,0,127}));
  connect(TTow, feedback3.u1)
    annotation (Line(points={{-200,0},{-80,0},{-80,-40},{-62,-40}},
      color={0,0,127}));
  connect(feedback3.y, hys4.u)
    annotation (Line(points={{-38,-40},{18,-40}},  color={0,0,127}));
  connect(mulAnd.y, and3.u1)
    annotation (Line(points={{42,0},{50,0},{50,-32},{58,-32}}, color={255,0,255}));
  connect(hys4.y, and3.u2)
    annotation (Line(points={{42,-40},{58,-40}},  color={255,0,255}));
  connect(greEquThr1.y, and3.u3)
    annotation (Line(points={{42,-120},{50,-120},{50,-48},{58,-48}},color={255,0,255}));
  connect(not1.y, mulOr.u)
    annotation (Line(points={{22,160},{38,160}}, color={255,0,255}));
  connect(hys.y, mulAnd.u)
    annotation (Line(points={{-18,160},{-10,160},{-10,0},{18,0}}, color={255,0,255}));
  connect(uTowSta, mulOr1.u)
    annotation (Line(points={{-200,-120},{-142,-120}}, color={255,0,255}));
  connect(uConWatPumNum, intEqu.u1)
    annotation (Line(points={{-200,-160},{-82,-160}},  color={255,127,0}));
  connect(conInt.y, intEqu.u2)
    annotation (Line(points={{-118,-180},{-100,-180},{-100,-168},{-82,-168}},
      color={255,127,0}));
  connect(TTowSet, addPar1.u)
    annotation (Line(points={{-200,40},{-172,40},{-172,40},{-142,40}}, color={0,0,127}));
  connect(addPar1.y, feedback2.u1)
    annotation (Line(points={{-118,40},{-92,40}}, color={0,0,127}));
  connect(addPar.y, feedback3.u2)
    annotation (Line(points={{-118,-80},{-50,-80},{-50,-52}}, color={0,0,127}));
  connect(TTowSet, addPar.u)
    annotation (Line(points={{-200,40},{-160,40},{-160,-80},{-142,-80}}, color={0,0,127}));
  connect(not2.y, tim2.u)
    annotation (Line(points={{22,120},{38,120}}, color={255,0,255}));
  connect(tim2.y, greEquThr2.u)
    annotation (Line(points={{62,120},{70,120},{70,100},{30,100},{30,80},{38,80}},
      color={0,0,127}));
  connect(greEquThr2.y, and2.u1)
    annotation (Line(points={{62,80},{78,80}}, color={255,0,255}));
  connect(disFan1.y, logSwi2.u1)
    annotation (Line(points={{102,-120},{112,-120},{112,-132},{138,-132}},
      color={255,0,255}));
  connect(intEqu.y, logSwi2.u2)
    annotation (Line(points={{-58,-160},{120,-160},{120,-140},{138,-140}},
      color={255,0,255}));
  connect(and3.y, edg.u)
    annotation (Line(points={{82,-40},{98,-40}}, color={255,0,255}));
  connect(edg.y, lat.u)
    annotation (Line(points={{122,-40},{138,-40}}, color={255,0,255}));
  connect(or2.y, edg1.u)
    annotation (Line(points={{142,120},{150,120},{150,100},{130,100},{130,80},
      {138,80}}, color={255,0,255}));
  connect(edg1.y, lat.clr)
    annotation (Line(points={{162,80},{170,80},{170,0},{130,0},{130,-46},
      {138,-46}}, color={255,0,255}));
  connect(lat.y, logSwi2.u3)
    annotation (Line(points={{162,-40},{170,-40},{170,-100},{130,-100},
      {130,-148},{138,-148}}, color={255,0,255}));
  connect(logSwi2.y, yTow)
    annotation (Line(points={{162,-140},{200,-140}}, color={255,0,255}));

annotation (
  defaultComponentName="enaTow",
  Diagram(coordinateSystem(preserveAspectRatio=false,
          extent={{-180,-200},{180,200}})),
  Icon(graphics={
        Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={0,0,127},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid),
        Text(
          extent={{-120,146},{100,108}},
          lineColor={0,0,255},
          textString="%name")}),
Documentation(info="<html>
<p>
Block that outputs signal <code>yTow</code> for enabling and disabling cooling tower 
fan. This is implemented according to ASHRAE RP-1711 Advanced Sequences of Operation for 
HVAC Systems Phase II – Central Plants and Hydronic Systems (Draft 6 on July 25, 
2019), section 5.2.12.2, item 2.j-l.
</p>
<p>
1. Disable the tower fans if either:
</p>
<ul>
<li>
Any enabled chiller’s head pressure control maximum tower fan speed <code>uMaxTowSpeSet</code> 
has equaled tower minimum speed <code>fanSpeMin</code> for 5 minutes, or
</li>
<li>
Tower fans <code>uTowSpe</code> have been at minimum speed <code>fanSpeMin</code> for 
5 minutes and tower temperature <code>TTow</code> drops below setpoint 
<code>TTowSet</code> minus 1 &deg;F. 
</li>
</ul>
<p>
2. Enable the tower fans if:
</p>
<ul>
<li>
They have been off (<code>uTowSta=false</code>) for at least 1 minute, and
</li>
<li>
The tower temperature <code>TTow</code> rises above setpoint <code>TTowSet</code>
by 1 &deg;F, and
</li>
<li>
All enabled chillers’ head pressure control maximum tower fan speed <code>uMaxTowSpeSet</code> 
are greater than tower minimum speed <code>fanSpeMin</code>.
</li>
</ul>
<p>
3. When all condenser water pumps are commanded OFF, disable the PID loop and
stop all tower fans.
</p>
<p>
Note that the tower temperature <code>TTow</code> could be condenser water return 
temperature or condenser water supply temperature, depending on whether the fan 
speed control is to maintain return temperature or supply temperature.
</p>
</html>", revisions="<html>
<ul>
<li>
August 9, 2019, by Jianjun Hu:<br/>
First implementation.
</li>
</ul>
</html>"));
end Enable;