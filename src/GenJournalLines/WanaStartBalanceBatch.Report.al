namespace Wanamics.WanaStart;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Account;

report 87101 "WanaStart Balance Batch"
{
    Caption = 'WanaStart Balance Batch';
    ProcessingOnly = true;
    dataset
    {
        dataitem(GenJournalLine; "Gen. Journal Line")
        {
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.";
            DataItemTableView =
                sorting("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.")
                where("Bal. Account No." = const(''));
            trigger OnPreDataItem()
            var
                ConfirmMsg: Label 'Do you want to balance batch journal lines by Posting Date and Document No.?';
            begin
                if not Confirm(ConfirmMsg, true) then
                    exit;
            end;

            trigger OnAfterGetRecord()
            begin
                if (GenJournalLine."Posting Date" <> BalanceLine."Posting Date") or
                    (GenJournalLine."Document No." <> BalanceLine."Document No.") then
                    Balance();
                BalanceLine."Line No." := GenJournalLine."Line No." + 1;
                BalanceLine.Amount -= GenJournalLine.Amount;
            end;

            trigger OnPostDataItem()
            begin
                Balance();
            end;
        }
    }
    requestpage
    {
        SaveValues = true;
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(BalanceAccountNo; GLAccount."No.")
                    {
                        Caption = 'Balance Account No.';
                        ToolTip = 'Specifies the G/L Account to use for balancing the journal lines.';
                        TableRelation = "G/L Account";
                        ApplicationArea = All;
                        Visible = true;
                    }
                }
            }
        }
    }
    trigger OnPreReport()
    begin
        GLAccount.TestField("No.");
        GLAccount.Find();
        GLAccount.TestField("Direct Posting", true);
        GLAccount.TestField("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
    end;

    trigger OnPostReport()
    var
        InsertedMsg: Label '%1 journal line(s) balanced.', Comment = '%1:No. of journal lines inserted';
    begin
        Message(InsertedMsg, Inserted);
    end;

    var
        GLAccount: Record "G/L Account";
        BalanceLine: Record "Gen. Journal Line";
        Inserted: Integer;

    local procedure Balance()
    begin
        if BalanceLine.Amount <> 0 then begin
            BalanceLine.Validate(Amount);
            BalanceLine.Insert();
            Inserted += 1;
        end;
        BalanceLine.Init();
        BalanceLine."Journal Template Name" := GenJournalLine."Journal Template Name";
        BalanceLine."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        BalanceLine."Source Code" := GenJournalLine."Source Code";
        BalanceLine.Validate("Posting Date", GenJournalLine."Posting Date");
        BalanceLine.Validate("Document No.", GenJournalLine."Document No.");
        BalanceLine.Validate("Document Type", GenJournalLine."Document Type");
        BalanceLine.Validate("Account No.", GLAccount."No.");
    end;
}
