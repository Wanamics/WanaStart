codeunit 87102 "wanaStart Suggest Setup"
{
    TableNo = "wanaStart Account";
    trigger OnRun()
    begin
        if Rec.FindSet() then
            repeat
                if Rec."Account Type" = Rec."Account Type"::"G/L Account" then
                    MapGLAccount(Rec);
                case Rec."Account Type" of
                    Rec."Account Type"::Customer:
                        MapCustomer(Rec);
                    Rec."Account Type"::Vendor:
                        MapVendor(Rec);
                    Rec."Account Type"::Employee:
                        MapEmployee(Rec);
                end;
            until Rec.Next() = 0;
    end;

    local procedure MapGLAccount(var pRec: Record "wanaStart Account")
    var
        GLAccount: Record "G/L Account";
        Root: Code[20];
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        Root := pRec."From Account No.";
        repeat
            GLAccount.SetFilter("No.", Root + '*');
            Root := CopyStr(Root, 1, StrLen(Root) - 1);
        until GLAccount.FindFirst() or (StrLen(Root) < 4);

        if GLAccount."No." = '' then
            exit
        else
            if GLAccount."Direct Posting" then
                pRec."Account No." := GLAccount."No."
            else
                case CopyStr(GLAccount."No.", 1, 4) of
                    /*
                        '2000' .. '2199',
                        '2800' .. '2899':
                            SetAccount(pRec, '471200');
                        '3000' .. '3999':
                            SetAccount(pRec, '471300');
                    */
                    '4010' .. '4019',
                    '4040' .. '4049':
                        pRec.Validate("Account Type", pRec."Account Type"::Vendor);
                    '4110' .. '4119',
                    '4160' .. '4169':
                        pRec.Validate("Account Type", pRec."Account Type"::Customer);
                    '4452',
                    '4456':
                        pRec.Validate("Gen. Posting Type", pRec."Gen. Posting Type"::Purchase);
                    '4457':
                        pRec.Validate("Gen. Posting Type", pRec."Gen. Posting Type"::Sale);
                    '5120' .. '5129':
                        pRec.Validate("Account Type", pRec."Account Type"::"Bank Account");
                /*
                '6000' .. '6099',
                '7000', '7099':
                    SetAccount(pRec, '471300');
                */
                end;
        pRec.Modify();
    end;

    /*
    local procedure SetAccount(var pRec: Record "wanaStart Account"; pAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(pAccountNo) then begin
            GLAccount.Validate("No.", pAccountNo);
            GLAccount.Insert(true);
        end;
        pRec.Validate("Account No.", GLAccount."No.");
    end;
    */


    local procedure MapCustomer(var pRec: Record "wanaStart Account")
    var
        Customer: Record Customer;
    begin
        if Customer.Get(pRec."From SubAccount No.") then begin
            pRec."Account No." := Customer."No.";
            pRec.Modify();
        end else begin
            Customer.SetRange(Name, pRec."From Account Name");
            if Customer.FindFirst() then begin
                pRec."Account No." := Customer."No.";
                pRec.Modify();
            end;
        end;
    end;

    local procedure MapVendor(var pRec: Record "wanaStart Account")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(pRec."From SubAccount No.") then begin
            pRec."Account No." := Vendor."No.";
            pRec.Modify();
        end else begin
            Vendor.SetRange(Name, pRec."From Account Name");
            if Vendor.FindFirst() then begin
                pRec."Account No." := Vendor."No.";
                pRec.Modify();
            end;
        end;
    end;

    local procedure MapEmployee(var pRec: Record "wanaStart Account")
    var
        Employee: Record Employee;
    begin
        if Employee.Get(pRec."From SubAccount No.") then begin
            pRec."Account No." := Employee."No.";
            pRec.Modify();
        end else begin
            Employee.SetRange("Last Name", pRec."From Account Name");
            if Employee.FindFirst() then begin
                pRec."Account No." := Employee."No.";
                pRec.Modify();
            end;
        end;
    end;
}