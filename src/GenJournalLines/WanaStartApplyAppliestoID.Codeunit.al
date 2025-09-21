codeunit 87104 "WanaStart Apply Applies-to ID"
{
    Permissions =
        tabledata "Cust. Ledger Entry" = m,
        tabledata "Vendor Ledger Entry" = m,
        tabledata "Employee Ledger Entry" = m;

    trigger OnRun()
    var
        ConfirmLbl: Label 'Do-you want to Apply Customer, Vendor and Employee entries by Applies-to Id?';
    begin
        if not Confirm(ConfirmLbl, false) then
            exit;
        Report.RunModal(87477, false); // WanApply Report::"wan Apply Cust. Applies-to ID"
        Report.RunModal(87478, false); // WanApply Report::"wan Apply Vendor Applies-to ID"
        Report.RunModal(87479, false); // WanApply Report::"wan Apply Empl. Applies-to ID"

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


#if FALSE
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeRunWithCheck, '', false, false)]
    local procedure OnBeforeRunWithCheck()
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
#endif

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeCustLedgEntryInsert, '', false, false)]
    // local procedure OnBeforeCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    // begin
    //     if CustLedgerEntry.Open then
    //         CustLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeVendLedgEntryInsert, '', false, false)]
    // local procedure OnBeforeVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    // begin
    //     if VendorLedgerEntry.Open then
    //         VendorLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnPostEmployeeOnBeforeEmployeeLedgerEntryInsert, '', false, false)]
    // local procedure OnPostEmployeeOnBeforeEmployeeLedgerEntryInsert(var GenJnlLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    // begin
    //     if EmployeeLedgerEntry.Open then
    //         EmployeeLedgerEntry."Applies-to ID" := GenJnlLine."Applies-to ID";
    // end;
}
