within Buildings.Applications.DHC.Loads.BaseClasses;
model FlowDistribution "Model of building hydraulic distribution system"
  extends Buildings.Fluid.Interfaces.PartialTwoPortInterface(
    redeclare replaceable package Medium = Buildings.Media.Water,
    final m_flow_small=1E-4*m_flow_nominal,
    final show_T=false,
    final allowFlowReversal=false);
  import Type_dis = Buildings.Applications.DHC.Loads.Types.DistributionType
    "Types of distribution system";
  import Type_ctr = Buildings.Applications.DHC.Loads.Types.PumpControlType
    "Types of distribution pump control";
  replaceable parameter Buildings.Fluid.Movers.Data.Generic per(
    pressure(
      V_flow=m_flow_nominal/rho_default.*{0,1,2},
      dp=dp_nominal.*{1.5,1,0.5}),
    motorCooledByFluid=false) constrainedby Buildings.Fluid.Movers.Data.Generic
    "Record with performance data"
    annotation (choicesAllMatching=true,
      Placement(transformation(extent={{70,-100},{90,-80}})));
  parameter Integer nPorts_a1 = 0
    "Number of terminal units return ports"
    annotation(Dialog(connectorSizing=true), Evaluate=true);
  parameter Integer nPorts_b1 = 0
    "Number of terminal units supply ports"
    annotation(Dialog(connectorSizing=true), Evaluate=true);
  final parameter Integer nUni = nPorts_a1
    "Number of served units"
    annotation(Evaluate=true);
  parameter Boolean have_pum = false
    "Set to true if the system has a pump"
    annotation(Evaluate=true);
  parameter Boolean have_val = false
    "Set to true if the system has a mixing valve"
    annotation(Evaluate=true);
  parameter Boolean have_twoPip = true
    "Set to true in case of a two-pipe system";
  parameter Type_dis typDis = Type_dis.HeatingWater
    "Type of distribution system"
    annotation(Dialog(enable=have_val), Evaluate=true);
  parameter Type_ctr typCtr = Type_ctr.ConstantHead
    "Type of distribution pump control"
    annotation(Dialog(enable=have_pum), Evaluate=true);
  parameter Real spePum_nominal(final unit="1", final min=0, final max=1) = 1
    "Pump speed at nominal conditions"
    annotation(Dialog(group="Nominal condition"));
  parameter Modelica.SIunits.PressureDifference dp_nominal(
    final min=0, final displayUnit="Pa")
    "Pressure drop at nominal conditions"
    annotation(Dialog(group="Nominal condition"));
  final parameter Modelica.SIunits.PressureDifference dpVal_nominal(
    final min=0, final displayUnit="Pa")=
    if have_val then 0.1 * dp_nominal else 0
    "Mixing valve pressure drop at nominal conditions"
    annotation(Dialog(group="Nominal condition"));
  parameter Modelica.SIunits.PressureDifference dpDis_nominal[:](
    final min=0, final displayUnit="Pa")=
    if nUni==1 then {1/2*(dp_nominal-dpVal_nominal-dpMin)} else
    1/2 .* cat(1, {(dp_nominal-dpVal_nominal-dpMin)*0.2},
    fill((dp_nominal-dpVal_nominal-dpMin)*0.8 / (nUni-1), nUni-1))
    "Pressure drop between each connected unit at nominal conditions (supply line): 
    use zero for each connection downstream the differential pressure sensor"
    annotation(Dialog(
      group="Nominal condition",
      enable=typCtr==Type_ctr.ConstantDp));
  parameter Modelica.SIunits.PressureDifference dpMin(
    final min=0, final displayUnit="Pa") = dp_nominal / 2
    "Pressure difference setpoint for ConstantDp or at zero flow for LinearHead"
    annotation(Dialog(enable=typCtr==Type_ctr.ConstantDp));
  parameter Modelica.SIunits.MassFlowRate mUni_flow_nominal[:](min=0)=
    fill(m_flow_nominal/nUni, nUni)
    "Mass flow rate of each connected unit at nominal conditions"
    annotation(Dialog(
      group="Nominal condition",
      enable=typCtr==Type_ctr.ConstantDp));
  parameter Modelica.Fluid.Types.Dynamics energyDynamics=
    Modelica.Fluid.Types.Dynamics.FixedInitial
    "Type of energy balance (except for the pump always modeled in steady state)"
    annotation(Evaluate=true, Dialog(tab="Dynamics", group="Equations"));
  final parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics
    "Type of mass balance (except for the pump always modeled in steady state)"
    annotation(Evaluate=true, Dialog(tab="Dynamics", group="Equations"));
  parameter Modelica.SIunits.Time tau = 120
    "Time constant of fluid temperature variation at nominal flow rate"
    annotation (
      Dialog(tab="Dynamics", group="Nominal condition"),
      enable=energyDynamics<> Modelica.Fluid.Types.Dynamics.SteadyState);
  // IO CONNECTORS
  Modelica.Fluid.Interfaces.FluidPorts_a ports_a1[nPorts_a1](
    redeclare each final package Medium=Medium,
    each m_flow(min=if allowFlowReversal then -Modelica.Constants.inf else 0),
    each h_outflow(start=Medium.h_default, nominal=Medium.h_default))
    "Terminal units return ports"
    annotation (Placement(transformation(extent={{-110,160},{-90,240}}),
      iconTransformation(extent={{90,20},{110,100}})));
  Modelica.Fluid.Interfaces.FluidPorts_b ports_b1[nPorts_b1](
    redeclare each final package Medium=Medium,
    each m_flow(max=if allowFlowReversal then +Modelica.Constants.inf else 0),
    each h_outflow(start=Medium.h_default, nominal=Medium.h_default))
    "Terminal units supply ports"
    annotation (Placement(transformation(extent={{90,160},{110,240}}),
      iconTransformation(extent={{-110,20},{-90,100}})));
  Modelica.Blocks.Interfaces.RealInput mReq_flow[nUni](
    each final quantity="MassFlowRate")
    "Heating or chilled water flow rate required to meet the load"
    annotation (
      Placement(transformation(
        extent={{-20,-20},{20,20}},
        rotation=0,
        origin={-120,260}), iconTransformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-110,-40})));
  Modelica.Blocks.Interfaces.IntegerInput modChaOve if
    have_val and typDis == Type_dis.ChangeOver
    "Operating mode in change-over (1 for heating, -1 for cooling)"
    annotation (Placement(
      transformation(
      extent={{-20,-20},{20,20}},
      rotation=0,
      origin={-120,-60}), iconTransformation(extent={{-120,-70},{-100,-50}})));
  Modelica.Blocks.Interfaces.RealInput TSupSet(
    final quantity="ThermodynamicTemperature",
    final unit="K", final displayUnit="degC") if have_val
    "Supply temperature set point"
    annotation (Placement(transformation(
      extent={{-20,-20},{20,20}},
      rotation=0,
      origin={-120,-100}),
      iconTransformation(
      extent={{-10,-10},{10,10}},
      rotation=0,
      origin={-110,-80})));
  Modelica.Blocks.Interfaces.RealOutput mReqTot_flow(
    final quantity="MassFlowRate", final unit="kg/s")
    "Total heating or chilled water flow rate required to meet the loads"
    annotation (Placement(transformation(extent={{100,240},{140,280}}),
      iconTransformation(extent={{100,-50},{120,-30}})));
  Modelica.Blocks.Interfaces.RealOutput QActTot_flow(
    final quantity="HeatFlowRate", final unit="W")
    "Total heat flow rate transferred to the loads (>=0 for heating)"
    annotation (Placement(transformation(extent={{100,140},{140,180}}),
      iconTransformation(extent={{100,-70},{120,-50}})));
  Modelica.Blocks.Interfaces.RealOutput PPum(
    final quantity="Power", final unit="W") if have_pum
    "Power drawn by pump motor"
    annotation (Placement(transformation(extent={{100,100},{140,140}}),
      iconTransformation(extent={{100,-90},{120,-70}})));
  // COMPONENTS
  Buildings.Controls.OBC.CDL.Continuous.MultiSum sumMasFloReq(
    final k=fill(1, nUni), final nin=nUni)
    "Total required mass flow rate"
    annotation (Placement(transformation(extent={{-80,250},{-60,270}})));
  Buildings.Fluid.Sources.MassFlowSource_T sou_m_flow[nUni](
    redeclare each final package Medium = Medium,
    each final use_m_flow_in=true,
    each final use_T_in=true,
    each final nPorts=1)
    "Source for terminal units supplied flow rate"
    annotation (Placement(transformation(extent={{60,190},{80,210}})));
  Buildings.Fluid.Sources.Boundary_pT sin(
    redeclare final package Medium=Medium,
    final nPorts=nUni)
    "Sink for terminal units return flow rate"
    annotation (Placement(transformation(extent={{-60,190},{-80,210}})));
  Buildings.Controls.OBC.CDL.Continuous.MultiSum Q_flowSum(
    final nin=nUni)
    annotation (Placement(transformation(extent={{-70,130},{-50,150}})));
  Modelica.Blocks.Sources.RealExpression mAct_flow[nUni](
    final y=if have_pum then mReq_flow else mReq_flow .*
    Buildings.Utilities.Math.Functions.smoothMin(
      1,
      senMasFlo.m_flow/Buildings.Utilities.Math.Functions.smoothMax(
        mReqTot_flow,
        m_flow_small,
        m_flow_small),
      1E-2))
    "Actual supplied mass flow rate"
    annotation (Placement(transformation(extent={{-100,150},{-80,170}})));
  Modelica.Blocks.Sources.RealExpression QAct_flow[nUni](
    final y=mAct_flow.y .* (ports_b1.h_outflow - inStream(ports_a1.h_outflow)))
    "Actual heat flow rate transferred to each load"
    annotation (Placement(transformation(extent={{-100,130},{-80,150}})));
  Buildings.Fluid.Actuators.Valves.ThreeWayEqualPercentageLinear val(
    redeclare final package Medium = Medium,
    final portFlowDirection_1=if allowFlowReversal then
      Modelica.Fluid.Types.PortFlowDirection.Bidirectional else
      Modelica.Fluid.Types.PortFlowDirection.Entering,
    final portFlowDirection_2=if allowFlowReversal then
      Modelica.Fluid.Types.PortFlowDirection.Bidirectional else
      Modelica.Fluid.Types.PortFlowDirection.Leaving,
    final portFlowDirection_3=if allowFlowReversal then
      Modelica.Fluid.Types.PortFlowDirection.Bidirectional else
      Modelica.Fluid.Types.PortFlowDirection.Entering,
    final dpValve_nominal=dpVal_nominal,
    final use_inputFilter=false,
    final m_flow_nominal=m_flow_nominal,
    final linearized={true,true},
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial) if have_val
    "Mixing valve"
    annotation (Placement(transformation(extent={{-10,10},{10,-10}}, origin={-80,0})));
  Buildings.Fluid.Movers.BaseClasses.IdealSource pipPre(
    redeclare final package Medium = Medium,
    final dp_start=dp_nominal - dpVal_nominal,
    final m_flow_start=m_flow_nominal,
    final show_T=false,
    final show_V_flow=false,
    final control_m_flow=typCtr==Type_ctr.ConstantSpeed,
    final control_dp=typCtr<>Type_ctr.ConstantSpeed,
    final allowFlowReversal=allowFlowReversal,
    final m_flow_small=m_flow_small)
    "Fictitious pipe used to prescribe pump head or flow rate"
    annotation (Placement(transformation(extent={{-16,-10},{4,10}})));
  Buildings.Fluid.HeatExchangers.HeaterCooler_u heaCoo(
    redeclare final package Medium=Medium,
    final dp_nominal=0,
    final m_flow_nominal=m_flow_nominal,
    final Q_flow_nominal=-1,
    final allowFlowReversal=allowFlowReversal,
    final energyDynamics=energyDynamics,
    final massDynamics=massDynamics,
    final tau=tau)
    "Heat transfer from the terminal units to the distribution system"
    annotation (Placement(transformation(extent={{46,-10},{66,10}})));
  Buildings.Fluid.FixedResistances.Junction spl(
    redeclare final package Medium=Medium,
    final portFlowDirection_1=if allowFlowReversal then
      Modelica.Fluid.Types.PortFlowDirection.Bidirectional else
      Modelica.Fluid.Types.PortFlowDirection.Entering,
    final portFlowDirection_2=if allowFlowReversal then
      Modelica.Fluid.Types.PortFlowDirection.Bidirectional else
      Modelica.Fluid.Types.PortFlowDirection.Leaving,
    final portFlowDirection_3=if allowFlowReversal then
      Modelica.Fluid.Types.PortFlowDirection.Bidirectional else
      Modelica.Fluid.Types.PortFlowDirection.Leaving,
    final m_flow_nominal=m_flow_nominal*{1,1,1},
    final dp_nominal=0*{1,1,1},
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial) if have_val
    "Flow splitter"
    annotation (Placement(transformation(
      extent={{-10,10},{10,-10}}, origin={80,0})));
  Modelica.Blocks.Sources.RealExpression TSupVal(y=TSup)
    "Supply temperature value"
    annotation (Placement(transformation(extent={{10,10},{-10,-10}},
      rotation=180, origin={-90,120})));
  Buildings.Fluid.Sensors.MassFlowRate senMasFlo(
    redeclare final package Medium=Medium,
    final allowFlowReversal=allowFlowReversal)
    "Supply mass flow rate sensor"
    annotation (Placement(transformation(extent={{10,-10},{30,10}})));
  Buildings.Controls.OBC.CDL.Routing.RealReplicator reaRep(
    final nout=nUni)
    annotation (Placement(transformation(extent={{-20,110},{0,130}})));
  Controls.MixingValveControl conVal(final typDis=typDis) if
                                                    have_val
    "Mixing valve controller"
    annotation (Placement(transformation(extent={{-48,-106},{-28,-86}})));
  Modelica.Blocks.Sources.RealExpression dpNetVal(final y=dpPum - dpVal_nominal)
    "Pressure drop over the distribution network (excluding mixing valve)"
    annotation (Placement(transformation(extent={{10,10},{-10,-10}},
      rotation=180, origin={-90,100})));
  Modelica.Blocks.Sources.RealExpression masFloPum(final y=mPum_flow)
    "Pump mass flow rate value"
    annotation (Placement(transformation(extent={{10,10},{-10,-10}},
      rotation=180, origin={-90,80})));
  Modelica.Blocks.Sources.RealExpression spePum(final y=spePum_nominal)
    "Pump speed (fractional)" annotation (Placement(transformation(
        extent={{10,10},{-10,-10}},
        rotation=180,
        origin={-90,60})));
  // MISCELLANEOUS VARIABLES
  Modelica.SIunits.Temperature TSup(final displayUnit="degC")=
    Medium.temperature(state=Medium.setState_phX(
    p=pipPre.port_a.p,
    h=inStream(pipPre.port_a.h_outflow),
    X=inStream(pipPre.port_a.Xi_outflow)))
    "Supply temperature";
  Buildings.Fluid.Movers.FlowControlled_m_flow pumFlo(
    redeclare final package Medium = Medium,
    per(
      final hydraulicEfficiency=per.hydraulicEfficiency,
      final motorEfficiency=per.motorEfficiency,
      final motorCooledByFluid=per.motorCooledByFluid,
      final speed_nominal=per.speed_nominal,
      final constantSpeed=per.constantSpeed,
      final speeds=per.speeds,
      final power=per.power),
    final allowFlowReversal=allowFlowReversal,
    final m_flow_nominal=m_flow_nominal,
    final dp_nominal=dp_nominal,
    addPowerToMedium=false,
    nominalValuesDefineDefaultPressureCurve=true,
    use_inputFilter=false,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState) if
    have_pum and typCtr <> Type_ctr.ConstantSpeed
    "Distribution pump with prescribed mass flow rate"
    annotation (Placement(transformation(extent={{-50,-10},{-30,10}})));
  Buildings.Fluid.Movers.SpeedControlled_y pumSpe(
    redeclare final package Medium = Medium,
    per(
      pressure(
        final V_flow=per.pressure.V_flow,
        final dp=per.pressure.dp),
      final hydraulicEfficiency=per.hydraulicEfficiency,
      final motorEfficiency=per.motorEfficiency,
      final motorCooledByFluid=per.motorCooledByFluid,
      final speed_nominal=per.speed_nominal,
      final constantSpeed=per.constantSpeed,
      final speeds=per.speeds,
      final power=per.power),
    final allowFlowReversal=allowFlowReversal,
    addPowerToMedium=false,
    use_inputFilter=false,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState) if
    have_pum and typCtr == Type_ctr.ConstantSpeed
    "Distribution pump with prescribed speed (fractional)"
    annotation (Placement(transformation(extent={{-50,-50},{-30,-30}})));
protected
  final parameter Modelica.SIunits.MassFlowRate mDis_flow_nominal[nUni]=
    {sum(mUni_flow_nominal[i:nUni]) for i in 1:nUni}
    "Distribution flow rate between each connected unit at nominal conditions";
  final parameter Real kDis[nUni]=
    {if dpDis_nominal[i] > Modelica.Constants.eps then
      mDis_flow_nominal[i] / sqrt(dpDis_nominal[i]) else Modelica.Constants.inf
      for i in 1:nUni}
    "Flow coefficient between each connected unit at nominal conditions";
  Modelica.SIunits.MassFlowRate mDis_flow[nUni]=
    {sum(mReq_flow[i:nUni]) for i in 1:nUni}
    "Distribution flow rate between each connected unit";
  Modelica.SIunits.PressureDifference dpDis[nUni]=
    (mDis_flow ./ kDis) .^ 2
    "Pressure drop between each connected unit (supply line)";
  Modelica.SIunits.PressureDifference dpPum(final displayUnit="Pa")=
    if typCtr==Type_ctr.LinearHead then dpMin + mPum_flow / m_flow_nominal * dp_nominal
    elseif typCtr==Type_ctr.ConstantDp then 2 * sum(dpDis) + dpMin + dpVal_nominal
    else dp_nominal
    "Pump head";
  Modelica.SIunits.MassFlowRate mPum_flow=
    if typCtr==Type_ctr.ConstantFlow then m_flow_nominal else sum(mReq_flow)
    "Pump mass flow rate";
  parameter Medium.ThermodynamicState sta_default=Medium.setState_pTX(
      T=Medium.T_default,
      p=Medium.p_default,
      X=Medium.X_default);
  parameter Modelica.SIunits.Density rho_default=Medium.density(sta_default)
    "Density, used to compute fluid volume";
initial equation
  assert(nPorts_a1 == nPorts_b1,
    "In " + getInstanceName() +
    ": The numbers of terminal units return ports (" + String(nPorts_a1) +
    ") and supply ports (" + String(nPorts_b1) + ") must be equal.");
  assert(if have_val then have_pum else true,
    "In " + getInstanceName() +
    ": The configuration where have_val is true and have_pum is false is not allowed.");
equation

  assert(mReqTot_flow < m_flow_nominal + m_flow_small,
    "In " + getInstanceName() + ": The total required mass flow rate equals "
    + String(mReqTot_flow) + " (kg/s) which is higher than the nominal mass
    flow rate value of " + String(m_flow_nominal) + " (kg/s).",
    AssertionLevel.error);

  connect(sumMasFloReq.y, mReqTot_flow)
    annotation (Line(points={{-58,260},{120,260}}, color={0,0,127}));
  connect(mReq_flow, sumMasFloReq.u)
    annotation (Line(points={{-120,260},{-82,260}}, color={0,0,127}));
  connect(mAct_flow.y, sou_m_flow.m_flow_in)
    annotation (Line(points={{-79,160},{16,160},{16,208},{58,208}},
                                                color={0,0,127}));
  connect(ports_a1, sin.ports)
    annotation (Line(points={{-100,200},{-80,200}}, color={0,127,255}));
  connect(sou_m_flow.ports[1], ports_b1)
    annotation (Line(points={{80,200},{100,200}}, color={0,127,255}));
  connect(pipPre.port_b, senMasFlo.port_a)
    annotation (Line(points={{4,0},{10,0}}, color={0,127,255}));
  connect(senMasFlo.port_b, heaCoo.port_a)
    annotation (Line(points={{30,0},{46,0}}, color={0,127,255}));
  connect(Q_flowSum.y, QActTot_flow)
    annotation (Line(points={{-48,140},{94,140},{94,160},{120,160}},
                                                   color={0,0,127}));
  connect(QAct_flow.y, Q_flowSum.u)
    annotation (Line(points={{-79,140},{-72,140}}, color={0,0,127}));
  connect(Q_flowSum.y, heaCoo.u) annotation (Line(points={{-48,140},{40,140},{
          40,6},{44,6}},
                      color={0,0,127}));
  connect(TSupVal.y, reaRep.u)
    annotation (Line(points={{-79,120},{-22,120}}, color={0,0,127}));
  connect(reaRep.y, sou_m_flow.T_in)
    annotation (Line(points={{2,120},{20,120},{20,204},{58,204}},
                             color={0,0,127}));

  if have_val then
    connect(port_a, val.port_1)
    annotation (Line(points={{-100,0},{-90,0}}, color={0,127,255}));
    connect(heaCoo.port_b, spl.port_1)
      annotation (Line(points={{66,0},{70,0}}, color={0,127,255}));
    connect(spl.port_2, port_b)
      annotation (Line(points={{90,0},{100,0}}, color={0,127,255}));
    connect(spl.port_3, val.port_3)
      annotation (Line(points={{80,10},{80,40},{-80,40},{-80,10}}, color={0,127,255}));
    connect(TSupSet, conVal.TSupSet)
      annotation (Line(points={{-120,-100},{-80,-100},{-80,-92},{-49,-92}},
                                                         color={0,0,127}));
    connect(TSupVal.y, conVal.TSupMes)
      annotation (Line(points={{-79,120},{-60,120},{-60,-100},{-49,-100}},  color={0,0,127}));
    connect(conVal.yVal, val.y)
      annotation (Line(points={{-27,-96},{-20,-96},{-20,-80},{-80,-80},{-80,-12}},
      color={0,0,127}));

    if typDis == Type_dis.ChangeOver then
      connect(modChaOve, conVal.modChaOve)
        annotation (Line(points={{-120,-60},{-90,-60},{-90,-88},{-49,-88}},
                                              color={255,127,0}));
    end if;

    connect(val.port_2, pumFlo.port_a)
      annotation (Line(points={{-70,0},{-50,0}}, color={0,127,255}));
    connect(val.port_2, pumSpe.port_a)
      annotation (Line(points={{-70,0},{-56,0},{-56,-40},{-50,-40}},color={0,127,255}));

  else

    connect(heaCoo.port_b, port_b)
      annotation (Line(points={{66,0},{100,0}}, color={0,127,255}));

    if have_pum then
      connect(port_a, pumFlo.port_a)
        annotation (Line(points={{-100,0},{-50,0}}, color={0,127,255}));
      connect(port_a, pumSpe.port_a)
        annotation (Line(points={{-100,0},{-56,0},{-56,-40},{-50,-40}},color={0,127,255}));
    else
      connect(port_a, pipPre.port_a)
        annotation (Line(points={{-100,0},{-16,0}}, color={0,127,255}));
    end if;

  end if;

  connect(pumFlo.port_b, pipPre.port_a)
    annotation (Line(points={{-30,0},{-16,0}}, color={0,127,255}));
  connect(pumSpe.port_b, pipPre.port_a)
    annotation (Line(points={{-30,-40},{-24,-40},{-24,0},{-16,0}},color={0,127,255}));

  connect(pumFlo.P, PPum)
    annotation (Line(points={{-29,9},{-20,9},{-20,20},{94,20},{94,120},{120,120}},
                                 color={0,0,127}));
  connect(pumSpe.P, PPum)
    annotation (Line(points={{-29,-31},{94,-31},{94,120},{120,120}},
                 color={0,0,127}));

  connect(dpNetVal.y, pipPre.dp_in)
    annotation (Line(points={{-79,100},{0,100},{0,8}}, color={0,0,127}));
  connect(masFloPum.y, pipPre.m_flow_in)
    annotation (Line(points={{-79,80},{-12,80},{-12,8}},   color={0,0,127}));

  connect(masFloPum.y, pumFlo.m_flow_in)
    annotation (Line(points={{-79,80},{-40,80},{-40,12}},   color={0,0,127}));
  connect(spePum.y, pumSpe.y)
    annotation (Line(points={{-79,60},{-46,60},{-46,-20},{-40,-20},{-40,-28}},color={0,0,127}));

annotation (
  defaultComponentName="dis",
  Documentation(info="<html>
<p>
This model represents a hydraulic distribution system serving multiple
terminal units.
It is primarily intended to be used in conjunction with models that derive from
<a href=\"modelica://Buildings.Applications.DHC.Loads.BaseClasses.PartialTerminalUnit\">
Buildings.Applications.DHC.Loads.BaseClasses.PartialTerminalUnit</a>.
</p>
<p>
The pipe network modeling is decoupled between a main distribution
loop and several terminal branch circuits:
</p>
<ul>
<li>
The flow rate in each branch circuit is equal to the flow rate demand yielded
by the terminal unit model, constrained by the condition that the sum of all
demands is lower or equal to the flow rate in the main loop.
Additionally if the total flow rate demand exceeds the nominal mass flow rate
the model throws an error.
</li>
<li>
The inlet temperature in each branch circuit is equal to the supply temperature
in the main loop.
The outlet temperature in the main loop results from transferring the enthalpy
flow rate of each individual fluid stream to the main fluid stream.
</li>
<li>
The pressure drop in the main distribution loop corresponds to the pressure drop
over the whole distribution system (the pump head): it is governed by an equation
representing the control logic of the distribution pump.
The pressure drop in each branch circuit is irrelevant: <code>dp_nominal</code>
must be set to zero for each terminal unit model being connected
to that component.
</li>
</ul>
<p>
That modeling approach aims to minimize the number of algebraic
equations by avoiding an explicit modeling of the terminal actuators and
the whole flow network.
In addition, the assumption <code>allowFlowReversal=false</code> is used
systematically together with boundary conditions which actually ensure that
no reverse flow conditions are encountered in simulation.
This allows directly accessing the inlet enthalpy value of a component from
the fluid port <code>port_a</code> with the built-in function <code>inStream</code>.
This approach is preferred to the use of two-port sensors which introduce a
state to ensure a smooth transition at flow reversal.
All connected components must meet the same requirements.
The impact on the computational performance is illustrated 
<a href=\"#my_comp\">below</a>.
</p>
<p>
Optionally:
</p>
<ul>
<li>
A distribution pump can be modeled with a prescribed flow rate corresponding
to the total flow rate demand.
</li>
<li>
A mixing valve can be modeled (together with a distribution pump) with a
control loop tracking the supply temperature. Note that the nominal pressure
drop of the valve is not an exposed parameter: it is set by default to 10%
of the nominal total pressure drop.
</li>
</ul>
<h4>Pump head computation</h4>
<p>
The pump head is computed as follows (see also
<a href=\"modelica://Buildings.Applications.DHC.Loads.Validation.FlowDistributionPumpControl\">
Buildings.Applications.DHC.Loads.Validation.FlowDistributionPumpControl</a>
for a comparison with an explicit modeling of the piping network).
</p>
<ul>
<li>
In case of a constant pump head:
<p style=\"font-style:italic;\">
dpPum = dp_nominal
</p>
</li>
<li>
In case of a constant flow rate (three-way valves) the network flow
characteristics is considered independent from the actuator positions.
Thus:
<p style=\"font-style:italic;\">
dpPum = dp_nominal
</p>
<li>
In case of a linear head:
<p style=\"font-style:italic;\">
dpPum = dpMin + (dp_nominal - dpMin) * m_flow / m_flow_nominal
</p>
</li>
<li>
In case of a constant speed, the pump head is computed based on the pump pressure
curve and the total required mass flow rate.
<li>
In case of a constant pressure difference at a given location, the pump head
is computed according to the schematics hereunder, under the
assumption of a two-pipe distribution system:
<p style=\"font-style:italic;\">
dpPum = dpMin + dpVal + 2 * &Sigma;<sub>i</sub> dpDis[i]
</p>
<p>
Where:
</p>
<ul>
<li>
<i>dpMin</i> is the differential pressure setpoint.
</li>
<li>
<i>dpVal</i> is the pressure drop across the optional mixing valve. 
It is considered independent from the valve position: 
<i>dpVal = dpVal_nominal</i>.
</li>
<li>
<i>dpDis[i]</i> is the pressure drop in the supply pipe segment directly
upstream the i<sup>th</sup> connection:
<p>
<i>dpDis[i] = 1 / K[i]<sup>2</sup></i> * mDis_flow[i] <sup>2</sup></i>
</p>
Where:
<p> 
<i>mDis_flow[i]  = &Sigma;<sub>i to nUni</sub> mReq_flow[i]</i>
is the mass flow rate in the same pipe segment.
</p> 
<p>
<i>K[i] = (&Sigma;<sub>i to nUni</sub> mUni_flow_nominal[i]) /
dpDis_nominal[i]<sup>0.5</sup></i> 
is the corresponding flow coefficient (constant).
</p>
<p>
The pressure drop in the corresponding pipe segment of the return line
is considered equal, hence the factor 2 in the above equation.
</p>
<p>
The default value for <code>dpDis_nominal</code> corresponds to a configuration
where the differential pressure sensor is located before the most remote 
connected unit, 20% of the nominal pressure drop in the distribution network 
occurs between the pump and the first connected unit (supply and return), 
the remaining pressure drop is evenly distributed over each pipe segment 
between the other connected units. 
The user can override those default values with the requirement that the 
nominal pressure drop of each pipe segment downstream the differential pressure 
sensor must be set to zero.
</p>
</li>
</ul>
</li>
</ul>
<p>
<img alt=\"image\"
src=\"modelica://Buildings/Resources/Images/Applications/DHC/Loads/FlowDistribution1.png\"/>
</p>
<h4>Energy and mass dynamics</h4>
<p>
The energy dynamics and the time constant used in the ideal heater and cooler 
model are exposed as advanced parameters. 
They are used to represent the typical dynamics over the whole 
piping network, from supply to return.
The mass dynamics are by default identical to the energy dynamics.
</p>
<p>
Simplifying assumptions are used otherwise:
</p>
<ul>
<li>
The pump is modeled in steady-state.
</li>
<li>
The valve and the flow splitter are modeled with fixed initial conditions.
This is because the temperature of the fluid leaving the valve is used 
as a control input signal. If a steady-state model is used, that temperature
is computed by assuming ideal mixing at the inner fluid ports of the valve.
In case of zero flow rate, the temperature value results from regularizing
the corresponding equation that is not well defined in that domain. 
That triggers non-physical temperature variations which themselves lead to
control transients when the flow rate gets reestablished. Those effects 
turn out to be detrimental to computational performance.
</li>
</ul>
<h4 id=\"my_comp\">Computational performance</h4>
<p>
The figure below compares the computational performance of that model
(labelled <code>simple</code>, see model 
<a href=\"modelica://Buildings.Applications.DHC.Loads.Validation.BenchmarkFlowDistribution1\">
Buildings.Applications.DHC.Loads.Validation.BenchmarkFlowDistribution1</a>) 
with an explicit modeling of the distribution network and 
the terminal unit actuators (labelled <code>detailed</code>, see model
<a href=\"modelica://Buildings.Applications.DHC.Loads.Validation.BenchmarkFlowDistribution2\">
Buildings.Applications.DHC.Loads.Validation.BenchmarkFlowDistribution2</a>).
The impact of a varying number of connected loads (<code>nLoa</code>) is
assessed on:
</p>
<ol>
<li>
the total time for all model evaluations, 
</li>
<li>
the total time spent between model evaluations,
</li>
<li>
the number of continuous state variables.
</li>
</ol>
<p>
<img alt=\"image\"
src=\"modelica://Buildings/Resources/Images/Applications/DHC/Loads/FlowDistribution2.png\"/>
</p>
</html>"),
  Icon(coordinateSystem(preserveAspectRatio=false,
    extent={{-100,-100},{100,100}}),
    graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={95,95,95},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-104,6},{6,-6}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-49,6},{49,-6}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={66,43},
          rotation=90),
        Rectangle(
          extent={{72,6},{100,-6}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-60,92},{-6,80}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-43,6},{43,-6}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={-2.66454e-15,49},
          rotation=90),
        Rectangle(
          extent={{-15,20},{15,-20}},
          lineColor={0,0,0},
          lineThickness=1,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          visible=have_val,
          origin={-42,-3},
          rotation=-90),
        Polygon(
          points={{-10,12},{-10,-8},{10,2},{-10,12}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={-52,-2},
          rotation=0,
          lineThickness=0.5,
          visible=have_val),
        Polygon(
          points={{-10,12},{-10,-8},{10,2},{-10,12}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={-40,-10},
          rotation=90,
          lineThickness=0.5,
          visible=have_val),
        Polygon(
          points={{-10,12},{-10,-8},{10,2},{-10,12}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid,
          origin={-32,2},
          rotation=180,
          lineThickness=0.5,
          visible=have_val),
        Rectangle(
          extent={{-48,-56},{72,-68}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          visible=have_val),
        Rectangle(
          extent={{-32,6},{32,-6}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={-66,60},
          rotation=90),
        Rectangle(
          extent={{-100,92},{-72,80}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-100,66},{-72,54}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-100,40},{-72,28}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{72,66},{100,54}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{72,92},{100,80}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{72,40},{100,28}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-20,68},{20,28}},
          lineColor={0,0,0},
          lineThickness=0.5,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid,
          startAngle=0,
          endAngle=360,
          visible=have_pum),
        Polygon(
          points={{-16,16},{-16,-16},{16,0},{-16,16}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={0,52},
          rotation=90,
          visible=have_pum),
        Rectangle(
          extent={{-18,6},{18,-6}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={-42,-38},
          rotation=90,
          visible=have_val),
        Rectangle(
          extent={{-25,6},{25,-6}},
          lineThickness=1,
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={66,-31},
          rotation=90,
          visible=have_val)}),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-120},{100,
            280}})));
end FlowDistribution;