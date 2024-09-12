codeunit 87101 "wanaStart Import FR"
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
        DeleteLines: Label 'Do you want to delete %1 previous lines?';
    begin
        if not ImportLine.IsEmpty then
            if not Confirm(DeleteLines, false, ImportLine.Count) then
                exit
            else
                ImportLine.DeleteAll();

        if UploadIntoStream('', '', '', FileName, iStream) then begin
            CompanyInformation.Get();
            CompanyInformation.TestField("VAT Registration No.");
            if FileName.Substring(1, 9) <> CompanyInformation."VAT Registration No.".Replace(' ', '').Substring(5, 9) then
                if not Confirm(FileNameMsg + '\' + ContinueMsg, false, FileName, CompanyInformation.FieldCaption("VAT Registration No."), CompanyInformation."VAT Registration No.") then
                    Error('');

            StartDateTime := CurrentDateTime;
            SwitchTextEncoding(iStream);
            // CsvBuffer.LockTable();
            Tab[1] := 9;
            CsvBuffer.LoadDataFromStream(iStream, Tab, '"');
            Import();
            CsvBuffer.DeleteAll();
            Message(DoneMsg, ImportLine."Line No." - 1, CurrentDateTime - StartDateTime);
        end;
    end;

    var
        RowNo: Integer;
        ColumnNo: Integer;
        CsvBuffer: Record "CSV Buffer" temporary;
        MapSourceCode: Record "wanaStart Map Source Code";
        MapAccount: Record "wanaStart Map Account";
        ImportLine: Record "wanaStart Import FR Line";
        JournalLib: Text[100];
        CompteLib: Text[100];
        CompAuxLib: Text[100];
        Helper: Codeunit "wan Helper";
        TypeHelper: Codeunit "Type Helper";

    local procedure SwitchTextEncoding(var pInStream: InStream)
    begin
        //TODO
    end;

    local procedure Import()
    var
        LineNo: Integer;
        Next: Integer;
        ProgressMsg: Label 'FR Tax Audit Import...';
        DoneMsg: Label '%1 account(s) to map inserted.';
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";
    begin
        CsvBuffer.SetFilter(CsvBuffer."Line No.", '>1');
        // CsvBuffer.SetFilter(CsvBuffer."Field No.", '1..2|5..8');
        // CsvBuffer.SetFilter(CsvBuffer."Field No.", '1..14');
        ProgressDialog.Open(ProgressMsg);
        if CsvBuffer.FindSet then
            repeat
                ProgressDialog.SetProgress(CsvBuffer."Line No.");
                InitLine();
                LineNo := CsvBuffer."Line No.";
                repeat
                    ImportCell();
                    Next := CsvBuffer.Next;
                until (Next = 0) or (CsvBuffer."Line No." <> LineNo);
                InsertLine();
            until Next = 0;
        SetVatPercent();
        ProgressDialog.Close();
    end;

    local procedure InitLine()
    begin
        ImportLine.Init();
        ImportLine."Line No." := CsvBuffer."Line No.";
    end;

    local procedure InsertLine()
    begin
        if ImportLine.JournalCode <> MapSourceCode."Source Code" then
            if not MapSourceCode.Get(ImportLine.JournalCode) then begin
                MapSourceCode.Init();
                MapSourceCode."From Source Code" := ImportLine.JournalCode;
                MapSourceCode."From Source Name" := JournalLib;
                MapSourceCode.Insert();
            end;
        if (ImportLine.CompteNum <> MapAccount."From Account No.") or (ImportLine.CompAuxNum <> MapAccount."From SubAccount No.") then
            if not MapAccount.Get(ImportLine.CompteNum, ImportLine.CompAuxNum) then begin
                MapAccount.Init();
                MapAccount."From Account No." := ImportLine.CompteNum;
                MapAccount."From SubAccount No." := ImportLine.CompAuxNum;
                if ImportLine.CompAuxNum = '' then
                    MapAccount."From Account Name" := CompteLib
                else
                    MapAccount."From Account Name" := CompAuxLib;
                MapAccount.Insert();
            end;
        ImportLine.Amount := ImportLine.Debit - ImportLine.Credit;
        ImportLine.Open := (ImportLine.CompAuxNum <> '') and (ImportLine.EcritureLet = '');
        OnBeforeInsert(ImportLine);
        ImportLine.Insert();
    end;

    local procedure ImportCell();
    var
        v: Variant;
    begin
        case CsvBuffer."Field No." of
            1:
                ImportLine.JournalCode := CsvBuffer.Value;
            2:
                JournalLib := CsvBuffer.Value;
            3:
                ImportLine.EcritureNum := CopyStr(CsvBuffer.Value, 1, MaxStrLen(ImportLine.EcritureNum));
            4:
                // ImportLine.EcritureDate := Helper.yyyyddmmToDate(CsvBuffer.Value);
                if TypeHelper.Evaluate(v, CsvBuffer.Value, 'yyyyMMdd', '') then
                    ImportLine.EcritureDate := v;
            5:
                ImportLine.CompteNum := CsvBuffer.Value;
            6:
                CompteLib := CsvBuffer.Value;
            7:
                ImportLine.CompAuxNum := CsvBuffer.Value;
            8:
                CompAuxLib := CsvBuffer.Value;
            9:
                ImportLine.PieceRef := CopyStr(CsvBuffer.Value, 1, MaxStrLen(ImportLine.PieceRef));
            10:
                ImportLine.PieceDate := Helper.yyyyddmmToDate(CsvBuffer.Value);
            11:
                ImportLine.EcritureLib := CopyStr(CsvBuffer.Value, 1, MaxStrLen(ImportLine.EcritureLib));
            12:
                ImportLine.Debit := Helper.ToDecimal(CsvBuffer.Value);
            13:
                case CsvBuffer.Value of
                    'D':
                        ;
                    'C':
                        begin
                            ImportLine.Credit := ImportLine.Debit;
                            ImportLine.Debit := 0;
                        end;
                    else
                        ImportLine.Credit := Helper.ToDecimal(CsvBuffer.Value);
                end;
            14:
                ImportLine.EcritureLet := CopyStr(CsvBuffer.Value, 1, MaxStrLen(ImportLine.EcritureLet));
            15:
                ImportLine.DateLet := Helper.yyyyddmmToDate(CsvBuffer.Value);
            16:
                ImportLine.ValidDate := Helper.yyyyddmmToDate(CsvBuffer.Value);
            17:
                ImportLine.MontantDev := Helper.ToDecimal(CsvBuffer.Value);
            18:
                ImportLine.Idevise := CsvBuffer.Value;
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
                OnAfterImportCell(ImportLine, CsvBuffer);
        end;
    end;

    local procedure SetVATPercent()
    var
        ImportLine: Record "wanaStart Import FR Line";
    begin
        ImportLine.SetFilter(CompAuxNum, '<>%1', '');
        if ImportLine.FindSet() then
            repeat
                ImportLine.Validate("VAT Amount", VATAmount(ImportLine));
                if ImportLine."VAT Amount" <> 0 then
                    ImportLine.Modify();
            until ImportLine.Next() = 0;
    end;

    local procedure VATAmount(var Rec: Record "wanaStart Import FR Line"): Decimal;
    var
        ImportLine2: Record "wanaStart Import FR Line";
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportCell(var ImportLine: Record "wanaStart Import FR Line"; var CsvBuffer: Record "CSV Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert(var ImportLine: Record "wanaStart Import FR Line")
    begin
    end;
}
