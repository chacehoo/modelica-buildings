within Buildings.HeatTransfer.Examples;
model ConductorMultiLayer2
  "Test model for multi layer heat conductor with one
  capacity added at the surface a of the construction"
  extends ConductorMultiLayer(con(placeCapacityAtSurf_a=true));
  annotation (experiment(StartTime=0, StopTime=86400, Tolerance=1e-6),
  __Dymola_Commands(file="modelica://Buildings/Resources/Scripts/Dymola/HeatTransfer/Examples/ConductorMultiLayer2.mos" "Simulate and plot"),
  Documentation(revisions="<html>
<ul>
<li>
December 6 2016, by Thierry S. Nouidui:<br/>
First implementation.
</li>
</ul>
</html>", info="<html>
This example is similar to <a href=\"modelica://Buildings.HeatTransfer.Examples.ConductorMultiLayer\">
Buildings.HeatTransfer.Examples.ConductorMultiLayer</a>. The main difference
is that a capacity is added at the surface a of the construction.
</html>"));
end ConductorMultiLayer2;
