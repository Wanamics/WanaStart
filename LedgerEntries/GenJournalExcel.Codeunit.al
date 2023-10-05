#IF FALSE
Moved to WanaPort
/*
codeunit 87105 "wanaStart Gen. Journal Excel"
{
    trigger OnRun()
    begin
    end;

    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        RowNo: Integer;
        ColumnNo: Integer;
        SheetName: Label 'Data', Locked = true;
        ShortcutDimCode: array[8] of Code[20];
        GLAccountNotAllowed: Code[20];

    procedure Import(var pRec: Record "Gen. Journal Line")
    var
        ImportFromExcelTitle: Label 'Import Excel File';
        ExcelFileCaption: Label 'Excel Files (*.xlsx)';
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;
        IStream: InStream;
        FileName: Text;
    begin
        if UploadIntoStream('', '', '', FileName, IStream) then begin
            ExcelBuffer.LOCKTABLE;
            ExcelBuffer.OpenBookStream(IStream, SheetName);
            ExcelBuffer.ReadSheet();
            AnalyzeData(pRec);
            ExcelBuffer.DeleteAll();
        end;
    end;

    local procedure AnalyzeData(pRec: Record "Gen. Journal Line")
    var
        lRowNo: Integer;
        lNext: Integer;
        lExists: Boolean;
        lCount: Integer;
        lProgress: Integer;
        lDialog: Dialog;
        ltAnalyzing: Label 'Analyzing Data';

    begin
        pRec.ShowShortcutDimCode(ShortcutDimCode);
        pRec.SetRange("Journal Template Name", pRec."Journal Template Name");
        pRec.SetRange("Journal Batch Name", pRec."Journal Batch Name");
        if pRec.FindLast then;

        lDialog.Open(ltAnalyzing + '\\' + '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
        lDialog.Update(1, 0);
        ExcelBuffer.SetFilter("Row No.", '>1');
        lCount := ExcelBuffer.Count;
        if ExcelBuffer.FindSet then
            repeat
                InitLine(pRec);
                lRowNo := ExcelBuffer."Row No.";
                repeat
                    lProgress += 1;
                    ImportCell(pRec, ExcelBuffer."Column No.", ExcelBuffer."Cell Value as Text");
                    lNext := ExcelBuffer.Next;
                until (lNext = 0) or (ExcelBuffer."Row No." <> lRowNo);
                InsertLine(pRec);
                lDialog.Update(1, Round(lProgress / lCount * 10000, 1));
            until lNext = 0;
    end;

    local procedure InitLine(var pRec: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        pRec.Init;
        GenJournalTemplate.Get(pRec."Journal Template Name");
        GenJournalBatch.Get(pRec."Journal Template Name", pRec."Journal Batch Name");
        pRec."Source Code" := GenJournalTemplate."Source Code";
        pRec."Reason Code" := GenJournalBatch."Reason Code";
        pRec."Posting No. Series" := GenJournalBatch."Posting No. Series";
        pRec."Copy VAT Setup to Jnl. Lines" := GenJournalBatch."Copy VAT Setup to Jnl. Lines";
        pRec."Bal. Account Type" := GenJournalBatch."Bal. Account Type";
        pRec.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        GLAccountNotAllowed := '';
    end;

    local procedure InsertLine(var pRec: Record "Gen. Journal Line")
    begin
        pRec."Line No." += 10000;
        pRec.Insert(true);
        AfterInsert(pRec);
    end;

    local procedure ToDecimal() ReturnValue: Decimal
    begin
        Evaluate(ReturnValue, ExcelBuffer."Cell Value as Text");
    end;

    local procedure ToDate(pCell: Text) ReturnValue: Date
    begin
        Evaluate(ReturnValue, ExcelBuffer."Cell Value as Text");
    end;

    procedure Export(var pRec: Record "Gen. Journal Line")
    var
        lblConfirm: Label 'Do-you want to create an Excel book for %1 %2(s)?';
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";
        lRec: Record "Gen. Journal Line";
    begin
        lRec.SetRange("Journal Template Name", pRec."Journal Template Name");
        lRec.SetRange("Journal Batch Name", pRec."Journal Batch Name");
        if not Confirm(lblConfirm, true, lRec.Count, lRec.TableCaption) then
            exit;

        ProgressDialog.Open('');
        RowNo := 1;
        ColumnNo := 1;
        ExportTitles(pRec);
        if lRec.FindSet then
            repeat
                ProgressDialog.SetProgress(RowNo);
                RowNo += 1;
                ColumnNo := 1;
                ExportLine(lRec);
            until lRec.Next = 0;
        ProgressDialog.Close;

        ExcelBuffer.CreateNewBook(SheetName);
        ExcelBuffer.WriteSheet(Format(pRec."Journal Template Name" + ' ' + pRec."Journal Batch Name"), CompanyName, UserId);
        ExcelBuffer.CloseBook;
        ExcelBuffer.SetFriendlyFilename(SafeFileName(pRec));
        ExcelBuffer.OpenExcel;
    end;

    local procedure SafeFileName(pRec: Record "Gen. Journal Line"): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        exit(FileManagement.GetSafeFileName(pRec."Journal Template Name" + ' ' + pRec."Journal Batch Name"));
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

    local procedure ExportTitles(pRec: Record "Gen. Journal Line")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Posting Date"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Document Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Document No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Account Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Account No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption(Description), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("External Document No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Applies-to ID"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Document Date"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Due Date"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Gen. Posting Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("VAT Bus. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("VAT Prod. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption(Amount), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. Account Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. Account No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. Gen. Posting Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. VAT Bus. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Bal. VAT Prod. Posting Group"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Shortcut Dimension 1 Code"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Shortcut Dimension 2 Code"), true, false, '', ExcelBuffer."Cell Type"::Text);
        GLSetup.Get;
        EnterCell(RowNo, ColumnNo, GLSetup."Shortcut Dimension 3 Code", true, false, '', ExcelBuffer."cell type"::Text);
        EnterCell(RowNo, ColumnNo, GLSetup."Shortcut Dimension 4 Code", true, false, '', ExcelBuffer."cell type"::Text);
        EnterCell(RowNo, ColumnNo, GLSetup."Shortcut Dimension 5 Code", true, false, '', ExcelBuffer."cell type"::Text);
        EnterCell(RowNo, ColumnNo, GLSetup."Shortcut Dimension 6 Code", true, false, '', ExcelBuffer."cell type"::Text);
        EnterCell(RowNo, ColumnNo, GLSetup."Shortcut Dimension 7 Code", true, false, '', ExcelBuffer."cell type"::Text);
        EnterCell(RowNo, ColumnNo, GLSetup."Shortcut Dimension 8 Code", true, false, '', ExcelBuffer."cell type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Job No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Job Task No."), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("Depreciation Book Code"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("FA Posting Type"), true, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.FieldCaption("FA Posting Date"), true, false, '', ExcelBuffer."Cell Type"::Text);

        OnAfterExportTitles(pRec, ColumnNo);
    end;

    local procedure ExportLine(pRec: Record "Gen. Journal Line")
    var
        ShortcutDimCode: array[8] of Code[20];
        i: Integer;
    begin
        EnterCell(RowNo, ColumnNo, Format(pRec."Posting Date"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Document Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Document No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Account Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Account No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec.Description, false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."External Document No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Applies-to ID", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Document Date"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Due Date"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Gen. Posting Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."VAT Bus. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."VAT Prod. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec.Amount), false, false, '', ExcelBuffer."Cell Type"::Number);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. Account Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. Account No."), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."Bal. Gen. Posting Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Bal. VAT Bus. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Bal. VAT Prod. Posting Group", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Shortcut Dimension 1 Code", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Shortcut Dimension 2 Code", false, false, '', ExcelBuffer."Cell Type"::Text);
        pRec.ShowShortcutDimCode(ShortcutDimCode);
        for i := 3 to 8 do
            EnterCell(RowNo, ColumnNo, ShortcutDimCode[i], false, false, '', ExcelBuffer."Cell type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Job No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Job Task No.", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, pRec."Depreciation Book Code", false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."FA Posting Type"), false, false, '', ExcelBuffer."Cell Type"::Text);
        EnterCell(RowNo, ColumnNo, Format(pRec."FA Posting Date"), false, false, '', ExcelBuffer."Cell Type"::Text);

        OnAfterExportLine(pRec, ColumnNo);
    end;

    local procedure ImportCell(var pRec: Record "Gen. Journal Line"; pColumnNo: Integer; pCell: Text)
    var
        Code20: Code[20];
        GLAccount: Record "G/L Account";
    begin
        case pColumnNo of
            1:
                pRec.Validate("Posting Date", ToDate(pCell));
            2:
                begin
                    Evaluate(pRec."Document Type", pCell);
                    pRec.Validate("Document Type");
                end;
            3:
                pRec.Validate("Document No.", pCell);
            4:
                begin
                    Evaluate(pRec."Account Type", pCell);
                    pRec.Validate("Account Type");
                end;
            5:
                if pRec."Account Type" <> pRec."Account Type"::"G/L Account" then
                    pRec.Validate("Account No.", pCell)
                else
                    if not GLAccount.Get(pCell) or GLAccount.Blocked or not GLAccount."Direct Posting" then
                        GLAccountNotAllowed := pCell
                    else
                        pRec.Validate("Account No.", pCell);
            6:
                if GLAccountNotAllowed = '' then
                    pRec.Validate(Description, pCell)
                else
                    pRec.Validate(Description, Copystr(GLAccountNotAllowed + ' ' + pCell, 1, MaxStrLen(pRec.Description)));
            7:
                pRec.Validate("External Document No.", pCell);
            8:
                pRec.Validate("Applies-to ID", pCell);
            9:
                pRec.Validate("Document Date", ToDate(pCell));
            10:
                pRec.Validate("Due Date", ToDate(pCell));
            11:
                begin
                    Evaluate(pRec."Gen. Posting Type", pCell);
                    pRec.Validate("Gen. Posting Type");
                end;
            12:
                pRec.Validate("VAT Bus. Posting Group", pCell);
            13:
                pRec.Validate("VAT Prod. Posting Group", pCell);
            14:
                pRec.Validate(Amount, ToDecimal);
            15:
                begin
                    Evaluate(pRec."Bal. Account Type", pCell);
                    pRec.Validate("Bal. Account Type");
                end;
            16:
                pRec.Validate("Bal. Account No.", pCell);
            17:
                begin
                    Evaluate(pRec."Bal. Gen. Posting Type", pCell);
                    pRec.Validate("Bal. Gen. Posting Type");
                end;
            18:
                pRec.Validate("Bal. VAT Bus. Posting Group", pCell);
            19:
                pRec.Validate("Bal. VAT Prod. Posting Group", pCell);
            20 .. 27:
                ShortcutDimCode[pColumnNo - 19] := pCell;
            28:
                pRec.Validate("Job No.", pCell);
            29:
                pRec.Validate("Job Task No.", pCell);
            30:
                pRec.Validate("Depreciation Book Code", pCell);
            31:
                begin
                    Evaluate(pRec."FA Posting Type", pCell);
                    pRec.Validate("FA Posting Type");
                end;
            32:
                pRec.Validate("FA Posting Date", ToDate(pCell));
            else
                OnAfterImportCell(pColumnNo, pRec);
        end;
    end;

    local procedure AfterInsert(var pRec: Record "Gen. Journal Line")
    var
        i: Integer;
    begin
        pRec.Validate("Shortcut Dimension 1 Code", ShortcutDimCode[1]);
        pRec.Validate("Shortcut Dimension 2 Code", ShortcutDimCode[2]);
        for i := 3 to 8 do
            if ShortcutDimCode[i] <> '' then
                pRec.ValidateShortcutDimCode(i, ShortcutDimCode[i]);
        OnAfterInsert(pRec);
        pRec.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExportTitles(pRec: Record "Gen. Journal Line"; pColumn: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExportLine(pRec: Record "Gen. Journal Line"; pColumn: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportCell(pColumn: Integer; var pRec: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsert(var pRec: Record "Gen. Journal Line")
    begin
    end;
}
*/
#ENDIF