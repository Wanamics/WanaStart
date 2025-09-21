#if FALSE
codeunit 87131 "WanaStart Import Balance"
{
    trigger OnRun()
    var
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines imported in %2.';
        DeleteLines: Label 'Do you want to delete %1 previous lines?';
    begin
        if not ImportLine.IsEmpty then
            if not Confirm(DeleteLines, false, ImportLine.Count) then
                exit
            else
                ImportLine.DeleteAll();
        StartDateTime := CurrentDateTime;
        // Xmlport.Run(Xmlport::"WanaStart Import Balance", false, true, ImportLine);
        ExcelImport();
        InsertDefaultSourceCode();
        Message(DoneMsg, ImportLine.Count, CurrentDateTime - StartDateTime);
    end;

    var
        ImportLine: Record "WanaStart Import FR Line";
        Default: Record "Gen. Journal Line";
        MapSourceCode: Record "WanaStart Map Source Code";
        MapAccount: Record "WanaStart Map Account";
        ExcelBuffer: Record "Excel Buffer";

    local procedure ExcelImport()
    var
        IStream: InStream;
        FileName: Text;
        ExcelBuffer: Record "Excel Buffer" temporary;
        Next: Integer;
    begin
        if UploadIntoStream('', '', '', FileName, IStream) then begin
            ExcelBuffer.OpenBookStream(IStream, ExcelBuffer.SelectSheetsNameStream(IStream));
            ExcelBuffer.ReadSheet();
            ExcelBuffer.SetFilter("Row No.", '>1');
            if ExcelBuffer.FindSet then
                repeat
                    ImportLine.Init();
                    ImportLine.EcritureNum := Default."Document No.";
                    ImportLine.EcritureDate := Default."Posting Date";
                    ImportLine."Line No." := ExcelBuffer."Row No." * 10000;
                    repeat
                        case ExcelBuffer."Column No." of
                            1:
                                ImportLine.CompteNum := ExcelBuffer."Cell Value as Text";
                            2:
                                ImportLine.EcritureLib := ExcelBuffer."Cell Value as Text";
                            3:
                                ImportLine.Amount := ToDecimal(ExcelBuffer."Cell Value as Text");
                            4:
                                ImportLine."_Shortcut Dimension 1 Code" := ExcelBuffer."Cell Value as Text";
                            5:
                                ImportLine."_Shortcut Dimension 2 Code" := ExcelBuffer."Cell Value as Text";
                        end;
                        Next := ExcelBuffer.Next;
                    until (Next = 0) or (ExcelBuffer."Row No." <> ImportLine."Line No.");
                    InsertLine();
                until Next = 0;
        end;
    end;

    local procedure InsertDefaultSourceCode()
    var
        MapSourceCode: Record "wanaStart Map Source Code";
    begin
        Default.TestField("Document No.");
        Default.TestField("Posting Date");
        Default.TestField("Description");
        MapSourceCode."From Source Name" := 'Opening Balance';
        if MapSourceCode.Insert() then;
    end;

    local procedure InsertLine()
    begin
        // ImportLine."Line No." := LineNo;
        // if ImportLine.CompteNum <> MapAccount."From Account No." then
        if not MapAccount.Get(ImportLine.CompteNum, '') then begin
            MapAccount.Init();
            MapAccount."From Account No." := ImportLine.CompteNum;
            MapAccount."From Account Name" := ImportLine.EcritureLib;
            MapAccount.Insert();
        end;
        // ImportLine.CompteNum := ImportLine.CompteNum;
        // ImportLine.EcritureLib := Default.Description;
        // ImportLine.Amount := ToDecimal(_Amount);
        if ImportLine.Amount > 0 then
            ImportLine.Debit := ImportLine.Amount
        else
            ImportLine.Credit := -ImportLine.Amount;
        // ImportLine."_Shortcut Dimension 1 Code" := _ShortcutDimension1Code;
        // ImportLine."_Shortcut Dimension 2 Code" := _ShortcutDimension2Code;
        ImportLine.Insert();
    end;

    procedure ToDecimal(pText: Text) ReturnValue: Decimal
    begin
        if pText <> '' then
            Evaluate(ReturnValue, pText);
    end;
}
#endif
