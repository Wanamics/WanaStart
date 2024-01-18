page 87100 "wanaStart Map Accounts"
{
    ApplicationArea = All;
    Caption = 'Map Accounts';
    PageType = List;
    SourceTable = "wanaStart Map Account";
    UsageCategory = Administration;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("FEC CompteNum"; Rec."From Account No.")
                {
                    Editable = false;
                }
                field("FEC CompteAuxNum"; Rec."From SubAccount No.")
                {
                    Editable = false;
                }
                field("FEC Account Name"; Rec."From Account Name")
                {
                    Editable = false;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                }
                field("Has Open Lines"; Rec."Has Open Lines") { }
                field("Account Type"; Rec."Account Type")
                {
                }
                field("Account No."; Rec."Account No.")
                {
                }
                field(AccountName; Rec.GetAccountName())
                {
                    Caption = 'Account Name';
                }
                field(VATBusPostingGroup; Rec.GetVATBusPostingGroup())
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                }
                field("Template Code"; Rec."Template Code")
                {
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                }
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                }
                field("Dimension 4 Code"; Rec."Dimension 4 Code")
                {
                }
                field(Skip; Rec.Skip)
                {
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            // action(ImportFEC)
            // {
            //     Caption = 'Import FR Tax Audit File';
            //     Image = ImportCodes;
            //     RunObject = Codeunit "wanaStart Import FR";
            // }
            action(MapAccounts)
            {
                Caption = 'Map Account Nos.';
                trigger OnAction()
                var
                    lRec: Record "wanaStart Map Account";
                    ConfirmMsg: Label 'Do-you want to map %1 account(s)?';
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    lRec.SetRange("Account No.", '');
                    //lRec.SetRange("Account Type", lRec."Account Type"::"G/L Account");
                    if Confirm(ConfirmMsg, false, lRec.Count()) then
                        Codeunit.Run(Codeunit::"wanaStart Suggest Setup", lRec);
                end;
            }
            action(UpdateAccounts)
            {
                Caption = 'Set Values';
                trigger OnAction()
                var
                    lRec: Record "wanaStart Map Account";
                    MapAccountUpdate: Page "wanaStart Map Account Update";
                    ConfirmMsg: Label 'Do-you want to set %1 account(s)?';
                begin
                    if MapAccountUpdate.RunModal() = Action::OK then begin
                        CurrPage.SetSelectionFilter(lRec);
                        if Confirm(ConfirmMsg, true, lRec.Count()) then
                            MapAccountUpdate.Update(lRec);
                    end;
                end;
            }
            action(CreateAccounts)
            {
                Caption = 'Create Accounts';
                trigger OnAction()
                var
                    lRec: Record "wanaStart Map Account";
                    ConfirmMsg: Label 'Do-you want to create %1 account(s)?';
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    lRec.SetRange("Account No.", '');
                    if Confirm(ConfirmMsg, false, lRec.Count()) then
                        Codeunit.Run(Codeunit::"wanaStart Create Accounts", lRec);
                end;
            }
        }
        area(Reporting)
        {
            action(CheckVAT)
            {
                Caption = 'Check VAT Codeunit';
                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"wanaStart Import FR Check VAT")
                    // Xmlport.Run(Xmlport::"wanaStart ImportFR Check VAT", false, true);
                end;
            }
            action(CheckVAT_XmlPort)
            {
                Caption = 'Check VAT XmlPort';
                trigger OnAction()
                begin
                    // Codeunit.Run(Codeunit::"wanaStart Import FR Check VAT")
                    Xmlport.Run(Xmlport::"wanaStart ImportFR Check VAT");
                end;
            }
        }
        area(Navigation)
        {
            // action(MapSourceCodes)
            // {
            //     Caption = 'Map Source Codes';
            //     Image = JournalSetup;
            //     RunObject = page "wanaStart Map Source Codes";
            // }
            action(Lines)
            {
                Caption = 'Lines';
                Image = LedgerEntries;
                RunObject = page "wanaStart Import Lines";
                RunPageLink = CompteNum = field("From Account No."), CompAuxNum = field("From SubAccount No.");
                ShortcutKey = 'Ctrl+F7';
            }
        }
    }
}
