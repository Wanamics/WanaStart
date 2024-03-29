#if FALSE
codeunit 87101 "wanaStart Import FR Setup"
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
        StartAccount: Record "wanaStart Map Account";
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
            Import(StartAccount, CsvBuffer);
            CsvBuffer.DeleteAll();
            Message(DoneMsg, StartAccount.Count(), CurrentDateTime - StartDateTime);
        end;
    end;

    var
        RowNo: Integer;
        ColumnNo: Integer;
        StartSourceCode: Record "wanaStart Map Source Code";
        Inserted: Integer;

    local procedure SwitchTextEncoding(var pInStream: InStream)
    begin
        //TODO
    end;

    local procedure Import(pRec: Record "wanaStart Map Account"; var CsvBuffer: Record "CSV Buffer")
    var
        LineNo: Integer;
        Next: Integer;
        ProgressMsg: Label 'FR Tax Audit Import...';
        DoneMsg: Label '%1 account(s) to map inserted.';
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";
    begin
        CsvBuffer.SetFilter(CsvBuffer."Line No.", '>1');
        CsvBuffer.SetFilter(CsvBuffer."Field No.", '1..2|5..8');
        ProgressDialog.Open(ProgressMsg);
        if CsvBuffer.FindSet then
            repeat
                ProgressDialog.SetProgress(CsvBuffer."Line No.");
                InitLine(pRec);
                LineNo := CsvBuffer."Line No.";
                repeat
                    ImportCell(pRec, CsvBuffer);
                    Next := CsvBuffer.Next;
                until (Next = 0) or (CsvBuffer."Line No." <> LineNo);
                InsertLine(pRec);
            until Next = 0;
        ProgressDialog.Close();
    end;

    local procedure InitLine(var pRec: Record "wanaStart Map Account")
    begin
        pRec.Init;
    end;

    local procedure InsertLine(var pRec: Record "wanaStart Map Account")
    begin
        if pRec.Get(pRec."From Account No.", pRec."From SubAccount No.") then
            exit;
        pRec.Insert();
        Inserted += 1;
    end;

    local procedure ImportCell(var pRec: Record "wanaStart Map Account"; pCsvBuffer: Record "CSV Buffer");
    begin
        case pCsvBuffer."Field No." of
            1: // JournalCode
                if pCsvBuffer.Value <> StartSourceCode."Source Code" then
                    if not StartSourceCode.Get(pCsvBuffer.Value) then begin
                        StartSourceCode.Init();
                        StartSourceCode."From Source Code" := pCsvBuffer.Value;
                        StartSourceCode.Insert();
                    end;
            2: //JournalLib
                if StartSourceCode."From Source Name" = '' then begin
                    StartSourceCode."From Source Name" := pCsvBuffer.Value;
                    StartSourceCode.Modify();
                end;
            5: // CompteNum
                pRec."From Account No." := pCsvBuffer.Value;
            6: // CompteLib
                pRec."From Account Name" := pCsvBuffer.Value;
            7: // CompteAuxNum
                pRec."From SubAccount No." := pCsvBuffer.Value;
            8: // CompteAuxLib
                if pCsvBuffer.Value <> '' then
                    pRec."From Account Name" := pCsvBuffer.Value;
        end;
    end;
}
#endif