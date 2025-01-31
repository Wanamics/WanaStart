#if FALSE
codeunit 87101 "WanaStart Import FR"
{
    // TableNo = "WanaStart Import FR Line";

    trigger OnRun()
    var
        //     ImportFromExcelTitle: Label 'Import FR Tax Audit';
        //     ExcelFileCaption: Label 'Text Files (*.txt)';
        //     ExcelFileExtensionTok: Label '.txt', Locked = true;
        //     iStream: InStream;
        //     FileName: Text;
        //     CompanyInformation: Record "Company Information";
        //     ContinueMsg: Label 'Do-you want to continue?';
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines imported in %2.';
        //     FileNameMsg: Label 'Warning, File name %1 does not match "%2" %3.';
        //     Tab: Text[1];
        DeleteLines: Label 'Do you want to delete %1 previous lines?';
    //     TempBlob: Codeunit "Temp Blob";
    begin
        if not Rec.IsEmpty then
            if not Confirm(DeleteLines, false, Rec.Count) then
                exit;
        // else begin
        Rec.DeleteAll();
        // Commit();
        // end;

        StartDateTime := CurrentDateTime;
        Xmlport.Run(Xmlport::"Import FEC+", false, true, Rec);

        // // //[
        // // TempBlob.CreateInStream(iStream, TextEncoding::UTF8);
        // // //]
        // if UploadIntoStream('', '', '', FileName, iStream) then begin
        //     CompanyInformation.Get();
        //     CompanyInformation.TestField("VAT Registration No.");
        //     if FileName.Substring(1, 9) <> CompanyInformation."VAT Registration No.".Replace(' ', '').Substring(5, 9) then
        //         if not Confirm(FileNameMsg + '\' + ContinueMsg, false, FileName, CompanyInformation.FieldCaption("VAT Registration No."), CompanyInformation."VAT Registration No.") then
        //             Error('');

        //     // SwitchTextEncoding(iStream);
        //     // CsvBuffer.LockTable();
        //     // Tab[1] := 9;
        //     Tab[1] := '|';
        //     CsvBuffer.LoadDataFromStream(iStream, Tab, '"|');
        //     Import();
        //     CsvBuffer.DeleteAll();



        // if Rec.FindSet() then
        //     repeat
        //     if Rec.CompAuxNum <> '' then begin
        //         Rec.Validate("VAT Amount", VATAmount(Rec));
        //         if Rec."VAT Amount" <> 0 then
        //             Rec.Modify();
        //     end;
        //     until Rec.Next() = 0;

        Message(DoneMsg, Rec."Line No." - 1, CurrentDateTime - StartDateTime);
        // end;
    end;

    var
        Rec: Record "wanaStart Import FR Line";
    // RowNo: Integer;
    // ColumnNo: Integer;
    // CsvBuffer: Record "CSV Buffer" temporary;
    // MapSourceCode: Record "WanaStart Map Source Code";
    // MapAccount: Record "WanaStart Map Account";
    // ImportLine: Record "WanaStart Import FR Line";
    // JournalLib: Text[100];
    // CompteLib: Text[100];
    // CompAuxLib: Text[100];
    // Helper: Codeunit "WanaStart Helper";
    // TypeHelper: Codeunit "Type Helper";

    // local procedure SwitchTextEncoding(var pInStream: InStream)
    // begin
    //     //TODO
    // end;

    // local procedure Import()
    // var
    //     LineNo: Integer;
    //     Next: Integer;
    //     ProgressMsg: Label 'FR Tax Audit Import...';
    //     DoneMsg: Label '%1 account(s) to map inserted.';
    //     ProgressDialog: Codeunit "Excel Buffer Dialog Management";
    // begin
    //     CsvBuffer.SetFilter(CsvBuffer."Line No.", '>1');
    //     // CsvBuffer.SetFilter(CsvBuffer."Field No.", '1..2|5..8');
    //     // CsvBuffer.SetFilter(CsvBuffer."Field No.", '1..14');
    //     ProgressDialog.Open(ProgressMsg);
    //     if CsvBuffer.FindSet then
    //         repeat
    //             ProgressDialog.SetProgress(CsvBuffer."Line No.");
    //             InitLine();
    //             LineNo := CsvBuffer."Line No.";
    //             repeat
    //                 ImportCell();
    //                 Next := CsvBuffer.Next;
    //             until (Next = 0) or (CsvBuffer."Line No." <> LineNo);
    //             InsertLine();
    //         until Next = 0;
    //     SetVatPercent();
    //     ProgressDialog.Close();
    // end;

    // local procedure InitLine()
    // begin
    //     ImportLine.Init();
    //     ImportLine."Line No." := CsvBuffer."Line No.";
    // end;

    // local procedure InsertLine()
    // begin
    //     if ImportLine.JournalCode <> MapSourceCode."Source Code" then
    //         if not MapSourceCode.Get(ImportLine.JournalCode) then begin
    //             MapSourceCode.Init();
    //             MapSourceCode."From Source Code" := ImportLine.JournalCode;
    //             MapSourceCode."From Source Name" := JournalLib;
    //             MapSourceCode.Insert();
    //         end;
    //     if (ImportLine.CompteNum <> MapAccount."From Account No.") or (ImportLine.CompAuxNum <> MapAccount."From SubAccount No.") then
    //         if not MapAccount.Get(ImportLine.CompteNum, ImportLine.CompAuxNum) then begin
    //             MapAccount.Init();
    //             MapAccount."From Account No." := ImportLine.CompteNum;
    //             MapAccount."From SubAccount No." := ImportLine.CompAuxNum;
    //             if ImportLine.CompAuxNum = '' then
    //                 MapAccount."From Account Name" := CompteLib
    //             else
    //                 MapAccount."From Account Name" := CompAuxLib;
    //             MapAccount.Insert();
    //         end;
    //     ImportLine.Amount := ImportLine.Debit - ImportLine.Credit;
    //     ImportLine.Open := (ImportLine.CompAuxNum <> '') and (ImportLine.EcritureLet = '');
    //     OnBeforeInsert(ImportLine);
    //     ImportLine.Insert();
    // end;


    // local procedure SetVATPercent()
    // var
    //     ImportLine: Record "WanaStart Import FR Line";
    // begin
    //     ImportLine.SetFilter(CompAuxNum, '<>%1', '');
    //     if ImportLine.FindSet() then
    //         repeat
    //             ImportLine.Validate("VAT Amount", VATAmount(ImportLine));
    //             if ImportLine."VAT Amount" <> 0 then
    //                 ImportLine.Modify();
    //         until ImportLine.Next() = 0;
    // end;

    // local procedure VATAmount(var Rec: Record "WanaStart Import FR Line"): Decimal;
    // var
    //     ImportLine2: Record "WanaStart Import FR Line";
    // begin
    //     // if MapSourceCode."VAT Account No. Filter" = '' then
    //     // exit;
    //     ImportLine2.SetCurrentKey(JournalCode, PieceRef, EcritureNum);
    //     ImportLine2.SetRange(JournalCode, Rec.JournalCode);
    //     ImportLine2.SetRange(EcritureDate, Rec.EcritureDate);
    //     ImportLine2.SetRange(EcritureNum, Rec.EcritureNum);
    //     ImportLine2.SetRange(PieceRef, Rec.PieceRef);
    //     ImportLine2.SetFilter(CompAuxNum, '<>%1', '');
    //     if ImportLine2.Count > 1 then
    //         exit;
    //     ImportLine2.SetRange(CompAuxNum);
    //     ImportLine2.SetFilter(CompteNum, '445*'); //MapSourceCode."VAT Account No. Filter"); 
    //     ImportLine2.CalcSums(Amount);
    //     exit(ImportLine2.Amount);
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterImportCell(var ImportLine: Record "WanaStart Import FR Line"; var CsvBuffer: Record "CSV Buffer")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeInsert(var ImportLine: Record "WanaStart Import FR Line")
    // begin
    // end;
}
#endif
