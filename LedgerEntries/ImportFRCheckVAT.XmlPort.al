xmlport 87100 "wanaStart ImportFR Check VAT"
{
    Caption = 'ImportFR Check VAT';
    Direction = Import;
    Format = VariableText;
    FieldSeparator = '<TAB>';
    // RecordSeparator = '<CR/LF>'; // Default ?
    // TableSeparator = '<NewLine><NewLine>'; // Default ?
    // RecordSeparator = '<LF>';
    TableSeparator = '<None>';
    UseRequestPage = false;

    TextEncoding = UTF8;

    schema
    {
        textelement(RootNodeName)
        {
            tableelement(TempRec; "Gen. Journal Line")
            {
                UseTemporary = true;
                AutoSave = false;
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
                textelement(Idevise) { }
                trigger OnAfterGetRecord()
                begin
                    LineNo += 1;
                    if true then begin
                        if true then begin
                            if true then
                                // if LineNo > 1 then begin
                                // if (JournalLib <> TempRec."Source Code") or
                                //     (EcritureNum <> TempRec."Document No.") or
                                //     (ToDate(EcritureDate) <> TempRec."Posting Date") or
                                //     (PieceRef <> TempRec."External Document No.") then begin
                                //     if (TempRec."Line No." <> 0) and
                                //         not MapSourceCode.Skip and
                                //         (MapSourceCode."Gen. Posting Type" in [MapSourceCode."Gen. Posting Type"::Purchase, MapSourceCode."Gen. Posting Type"::Sale]) and
                                //         (TempRec."VAT Amount" <> TempRec."Bal. VAT Amount") then
                                TempRec.Insert();
                            InitRec();
                        end;
                        ProcessLine();
                    end;
                end;
            }
        }
    }
    trigger OnPreXmlPort()
    var
        CompanyInformation: Record "Company Information";
        ContinueMsg: Label 'Do-you want to continue?';
        FileNameMsg: Label 'Warning, File name %1 does not match "%2" %3.';
    begin
        CompanyInformation.Get();
        CompanyInformation.TestField("VAT Registration No.");
        if FileName.Substring(1, 9) <> CompanyInformation."VAT Registration No.".Replace(' ', '').Substring(5, 9) then
            if not Confirm(FileNameMsg + '\' + ContinueMsg, false, FileName, CompanyInformation.FieldCaption("VAT Registration No."), CompanyInformation."VAT Registration No.") then
                Error('');

        StartDateTime := CurrentDateTime;
    end;

    trigger OnPostXmlPort()
    var
        DoneMsg: Label '%1 lines imported in %2.';
    begin
        Message(DoneMsg, LineNo, CurrentDateTime - StartDateTime);
        // Message(DoneMsg, TempRec.Count(), CurrentDateTime - StartDateTime);
    end;

    var
        StartDateTime: DateTime;
        MapSourceCode: Record "wanaStart Map Source Code";
        MapAccount: Record "wanaStart Map Account";
        LineNo: Integer;
        ExcelBuffer: Record "Excel Buffer" temporary;

    local procedure InitRec()
    begin
        TempRec.Init;
        TempRec."Line No." := LineNo;
        if JournalCode <> MapSourceCode."From Source Code" then
            MapSourceCode.Get(JournalCode);
        TempRec."Source Code" := MapSourceCode."Source Code";
        TempRec."Bal. Gen. Posting Type" := MapSourceCode."Gen. Posting Type";
        TempRec."Document No." := EcritureNum;
        TempRec."Posting Date" := ToDate(EcritureDate);
        // TempRec."External Document No." := PieceRef;
        // TempRec.Description := EcritureLib;
    end;

    local procedure ProcessLine()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        if MapSourceCode.Skip or
            not (MapSourceCode."Gen. Posting Type" in [MapSourceCode."Gen. Posting Type"::Purchase, MapSourceCode."Gen. Posting Type"::Sale]) then
            exit;

        if CompteNum <> MapAccount."From Account No." then
            MapAccount.Get(CompteNum, CompAuxNum);
        If MapAccount."Account Type" in [MapAccount."Account Type"::Customer, MapAccount."Account Type"::Vendor] then begin
            TempRec."Account Type" := MapAccount."Account Type";
            TempRec."Account No." := MapAccount."Account No.";
            TempRec."Document Date" := ToDate(PieceDate);
            TempRec."Applies-to ID" := EcritureLet;
            TempRec.Amount := ToAmount();
            if (TempRec."Account Type" = TempRec."Account Type"::Customer) and (TempRec.Amount >= 0) or
                (TempRec."Account Type" = TempRec."Account Type"::Vendor) and (TempRec.Amount <= 0) then
                TempRec."Document Type" := TempRec."Document Type"::Invoice
            else
                TempRec."Document Type" := TempRec."Document Type"::"Credit Memo";
        end;
        if MapAccount."Gen. Posting Type" = MapSourceCode."Gen. Posting Type" then
            TempRec."VAT Amount" += ToAmount()
        else begin
            case MapAccount."Account Type" of
                MapAccount."Account Type"::Customer:
                    begin
                        Customer.Get(MapAccount."Account No.");
                        SetBalVAT(Customer."VAT Bus. Posting Group")
                    end;
                MapAccount."Account Type"::Vendor:
                    begin
                        Vendor.Get(MapAccount."Account No.");
                        SetBalVAT(Vendor."VAT Bus. Posting Group")
                    end;
                else
                    if TempRec."Bal. Account No." = '' then
                        TempRec."Bal. Account No." := MapAccount."Account No."
                    else
                        TempRec."Bal. Account No." := '*';
                    TempRec."VAT Base Amount" += ToAmount();
            end;
            if MapAccount."Account Type" in [MapAccount."Account Type"::Customer, MapAccount."Account Type"::Vendor] then begin
                TempRec."External Document No." := PieceRef;
                TempRec.Description := EcritureLib;
            end;
        end;
    end;

    local procedure ToAmount() ReturnValue: Decimal
    begin
        Evaluate(ReturnValue, Debit);
        Case Credit of
            'D':
                ;
            'C':
                exit(-ReturnValue);
            else
                Evaluate(ReturnValue, Credit)
        end;
    end;

    local procedure ToDate(pCell: Text) ReturnValue: Date
    begin
        if not Evaluate(ReturnValue, pCell.Substring(7, 2) + pCell.Substring(5, 2) + pCell.Substring(1, 4)) then
            Evaluate(ReturnValue, pCell);
    end;

    local procedure SetBalVAT(VATBusPostingGroup: Code[20])
    begin
        TempRec."Bal. VAT Bus. Posting Group" := VATBusPostingGroup;
        if MapAccount."VAT Prod. Posting Group" <> '' then
            TempRec.Validate("Bal. VAT Prod. Posting Group", MapAccount."VAT Prod. Posting Group")
        else
            TempRec.Validate("Bal. VAT Prod. Posting Group", MapSourceCode."VAT Prod. Posting Group");
    end;

    local procedure ToExcel()
    var
        RowNo: Integer;
        ColumnNo: Integer;
    begin
        ExportTitles(RowNo, ColumnNo);
        if TempRec.FindSet() then
            repeat
                ExportLine(RowNo, ColumnNo);
            until TempRec.Next = 0;

        ExcelBuffer.CreateNewBook(CompanyName);
        ExcelBuffer.WriteSheet(CompanyName, CompanyName, UserId);
        ExcelBuffer.CloseBook;
        ExcelBuffer.SetFriendlyFilename(SafeFileName(TempRec));
        ExcelBuffer.OpenExcel;
    end;

    local procedure ExportTitles(var RowNo: Integer; var ColumnNo: integer)
    var
        VATDifference: Label 'VAT Difference';
    begin
        RowNo := 1;
        ColumnNo := 1;
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Line No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Posting Date"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Document Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Document No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Account Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Account No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption(Description), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("External Document No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Applies-to ID"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Document Date"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption(Amount), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("VAT Amount"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("VAT %"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Bal. Account No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Bal. VAT Base Amount"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Bal. Gen. Posting Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Bal. VAT Bus. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Bal. VAT Prod. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Bal. VAT %"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.FieldCaption("Bal. VAT Amount"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, VATDifference, true, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    local procedure ExportLine(var RowNo: Integer; var ColumnNo: integer)
    var
        NumberFormat: Label '#,##0.00', Locked = true;
    begin
        RowNo += 1;
        ColumnNo := 1;
        EnterCell(RowNo, ColumnNo, Format(TempRec."Line No."), false, false, '', ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Posting Date"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Document Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec."Document No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Account Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec."Account No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec.Description, false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec."External Document No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec."Applies-to ID", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Document Date"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(TempRec.Amount), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(TempRec."VAT Amount"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(PercentageVAT(TempRec."VAT Amount", TempRec.Amount - TempRec."VAT Amount")), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Bal. Account No."), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Bal. VAT Base Amount"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Bal. Gen. Posting Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec."Bal. VAT Bus. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, TempRec."Bal. VAT Prod. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Bal. VAT %"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(TempRec."Bal. VAT Amount"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(PercentageVAT(TempRec."Bal. VAT Amount", TempRec."Bal. VAT Base Amount")), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
    end;

    local procedure EnterCell(pRowNo: Integer; var pColumnNo: Integer; pCellValue: Text; pBold: Boolean; pUnderLine: Boolean; pNumberFormat: Text; pCellType: Option)
    begin
        ExcelBuffer.Init;
        ExcelBuffer.Validate("Row No.", pRowNo);
        ExcelBuffer.Validate("Column No.", pColumnNo);
        ExcelBuffer."Cell Value as Text" := pCellValue;
        ExcelBuffer.Formula := '';
        ExcelBuffer.Bold := pBold;
        ExcelBuffer.Underline := pUnderLine;
        ExcelBuffer.NumberFormat := pNumberFormat;
        ExcelBuffer."Cell Type" := pCellType;
        ExcelBuffer.Insert;
        pColumnNo += 1;
    end;

    local procedure PercentageVAT(pVATAmount: Decimal; pAmountExclVAT: Decimal): Text
    var
        NumberFormat: Label '#,##0.0', Locked = true;
    begin
        if pAmountExclVAT = 0 then
            exit('')
        else
            exit(Format(pVATAmount / pAmountExclVAT * 100, 0, NumberFormat));
    end;

    local procedure SafeFileName(pRec: Record "Gen. Journal Line"): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        exit(FileManagement.GetSafeFileName(CompanyName));
    end;
}
