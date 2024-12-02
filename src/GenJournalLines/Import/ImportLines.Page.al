page 87106 "WanaStart Import Lines"
{
    ApplicationArea = All;
    Caption = 'Import Lines';
    PageType = List;
    SourceTable = "WanaStart Import FR Line";
    UsageCategory = Administration;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; Rec."Line No.") { Visible = false; }
                field(JournalCode; Rec.JournalCode) { }
                field(EcritureNum; Rec.EcritureNum) { Editable = true; }
                field(EcritureDate; Rec.EcritureDate) { }
                field(CompteNum; Rec.CompteNum) { }
                field(CompAuxNum; Rec.CompAuxNum) { }
                field(PieceRef; Rec.PieceRef) { }
                field(PieceDate; Rec.PieceDate) { }
                field(EcritureLib; Rec.EcritureLib) { }
                field(EcritureLet; Rec.EcritureLet) { Visible = false; }
                field(Debit; Rec.Debit) { Visible = false; }
                field(Credit; Rec.Credit) { Visible = false; }
                field(Amount; Rec.Amount) { }
                field("VAT Amount"; Rec."VAT Amount") { Visible = false; }
                field("VAT %"; Rec."VAT %") { }
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
                field("Document No."; Rec."Document No.") { Visible = false; }
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
            action(Split)
            {
                Caption = 'Split';
                Image = Split;
                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"WanaStart Import Line Split", Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ImportFECPromoted; ImportFEC) { }
            actionref(MapSourceCodePromoted; MapSourceCode) { }
            actionref(MapAccountsPromoted; MapAccounts) { }
            actionref(SplitPromoted; Split) { }
        }
    }
    var
        MapAccount: Record "WanaStart Map Account";

    trigger OnAfterGetRecord()
    begin
        if MapAccount.Get(Rec.CompteNum, Rec.CompAuxNum) then;
    end;
}
