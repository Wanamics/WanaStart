codeunit 87104 "wanaStart Apply Applies-to ID"
{
    Permissions =
        tabledata "Cust. Ledger Entry" = m,
        tabledata "Vendor Ledger Entry" = m,
        tabledata "Employee Ledger Entry" = m;

    trigger OnRun()
    var
        ApplyCustLedgerEntries: Report "wan Apply Cust. Applies-to ID";
        ApplyVendLedgerEntries: Report "wan Apply Vendor Applies-to ID";
        ApplyEmplLedgerEntries: Report "wan Apply Empl. Applies-to ID";
    begin
        ApplyCustLedgerEntries.UseRequestPage(false);
        ApplyCustLedgerEntries.RunModal();
        ApplyVendLedgerEntries.UseRequestPage(false);
        ApplyVendLedgerEntries.RunModal();
        ApplyEmplLedgerEntries.UseRequestPage(false);
        ApplyEmplLedgerEntries.RunModal();

        ResetAppliesToIDs();
    end;

    procedure ResetAppliesToIDs()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        CustLedgerEntry.ModifyAll("Applies-to ID", '');
        VendorLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        VendorLedgerEntry.ModifyAll("Applies-to ID", '');
        EmployeeLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostEmployeeOnBeforeEmployeeLedgerEntryInsert', '', false, false)]
    local procedure OnPostEmployeeOnBeforeEmployeeLedgerEntryInsert(var GenJnlLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        if EmployeeLedgerEntry.Open then
            EmployeeLedgerEntry."Applies-to ID" := GenJnlLine."Applies-to ID";
    end;
}
