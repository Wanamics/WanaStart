namespace Wanamics.WanaStart;

using Microsoft.Sales.Customer;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;

report 87103 "WanaStart Delete Unmapped Acc."
{
    Caption = 'WanaStart Delete Unmapped Acc.';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = None;
    dataset
    {
        dataitem(MapAccount; "wanaStart Map Account")
        {
            DataItemTableView = sorting("From Account No.", "From SubAccount No.");
            trigger OnPreDataItem()
            begin
                SetFilter("Account Type", '%1|%2', "Account Type"::Vendor, "Account Type"::Customer);
            end;

            trigger OnAfterGetRecord()
            var
                ImportLine: Record "wanaStart Import Line";
            begin
                ImportLine.SetCurrentKey(CompteNum, CompAuxNum);
                ImportLine.SetRange(CompteNum, "From Account No.");
                ImportLine.SetRange(CompAuxNum, "From SubAccount No.");
                if ImportLine.IsEmpty then
                    Delete(true);
            end;
        }
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                if Unmapped("Gen. Journal Account Type"::Customer, "No.") then
                    Delete(true);
            end;
        }
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";


            trigger OnAfterGetRecord()
            begin
                if Unmapped("Gen. Journal Account Type"::Vendor, "No.") then
                    Delete(true);
            end;
        }
    }
    trigger OnPreReport()
    begin
        if not Confirm(('Do you want to delete Vendors and Customers without Import Line?'), false) then
            CurrReport.Quit();
    end;

    local procedure Unmapped(pAccountType: Enum "Gen. Journal Account Type"; pAccountNo: Code[20]): Boolean
    var
        MapAccount: Record "WanaStart Map Account";
    begin
        MapAccount.SetRange("Account Type", pAccountType);
        MapAccount.SetRange("Account No.", pAccountNo);
        exit(MapAccount.IsEmpty);
    end;
}
