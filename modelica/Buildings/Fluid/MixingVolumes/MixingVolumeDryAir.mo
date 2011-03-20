within Buildings.Fluid.MixingVolumes;
model MixingVolumeDryAir
  "Mixing volume with heat port for latent heat exchange, to be used with dry air"
  extends BaseClasses.PartialMixingVolumeWaterPort;

equation
  if cardinality(mWat_flow) == 0 then
    mWat_flow = 0;
  end if;
  if cardinality(TWat) == 0 then
    TWat = Medium.T_default;
  end if;
  HWat_flow = 0;
  mXi_flow  = zeros(Medium.nXi);
// Assign output port
  X_w = 0;
  annotation (Diagram(graphics),
                       Icon(graphics={Text(
          extent={{-152,102},{148,142}},
          textString="%name",
          lineColor={0,0,255})}),
defaultComponentName="vol",
Documentation(info="<html>
Model for an ideally mixed fluid volume and the ability 
to store mass and energy. The volume is fixed, 
and sensible heat can be exchanged.
<p>
This model has the same ports as
<a href=\"modelica://Buildings.Fluid.MixingVolumes.MixingVolumeMoistAir\">
Buildings.Fluid.MixingVolumes.MixingVolumeMoistAir</a>.
However, there is no mass exchange with the medium other than through the port
<code>ports</code>.
</p>
<p>
For media that do provide water as a species, use the model
<a href=\"modelica://Buildings.Fluid.MixingVolumes.MixingVolumeMoistAir\">
Buildings.Fluid.MixingVolumes.MixingVolumeMoistAir</a> to add
or subtract moisture using a signal that is connected to the port
<code>mWat_flow</code> and <code>TWat</code>.
</p>
</html>", revisions="<html>
<ul>
<li>
August 7, 2008 by Michael Wetter:<br>
First implementation.
</li>
</ul>
</html>"));
end MixingVolumeDryAir;
