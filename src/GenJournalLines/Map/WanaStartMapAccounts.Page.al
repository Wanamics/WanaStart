namespace Wanamics.WanaStart;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.GeneralLedger.Account;
page 87100 "WanaStart Map Accounts"
{
    ApplicationArea = All;
    Caption = 'Map Accounts';
    PageType = List;
    SourceTable = "WanaStart Map Account";
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
                field("Balance at Date"; Rec."Balance at Date")
                {
                }
                field("Net Change"; Rec."Net Change")
                {
                }
                field("No. of Open Lines"; Rec."No. of Open Lines") { }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT") { Visible = false; }
                field("VAT Amount"; Rec."VAT Amount") { Visible = false; }
                field("VAT %"; Rec."VAT %")
                {
                    Width = 5;
                    BlankZero = true;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        ImportLine: Record "wanaStart Import Line";
                    begin
                        ImportLine.SetRange(CompteNum, Rec."From Account No.");
                        ImportLine.SetRange(CompAuxNum, Rec."From SubAccount No.");
                        case Rec."Account Type" of
                            Rec."Account Type"::Vendor:
                                ImportLine.SetRange("Posting Type", ImportLine."Posting Type"::Purchase);
                            Rec."Account Type"::Customer:
                                ImportLine.SetRange("Posting Type", ImportLine."Posting Type"::Sale);
                            else
                                Rec.FieldError("Account Type");
                        end;
                        Page.RunModal(Page::WanaStart, ImportLine);
                    end;
                }
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
                    Width = 5;
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowAccount();
                    end;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                }
                field("Template Code"; Rec."Template Code")
                {
                }
                // field(GLAccountVATProdPostingGroup; GetGLAccountVATProdPostingGroup())
                // {
                //     Caption = 'G.L Account VAT Prod. Posting Group';
                //     Width = 8;
                //     DrillDown = true;

                //     trigger OnDrillDown()
                //     begin
                //         ShowGLAccountCard();
                //     end;
                // }
                field("G/L Acc. Prod. Posting Group"; Rec."G/L Acc. VAT Prod. P. G.")
                {
                }
                field("WanaStart Source Posting Type"; Rec."WanaStart Source Posting Type")
                {
                }
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    Visible = false;
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    Visible = false;
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    Visible = false;
                }
                field("Dimension 4 Code"; Rec."Dimension 4 Code")
                {
                    Visible = false;
                }
                field("Skip"; Rec.Skip)
                {
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(MapAccounts)
            {
                Caption = 'Map Account Nos.';
                trigger OnAction()
                var
                    lRec: Record "WanaStart Map Account";
                    ConfirmMsg: Label 'Do-you want to map %1 account(s)?';
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    lRec.SetRange("Account No.", '');
                    if Confirm(ConfirmMsg, false, lRec.Count()) then
                        Codeunit.Run(Codeunit::"WanaStart Map Suggest Setup", lRec);
                end;
            }
            action(UpdateAccounts)
            {
                Caption = 'Set Values';
                trigger OnAction()
                var
                    lRec: Record "WanaStart Map Account";
                    MapAccountUpdate: Page "WanaStart Map Account Update";
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
                    lRec: Record "WanaStart Map Account";
                    ConfirmMsg: Label 'Do-you want to create %1 account(s)?';
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    lRec.SetRange("Account No.", '');
                    if Confirm(ConfirmMsg, false, lRec.Count()) then
                        Codeunit.Run(Codeunit::"WanaStart Map Create Accounts", lRec);
                end;
            }
            action(SetVATBusPostingGroup)
            {
                Caption = 'Set VAT Bus. Posting Group';
                trigger OnAction()
                var
                    lRec: Record "WanaStart Map Account";
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    Codeunit.Run(Codeunit::"WanaStart Map Set VAT Bus. PG", lRec);
                end;
            }
            action(SetMapAccountVATProdPostingGroup)
            {
                Caption = 'Set Map Account VAT Prod. Posting Group';
                trigger OnAction()
                var
                    lRec: Record "WanaStart Map Account";
                    VATProductPostingGroup: Record "VAT Product Posting Group";
                    ConfirmMsg: Label 'Do-you want to set %1 for %2 "%3"?';
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    lRec.SetFilter("Account Type", '%1|%2', lRec."Account Type"::Vendor, lRec."Account Type"::Customer);
                    // lRec.SetFilter("Account No.", '<>%1', '');
                    if Page.RunModal(0, VATProductPostingGroup) = Action::LookupOK then
                        if Confirm(ConfirmMsg, false, VATProductPostingGroup.TableCaption, lRec.Count(), Rec.TableCaption) then
                            lRec.ModifyAll("VAT Prod. Posting Group", VATProductPostingGroup.Code, true);
                end;
            }
            action(SetGLAccountVATProdPostingGroup)
            {
                Caption = 'Set G/L Account VAT Prod. Posting Group';
                trigger OnAction()
                var
                    lRec: Record "WanaStart Map Account";
                begin
                    CurrPage.SetSelectionFilter(lRec);
                    SetGLAccountVATProductPostingGroup(lRec);
                end;
            }
        }
        // area(Reporting)
        // {
        //     action(CheckVAT)
        //     {
        //         Caption = 'Check VAT Codeunit';
        //         trigger OnAction()
        //         begin
        //             Codeunit.Run(Codeunit::"wanaStart Import FR Check VAT")
        //             // Xmlport.Run(Xmlport::"wanaStart ImportFR Check VAT", false, true);
        //         end;
        //     }
        //     action(CheckVAT_XmlPort)
        //     {
        //         Caption = 'Check VAT XmlPort';
        //         trigger OnAction()
        //         begin
        //             // Codeunit.Run(Codeunit::"wanaStart Import FR Check VAT")
        //             Xmlport.Run(Xmlport::"wanaStart ImportFR Check VAT");
        //         end;
        //     }
        // }
        area(Navigation)
        {
            action(Lines)
            {
                Caption = 'Lines';
                Image = LedgerEntries;
                RunObject = page WanaStart;
                RunPageLink = CompteNum = field("From Account No."), CompAuxNum = field("From SubAccount No.");
                ShortcutKey = 'Ctrl+F7';
            }
        }
    }

    local procedure SetGLAccountVATProductPostingGroup(var pRec: Record "WanaStart Map Account")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        ConfirmMsg: Label 'Do-you want to set %1 for %2 "%3"?';
        GLAccount: Record "G/L Account";
    begin
        pRec.SetRange("Account Type", pRec."Account Type"::"G/L Account");
        pRec.SetFilter("Account No.", '<>%1', '');
        if Page.RunModal(0, VATProductPostingGroup) <> Action::LookupOK then
            exit;
        if Confirm(ConfirmMsg, false, VATProductPostingGroup.TableCaption, pRec.Count(), GLAccount.TableCaption) then
            if pRec.FindSet() then
                repeat
                    GLAccount.Get(pRec."Account No.");
                    if GLAccount."No."[1] = '6' then
                        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
                    if GLAccount."No."[1] = '7' then
                        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
                    GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                    GLAccount.Modify(true);
                until pRec.Next() = 0;
    end;
}
