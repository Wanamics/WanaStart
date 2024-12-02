codeunit 87100 "WanaStart Import Fixed Assets"
{
    TableNo = "Gen. Journal Line";
    trigger OnRun()
    var
        MustBeEmptyErr: Label 'Journal must be empty';
        ConfirmMsg: Label 'Do you want to create Fixed Assets and suggest depreciation on %1?', Comment = '%1: PostingDate';
        DoneMsg: Label '%1 inserted : %2', Comment = '%1:TableCaption, %2:Inserted';
        FixedAsset: Record "Fixed Asset";
    begin
        Rec.Reset();
        Rec.SetRange("Journal Template Name", Rec."Journal Template Name");
        Rec.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        if not Rec.IsEmpty() then
            Error(MustBeEmptyErr);
        GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        GenJournalBatch.TestField("Bal. Account No.");
        GenJournalBatch.TestField("No. Series");
        FASetup.Get();
        FASetup.TestField("Default Depr. Book");
        if Confirm(ConfirmMsg, false, WorkDate) then begin
            SetDefault(Default);
            Import();
            Message(DoneMsg, FixedAsset.TableCaption, Inserted);
        end;
    end;

    var
        ShortcutDimCode: array[8] of Code[20];
        GenJournalBatch: Record "Gen. Journal Batch";
        ImportBuffer: Record "WanaStart FA Import Buffer";
        Default: Record "Gen. Journal Line";
        FASetup: Record "FA Setup";
        Helper: Codeunit "WanaStart Helper";
        Inserted: Integer;

    local procedure SetDefault(var pRec: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        // NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeries: Codeunit "No. Series";
    begin
        pRec.ShowShortcutDimCode(ShortcutDimCode);
        pRec."Journal Template Name" := GenJournalBatch."Journal Template Name";
        pRec."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        pRec."Source Code" := GenJournalTemplate."Source Code";
        pRec."Reason Code" := GenJournalBatch."Reason Code";
        pRec."Posting No. Series" := GenJournalBatch."Posting No. Series";
        // pRec."Document No." := NoSeriesManagement.TryGetNextNo(GenJournalBatch."No. Series", WorkDate());
        pRec."Document No." := NoSeries.PeekNextNo(GenJournalBatch."No. Series", WorkDate());
        // pRec.TestField("Document No.");
        pRec.Validate("Account Type", pRec."Account Type"::"Fixed Asset");
        pRec.Validate("Posting Date", WorkDate());
    end;

    local procedure Import()
    var
        IStream: InStream;
        FileName: Text;
    begin
        if UploadIntoStream('', '', '', FileName, IStream) then begin
            ImportBuffer.Load(IStream);
            Process();
        end;
    end;

    local procedure Process()
    var
        Progress: Integer;
        Dialog: Dialog;
        AnalyzingLbl: Label 'In Progress...';
    begin
        Dialog.Open(AnalyzingLbl + ' \\' + '#1######');
        Dialog.Update(1, 0);
        if ImportBuffer.FindSet() then
            repeat
                Progress += 1;
                Dialog.Update(1, Progress);
                if InsertFixedAsset() then
                    Inserted += 1;
                InsertLine();
            until ImportBuffer.Next() = 0;
    end;

    local procedure InsertFixedAsset() ReturnValue: Boolean
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        if not FixedAsset.Get(ImportBuffer."No.") then begin
            FixedAsset.TransferFields(ImportBuffer);
            FixedAsset.Insert(true);
            ReturnValue := true;
        end;
        if not FADepreciationBook.Get(ImportBuffer."No.", FASetup."Default Depr. Book") then begin
            FADepreciationBook.Validate("FA No.", FixedAsset."No.");
            FADepreciationBook.Validate("Depreciation Book Code", FASetup."Default Depr. Book");
            FADepreciationBook.Validate("FA Posting Group", ImportBuffer."FA Posting Group");
            FADepreciationBook.Validate("Depreciation Method", ImportBuffer."Depreciation Method");
            FADepreciationBook.Validate("No. of Depreciation Years", ImportBuffer."No. of Depreciation Years");
            FADepreciationBook.Validate("Declining-Balance %", ImportBuffer."Declining-Balance %");
            FADepreciationBook.Validate("Depreciation Starting Date", ImportBuffer."Depreciation Starting Date");
            FADepreciationBook.Insert(true);
        end;
    end;

    local procedure InsertLine()
    var
        Rec: Record "Gen. Journal Line";
    begin
        Rec := Default;
        Rec.Validate("Account No.", ImportBuffer."No.");

        if ImportBuffer."Acquisition Cost" <> 0 then begin
            Rec."Line No." := ImportBuffer."Row No." * 10000;
            Rec.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
            Rec.Validate(Amount, ImportBuffer."Acquisition Cost");
            Rec.Validate("FA Posting Type", Rec."FA Posting Type"::"Acquisition Cost");
            Rec.Insert(true);
        end;
        if ImportBuffer."Depreciation" <> 0 then begin
            Rec."Line No." := ImportBuffer."Row No." * 10000 + 1;
            Rec.Validate(Amount, -ImportBuffer.Depreciation);
            Rec.Validate("FA Posting Type", Rec."FA Posting Type"::Depreciation);
            Rec.Validate("Bal. Account No.", '');
            Rec.Insert(true);
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
        pRec.Modify(true);
    end;
}
