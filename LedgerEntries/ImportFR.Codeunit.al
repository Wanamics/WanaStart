codeunit 87100 "wanaStart Import FR"
{
    TableNo = "Gen. Journal Line";
    trigger OnRun()
    var
        ImportFromExcelTitle: Label 'Import FR Tax Audit';
        ExcelFileCaption: Label 'Text Files (*.txt)';
        ExcelFileExtensionTok: Label '.txt', Locked = true;
        iStream: InStream;
        FileName: Text;
        CompanyInformation: Record "Company Information";
        ConfirmMsg: Label 'Warning, %1 line(s) of this journal will be deleted.';
        ContinueMsg: Label 'Do-you want to continue?';
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines imported in %2.';
        FileNameMsg: Label 'Warning, File name %1 does not match "%2" %3.';
        Tab: Text[1];
    begin
        if not Rec.IsEmpty() then
            if not Confirm(ConfirmMsg + '\' + ContinueMsg, false, Rec.Count()) then
                error('');
        if UploadIntoStream('', '', '', FileName, iStream) then begin
            CompanyInformation.Get();
            CompanyInformation.TestField("VAT Registration No.");
            if FileName.Substring(1, 9) <> CompanyInformation."VAT Registration No.".Replace(' ', '').Substring(5, 9) then
                if not Confirm(FileNameMsg + '\' + ContinueMsg, false, FileName, CompanyInformation.FieldCaption("VAT Registration No."), CompanyInformation."VAT Registration No.") then
                    Error('');

            Rec.DeleteAll(true);

            StartDateTime := CurrentDateTime;
            SwitchTextEncoding(iStream);

            CsvBuffer.LockTable();
            Tab[1] := 9;
            CsvBuffer.LoadDataFromStream(iStream, Tab, '"');
            Import(Rec);
            CsvBuffer.DeleteAll();
            Message(DoneMsg, Rec.Count(), CurrentDateTime - StartDateTime);
        end;
    end;

    var
        RowNo: Integer;
        ColumnNo: Integer;
        CsvBuffer: Record "CSV Buffer" temporary;
        Columns: Dictionary of [Integer, Text];
        MapAccount: Record "wanaStart Map Account";
        MapSourceCode: Record "wanaStart Map Source Code";

    local procedure SwitchTextEncoding(var pInStream: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        oStream: OutStream;
    begin
        /*
        TempBlob.CreateOutStream(oStream, TextEncoding::UTF8);
        CopyStream(oStream, pInStream);
        TempBlob.CreateInStream(pInStream);
        */
    end;

    local procedure Import(pRec: Record "Gen. Journal Line")
    var
        LineNo: Integer;
        Next: Integer;
        ProgressMsg: Label 'FR Tax Audit Import';
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";
    begin
        CsvBuffer.SetFilter("Line No.", '>1');
        CsvBuffer.SetFilter("Field No.", Select());
        ProgressDialog.Open(ProgressMsg);
        if CsvBuffer.FindSet then
            repeat
                ProgressDialog.SetProgress(CsvBuffer."Line No.");
                Init(pRec);
                LineNo := CsvBuffer."Line No.";
                repeat
                    ImportCell(pRec);
                    Next := CsvBuffer.Next;
                until (Next = 0) or (CsvBuffer."Line No." <> LineNo);
                Insert(pRec);
            until Next = 0;
    end;

    local procedure Select() ReturnValue: Text
    begin
        Append(ReturnValue, 1, 'JournalCode');
        Append(ReturnValue, 3, 'EcritureNum');
        Append(ReturnValue, 4, 'EcritureDate');
        Append(ReturnValue, 5, 'CompteNum');
        Append(ReturnValue, 7, 'CompAuxNum');
        Append(ReturnValue, 9, 'PieceRef');
        Append(ReturnValue, 10, 'PieceDate');
        Append(ReturnValue, 11, 'EcritureLib');
        Append(ReturnValue, 12, 'Debit');
        Append(ReturnValue, 13, 'Credit');
        Append(ReturnValue, 14, 'EcritureLet');
        ReturnValue += '|19..';
    end;

    local procedure Append(var pSelect: Text; pColumnNo: Integer; pTitle: Text)
    var
        TitleErr: Label 'Title must be %1 for column %2';
    begin
        if pSelect <> '' then
            pSelect += '|';
        pSelect += Format(pColumnNo);
        if not CsvBuffer.Get(1, pColumnNo) or (CsvBuffer.Value <> pTitle) then
            Error(TitleErr, pTitle, pColumnNo);
    end;

    local procedure Init(var pRec: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        pRec.Init;
        GenJournalTemplate.Get(pRec."Journal Template Name");
        GenJournalBatch.Get(pRec."Journal Template Name", pRec."Journal Batch Name");
        pRec."Reason Code" := GenJournalBatch."Reason Code";
        MapAccount.Init();
        Clear(Columns);
    end;

    local procedure Insert(var pRec: Record "Gen. Journal Line")
    begin
        if MapAccount.Skip or MapSourceCode.Skip or
            (MapAccount."Gen. Posting Type" <> MapAccount."Gen. Posting Type"::" ") and
            (MapAccount."Gen. Posting Type" = MapSourceCode."Gen. Posting Type") then
            exit;
        if MapSourceCode."Gen. Posting Type" <> MapSourceCode."Gen. Posting Type"::" " then begin
            pRec.Validate("Bal. Account No.", MapSourceCode."Bal. Account No.");
            if IsInvoice(MapSourceCode."Gen. Posting Type", pRec) then
                pRec.Validate("Document Type", pRec."Document Type"::Invoice)
            else
                pRec.Validate("Document Type", pRec."Document Type"::"Credit Memo");
            if pRec."Account Type" in [pRec."Account Type"::Vendor, prec."Account Type"::Customer] then
                SetBalanceVAT(pRec);
            //BalanceDocumentNo := pRec."Document No.";
        end;

        if pRec."Account No." = '' then
            pRec.Description := CopyStr('!' + MapAccount."From Account No." + '|' + MapAccount."From SubAccount No." + '!' + pRec.Description, 1, MaxStrLen(prec.Description));

        if not (pRec."Account Type" in [pRec."Account Type"::Customer, pRec."Account Type"::Vendor]) then
            pRec."Applies-to ID" := '';

        // if ((pRec."Account Type" = pRec."Account Type"::Vendor) or (pRec."Bal. Account Type" = pRec."Account Type"::Vendor)) and
        //     (PurchaseSetup."Ext. Doc. No. Mandatory")
        // or
        //    ((pRec."Account Type" = pRec."Account Type"::Customer) or (pRec."Bal. Account Type" = pRec."Account Type"::Customer)) and
        //     (SalesSetup."Ext. Doc. No. Mandatory") then
        //     pRec.TestField("External Document No."); // := pRec."Document No.";
        if (pRec."Account Type" = pRec."Account Type"::Vendor) and
            (pRec."External Document No." <> '') and
            (pRec."Document Type" in [pRec."Document Type"::Invoice, pRec."Document Type"::"Credit Memo"]) then
            SetUniqueExternalDocumentNo(pRec);
        pRec."Line No." += 10000;
        OnBeforeInsert(pRec, Columns);
        pRec.Insert(true);
        MapDimensions(pRec);
        OnAfterInsert(pRec, Columns);
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

    local procedure ImportCell(var pRec: Record "Gen. Journal Line");
    var
        GLAccount: Record "G/L Account";
    begin
        case CsvBuffer."Field No." of
            1: // JournalCode
                pRec.Validate("Source Code", ToSourceCode(CsvBuffer.Value));
            // 2: // JournalLib
            //     ;
            3: // EcritureNum
                pRec.Validate("Document No.", CopyStr(CsvBuffer.Value, 1, MaxStrLen(pRec."Document No.")));
            4: // EcritureDate
                pRec.Validate("Posting Date", ToDate(CsvBuffer.Value));
            5: // CompteNum
                MapAccount."From Account No." := CsvBuffer.Value;
            // 6: // CompteLib
            //     ;
            7: // CompteAuxNum
                MapAccount."From SubAccount No." := CsvBuffer.Value;
            // 8: // CompteAuxLib
            //     ;
            9: // PieceRef
                begin
                    ToAccount(pRec);
                    if MapSourceCode."Start" then
                        pRec.Validate("External Document No.", CopyStr(CsvBuffer.Value, 1, MaxStrLen(pRec."External Document No.")))
                    else
                        pRec.Validate("Document No.", CopyStr(CsvBuffer.Value, 1, MaxStrLen(pRec."Document No.")));
                end;
            10: // PieceDate
                pRec.Validate("Document Date", ToDate(CsvBuffer.Value));
            11: // EcritureLib
                //if pRec.Description = '' then
                pRec.Validate(Description, CopyStr(CsvBuffer.Value, 1, MaxStrLen(pRec.Description)));
            //else
            //    pRec.Description := CopyStr(pRec.Description + CsvBuffer.Value, 1, MaxStrLen(pRec.Description));
            12: // Debit
                pRec.Validate("Debit Amount", ToDecimal(CsvBuffer.Value));
            13: // Credit
                case CsvBuffer.Value of
                    'D':
                        ;
                    'C':
                        pRec.Validate("Credit Amount", pRec."Debit Amount")
                    else
                        pRec.Validate("Credit Amount", ToDecimal(CsvBuffer.Value));
                end;
            14: // EcritureLet
                pRec.Validate("Applies-to ID", CopyStr(CsvBuffer.Value, 1, MaxStrLen(pRec."Applies-to ID")));
            // 15: // DateLet
            //     ;
            // 16: // ValidDate
            //     ;
            // 17:// MontantDev
            //     ;
            // 18: // Idevise
            //     ;
            // //[
            // 19:
            //     pRec.Validate("External Document No.", CopyStr(CsvBuffer.Value, 1, MaxStrLen(pRec."External Document No.")));
            // 20:
            //     pRec.Validate("Applies-to ID", CopyStr(CsvBuffer.Value,1, MaxStrLen(pRec."Applies-to ID")));
            // 21:
            //     pRec.Validate("Shortcut Dimension 1 Code", CsvBuffer.Value);
            // 22:
            //     pRec.Validate("Shortcut Dimension 2 Code", CsvBuffer.Value);
            // //]
            else
                // OnAfterImportCell(pRec, CsvBuffer);
                Columns.Add(CsvBuffer."Field No.", CsvBuffer.Value);
        end;
    end;

    local procedure ToSourceCode(pCode: Code[10]): Code[10]
    begin
        if pCode <> MapSourceCode."From Source Code" then
            MapSourceCode.Get(pCode);
        exit(MapSourceCode."Source Code");
    end;

    local procedure ToAccount(var pRec: Record "Gen. Journal Line")
    begin
        if MapAccount.Get(MapAccount."From Account No.", MapAccount."From SubAccount No.") and
            (MapAccount."Account No." <> '') then begin
            pRec.Validate("Account Type", MapAccount."Account Type");
            pRec.Validate("Account No.", MapAccount."Account No.");
        end;
    end;

    local procedure IsInvoice(pGenPostingType: enum "General Posting Type"; pRec: Record "Gen. Journal Line"): Boolean
    begin
        case pGenPostingType of
            pGenPostingType::Purchase:
                exit((pRec."Account Type" = pRec."Account type"::Vendor) xor (pRec.Amount >= 0));
            pGenPostingType::Sale:
                exit((pRec."Account Type" = pRec."Account type"::Customer) xor (pRec.Amount <= 0));
        end;
    end;

    local procedure SetBalanceVAT(var pRec: Record "Gen. Journal Line")
    begin
        pRec.Validate("Bal. Gen. Posting Type", MapSourceCode."Gen. Posting Type");
        case pRec."Account Type" of
            pRec."Account Type"::Customer:
                SetCustomerVATBusPostingGroup(pRec);
            pRec."Account Type"::Vendor:
                SetVendorVATBusPostingGroup(pRec);
        end;
        if MapAccount."VAT Prod. Posting Group" <> '' then
            pRec.Validate("Bal. VAT Prod. Posting Group", MapAccount."VAT Prod. Posting Group")
        else
            if MapSourceCode."VAT Prod. Posting Group" <> '' then
                pRec.Validate("Bal. VAT Prod. Posting Group", MapSourceCode."VAT Prod. Posting Group");
        pRec.TestField("Bal. VAT Prod. Posting Group");
    end;

    local procedure SetCustomerVATBusPostingGroup(var pRec: Record "Gen. Journal Line");
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("VAT Bus. Posting Group");
        if Customer.Get(pRec."Account No.") then
            pRec.Validate("Bal. VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
    end;

    local procedure SetVendorVATBusPostingGroup(var pRec: Record "Gen. Journal Line");
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetLoadFields("VAT Bus. Posting Group");
        if Vendor.Get(pRec."Account No.") then
            pRec.Validate("Bal. VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
    end;

    local procedure SetUniqueExternalDocumentNo(var pRec: Record "Gen. Journal Line")
    var
        lRec: Record "Gen. Journal Line";
        i: Integer;
    begin
        lRec.SetRange("Journal Template Name", pRec."Journal Template Name");
        lRec.SetRange("Journal Batch Name", pRec."Journal Batch Name");
        lRec.SetRange("Account Type", pRec."Account Type");
        lRec.SetRange("Account No.", prec."Account No.");
        lRec.SetRange("External Document No.", pRec."External Document No.");
        if lRec.FindSet() then
            repeat
                i += 1;
                pRec."External Document No." := lRec."External Document No." + '.' + format(i);
                lRec.SetRange("External Document No.", pRec."External Document No.");
            until lRec.IsEmpty();
    end;

    local procedure MapDimensions(var pRec: Record "Gen. Journal Line"): Boolean
    var
        DimensionSetId: Integer;
    begin
        DimensionSetId := pRec."Dimension Set ID";
        if MapAccount."Dimension 1 Code" <> '' then
            pRec.ValidateShortcutDimCode(1, MapAccount."Dimension 1 Code");
        if MapAccount."Dimension 2 Code" <> '' then
            pRec.ValidateShortcutDimCode(2, MapAccount."Dimension 2 Code");
        if MapAccount."Dimension 3 Code" <> '' then
            pRec.ValidateShortcutDimCode(3, MapAccount."Dimension 3 Code");
        if MapAccount."Dimension 4 Code" <> '' then
            pRec.ValidateShortcutDimCode(4, MapAccount."Dimension 4 Code");
        if pRec."Dimension Set ID" <> DimensionSetId then
            pRec.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert(var pRec: Record "Gen. Journal Line"; var pColumns: Dictionary of [Integer, Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsert(var pRec: Record "Gen. Journal Line"; var pColumns: Dictionary of [Integer, Text])
    begin
    end;
}