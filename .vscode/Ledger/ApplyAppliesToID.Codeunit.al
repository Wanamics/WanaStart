codeunit 81904 "wanaStart Apply Applies-to ID"

{
    trigger OnRun()
    var
        ApplicationMethod: enum "Application Method";
        ApplyCustLedgerEntries: Report "wan Apply Cust. Applies-to ID";
        ApplyVendLedgerEntries: Report "wan Apply Vendor Applies-to ID";
    begin
        ApplyCustLedgerEntries.UseRequestPage(false);
        ApplyCustLedgerEntries.RunModal();
        ApplyVendLedgerEntries.UseRequestPage(false);
        ApplyVendLedgerEntries.RunModal();

        ResetAppliesToIDs();
    end;

    /*
    procedure SetApplicationMethod(pApplicationMethod: Enum "Application Method")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
    tConfirm: TextConst
        ENU = 'Do you want to set "Application Method" to ::"Apply to Oldest" for ALL customers and ALL vendors?',
        FRA = 'Voulez-vous définir "%1" à ''%2'' pour TOUS les clients et TOUS les fournisseurs ?';
    begin
        if not Confirm(tConfirm, false, Customer.FieldCaption("Application Method"), Customer."Application Method"::"Apply to Oldest") then
            exit;
        Customer.ModifyAll("Application Method", pApplicationMethod);
        Vendor.ModifyAll("Application Method", pApplicationMethod);
        Employee.ModifyAll("Application Method", pApplicationMethod);
    end;
    */

    procedure ResetAppliesToIDs()

    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        VendorLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        EmployeeLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        CustLedgerEntry.ModifyAll("Applies-to ID", '');
        VendorLedgerEntry.ModifyAll("Applies-to ID", '');
        EmployeeLedgerEntry.ModifyAll("Applies-to ID", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeCustLedgEntryInsert', '', false, false)]
    local procedure OnBeforeCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
        if CustLedgerEntry.Open then
            CustLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeVendLedgEntryInsert', '', false, false)]
    local procedure OnBeforeVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
        if VendorLedgerEntry.Open then
            VendorLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
    end;
    /* Missing Event
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeEmployeeLedgEntryInsert', '', false, false)]
    local procedure OnBeforeEmployeeLedgEntryInsert(var VendorLedgerEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
        if EmployeeLedgerEntry.Open then
            EmployeeLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
    end;
    */
}
