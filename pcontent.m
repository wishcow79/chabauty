/* 
TODO: improve documentation
TODO: what if I is not p-saturated?
TODO: what if F is in I? Do we have infinite loop? No, it crashes on ExactQuotient.

Given a polynomial with integer coefficients, a prime p, and an ideal I, we can reduce the polynomial modulo
I. We might then get a polynomial which has p-content, i.e. when reduced modulo p, we get 0. 
This function removes the p-content, and returns the content and the content-less polynomial.
*/

// intrinsic pContentModI(F::RngMPolElt, p::RngIntElt, I::RngMPol) -> RngIntElt, RngMPolElt
// {Return pPrimitive part and pContent of the multivariate polynomial F modulo ideal I}
function pContentModI(F, p, I)
    assert F ne 0;

    RZ := Generic(I);
    assert BaseRing(RZ) eq Integers();

    Rp := ChangeRing(RZ, GF(p));

    gens_I := Generators(I);
    gens_Ip := [Rp ! g : g in gens_I];
    // we want the generators of Ip to be the generators of I, reduced modulo p.
    // There might be a problem here that I might not be saturated, and then we get 
    Ip := IdealWithFixedBasis(gens_Ip); 

    Fp := Rp ! F;
    coeff := 1;

    while Fp in Ip do
        Fp_coords := Coordinates(Ip, Fp);
        fixF := &+[gens_I[i]*(RZ ! Fp_coords[i]) : i in [1..#Fp_coords]];
        F -:= fixF;
        contentF := Content(F);
        coeff *:= contentF;
        F := ExactQuotient(F , contentF);
        Fp := Rp ! F;
    end while;

    return coeff,F;
end function;
