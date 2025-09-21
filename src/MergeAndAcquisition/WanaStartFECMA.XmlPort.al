namespace Wanamics.Start.MergeAndAcquisition;

using System.Reflection;
xmlport 87102 "WanaStart FEC M&A"
{
    Caption = 'FEC M&A';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '|';
    Format = VariableText;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(ImportLine; "wanaStart Import Line")
            {
                textelement(JournalCode) { }
                textelement(JournalLib) { }
                textelement(EcritureNum) { }
                textelement(EcritureDate) { }
                textelement(CompteNum) { }
                textelement(CompteLib) { }
                textelement(CompAuxNum) { }
                textelement(CompAuxLib) { }
                textelement(PieceRef) { }
                textelement(PieceDate) { }
                textelement(EcritureLib) { }
                textelement(Debit) { }
                textelement(Credit) { }
                textelement(EcritureLet) { }
                textelement(DateLet) { }
                textelement(ValidDate) { }
                textelement(MontantDevise) { }
                textelement(IDevise) { }
                textelement(_ExternalDocumentNo) { MinOccurs = Zero; }
                // textelement(_AppliesToID) { MinOccurs = Zero; }
                textelement(_ShortcutDimension1Code) { MinOccurs = Zero; }
                textelement(_ShortcutDimension2Code) { MinOccurs = Zero; }

                trigger OnPreXmlItem()
                begin
                    // currXMLport.Skip();
                    // if ImportLine.FindLast() then
                    //     LineNo := ImportLine."Line No.";
                end;

                trigger OnBeforeInsertRecord()
                begin
                    if not FirstlineSkipped then begin
                        FirstlineSkipped := true;
                        currXMLport.Skip();
                    end;
                    LineNo += 1;
                    ImportLine."Line No." := LineNo;
                    if JournalCode <> MapSourceCode."Source Code" then
                        if not MapSourceCode.Get(JournalCode) then begin
                            MapSourceCode.Init();
                            MapSourceCode."From Source Code" := JournalCode;
                            MapSourceCode."From Source Name" := JournalLib;
                            MapSourceCode.Insert();
                        end;
                    ImportLine.JournalCode := JournalCode;
                    ImportLine.EcritureNum := EcritureNum;
                    ImportLine.EcritureDate := ToDate(EcritureDate);
                    if (CompteNum <> MapAccount."From Account No.") or (CompAuxNum <> MapAccount."From SubAccount No.") then
                        if not MapAccount.Get(CompteNum, CompAuxNum) then begin
                            MapAccount.Init();
                            MapAccount."From Account No." := CompteNum;
                            MapAccount."From SubAccount No." := CompAuxNum;
                            if CompAuxNum = '' then
                                MapAccount."From Account Name" := CompteLib
                            else
                                MapAccount."From Account Name" := CompAuxLib;
                            MapAccount.Insert();
                        end;
                    ImportLine.CompteNum := CompteNum;
                    ImportLine.CompAuxNum := CompAuxNum;
                    ImportLine.EcritureNum := EcritureNum;
                    ImportLine.PieceRef := PieceRef;
                    ImportLine.PieceDate := ToDate(PieceDate);
                    ImportLine.EcritureDate := ToDate(EcritureDate);
                    ImportLine.EcritureLib := EcritureLib;
                    ImportLine.Debit := ToDecimal(Debit);
                    if Credit = 'C' then
                        ImportLine.Credit := -ToDecimal(Debit)
                    else
                        ImportLine.Credit := ToDecimal(Credit);
                    ImportLine.EcritureLet := CopyStr(EcritureLet, 1, MaxStrLen(ImportLine.EcritureLet));
                    ImportLine.DateLet := ToDate(DateLet);
                    ImportLine.ValidDate := ToDate(ValidDate);
                    ImportLine.MontantDev := ToDecimal(MontantDevise);
                    ImportLine.IDevise := IDevise;
                    ImportLine."_External Document No." := _ExternalDocumentNo;
                    // ImportLine."_Applies-to ID" := _AppliesToID;
                    ImportLine."_Shortcut Dimension 1 Code" := _ShortcutDimension1Code;
                    ImportLine."_Shortcut Dimension 2 Code" := _ShortcutDimension2Code;

                    ImportLine.Amount := ImportLine.Debit - ImportLine.Credit;
                    ImportLine.Open := (ImportLine.CompAuxNum <> '') and (ImportLine.EcritureLet = '');
                    if ImportLine.CompAuxNum <> '' then
                        ImportLine.Validate("VAT Amount", VATAmount(ImportLine));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        if ImportLine.FindLast() then
            LineNo := ImportLine."Line No.";
    end;

    var
        FirstlineSkipped: Boolean;
        LineNo: Integer;
        MapSourceCode: Record "WanaStart Map Source Code";
        MapAccount: Record Wanamics.WanaStart."wanaStart Map Account";
        TypeHelper: Codeunit "Type Helper";

    procedure ToDecimal(pText: Text) ReturnValue: Decimal
    begin
        if pText <> '' then
            Evaluate(ReturnValue, pText);
    end;

    procedure ToDate(pText: Text) ReturnValue: Date
    var
        v: Variant;
    begin
        v := ReturnValue;
        TypeHelper.Evaluate(v, pText, 'yyyyMMdd', '');
        ReturnValue := v;
    end;

    local procedure VATAmount(var Rec: Record "wanaStart Import Line"): Decimal;
    var
        ImportLine2: Record "wanaStart Import Line";
    begin
        // if MapSourceCode."VAT Account No. Filter" = '' then
        // exit;
        ImportLine2.SetCurrentKey(JournalCode, PieceRef, EcritureNum);
        ImportLine2.SetRange(JournalCode, Rec.JournalCode);
        ImportLine2.SetRange(EcritureDate, Rec.EcritureDate);
        ImportLine2.SetRange(EcritureNum, Rec.EcritureNum);
        ImportLine2.SetRange(PieceRef, Rec.PieceRef);
        ImportLine2.SetFilter(CompAuxNum, '<>%1', '');
        if ImportLine2.Count > 1 then
            exit;
        ImportLine2.SetRange(CompAuxNum);
        ImportLine2.SetFilter(CompteNum, '445*'); //MapSourceCode."VAT Account No. Filter"); 
        ImportLine2.CalcSums(Amount);
        exit(ImportLine2.Amount);
    end;
}
