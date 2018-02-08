use_cache := true;
prefix := "Dyfj";

function IsCached(object,attribute0)
    if not use_cache then return false; end if;
    attribute := prefix cat attribute0;
    return attribute in GetAttributes(Type(object)) and
           assigned object``attribute;
end function;

function IsArrayCached(object,attribute0,key)
    if not IsCached(object,attribute0) then return false; end if;
    attribute := prefix cat attribute0;

    return Type(object``attribute) eq Assoc and IsDefined(object``attribute,key);
end function;

procedure InitiateCache(object,attribute0)
    if use_cache then;
        attribute := prefix cat attribute0;
        if not attribute in GetAttributes(Type(object)) then
            AddAttribute(Type(object), attribute);
        end if;
    end if;
end procedure;

procedure InitiateArrayCache(object,attribute0)
    if use_cache then;
        InitiateCache(object,attribute0);
        attribute := prefix cat attribute0;
        if not assigned object``attribute then
            object``attribute := AssociativeArray();
        end if;
    end if;
end procedure;

procedure SetArrayCache(object, attribute0, key, value : initiate := true)
    attribute := prefix cat attribute0;
    if use_cache then;
        if initiate then InitiateArrayCache(object, attribute0); end if;
        object``attribute[key] := value;
    end if;
end procedure;

function GetArrayCache(object, attribute0, key);
    attribute := prefix cat attribute0;
    if use_cache then;
        return (object``attribute)[key];
    end if;
    error "Can only get from cache if use_cache eq true";
end function;

procedure SetCache(object, attribute0, value : initiate := true);
    attribute := prefix cat attribute0;
    if use_cache then;
        if initiate then InitiateCache(object,attribute0); end if;
        object``attribute := value;
    end if;
    return;
end procedure;

function GetCache(object, attribute0);
    attribute := prefix cat attribute0;
    if use_cache then;
        return object``attribute;
    end if;
    error "Can only get from cache if use_cache eq true";
end function;
