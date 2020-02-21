within Buildings.Applications.DHC.Loads.Examples;
model CouplingTimeSeries
  "Example illustrating the coupling of a time series building model to a fluid loop"
  extends Modelica.Icons.Example;
  package Medium1 = Buildings.Media.Water
    "Source side medium";
  Buildings.Applications.DHC.Loads.Examples.BaseClasses.BuildingTimeSeries
    bui(
      filPat=
      "modelica://Buildings/Applications/DHC/Examples/Resources/SwissResidential_20190916.mos",
      nPorts_a=2,
      nPorts_b=2)
    "Building"
    annotation (Placement(transformation(extent={{20,40},{40,60}})));
  Buildings.Fluid.Sources.Boundary_pT sinHeaWat(
    redeclare package Medium = Medium1,
    p=300000,
    nPorts=1) "Sink for heating water" annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={130,80})));
  Buildings.Fluid.Sources.Boundary_pT sinChiWat(
    redeclare package Medium = Medium1,
    p=300000,
    nPorts=1)
    "Sink for chilled water"
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={130,20})));
  Modelica.Blocks.Sources.RealExpression THeaWatSup(y=bui.terUniHea.T_aHeaWat_nominal)
    "Heating water supply temperature"
    annotation (Placement(transformation(extent={{-120,70},{-100,90}})));
  Modelica.Blocks.Sources.RealExpression TChiWatSup(y=bui.terUniCoo.T_aChiWat_nominal)
    "Chilled water supply temperature"
    annotation (Placement(transformation(extent={{-120,10},{-100,30}})));
  Fluid.Sources.Boundary_pT           supHeaWat(
    redeclare package Medium = Medium1,
    use_T_in=true,
    nPorts=1) "Heating water supply" annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-50,80})));
  Fluid.Sources.Boundary_pT           supChiWat(
    redeclare package Medium = Medium1,
    use_T_in=true,
    nPorts=1) "Chilled water supply" annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-50,20})));
equation
  connect(bui.ports_b[1], sinHeaWat.ports[1]) annotation (Line(points={{60,30},
          {80,30},{80,80},{120,80}}, color={0,127,255}));
  connect(bui.ports_b[2], sinChiWat.ports[1]) annotation (Line(points={{60,34},
          {80,34},{80,20},{120,20}}, color={0,127,255}));
  connect(supHeaWat.T_in,THeaWatSup. y) annotation (Line(points={{-62,84},{-80,84},
          {-80,80},{-99,80}},     color={0,0,127}));
  connect(supHeaWat.ports[1], bui.ports_a[1]) annotation (Line(points={{-40,80},
          {-20,80},{-20,30},{0,30}},        color={0,127,255}));
  connect(TChiWatSup.y,supChiWat. T_in) annotation (Line(points={{-99,20},{-80,20},
          {-80,24},{-62,24}},     color={0,0,127}));
  connect(supChiWat.ports[1], bui.ports_a[2]) annotation (Line(points={{-40,20},
          {-20,20},{-20,34},{0,34}},        color={0,127,255}));
  annotation (
  experiment(
      StopTime=604800,
      __Dymola_NumberOfIntervals=5000,
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
space heating and cooling loads provided as time series, 
</li>
<li>
secondary pumps.
</li>
</ul>
</html>
"),
  Diagram(
  coordinateSystem(preserveAspectRatio=false, extent={{-120,-20},{140,120}})),
  __Dymola_Commands(file="Resources/Scripts/Dymola/Applications/DHC/Loads/Examples/CouplingTimeSeries.mos"
        "Simulate and plot"));
end CouplingTimeSeries;