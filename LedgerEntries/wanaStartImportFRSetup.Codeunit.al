codeunit 87101 "wanaStart Import FR Setup"
{
    trigger OnRun()
    var
        ImportFromExcelTitle: Label 'Import FR Tax Audit';
        ExcelFileCaption: Label 'Text Files (*.txt)';
        ExcelFileExtensionTok: Label '.txt', Locked = true;
        IStream: InStream;
        FileName: Text;
        CompanyInformation: Record "Company Information";
        ContinueMsg: Label 'Do-you want to continue?';
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines imported in %2.';
        FileNameMsg: Label 'Warning, File name %1 does not match "%2" %3.';
        Tab: Text[1];
        _Account: Record "wanaStart Account";
        CsvBuffer: Record "CSV Buffer" temporary;
    begin
        if UploadIntoStream('', '', '', FileName, IStream) then begin
            CompanyInformation.Get();
            CompanyInformation.TestField("VAT Registration No.");
            if FileName.Substring(1, 9) <> CompanyInformation."VAT Registration No.".Replace(' ', '').Substring(5, 9) then
                if not Confirm(FileNameMsg + '\' + ContinueMsg, false, FileName, CompanyInformation.FieldCaption("VAT Registration No."), CompanyInformation."VAT Registration No.") then
                    Error('');

            StartDateTime := CurrentDateTime;
            SwitchTextEncoding(IStream);
            CsvBuffer.LockTable();
            //CsvBuffer.LoadDataFromStream(iStream, ';', '"');
            Tab[1] := 9;
            CsvBuffer.LoadDataFromStream(iStream, Tab, '"');
            Import(_Account, CsvBuffer);
            CsvBuffer.DeleteAll();
            Message(DoneMsg, _Account.Count(), CurrentDateTime - StartDateTime);
        end;
    end;

    var
        RowNo: Integer;
        ColumnNo: Integer;
        _SourceCode: Record "wanaStart Source Code";
        Inserted: Integer;

    local procedure SwitchTextEncoding(var pInStream: InStream)
    begin
        //TODO
    end;

    local procedure Import(pRec: Record "wanaStart Account"; CsvBuffer: Record "CSV Buffer")
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
                    ImportCell(pRec, CsvBuffer); // CsvBuffer."Field No.", CsvBuffer.Value);
                    Next := CsvBuffer.Next;
                until (Next = 0) or (CsvBuffer."Line No." <> LineNo);
                InsertLine(pRec);
            until Next = 0;
        ProgressDialog.Close();
    end;

    local procedure InitLine(var pRec: Record "wanaStart Account")
    begin
        pRec.Init;
    end;

    local procedure InsertLine(var pRec: Record "wanaStart Account")
    begin
        if pRec.Get(pRec."From Account No.", pRec."From SubAccount No.") then
            exit;
        pRec.Insert();
        Inserted += 1;
    end;

    local procedure ImportCell(var pRec: Record "wanaStart Account"; pCsvBuffer: Record "CSV Buffer"); // pColumnNo: Integer; pCell: Text)
    begin
        case pCsvBuffer."Field No." of
            1: // JournalCode
                if pCsvBuffer.Value <> _SourceCode."Source Code" then
                    if not _SourceCode.Get(pCsvBuffer.Value) then begin
                        _SourceCode.Init();
                        _SourceCode."From Source Code" := pCsvBuffer.Value;
                        _SourceCode.Insert();
                    end;
            2: //JournalLib
                if _SourceCode."From Source Name" = '' then begin
                    _SourceCode."From Source Name" := pCsvBuffer.Value;
                    _SourceCode.Modify();
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
