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
                    ApplicationArea = All;
                    Editable = false;
                }
                field("FEC CompteAuxNum"; Rec."From SubAccount No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("FEC Account Name"; Rec."From Account Name")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = All;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = All;
                }
                field(AccountName; GetAccountName())
                {
                    ApplicationArea = All;
                    Caption = 'Account Name';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = All;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = All;
                }
                field(Skip; Rec.Skip)
                {
                    ApplicationArea = All;
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
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

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
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    lRec: Record "wanaStart Map Account";
                    GetValues: Page "wanaStart Set Accounts";
                    ConfirmMsg: Label 'Do-you want to set %1 account(s)?';
                begin
                    if GetValues.RunModal() = Action::OK then begin
                        CurrPage.SetSelectionFilter(lRec);
                        if Confirm(ConfirmMsg, true, lRec.Count()) then
                            GetValues.Update(lRec);
                    end;
                end;
            }
            action(CreateAccounts)
            {
                Caption = 'Create Accounts';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

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
    }
    local procedure GetAccountName(): Text
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
    begin
        case Rec."Account Type" of
            Rec."Account Type"::"G/L Account":
                if GLAccount.Get(Rec."Account No.") then
                    exit(GLAccount.Name);
            Rec."Account Type"::Customer:
                if Customer.Get(Rec."Account No.") then
                    exit(Customer.Name);
            Rec."Account Type"::Vendor:
                if Vendor.Get(Rec."Account No.") then
                    Exit(Vendor.Name);
            Rec."Account Type"::Employee:
                if Employee.Get(Rec."Account No.") then
                    exit(Employee.FullName());
            Rec."Account Type"::"Bank Account":
                if BankAccount.Get(Rec."Account No.") then
                    exit(BankAccount.Name);
        end;
    end;

}
