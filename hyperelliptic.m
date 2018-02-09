function GoodBasisOfDifferentialsHyp(H)
// it turns out magma creates the same basis, I will leave it here as backup....
	g := Genus(H);
	FF<x,y> := FunctionField(H);
	dx := Differential(x);
	w := dx/y;
	diff_basis := [w*x^(i-1) : i in [1..g]];

	return diff_basis;
end function;

function GoodUniformizerHyp(basept)
	H := Curve(basept);
	FF<x,y> := FunctionField(H);
	g := Genus(H);
	
	if basept[3] eq 0 then
		s := basept[2];
		if s eq 0 then
			return (FF ! (y/x^(g+1)));
		else
			return (FF ! (1/x));
		end if;
	else
		a := basept[1] / basept[3];
		b := basept[1] / (basept[3]^(g+1));

		if b ne 0 then
			return (FF ! (x-a));
		else
			return (FF ! y);
		end if;
	end if;
end function;