codeunit 87105 "wanaStart Import FR Check VAT"
{
    trigger OnRun()
    var
        ImportFromExcelTitle: Label 'Import FR Tax Audit';
        ExcelFileCaption: Label 'Text Files (*.txt)';
        ExcelFileExtensionTok: Label '.txt', Locked = true;
        iStream: InStream;
        FileName: Text;
        CompanyInformation: Record "Company Information";
        ContinueMsg: Label 'Do-you want to continue?';
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines imported in %2.';
        FileNameMsg: Label 'Warning, File name %1 does not match "%2" %3.';
        Tab: Text[1];
        TempRec: Record "Gen. Journal Line" temporary;
        CsvBuffer: Record "CSV Buffer" temporary;
    begin
        if UploadIntoStream('', '', '', FileName, iStream) then begin
            CompanyInformation.Get();
            CompanyInformation.TestField("VAT Registration No.");
            if FileName.Substring(1, 9) <> CompanyInformation."VAT Registration No.".Replace(' ', '').Substring(5, 9) then
                if not Confirm(FileNameMsg + '\' + ContinueMsg, false, FileName, CompanyInformation.FieldCaption("VAT Registration No."), CompanyInformation."VAT Registration No.") then
                    Error('');

            StartDateTime := CurrentDateTime;
            SwitchTextEncoding(iStream);
            CsvBuffer.LockTable();
            Tab[1] := 9;
            CsvBuffer.LoadDataFromStream(iStream, Tab, '"');
            Import(TempRec, CsvBuffer);
            CsvBuffer.DeleteAll();
            Message(DoneMsg, TempRec.Count(), CurrentDateTime - StartDateTime);

            ToExcel(TempRec);
            TempRec.DeleteAll();
        end;
    end;

    var
        MapSourceCode: Record "wanaStart Map Source Code";
        MapAccount: Record "wanaStart Map Account";
        ExcelBuffer: Record "Excel Buffer" temporary;

    local procedure SwitchTextEncoding(var pInStream: InStream)
    begin
        //TODO
    end;

    local procedure Import(var pRec: Record "Gen. Journal Line"; var CsvBuffer: Record "CSV Buffer")
    var
        LineNo: Integer;
        Next: Integer;
        ProgressMsg: Label 'FR Tax Audit Import...';
        // DoneMsg: Label '%1 account(s) to map inserted.';
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";
        Buffer: Record "Gen. Journal Line" temporary;
    begin
        CsvBuffer.SetFilter(CsvBuffer."Line No.", '>1');
        CsvBuffer.SetFilter(CsvBuffer."Field No.", '1|3..5|7|9..14');
        ProgressDialog.Open(ProgressMsg);
        if CsvBuffer.FindSet then
            repeat
                ProgressDialog.SetProgress(CsvBuffer."Line No.");
                LineNo := CsvBuffer."Line No.";
                Buffer."Line No." := CsvBuffer."Line No.";
                repeat
                    ImportCell(Buffer, CsvBuffer);
                    Next := CsvBuffer.Next;
                until (Next = 0) or (CsvBuffer."Line No." <> LineNo);
                if (Buffer."Source Code" <> pRec."Source Code") or
                    (Buffer."Document No." <> pRec."Document No.") or
                    (Buffer."External Document No." <> pRec."External Document No.") or //?
                    (Buffer."Posting Date" <> pRec."Posting Date") then begin
                    if (pRec."Line No." <> 0) and
                        not MapSourceCode.Skip and
                        (MapSourceCode."Gen. Posting Type" in [MapSourceCode."Gen. Posting Type"::Purchase, MapSourceCode."Gen. Posting Type"::Sale]) then
                        pRec.Insert();
                    InitRec(pRec, Buffer);
                end;
                ProcessLine(pRec, Buffer);
            until Next = 0;
        pRec.Insert();
        ProgressDialog.Close();
    end;

    local procedure InitRec(var pRec: Record "Gen. Journal Line"; pBuffer: Record "Gen. Journal Line")
    begin
        pRec.Init;
        pRec."Line No." := pBuffer."Line No.";
        if pBuffer."Source Code" <> MapSourceCode."Source Code" then
            MapSourceCode.Get(pBuffer."Source Code");
        pRec."Source Code" := pBuffer."Source Code";
        pRec."Bal. Gen. Posting Type" := MapSourceCode."Gen. Posting Type";
        pRec."Document No." := pBuffer."Document No.";
        pRec."Posting Date" := pBuffer."Posting Date";
        pRec."External Document No." := pBuffer."External Document No."; //?
        // pRec.Description := pBuffer.Description;
    end;

    local procedure ProcessLine(var pRec: Record "Gen. Journal Line"; pBuffer: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        if MapSourceCode.Skip or
            not (MapSourceCode."Gen. Posting Type" in [MapSourceCode."Gen. Posting Type"::Purchase, MapSourceCode."Gen. Posting Type"::Sale]) then
            exit;

        if pBuffer."Account No." <> MapAccount."From Account No." then
            MapAccount.Get(pBuffer."Account No.", pBuffer."Source No.");
        If MapAccount."Account Type" in [MapAccount."Account Type"::Customer, MapAccount."Account Type"::Vendor] then begin
            pRec."Account Type" := MapAccount."Account Type";
            pRec."Account No." := MapAccount."Account No.";
            pRec."Document Date" := pBuffer."Document Date";
            pRec."Applies-to ID" := pBuffer."Applies-to ID";
            pRec.Amount := pBuffer."Debit Amount" - pBuffer."Credit Amount";
            if (pRec."Account Type" = pRec."Account Type"::Customer) and (pRec.Amount >= 0) or
                (pRec."Account Type" = pRec."Account Type"::Vendor) and (pRec.Amount <= 0) then
                pRec."Document Type" := pRec."Document Type"::Invoice
            else
                pRec."Document Type" := pRec."Document Type"::"Credit Memo";
        end;
        if MapAccount."Gen. Posting Type" = MapSourceCode."Gen. Posting Type" then
            pRec."VAT Amount" += pBuffer."Debit Amount" - pBuffer."Credit Amount"
        else begin
            case MapAccount."Account Type" of
                MapAccount."Account Type"::Customer:
                    begin
                        Customer.Get(MapAccount."Account No.");
                        SetBalVAT(pRec, Customer."VAT Bus. Posting Group")
                    end;
                MapAccount."Account Type"::Vendor:
                    begin
                        Vendor.Get(MapAccount."Account No.");
                        SetBalVAT(pRec, Vendor."VAT Bus. Posting Group")
                    end;
                else
                    if pRec."Bal. Account No." = '' then
                        pRec."Bal. Account No." := MapAccount."Account No."
                    else
                        pRec."Bal. Account No." := '*';
                    pRec."VAT Base Amount" += pBuffer."Debit Amount" - pBuffer."Credit Amount";
            end;
            if MapAccount."Account Type" in [MapAccount."Account Type"::Customer, MapAccount."Account Type"::Vendor] then begin
                pRec."External Document No." := pBuffer."External Document No.";
                pRec.Description := pBuffer.Description;
            end;
        end;
    end;

    local procedure ToDecimal(pCell: Text) ReturnValue: Decimal
    begin
        Evaluate(ReturnValue, pCell);
    end;

    local procedure ToDate(pCell: Text) ReturnValue: Date
    begin
        if not Evaluate(ReturnValue, pCell.Substring(7, 2) + pCell.Substring(5, 2) + pCell.Substring(1, 4)) then
            Evaluate(ReturnValue, pCell);
    end;

    local procedure ImportCell(var pBuffer: Record "Gen. Journal Line"; pCsvBuffer: Record "CSV Buffer");
    begin
        case pCsvBuffer."Field No." of
            1: // JournalCode
                pBuffer."Source Code" := pCsvBuffer.Value;
            3: // EcritureNum
                pBuffer."Document No." := CopyStr(pCsvBuffer.Value, 1, MaxStrLen(pBuffer."Document No."));
            4: // EcritureDate
                pBuffer."Posting Date" := ToDate(pCsvBuffer.Value);
            5: // CompteNum
                pBuffer."Account No." := pCsvBuffer.Value;
            7: // CompteAuxNum
                pBuffer."Source No." := pCsvBuffer.Value;
            9: // PieceRef
                pBuffer."External Document No." := pCsvBuffer.Value;
            10: // PieceDate
                pBuffer.Validate("Document Date", ToDate(pCsvBuffer.Value));
            11: // EcritureLib
                pBuffer.Description := CopyStr(pCsvBuffer.Value, 1, MaxStrLen(pBuffer.Description));
            12: // Debit
                pBuffer."Debit Amount" := ToDecimal(pCsvBuffer.Value);
            13: // Credit
                case pCsvBuffer.Value of
                    'D':
                        ;
                    'C':
                        pBuffer."Credit Amount" := pBuffer."Debit Amount";
                    else
                        pBuffer."Credit Amount" := ToDecimal(pCsvBuffer.Value);
                end;
            14: // EcritureLet
                pBuffer."Applies-to ID" := CopyStr(pCsvBuffer.Value, 1, MaxStrLen(pBuffer."Applies-to ID"));
        end;
    end;

    local procedure SetBalVAT(var pRec: Record "Gen. Journal Line"; VATBusPostingGroup: Code[20])
    begin
        pRec."Bal. VAT Bus. Posting Group" := VATBusPostingGroup;
        if MapAccount."VAT Prod. Posting Group" <> '' then
            pRec.Validate("Bal. VAT Prod. Posting Group", MapAccount."VAT Prod. Posting Group")
        else
            pRec.Validate("Bal. VAT Prod. Posting Group", MapSourceCode."VAT Prod. Posting Group");
    end;

    local procedure ToExcel(var pRec: Record "Gen. Journal Line")
    var
        RowNo: Integer;
        ColumnNo: Integer;
    begin
        ExportTitles(pRec, RowNo, ColumnNo);
        if pRec.FindSet() then
            repeat
                if pRec."Bal. VAT Amount" <> pRec."VAT Amount" then
                    ExportLine(pRec, RowNo, ColumnNo);
            until pRec.Next = 0;

        ExcelBuffer.CreateNewBook(CompanyName);
        ExcelBuffer.WriteSheet(CompanyName, CompanyName, UserId);
        ExcelBuffer.CloseBook;
        ExcelBuffer.SetFriendlyFilename(SafeFileName(pRec));
        ExcelBuffer.OpenExcel;
    end;

    local procedure ExportTitles(var pRec: Record "Gen. Journal Line"; var RowNo: Integer; var ColumnNo: integer)
    var
        VATDifference: Label 'VAT Difference';
    begin
        RowNo := 1;
        ColumnNo := 1;
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Line No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Posting Date"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Document Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Document No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Account Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Account No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption(Description), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("External Document No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Applies-to ID"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Document Date"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption(Amount), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("VAT Amount"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("VAT %"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. Account No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. VAT Base Amount"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. Gen. Posting Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. VAT Bus. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. VAT Prod. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. VAT %"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. VAT Amount"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, VATDifference, true, false, '', ExcelBuffer."Cell Type"::Text);
    end;

    local procedure ExportLine(var pRec: Record "Gen. Journal Line"; var RowNo: Integer; var ColumnNo: integer)
    var
        NumberFormat: Label '#,##0.00', Locked = true;
    begin
        RowNo += 1;
        ColumnNo := 1;
        EnterCell(RowNo, ColumnNo, Format(pRec."Line No."), false, false, '', ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(pRec."Posting Date"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Document Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Document No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Account Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Account No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.Description, false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."External Document No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Applies-to ID", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Document Date"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec.Amount), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(pRec."VAT Amount"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(PercentageVAT(-pRec."VAT Amount", pRec.Amount + pRec."VAT Amount")), false, false, '', ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. Account No."), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. VAT Base Amount"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. Gen. Posting Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Bal. VAT Bus. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Bal. VAT Prod. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. VAT %"), false, false, '', ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. VAT Amount"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(pRec."VAT Amount" - pRec."Bal. VAT Amount"), false, false, NumberFormat, ExcelBuffer."Cell Type"::Number);
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
            exit(Format(Round(pVATAmount / pAmountExclVAT * 100, 0.01)));
    end;

    local procedure SafeFileName(pRec: Record "Gen. Journal Line"): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        exit(FileManagement.GetSafeFileName(CompanyName));
    end;
}
