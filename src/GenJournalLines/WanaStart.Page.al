namespace Wanamics.WanaStart;
using WanaStart.WanaStart;
using Microsoft.Finance.GeneralLedger.Journal;
page 87106 WanaStart
{
    ApplicationArea = All;
    Caption = 'WanaStart';
    PageType = List;
    SourceTable = "wanaStart Import Line";
    UsageCategory = Administration;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                FreezeColumn = EcritureNum;
                field("Line No."; Rec."Line No.") { Visible = false; }
                field(JournalCode; Rec.JournalCode) { }
                field(EcritureNum; Rec.EcritureNum) { Editable = true; Style = Subordinate; StyleExpr = IsSubordinate; }
                field(EcritureDate; Rec.EcritureDate) { }
                field(CompteNum; Rec.CompteNum) { }
                field(CompAuxNum; Rec.CompAuxNum) { }
                field(PieceRef; Rec.PieceRef) { }
                field(PieceDate; Rec.PieceDate) { Visible = false; }
                field(EcritureLib; Rec.EcritureLib) { Style = Subordinate; StyleExpr = IsSubordinate; }
                field(EcritureLet; Rec.EcritureLet) { Visible = false; }
                field(Debit; Rec.Debit) { Visible = false; }
                field(Credit; Rec.Credit) { Visible = false; }
                field(Amount; Rec.Amount) { }
                field(Open; Rec.Open) { Visible = false; }
                field("VAT Bus. Posting Group"; MapAccount.GetVATBusPostingGroup())
                {
                    Caption = 'VAT Bus. Posting Group';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        MapAccount.ShowAccount();
                    end;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { }
                field("VAT %"; Rec."VAT %") { }
                field("VAT Amount"; Rec."VAT Amount") { }
                field("VAT Account Amount"; Rec."VAT Account Amount") { }
                field("VAT Account Amt. %"; Rec."VAT Account Amt. %") { }
                field("VAT Amount Diff."; Rec."VAT Amount Diff.") { }
                field("Document No."; Rec."Document No.") { Visible = false; }
                field("No VAT"; Rec."No VAT") { Visible = false; }
            }
        }
        area(FactBoxes)
        {
            part(Details; "WanaStart Import Lines Details")
            {
                Caption = 'Details';
                ApplicationArea = All;
                SubPageLink =
                    JournalCode = field(JournalCode),
                    EcritureNum = field(EcritureNum),
                    EcritureDate = field(EcritureDate),
                    PieceRef = field(PieceRef);
            }
            part(CheckVAT; "WanaStart Import Check VAT")
            {
                Caption = 'Check VAT';
                ApplicationArea = All;
                SubPageLink =
                    "Line No." = field("Line No."),
                    "Split Line No." = field("Split Line No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ImportFEC)
            {
                Caption = 'Import FEC';
                ApplicationArea = All;
                Image = ImportChartOfAccounts;
                RunObject = codeunit "WanaStart Import FR";
            }
            action(MapSourceCode)
            {
                Caption = 'Map Source Codes';
                ApplicationArea = All;
                Image = JournalSetup;
                RunObject = page "WanaStart Map Source Codes";
            }
            action(MapAccounts)
            {
                Caption = 'Map Accounts';
                ApplicationArea = All;
                Image = Accounts;
                RunObject = page "WanaStart Map Accounts";
            }
            action(SetVAT)
            {
                Caption = 'Set VAT';
                ApplicationArea = All;
                Image = CalculateVAT;
                trigger OnAction()
                var
                    Selection: Record "wanaStart Import Line";
                begin
                    CurrPage.SetSelectionFilter(Selection);
                    Selection.SetFilter(CompAuxNum, '<>%1', '');
                    if Confirm('Do you want to set %1 on %2 line(s)?', false, Selection.FieldCaption("VAT Prod. Posting Group"), Selection.Count) then
                        if Selection.FindSet() then
                            repeat
                                Selection.Validate("VAT Prod. Posting Group");
                                Selection.Modify(true);
                            until Selection.Next = 0;
                end;
            }
            action(Split)
            {
                Caption = 'Split';
                Image = Split;
                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"WanaStart Import Line Split", Rec);
                end;
            }
            // action(Merge)
            // {
            //     Caption = 'Merge';
            //     Image = Group;
            //     trigger OnAction()
            //     begin
            //         Codeunit.Run(Codeunit::"WanaStart Import Line Merge", Rec);
            //     end;
            // }
            action(SetDocumentNoFromEcritureNum)
            {
                Caption = 'Set Document No. from Ecriture Num';
                ApplicationArea = All;
                Image = NumberSetup;
                trigger OnAction()
                var
                    lRec: Record "wanaStart Import Line";
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    SetDocumentNo(lRec, 0);
                end;
            }
            action(SetDocumentNoFromPieceRef)
            {
                Caption = 'Set Document No. from PieceRef';
                ApplicationArea = All;
                Image = NumberSetup;
                trigger OnAction()
                var
                    lRec: Record "wanaStart Import Line";
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    SetDocumentNo(lRec, 1);
                end;
            }
            action(SendToJournal)
            {
                ApplicationArea = All;
                Caption = 'Send to Journal';
                Image = Journal;
                RunObject = Report "WanaStart Send to Journal";
                Ellipsis = true;
            }
            action(GeneralJournal)
            {
                ApplicationArea = All;
                Caption = 'General Journal';
                Image = OpenJournal;
                RunObject = Page "General Journal";
            }
            action(Apply)
            {
                ApplicationArea = All;
                Caption = 'Apply Applies-to IDs';
                Image = ApplyEntries;
                RunObject = Codeunit "wanaStart Apply Applies-to ID";
            }
            action(CleanUp)
            {
                ApplicationArea = All;
                Caption = 'Clean Data Before GoLive';
                Image = DeleteAllBreakpoints;
                RunObject = report "WanaStart Clean Data";
            }
        }
        area(Promoted)
        {
            actionref(MapSourceCode_Promoted; MapSourceCode) { }
            actionref(MapAccounts_Promoted; MapAccounts) { }
            actionref(Split_Promoted; Split) { }
        }
    }
    var
        MapAccount: Record "WanaStart Map Account";
        IsSubordinate: Boolean;

    trigger OnAfterGetRecord()
    begin
        MapAccount.Get(Rec.CompteNum, Rec.CompAuxNum);
        IsSubordinate := Rec."Split Line No." <> 0;
    end;

    local procedure SetDocumentNo(var pRec: Record "wanaStart Import Line"; pFrom: Option EcritureNum,PieceRef)
    var
        FromCaption: Text;
        ConfirmMsg: Label 'Do you want to set the %1 to %2 for %3 selected lines?', Comment = '%1 = Document No., %2 = FieldCaption, %3 = Count';
    begin
        if pFrom = 0 then
            FromCaption := pRec.FieldCaption(EcritureNum)
        else
            FromCaption := pRec.FieldCaption(PieceRef);
        if Confirm(ConfirmMsg, false, pRec.FieldCaption("Document No."), FromCaption, pRec.Count) then
            if pRec.FindSet() then
                repeat
                    if pFrom = 0 then
                        pRec."Document No." := pRec.EcritureNum
                    else
                        pRec."Document No." := pRec.PieceRef;
                    pRec.Modify(true);
                until pRec.Next() = 0;
    end;
}
