within Buildings.Controls.OBC.CDL.Integers.Sources;
block TimeTable "Table look-up with respect to time with constant segments"

  parameter Real table[:,:]
    "Table matrix with time as a first table column (in seconds, unless timeScale is not 1) and Integers in all other columns";

  parameter Real timeScale(
     final unit="1") = 1
    "Time scale of first table column. Set to 3600 if time in table is in hours";

  parameter Modelica.SIunits.Time period
    "Periodicity of table";

  Interfaces.IntegerOutput y[nout] "Output of the table"
    annotation (Placement(transformation(extent={{100,-20},{140,20}})));
protected
  final parameter Integer nout=size(table, 2)-1
    "Dimension of output vector";
  final parameter Integer nT=size(table, 1)
    "Number of time stamps";
  parameter Modelica.SIunits.Time t0(fixed=false)
    "First sample time instant";

  final parameter Modelica.SIunits.Time timeStamps[:] = table[1:end, 1] "Time stamps";
  final parameter Integer val[:,:] = integer(table[1:end, 2:end] + ones(nT, nout) * Constants.small) "Table values as Integer";

  Integer idx(start=1, fixed=true) "Index for table lookup";

  function getIndex
    input Modelica.SIunits.Time t "Current time";
    input Modelica.SIunits.Time period "Time period";
    input Modelica.SIunits.Time x[:] "Time stamps";
    output Integer k "Index in table";
  protected
    Modelica.SIunits.Time tS "Time shifted so it is within the period";
  algorithm
    tS := mod(t, period);
    k := 1;
    for i in 1:size(x,1) loop
       if tS > x[i] then
         k := k+1;
       end if;
    end for;
  end getIndex;

initial equation
  t0=time;
  assert(nT > 0, "No table values defined.");

  // Check that all values in the second column are Integer values
  for i in 1:nT loop
    for j in 2:size(table, 2) loop
      assert(abs(table[i, j] - integer(table[i, j])) < Constants.small,
        "In " + getInstanceName() + ": Table value table[" + String(i) + ", " + String(j) + "] = " + String(table[i, j]) + " is not an Integer.");
    end for;
  end for;
  assert(abs(table[1,1]) < Constants.small, "In " + getInstanceName() + ": First time stamp must be zero as otherwise no data is defined for the start of the table.");
  assert(period - table[1,end] > Constants.small, "In " + getInstanceName() + ": Last time stamp in table must be smaller than period.");
equation
  when initial() then
    y[:] = val[pre(idx),:];
    idx = getIndex(time, period, timeStamps);
       elsewhen
            {sample(t0+timeStamps[i], period) for i in 1:nT} then
    y[:] = val[pre(idx),:];
    idx = if (pre(idx) + 1 > nT) then 1 else pre(idx) + 1;
  end when;
  annotation (
defaultComponentName = "intTimTab",
Documentation(info="<html>
<p>
Block that outputs <code>Integer</code> time table values.
</p>
<p>
The block takes as a parameter a time table of a format:
</p>
<pre>
table = [ 0*3600, 2;
          6*3600, 1;
         18*3600, 8];
</pre>
<p>
where the first column is time, and the remaining column(s) are the table values.
The time column contains <code>Real</code> values that are in units of seconds when <code>timeScale</code> equals <code>1</code>.
<code>timeScale</code> may be used to scale the time values, such that for <code>timeScale = 3600</code> the values 
in the first column of the table are interpreted as hours.
</p>
<p>
The values in all columns apart from the first column must be of type <code>Integer</code>, otherwise the model stops with an error.
</p>
<p>
Until a new tabulated value is set, the previous tabulated value is returned.
</p>
<p>
The table scope is repeated periodically with periodicity <code>period</code>.
</p>
<p>
The simulation can start at any time,
whether it is a multiple of a day or not, and positive or negative.
</p>
</html>",
revisions="<html>
<ul>
<li>
October 7, 2020, by Michael Wetter:<br/>
Revised implementation to add <code>timeSpan</code> and to guard against rounding errors.
Refactored to avoid non-needed event-triggering functions.
Removed parameter <code>offset</code> as I don't see a use case that justifies this complexity.
</li>
<li>
September 14, 2020, by Milica Grahovac:<br/>
Initial CDL implementation based on continuous time table implementation in CDL.
</li>
</ul>
</html>"),
    Icon(
    coordinateSystem(preserveAspectRatio=true,
      extent={{-100.0,-100.0},{100.0,100.0}}),
      graphics={                Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={244,125,35},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid), Text(
        extent={{-150,150},{150,110}},
        textString="%name",
        lineColor={0,0,255}),
    Polygon(lineColor={192,192,192},
      fillColor={192,192,192},
      fillPattern=FillPattern.Solid,
      points={{-80.0,90.0},{-88.0,68.0},{-72.0,68.0},{-80.0,90.0}}),
    Line(points={{-80.0,68.0},{-80.0,-80.0}},
      color={192,192,192}),
    Line(points={{-90.0,-70.0},{82.0,-70.0}},
      color={192,192,192}),
    Polygon(lineColor={192,192,192},
      fillColor={192,192,192},
      fillPattern=FillPattern.Solid,
      points={{90.0,-70.0},{68.0,-62.0},{68.0,-78.0},{90.0,-70.0}}),
    Rectangle(lineColor={255,255,255},
      fillColor={255,215,136},
      fillPattern=FillPattern.Solid,
      extent={{-48.0,-50.0},{2.0,70.0}}),
    Line(points={{-48.0,-50.0},{-48.0,70.0},{52.0,70.0},{52.0,-50.0},
        {-48.0,-50.0},{-48.0,-20.0},{52.0,-20.0},{52.0,10.0},{-48.0,10.0},
        {-48.0,40.0},{52.0,40.0},{52.0,70.0},{2.0,70.0},{2.0,-51.0}}),
        Text(
          extent={{226,60},{106,10}},
          lineColor={0,0,0},
          textString=DynamicSelect("", if (nout==1) then String(y[1], leftjustified=false, significantDigits=3) else ""))}));
end TimeTable;
