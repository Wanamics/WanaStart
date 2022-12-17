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
        CsvBuffer: Record "CSV Buffer" temporary;
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
            Import(Rec, CsvBuffer);
            CsvBuffer.DeleteAll();
            Message(DoneMsg, Rec.Count(), CurrentDateTime - StartDateTime);
        end;
    end;

    var
        RowNo: Integer;
        ColumnNo: Integer;
        StartAccount: Record "wanaStart Map Account";
        StartSourceCode: Record "wanaStart Map Source Code";

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

    local procedure Import(pRec: Record "Gen. Journal Line"; var pCsvBuffer: Record "CSV Buffer")
    var
        LineNo: Integer;
        Next: Integer;
        ProgressMsg: Label 'FR Tax Audit Import';
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";

    begin
        pCsvBuffer.SetFilter("Line No.", '>1');
        pCsvBuffer.SetFilter("Field No.", '1|4|5|7|9..');
        ProgressDialog.Open(ProgressMsg);
        if pCsvBuffer.FindSet then
            repeat
                ProgressDialog.SetProgress(pCsvBuffer."Line No.");
                InitLine(pRec);
                LineNo := pCsvBuffer."Line No.";
                repeat
                    ImportCell(pRec, pCsvBuffer);
                    Next := pCsvBuffer.Next;
                until (Next = 0) or (pCsvBuffer."Line No." <> LineNo);
                InsertLine(pRec);
            until Next = 0;
    end;

    local procedure InitLine(var pRec: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        pRec.Init;
        GenJournalTemplate.Get(pRec."Journal Template Name");
        GenJournalBatch.Get(pRec."Journal Template Name", pRec."Journal Batch Name");
        pRec."Reason Code" := GenJournalBatch."Reason Code";
        StartAccount.Init();
    end;

    local procedure InsertLine(var pRec: Record "Gen. Journal Line")
    begin
        if StartAccount.Skip or StartSourceCode.Skip or
            (StartAccount."Gen. Posting Type" <> StartAccount."Gen. Posting Type"::" ") and
            (StartAccount."Gen. Posting Type" = StartSourceCode."Gen. Posting Type") then
            exit;
        if StartSourceCode."Gen. Posting Type" <> StartSourceCode."Gen. Posting Type"::" " then begin
            pRec.Validate("Bal. Account No.", StartSourceCode."Bal. Account No.");
            if IsInvoice(StartSourceCode."Gen. Posting Type", pRec) then
                pRec.Validate("Document Type", pRec."Document Type"::Invoice)
            else
                pRec.Validate("Document Type", pRec."Document Type"::"Credit Memo");
            if pRec."Account Type" in [pRec."Account Type"::Vendor, prec."Account Type"::Customer] then
                SetBalanceVAT(pRec);
            //BalanceDocumentNo := pRec."Document No.";
        end;

        if pRec."Account No." = '' then
            pRec.Description := CopyStr('!' + StartAccount."From Account No." + '|' + StartAccount."From SubAccount No." + '!' + pRec.Description, 1, MaxStrLen(prec.Description));

        if not (pRec."Account Type" in [pRec."Account Type"::Customer, pRec."Account Type"::Vendor]) then
            pRec."Applies-to ID" := '';

        pRec."Line No." += 10000;
        pRec.Insert(true);
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

    local procedure ImportCell(var pRec: Record "Gen. Journal Line"; pCsvBuffer: Record "CSV Buffer"); //; pColumnNo: Integer; pCell: Text)
    var
        GLAccount: Record "G/L Account";
    begin
        case pCsvBuffer."Field No." of
            1: // JournalCode
                pRec.Validate("Source Code", ToSourceCode(pCsvBuffer.Value));
            2: // JournalLib
                ;
            3: // EcritureNum
                ;
            4: // EcritureDate
                pRec.Validate("Posting Date", ToDate(pCsvBuffer.Value));
            5: // CompteNum
                StartAccount."From Account No." := pCsvBuffer.Value;
            6: // CompteLib
                ;
            7: // CompteAuxNum
                StartAccount."From SubAccount No." := pCsvBuffer.Value;
            8: // CompteAuxLib
                ;
            9: // PieceRef
                begin
                    MapAccount(pRec);
                    pRec.Validate("Document No.", CopyStr(pCsvBuffer.Value, 1, maxstrlen(pRec."Document No.")));
                end;
            10: // PieceDate
                pRec.Validate("Document Date", ToDate(pCsvBuffer.Value));
            11: // EcritureLib
                //if pRec.Description = '' then
                pRec.Validate(Description, CopyStr(pCsvBuffer.Value, 1, maxstrlen(pRec.Description)));
            //else
            //    pRec.Description := CopyStr(pRec.Description + pCsvBuffer.Value, 1, MaxStrLen(pRec.Description));
            12: // Debit
                pRec.Validate("Debit Amount", ToDecimal(pCsvBuffer.Value));
            13: // Credit
                case pCsvBuffer.Value of
                    'D':
                        ;
                    'C':
                        pRec.Validate("Credit Amount", pRec."Debit Amount")
                    else
                        pRec.Validate("Credit Amount", ToDecimal(pCsvBuffer.Value));
                end;
            14: // EcritureLet
                pRec.Validate("Applies-to ID", CopyStr(pCsvBuffer.Value, 1, MaxStrLen(pRec."Applies-to ID")));
            15: // DateLet
                ;
            16: // ValidDate
                ;
            17:// MontantDev
                ;
            18: // Idevise
                ;
            else
                OnAfterImportCell(pRec, pCsvBuffer);
        end;
    end;

    local procedure ToSourceCode(pCode: Code[10]): Code[10]
    begin
        if pCode <> StartSourceCode."From Source Code" then
            StartSourceCode.Get(pCode);
        exit(StartSourceCode."Source Code");
    end;

    local procedure MapAccount(var pRec: Record "Gen. Journal Line")
    begin
        if StartAccount.Get(StartAccount."From Account No.", StartAccount."From SubAccount No.") and
            (StartAccount."Account No." <> '') then begin
            pRec.Validate("Account Type", StartAccount."Account Type");
            pRec.Validate("Account No.", StartAccount."Account No.");
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
        pRec.Validate("Bal. Gen. Posting Type", StartSourceCode."Gen. Posting Type");
        case pRec."Account Type" of
            pRec."Account Type"::Customer:
                SetCustomerVATBusPostingGroup(pRec);
            pRec."Account Type"::Vendor:
                SetVendorVATBusPostingGroup(pRec);
        end;
        if StartAccount."VAT Prod. Posting Group" <> '' then
            pRec.Validate("Bal. VAT Prod. Posting Group", StartAccount."VAT Prod. Posting Group")
        else
            if StartSourceCode."VAT Prod. Posting Group" <> '' then
                pRec.Validate("Bal. VAT Prod. Posting Group", StartSourceCode."VAT Prod. Posting Group");
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportCell(var pRec: Record "Gen. Journal Line"; pCsvBuffer: Record "CSV Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsert(var pRec: Record "Gen. Journal Line")
    begin
    end;
}