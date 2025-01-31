namespace Wanamics.Start.MergeAndAcquisition;

using System.Reflection;
xmlport 87102 "FEC M&A"
{
    Caption = 'FEC M&A';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '|';
    Format = VariableText;

    schema
    {
        textelement(Root)
        {
            tableelement(ImportFRLine; "wanaStart Import FR Line")
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
                textelement(_AppliesToID) { MinOccurs = Zero; }
                textelement(_ShortcutDimension1Code) { MinOccurs = Zero; }
                textelement(_ShortcutDimension2Code) { MinOccurs = Zero; }

                trigger OnPreXmlItem()
                begin
                    currXMLport.Skip();
                end;

                trigger OnBeforeInsertRecord()
                begin
                    if not FirstlineSkipped then begin
                        FirstlineSkipped := true;
                        currXMLport.Skip();
                    end;
                    LineNo += 1;
                    ImportFRLine."Line No." := LineNo;
                    if JournalCode <> MapSourceCode."Source Code" then
                        if not MapSourceCode.Get(JournalCode) then begin
                            MapSourceCode.Init();
                            MapSourceCode."From Source Code" := JournalCode;
                            MapSourceCode."From Source Name" := JournalLib;
                            MapSourceCode.Insert();
                        end;
                    ImportFRLine.JournalCode := JournalCode;
                    ImportFRLine.EcritureNum := EcritureNum;
                    ImportFRLine.EcritureDate := ToDate(EcritureDate);
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
                    ImportFRLine.CompteNum := CompteNum;
                    ImportFRLine.CompAuxNum := CompAuxNum;
                    ImportFRLine.EcritureNum := EcritureNum;
                    ImportFRLine.PieceRef := PieceRef;
                    ImportFRLine.PieceDate := ToDate(PieceDate);
                    ImportFRLine.EcritureDate := ToDate(EcritureDate);
                    ImportFRLine.EcritureLib := EcritureLib;
                    ImportFRLine.Debit := ToDecimal(Debit);
                    if Credit = 'C' then
                        ImportFRLine.Credit := -ToDecimal(Debit)
                    else
                        ImportFRLine.Credit := ToDecimal(Credit);
                    ImportFRLine.EcritureLet := CopyStr(EcritureLet, 1, MaxStrLen(ImportFRLine.EcritureLet));
                    ImportFRLine.DateLet := ToDate(DateLet);
                    ImportFRLine.ValidDate := ToDate(ValidDate);
                    ImportFRLine.MontantDev := ToDecimal(MontantDevise);
                    ImportFRLine.IDevise := IDevise;
                    ImportFRLine."_External Document No." := _ExternalDocumentNo;
                    ImportFRLine."_Applies-to ID" := _AppliesToID;
                    ImportFRLine."_Shortcut Dimension 1 Code" := _ShortcutDimension1Code;
                    ImportFRLine."_Shortcut Dimension 2 Code" := _ShortcutDimension2Code;

                    ImportFRLine.Amount := ImportFRLine.Debit - ImportFRLine.Credit;
                    ImportFRLine.Open := (ImportFRLine.CompAuxNum <> '') and (ImportFRLine.EcritureLet = '');
                    if ImportFRLine.CompAuxNum <> '' then
                        ImportFRLine.Validate("VAT Amount", VATAmount(ImportFRLine));
                end;
            }
        }
    }
    var
        FirstlineSkipped: Boolean;
        LineNo: Integer;
        MapSourceCode: Record "WanaStart Map Source Code";
        MapAccount: Record "WanaStart Map Account";
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

    local procedure VATAmount(var Rec: Record "WanaStart Import FR Line"): Decimal;
    var
        ImportFRLine2: Record "WanaStart Import FR Line";
    begin
        // if MapSourceCode."VAT Account No. Filter" = '' then
        // exit;
        ImportFRLine2.SetCurrentKey(JournalCode, PieceRef, EcritureNum);
        ImportFRLine2.SetRange(JournalCode, Rec.JournalCode);
        ImportFRLine2.SetRange(EcritureDate, Rec.EcritureDate);
        ImportFRLine2.SetRange(EcritureNum, Rec.EcritureNum);
        ImportFRLine2.SetRange(PieceRef, Rec.PieceRef);
        ImportFRLine2.SetFilter(CompAuxNum, '<>%1', '');
        if ImportFRLine2.Count > 1 then
            exit;
        ImportFRLine2.SetRange(CompAuxNum);
        ImportFRLine2.SetFilter(CompteNum, '445*'); //MapSourceCode."VAT Account No. Filter"); 
        ImportFRLine2.CalcSums(Amount);
        exit(ImportFRLine2.Amount);
    end;
}
