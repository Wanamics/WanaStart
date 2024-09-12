codeunit 87108 "wan Helper"
{
    SingleInstance = true;

    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        ColumnNo: Integer;
        SelectColumns: Text;
        TypeHelper: Codeunit "Type Helper";

    procedure ToDecimal(pText: Text) ReturnValue: Decimal
    begin
        if pText <> '' then
            Evaluate(ReturnValue, pText);
    end;

    procedure ToDate(pText: Text) ReturnValue: Date
    begin
        if pText <> '' then
            Evaluate(ReturnValue, pText);
    end;

    procedure yyyyddmmToDate(pText: Text) ReturnValue: Date
    var
        v: Variant;
    begin
        // if pText <> '' then
        //     Evaluate(ReturnValue, pText.Substring(7, 2) + pText.Substring(5, 2) + pText.Substring(1, 4));
        v := ReturnValue;
        if TypeHelper.Evaluate(v, pText, 'yyyyMMdd', '') then
            exit(v);
    end;

    procedure SelectFrom(var pExcelBuffer: Record "Excel Buffer" temporary)
    begin
        SelectFrom(pExcelBuffer, 1);
    end;

    procedure SelectFrom(var pExcelBuffer: Record "Excel Buffer" temporary; pFrom: Integer)
    begin
        ExcelBuffer.Copy(pExcelBuffer, true);
        ColumnNo := pFrom - 1;
        SelectColumns := '';
    end;

    procedure SelectNext(pTitle: Text)
    var
        TitleIsEmptyErr: Label 'Title is empty for column %1.', Comment = '%1:Column';
        UnexpectedTitleErr: Label 'Title "%2" expected for column %1 (current value is %3).', Comment = '%1:Column, %2 Expected, %3:current value';
    begin
        ColumnNo += 1;
        if SelectColumns <> '' then
            SelectColumns += '|';
        SelectColumns += format(ColumnNo);
        if not ExcelBuffer.Get(1, ColumnNo) then
            Error(TitleIsEmptyErr, Base26(ColumnNo), ExcelBuffer."Cell Value as Text");
        if ExcelBuffer."Cell Value as Text" <> pTitle then
            Error(UnexpectedTitleErr, Base26(ColumnNo), pTitle, ExcelBuffer."Cell Value as Text");
    end;

    procedure SelectSkip(pSkip: Integer)
    begin
        ColumnNo += pSkip;
    end;

    procedure Select(): Text
    begin
        exit(SelectColumns);
    end;

    procedure Base26(pColumnNo: Integer) ReturnValue: Text
    var
        c: char;
    begin
        while pColumnNo >= 1 do begin
            c := pColumnNo mod 26 + 64;
            ReturnValue := c + ReturnValue;
            pColumnNo := pColumnNo div 26;
        end;
    end;

    procedure Concat(var pText: Text; pAppend: Text)
    begin
        Concat(pText, pAppend, ' ');
    end;

    procedure Concat(var pText: Text; pAppend: Text; pSeparator: Text)
    begin
        if pText = '' then
            pText := pAppend
        else
            pText += pSeparator + pAppend;
    end;

    procedure GetNumber(var pText: Text; pFrom: Integer) ReturnValue: Text
    var
        Number: Integer;
        i: Integer;
    begin
        if pText = '' then
            exit;
        if pFrom < 0 then begin
            i := StrLen(pText);
            while (i >= 1) and not (pText[i] in ['0' .. '9']) do
                i -= 1;
            while (i >= 1) and (pText[i] in ['0' .. '9']) do begin
                ReturnValue := pText[i] + ReturnValue;
                i -= 1;
            end;
        end else begin
            if Evaluate(Number, pText) then
                exit(format(Number));
        end;
    end;
}
