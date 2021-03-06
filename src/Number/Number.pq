﻿section Number;
/////////////////////////
// Number              //
/////////////////////////
shared Number.Digits = {0,1,2,3,4,5,6,7,8,9};
shared Number.ParseText = Document(
    "Number.ParseText",
    "Returns the first number (1+ consecutive digits) in the given text. Optionally, provide allowed characters to ignore them",
    {[ Description = "Allow commas", Code="PBI[Number.ParseText](""It's over 9,000!"", 0, {"",""})", Result = "9000" ]},
    (text as text, optional startIndex as number, optional allowCharacters as list) => 
        let
            consider = if startIndex is null then text else Text.Range(text,startIndex), 
            _allowCharacters = if allowCharacters is null then {} else allowCharacters,
            numberSeries = List.FirstN(List.Skip(Text.ToList(consider), each not Text.IsNumber(_)), each Text.IsNumber(_) or List.Contains(_allowCharacters, _))
        in 
            if text is null then null else Text.FromList(numberSeries)
);
shared Number.ToLetters = Document(
        "Number.ToLetters",
        "Converts a number  (starting at 1) to an alphabet representation. Works like column headers in Excel.",
        {[ 
            Description = "Column 27", 
            Code = "PBI[Number.ToLetters](27)", 
            Result = "AB"
        ]},
        (value as number) =>
            let
                GetLetter = (num as number) => 
                    let 
                        number = Number.Mod(num, 26),
                        val = if number = 0 then 26 else number,
                        valid = number < 26 and number > 0 
                    in 
                        if valid then Text.At(Text.Alphabet, val - 1) else error "Can't get letter for " & Text.From(num),
                func = (value as number, factor as number) =>
                    let
                        ThisLetter = GetLetter(Number.RoundDown(value/Number.Power(26, factor))),
                        Result = if value <= Number.Power(26, factor) then "" else @func(value, factor+1) & ThisLetter
                    in
                        Result
            in
                if value <= 26 then GetLetter(value) else func(value, 1) & GetLetter(value)
);
shared Number.Reverse8BitInt  = (x) =>
        Number.Mod(Number.BitwiseAnd((x* 0x0202020202),0x010884422010),1023);
shared Number.Reverse32BitInt = (x) =>
    let
        b0 = Number.BitwiseAnd(x,0xff),
        b1 = Number.BitwiseShiftRight(Number.BitwiseAnd(x,0xff00),8),
        b2 = Number.BitwiseShiftRight(Number.BitwiseAnd(x,0xff0000),16),
        b3 = Number.BitwiseShiftRight(Number.BitwiseAnd(x,0xff000000),24)
    in   
        Number.BitwiseOr(
                 Number.BitwiseOr(
                    Number.BitwiseShiftLeft(Number.Reverse8BitInt(b0),24),
                    Number.BitwiseShiftLeft(Number.Reverse8BitInt(b1),16)),
                 Number.BitwiseOr(
                    Number.BitwiseShiftLeft(Number.Reverse8BitInt(b2),8),
                    Number.Reverse8BitInt(b3)));

shared Number.DecToBin = (num as number)=>
        List.Last(
            List.Generate(
                   () =>[reminder = num,
                         binString= Number.ToText(Number.BitwiseAnd(reminder,1))],
                   each [reminder]> 0,
                   each [reminder = Number.BitwiseShiftRight([reminder],1),
                         binString= Number.ToText(Number.BitwiseAnd(reminder,1))&[binString]],
                   each [binString]
                ));

shared Number.HexToDec = (hexString as text) 
                            => Expression.Evaluate("0x"&hexString);
/////////////////////////
// Dependencies        //
/////////////////////////

Document = (name as text, description as text, valueOrExample as any, optional valueIfExample as any) =>
    let
        value = if valueIfExample is null then valueOrExample else valueIfExample,
        examples = if valueIfExample is null then {} else valueOrExample
    in
        Value.ReplaceType(value, Value.Type(value) meta [
            Documentation.Name = name, 
            Documentation.Description = description,  
            // [Description = "", Code="", Result =""]
            Documentation.Examples = examples
        ]);

Text.Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
Text.FromList = (list as list) => List.Accumulate(list, "", (state, current) => state & Text.From(current));
Text.IsNumber = (text as text) => try Number.FromText(text) is number otherwise false;