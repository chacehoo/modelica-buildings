within Buildings.Applications.DHC.Loads.Examples;
model CouplingSpawnZ6
  "Example illustrating the coupling of a multizone Spawn model to a fluid loop"
  extends Modelica.Icons.Example;
  package Medium1 = Buildings.Media.Water
    "Source side medium";
  BaseClasses.BuildingSpawnZ6 bui(nPorts_a=2, nPorts_b=2) "Building"
    annotation (Placement(transformation(extent={{40,-40},{60,-20}})));
  Buildings.Fluid.Sources.Boundary_pT sinHeaWat(redeclare package Medium =
        Medium1, nPorts=1) "Sink for heating water" annotation (Placement(
        transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={130,0})));
  Buildings.Fluid.Sources.Boundary_pT sinChiWat(redeclare package Medium =
        Medium1, nPorts=1) "Sink for chilled water" annotation (Placement(
        transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={130,-60})));
  Modelica.Blocks.Sources.RealExpression THeaWatSup(y=max(bui.terUni.T_aHeaWat_nominal))
    "Heating water supply temperature"
    annotation (Placement(transformation(extent={{-100,-10},{-80,10}})));
  Modelica.Blocks.Sources.RealExpression TChiWatSup(y=min(bui.terUni.T_aChiWat_nominal))
    "Chilled water supply temperature"
    annotation (Placement(transformation(extent={{-100,-70},{-80,-50}})));
  Fluid.Sources.Boundary_pT supHeaWat(
    redeclare package Medium = Medium1,
    use_T_in=true,
    nPorts=1) "Heating water supply" annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-30,0})));
  Fluid.Sources.Boundary_pT supChiWat(
    redeclare package Medium = Medium1,
    use_T_in=true,
    nPorts=1) "Chilled water supply" annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-30,-60})));
equation
  connect(bui.ports_b[1], sinHeaWat.ports[1]) annotation (Line(points={{80,-50},
          {100,-50},{100,0},{120,0}}, color={0,127,255}));
  connect(bui.ports_b[2], sinChiWat.ports[1]) annotation (Line(points={{80,-46},
          {100,-46},{100,-60},{120,-60}}, color={0,127,255}));
  connect(supHeaWat.T_in, THeaWatSup.y) annotation (Line(points={{-42,4},{-60,4},
          {-60,0},{-79,0}}, color={0,0,127}));
  connect(supHeaWat.ports[1], bui.ports_a[1]) annotation (Line(points={{-20,0},
          {0,0},{0,-50},{20,-50}}, color={0,127,255}));
  connect(TChiWatSup.y, supChiWat.T_in) annotation (Line(points={{-79,-60},{-60,
          -60},{-60,-56},{-42,-56}}, color={0,0,127}));
  connect(supChiWat.ports[1], bui.ports_a[2]) annotation (Line(points={{-20,-60},
          {0,-60},{0,-46},{20,-46}}, color={0,127,255}));
  annotation (
  experiment(
      StopTime=604800,
      Tolerance=1e-06,
      __Dymola_Algorithm="Cvode"),
  Documentation(info="
<html>
<p>
This example illustrates the use of
<a href=\"modelica://Buildings.Applications.DHC.Loads.BaseClasses.PartialBuilding\">
Buildings.Applications.DHC.Loads.BaseClasses.PartialBuilding</a>,
<a href=\"modelica://Buildings.Applications.DHC.Loads.BaseClasses.PartialTerminalUnit\">
Buildings.Applications.DHC.Loads.BaseClasses.PartialTerminalUnit</a>
and
<a href=\"modelica://Buildings.Applications.DHC.Loads.BaseClasses.FlowDistribution\">
Buildings.Applications.DHC.Loads.BaseClasses.FlowDistribution</a>
in a configuration with:
</p>
<ul>
<li>
six-zone building model based on EnergyPlus envelope model, 
</li>
<li>
secondary pumps.
</li>
</ul>
</html>
"),
  Diagram(
        coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{140,40}}),
        graphics={Text(
          extent={{-28,36},{104,10}},
          lineColor={28,108,200},
          textString="Simulation requires
Hidden.AvoidDoubleComputation=true")}),
    __Dymola_Commands(file=
          "Resources/Scripts/Dymola/Applications/DHC/Loads/Examples/CouplingSpawnZ6.mos"
        "Simulate and plot"));
end CouplingSpawnZ6;