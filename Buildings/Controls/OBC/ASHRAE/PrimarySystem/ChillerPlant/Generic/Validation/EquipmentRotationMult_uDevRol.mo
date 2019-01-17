within Buildings.Controls.OBC.ASHRAE.PrimarySystem.ChillerPlant.Generic.Validation;
model EquipmentRotationMult_uDevRol
  "Validate lead/lag and lead/standby switching"

  parameter Integer num = 3
    "Total number of devices, such as chillers, isolation valves, CW pumps, or CHW pumps";

  parameter Boolean initialization[num] = {true, false, false}
    "Initiates device mapped to the first index with the lead role and all other to lag";

  parameter Boolean initRoles[num] = initialization[1:num]
    "Sets initial roles: true = lead, false = lag or standby";

  Buildings.Controls.OBC.ASHRAE.PrimarySystem.ChillerPlant.Generic.EquipmentRotationMult leaSta(
    final stagingRuntime=5*60*60,
    final num=num,
    final initRoles=initRoles) "Equipment rotation - lead/standby"
    annotation (Placement(transformation(extent={{-20,-60},{0,-40}})));

  EquipmentRotationMult leaLag(stagingRuntime=5*60*60)
                               "Equipment rotation - lead/lag"
    annotation (Placement(transformation(extent={{-20,40},{0,60}})));
protected
  Buildings.Controls.OBC.CDL.Logical.Sources.Pulse leadLoad(final width=0.8,
      final period=2*60*60) "Lead device on/off status"
    annotation (Placement(transformation(extent={{-80,70},{-60,90}})));

  Buildings.Controls.OBC.CDL.Logical.Sources.Pulse lagLoad(final width=0.2,
      final period=1*60*60)
    annotation (Placement(transformation(extent={{-80,10},{-60,30}})));

  Buildings.Controls.OBC.CDL.Logical.Sources.Pulse leadLoad1(final width=0.8,
      final period=2*60*60) "Lead device on/off status"
    annotation (Placement(transformation(extent={{-80,-30},{-60,-10}})));

  Buildings.Controls.OBC.CDL.Logical.Sources.Constant standby(final k=false)
    annotation (Placement(transformation(extent={{-80,-90},{-60,-70}})));

equation
  connect(leadLoad.y, leaLag.uLeaSta) annotation (Line(points={{-59,80},{-40,80},
          {-40,56},{-22,56}}, color={255,0,255}));
  connect(lagLoad.y, leaLag.uLagSta) annotation (Line(points={{-59,20},{-40,20},
          {-40,44},{-22,44}}, color={255,0,255}));
  connect(leadLoad1.y, leaSta.uLeaSta) annotation (Line(points={{-59,-20},{-40,
          -20},{-40,-44},{-22,-44}}, color={255,0,255}));
  connect(standby.y, leaSta.uLagSta) annotation (Line(points={{-59,-80},{-40,
          -80},{-40,-56},{-22,-56}}, color={255,0,255}));
          annotation (
   experiment(StopTime=10000.0, Tolerance=1e-06),
    __Dymola_Commands(file="modelica://Buildings/Resources/Scripts/Dymola/Controls/OBC/ASHRAE/PrimarySystem/ChillerPlant/Generic/Validation/EquipmentRotationMult_uDevRol.mos"
    "Simulate and plot"),
  Documentation(info="<html>
<p>
This example validates
<a href=\"modelica://Buildings.Controls.OBC.ASHRAE.PrimarySystem.ChillerPlant.Generic.EquipmentRotationMult\">
Buildings.Controls.OBC.ASHRAE.PrimarySystem.ChillerPlant.Generic.EquipmentRotationMult</a>.
</p>
</html>", revisions="<html>
<ul>
<li>
September 20, by Milica Grahovac:<br/>
First implementation.
</li>
</ul>
</html>"),
Icon(graphics={
        Ellipse(lineColor = {75,138,73},
                fillColor={255,255,255},
                fillPattern = FillPattern.Solid,
                extent = {{-100,-100},{100,100}}),
        Polygon(lineColor = {0,0,255},
                fillColor = {75,138,73},
                pattern = LinePattern.None,
                fillPattern = FillPattern.Solid,
                points = {{-36,60},{64,0},{-36,-60},{-36,60}})}),Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end EquipmentRotationMult_uDevRol;