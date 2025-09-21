codeunit 87109 "WanaStart Map Set VAT Bus. PG"
{
    TableNo = "WanaStart Map Account";
    trigger OnRun()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        ConfirmMsg: Label 'Do-you want to set %1 for %2 account(s)?';
    begin
        Rec.SetFilter("Account Type", '%1|%2', Rec."Account Type"::Vendor, Rec."Account Type"::Customer);
        Rec.SetFilter("Account No.", '<>%1', '');
        if Page.RunModal(0, VATBusPostingGroup) <> Action::LookupOK then
            exit;
        if Confirm(ConfirmMsg, false, VATBusPostingGroup.TableCaption, Rec.Count()) then
            if Rec.FindSet() then
                repeat
                    case Rec."Account Type" of
                        Rec."Account Type"::Customer:
                            UpdateCustomer(Rec, VATBusPostingGroup);
                        Rec."Account Type"::Vendor:
                            UpdateVendor(Rec, VATBusPostingGroup);
                    end;
                until Rec.Next() = 0;
    end;

    local procedure UpdateCustomer(pRec: Record "WanaStart Map Account"; pVATBusPostingGroup: Record "VAT Business Posting Group")
    var
        Customer: Record Customer;
    begin
        Customer.Get(pRec."Account No.");
        Customer.Validate("VAT Bus. Posting Group", pVATBusPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure UpdateVendor(pRec: Record "WanaStart Map Account"; pVATBusPostingGroup: Record "VAT Business Posting Group")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(pRec."Account No.");
        Vendor.Validate("VAT Bus. Posting Group", pVATBusPostingGroup.Code);
        Vendor.Modify(true);
    end;
}
