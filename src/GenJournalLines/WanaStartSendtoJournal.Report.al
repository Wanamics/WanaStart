namespace WanaStart.WanaStart;

using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;
using Microsoft.Finance.GeneralLedger.Account;
using System.Reflection;

report 87106 "WanaStart Send to Journal"
{
    Caption = 'WanaStart Send to Journal';
    ProcessingOnly = true;
    ApplicationArea = All;
    dataset
    {
        dataitem(ImportLine; "wanaStart Import Line")
        {
            RequestFilterFields = JournalCode;
            trigger OnAfterGetRecord()
            begin
                ProgressDialog.SetProgress("Line No.");
                GetJournalLines.GetLine(ImportLine); //, GenJnlLine);
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
                    field(GenJournalTemplate; GenJnlLine."Journal Template Name")
                    {
                        Caption = 'Gen. Journal Template';
                        ApplicationArea = All;
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the general journal template that is used by the batch job.';

                        trigger OnValidate()
                        begin
                            GenJnlLine."Journal Batch Name" := '';
                        end;
                    }
                    field(GenJournalBatch; GenJnlLine."Journal Batch Name")
                    {
                        Caption = 'Gen. Journal Batch';
                        ApplicationArea = All;
                        Lookup = true;
                        ToolTip = 'Specifies the general journal batch that is used by the batch job.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.FilterGroup(2);
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch.FilterGroup(0);
                            GenJnlBatch."Journal Template Name" := GenJnlLine."Journal Template Name";
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if Page.RunModal(0, GenJnlBatch) = Action::LookupOK then begin
                                Text := GenJnlBatch.Name;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLine."Journal Batch Name" <> '' then begin
                                GenJnlLine.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                            end;
                        end;
                    }
                    field(VendBalAccountNo; VendBalAccountNo)
                    {
                        Caption = 'Vend. Bal. Account';
                        ApplicationArea = All;
                        TableRelation = "G/L Account" where("Direct Posting" = const(true), "Income/Balance" = const("G/L Account Report Type"::"Balance Sheet"));
                        ToolTip = 'Specifies the bal. account No. for vendor entries (ex : 471401)';
                    }
                    field(CustBalAccountNo; CustBalAccountNo)
                    {
                        Caption = 'Cust. Bal. Account';
                        ApplicationArea = All;
                        TableRelation = "G/L Account" where("Direct Posting" = const(true), "Income/Balance" = const("G/L Account Report Type"::"Balance Sheet"));
                        ToolTip = 'Specifies the bal. account No. for customer entries (ex : 471411)';
                    }
                    field(DocumentPrefix; DocumentNoPrefix)
                    {
                        Caption = 'Document No. Prefix';
                        ApplicationArea = All;
                        ToolTip = 'Spécifies a Document No. prefix';
                    }
                }
            }
        }
    }
    trigger OnPreReport()
    var
        ConfirmLbl: Label 'Warning, %1 line(s) of this journal will be deleted.';
        ContinueLbl: Label 'Do-you want to continue?';
        BalAccountErr: Label 'Vend. Bal. Account and Cust. Bal. Account must be defined.';
        DeletingLbl: Label 'Deleting Journal Lines';
        SendingLbl: Label 'Sending to Journal';
    begin
        CheckWanApplyIsInstalled();
        if (CustBalAccountNo = '') or (VendBalAccountNo = '') then
            error(BalAccountErr);
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJnlBatch.TestField("Copy VAT Setup to Jnl. Lines", false);
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if not GenJnlLine.IsEmpty() then
            if not Confirm(ConfirmLbl + '\' + ContinueLbl, false, GenJnlLine.Count()) then
                Error('');
        ProgressDialog.Open(DeletingLbl);
        GenJnlLine.DeleteAll(true);
        ProgressDialog.Close();

        StartDateTime := CurrentDateTime;
        ProgressDialog.Open(SendingLbl);
        GetJournalLines.Initialize(GenJnlLine, VendBalAccountNo, CustBalAccountNo, DocumentNoPrefix);
    end;

    trigger OnPostReport()
    var
        ProcessLbl: Label 'Processed in %1.';
        OpenGenJournalLbl: Label 'Do you want to open journal?';
    begin
        ProgressDialog.Close();
        Commit();
        if Confirm(ProcessLbl + '\' + OpenGenJournalLbl, false, CurrentDateTime - StartDateTime) then
            Page.Run(Page::"General Journal", GenJnlLine);
    end;

    local procedure CheckWanApplyIsInstalled()
    var
        AllObj: Record AllObj;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        WanApplyNotInstalledLbl: Label 'WanApply extension not installed.';
        AppliesToIdWillNotBeAppliedLbl: Label '"%1" will not be applied', Comment = '%1: FieldCaption("Applies-to ID")';
        ContinueLbl: Label 'Do you want to continue?';
    begin
        if AllObj.Get(AllObj."Object Type"::Codeunit, 87477) and // WanApply Codeunit::"wanApply Cust. Applies Events"
            AllObj.Get(AllObj."Object Type"::Codeunit, 87478) and // WanApply Codeunit::"wanApply Vendor Applies Events"
            AllObj.Get(AllObj."Object Type"::Codeunit, 87479) then // WanApply Codeunit::"wanApply Employee Applies Events"
            exit;
        if not Confirm(WanApplyNotInstalledLbl + '\' + AppliesToIdWillNotBeAppliedLbl + '\' + ContinueLbl, false, TempGenJournalLine.FieldCaption("Applies-to ID")) then
            Error('');
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        StartDateTime: DateTime;
        ProgressDialog: Codeunit "Excel Buffer Dialog Management";
        GetJournalLines: Codeunit "WanaStart Send to Journal";
        VendBalAccountNo, CustBalAccountNo : Code[20];
        DocumentNoPrefix: Code[10];
}
