function ConvertPointToIntSeq(pt)
    dim := #Eltseq(pt) -1 ;

    pt_seq := [pt[i]*d where d := LCM([Denominator(pt[j]) : j in [1..dim+1]]): i in [1..dim+1]];
    pt_seq := ChangeUniverse(pt_seq, Integers());

    return pt_seq;
end function;

function ReducePointModp(pt, p)
    C := Curve(pt);
    Cp := ReduceCurveModp(C, p);

    pt_seq := ConvertPointToIntSeq(pt);
    pt_mod_p := Cp ! pt_seq;

    return pt_mod_p;
end function;

function ReducePointsModp(pts, p)
    assert #pts ge 1;
    assert IsPrime(p);
    C := Curve(pts[1]);
    Cp := ReduceCurveModp(C, p);

    pts_mod_p := [Cp ! ConvertPointToIntSeq(pt) : pt in pts];

    return pts_mod_p;
end function;

procedure PrintPoints(pts)
    pts_seq := [ConvertPointToIntSeq(pt) : pt in pts];

    print "the points found are: \n";
    for i in [1..#pts_seq] do
        printf "P_%o = %o\n", i , pts_seq[i];
    end for;
end procedure;
